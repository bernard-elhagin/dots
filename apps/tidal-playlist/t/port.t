use v5.36;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Time::HiRes           qw(time);
use Tidal::Client         qw(save load legacy_digest state_dir uuid);
use Tidal::Catalog        qw(album_seeds artist_match track_rows track_seed search);
use Tidal::IgnoredArtists qw(ignored_artists);
use Tidal::Playlist       qw(create append delete_playlist discover resolve);
use Tidal::Audio          ();

local $ENV{XDG_STATE_HOME} = tempdir( CLEANUP => 1 );
no warnings 'redefine';

sub catalog_doc(@rows) {
    my ( @data, @included );
    for my $row (@rows) {
        my ( $id, $artist, $title, $isrc ) = @$row;
        push @data, { type => 'tracks', id => $id };
        push @included,
            {
            type       => 'tracks',
            id         => $id,
            attributes => {
                title        => $title,
                isrc         => $isrc,
                availability => ['STREAM'],
            },
            relationships => { artists => { data => [ { type => 'artists', id => $artist } ] } }
            },
            { type => 'artists', id => $artist, attributes => { name => $artist } };
    }

    return { data => \@data, included => \@included };
}

subtest 'Python fingerprint and saved plan stay readable' => sub {
    my $payload = { name => 'Música — test', description => '', ids => [ '1', '2' ] };
    is( legacy_digest($payload),
        'c5958597b1536efc109fb4d78ba86204eff65cb347518f1158979bdd5c85c9d6' );
    my $path = "$ENV{XDG_STATE_HOME}/old-plan.json";
    save(
        $path,
        {
            %$payload,
            entries => [ map { { selected => { id => $_ } } } @{ $payload->{ids} } ],
            write   => {
                create_key   => uuid(),
                playlist_id  => 'legacy',
                attempted_at => time,
                complete     => JSON::PP::true,
                fingerprint  => legacy_digest($payload)
            }
        }
    );
    local *Tidal::Playlist::api = sub { die "Completed legacy plan must not make a request\n" };
    is( create( { plan => $path, yes => 1 } )->{tracks}, 2 );
};

subtest 'interrupted create reuses batch keys and verifies order' => sub {
    my $path = "$ENV{XDG_STATE_HOME}/create.json";
    my @ids  = map { "$_" } 1 .. 51;
    my $plan = {
        name    => 'Recovery',
        entries => [ map { { selected => { id => $_ } } } @ids ],
        write   => { create_key => uuid(), add_key => uuid() }
    };
    save( $path, $plan );
    my ( @tracked, $creates, @batch_keys );
    local *Tidal::Playlist::playlist_tracks = sub {
        return map { { id => $_ } } @tracked;
    };
    local *Tidal::Playlist::api = sub ( $method, $endpoint, $payload, %options ) {
        is( $method, 'POST' );
        if ( $endpoint eq '/playlists' ) {
            ++$creates;
            return { data => { id => 'example' } };
        }
        my @items = map { $_->{id} } @{ $payload->{data} };
        push @batch_keys, $options{key};
        if ( @batch_keys == 2 ) {
            die "Simulated lost batch response\n";
        }
        push @tracked, @items;

        return { data => $payload->{data} };
    };
    eval { create( { plan => $path, yes => 1 } ) };
    like( $@, qr/lost batch response/ );
    is( load($path)->{write}{added},                     50 );
    is( create( { plan => $path, yes => 1 } )->{tracks}, 51 );
    is( $batch_keys[1], $batch_keys[2], 'retry reused key' );
    is( $creates,       1,              'only one playlist creation' );
    is_deeply( \@tracked, \@ids );
};

subtest 'append deduplication and delete preview' => sub {
    my @before = track_rows( catalog_doc( [ 'old', 'Can', 'Song', 'original' ] ) );
    my @source = track_rows(
        catalog_doc(
            [ 'duplicate', 'Can', 'Song (Remastered)', 'original' ],
            [ 'new',       'Neu', 'Other',             'next' ]
        )
    );
    local *Tidal::Playlist::playlist_id = sub ( $name, $country ) { return $name };
    local *Tidal::Playlist::playlist_tracks =
        sub ( $id, $country ) { return $id eq 'source' ? @source : @before };
    local *Tidal::Playlist::api = sub ( $method, $endpoint ) {
        is( $method, 'GET', 'preview only makes a read request' );
        return { data => { attributes => { name => 'Destination' } } };
    };
    my $preview = append( { source => 'source', destination => 'dest', country => 'GB' } );
    is_deeply( [ map { $_->{id} } @{ $preview->{append} } ], ['new'] );
    is( delete_playlist( { playlist => 'dest', country => 'GB' } )->{tracks}, 1 );
};

subtest 'a single current track can be previewed and appended once' => sub {
    local $ENV{XDG_STATE_HOME} = tempdir( CLEANUP => 1 );
    my ($track) = track_rows( catalog_doc( [ 'current', 'Artist', 'Current Track', 'current-isrc' ] ) );
    my @destination = ({ id => 'existing' });
    local *Tidal::Playlist::playlist_id = sub ( $name, $country ) {
        is( $name, 'ugotocooked', 'only the destination is resolved by name' );
        return 'dest';
    };
    local *Tidal::Playlist::playlist_tracks = sub ( $id, $country ) {
        is( $id, 'dest', 'only the destination playlist is read' );
        return @destination;
    };
    my $posts = 0;
    local *Tidal::Playlist::api = sub ( $method, $endpoint, $payload, %options ) {
        ++$posts;
        is( $method, 'POST' );
        is( $endpoint, '/playlists/dest/relationships/items' );
        is_deeply( $payload->{data}, [{ id => 'current', type => 'tracks' }] );
        push @destination, $track;
        return { data => $payload->{data} };
    };
    my $args = { track => $track, destination => 'ugotocooked', country => 'GB' };
    is_deeply( append($args)->{append}, [$track] );
    is( $posts, 0, 'preview does not write' );
    $args->{yes} = 1;
    is( append($args)->{appended}, 1 );
    is( append($args)->{appended}, 0 );
    is( $posts, 1, 'repeat invokes no second write' );
    is_deeply( [ map { $_->{id} } @destination ], [qw(existing current)] );
};

subtest 'append recovery reconciles against the live destination before writing' => sub {
    for my $outcome (qw(applied unchanged conflict)) {
        subtest $outcome => sub {
            local $ENV{XDG_STATE_HOME} = tempdir( CLEANUP => 1 );
            my @destination = ('old');
            my @keys;
            my $path = state_dir() . '/operations/append.json';
            save($path, {
                kind => 'append', source => 'source', destination => 'dest', country => 'GB',
                before => ['old'], tracks => [ { id => 'new' }, { id => 'next' } ],
                write => { create_key => uuid(), add_key => uuid() }
            });
            local *Tidal::Playlist::playlist_tracks = sub { map { { id => $_ } } @destination };
            local *Tidal::Playlist::api = sub ( $method, $endpoint, $payload, %options ) {
                push @keys, $options{key};
                my @ids = map { $_->{id} } @{ $payload->{data} };
                push @destination, @ids if @keys > 1 || $outcome eq 'applied';
                die "Lost response\n" if @keys == 1;
                return { data => $payload->{data} };
            };
            my $args = { resume => $path, yes => 1 };
            eval { append($args) };
            like( $@, qr/Lost response/ );
            is( load($path)->{write}{batches}{0}, $keys[0], 'batch key was saved' );
            push @destination, 'new' if $outcome eq 'conflict';
            my $result = eval { append($args) };
            if ( $outcome eq 'conflict' ) {
                like( $@, qr/Destination playlist changed/ );
                is( scalar @keys, 1, 'no second POST on partial or conflicting edits' );
                is_deeply( \@destination, [qw(old new)] );
                ok( !load($path)->{write}{complete} );
            } else {
                is( $result->{appended}, 2 );
                is_deeply( \@destination, [qw(old new next)] );
                my @expected_keys = $outcome eq 'applied' ? ($keys[0]) : ($keys[0], $keys[0]);
                is_deeply( \@keys, \@expected_keys, 'replay only when the batch is missing' );
                ok( load($path)->{write}{complete} );
            }
        };
    }
};

subtest 'artist lookup reports duplicate names and accepts an explicit ID or URL' => sub {
    my @paths;
    local *Tidal::Catalog::api = sub ( $method, $path ) {
        push @paths, $path;
        return { data => { id => 'result' } } if $path =~ m{\A/searchResults\?};
        return { data => { id => '11949', type => 'artists', attributes => { name => 'Joy Division' } } };
    };
    local *Tidal::Catalog::pages = sub ( $path, $visit, @rest ) {
        $visit->({ data => [ map {
            { id => $_, type => 'artists', attributes => { name => 'Joy Division' } }
        } qw(58781034 11949) ] });
    };
    eval { artist_match( 'Joy Division', 'GB' ) };
    like( $@, qr/Multiple TIDAL artists.*11949.*58781034/s );
    for my $selector ( '11949', 'https://tidal.com/browse/artist/11949?foo=bar' ) {
        is_deeply( artist_match( $selector, 'GB' ), { id => '11949', name => 'Joy Division' } );
        is( $paths[-1], '/artists/11949?countryCode=GB', 'explicit selectors skip name search' );
    }
    eval { artist_match( 'https://example.com/artist/11949', 'GB' ) };
    like( $@, qr/Not a TIDAL artist URL/ );
};

subtest 'artist discovery saves a local plan with exclusions' => sub {
    my @seeds = track_rows( catalog_doc( [ 'seed', 'Can', 'Song', 'same' ] ) );
    local *Tidal::Playlist::artist_seeds =
        sub { return ( { id => 'artist', name => 'Can' }, \@seeds ) };
    local *Tidal::Client::api = sub ( $method, $endpoint ) {
        is( $method, 'GET' );
        like( $endpoint, qr{/tracks/seed/relationships/similarTracks\?} );
        return catalog_doc(
            [ 'copy',    'Can',         'Song',  'same' ],
            [ 'blocked', 'Ignored Act', 'Other', 'blocked' ],
            [ 'pick',    'Neu',         'Other', 'new' ]
        );
    };
    my $path   = "$ENV{XDG_STATE_HOME}/discover.json";
    my $result = discover(
        {
            artist             => 'Can',
            country            => 'GB',
            name               => 'Discovery',
            count              => 1,
            'seed-limit'       => 12,
            pages              => 2,
            'max-per-artist'   => 1,
            mood               => [],
            'exclude-playlist' => [],
            'allow-previous'   => 1,
            output             => $path,
            ignored_artists    => { ignoredact => 'Ignored Act' }
        }
    );
    ok( !$result->{created} );
    is( load($path)->{source_artist}{name}, 'Can' );
    is( $result->{tracks}[0]{id},           'pick' );
};

subtest 'album discovery resolves the release and excludes unsampled album tracks' => sub {
    local $ENV{XDG_STATE_HOME} = tempdir( CLEANUP => 1 );
    my $album_resource = sub ( $id, $artist, $title = 'Album' ) {
        return { type => 'albums', id => $id, attributes => { title => $title, releaseDate => '1979-06-15' },
            relationships => { artists => { data => [{ type => 'artists', id => $artist }] } } };
    };
    my @albums = ($album_resource->('12', 'band'), $album_resource->('14', 'namesake'),
        $album_resource->('15', 'band', 'Second Album (Deluxe Edition)'));
    my @artists = (
        { type => 'artists', id => 'band', attributes => { name => 'The Band' } },
        { type => 'artists', id => 'namesake', attributes => { name => 'Another Band' } }
    );
    my @seed_requests;
    my $api = sub ( $method, $path ) {
        die "Unexpected write: $method\n" unless $method eq 'GET';
        return { data => { id => 'results' } } if $path =~ m{\A/searchResults\?};
        return { data => [ map { { type => 'albums', id => $_->{id} } } @albums ], included => [ @albums, @artists ] }
            if $path =~ m{\A/searchResults/results/relationships/albums\?};
        return { data => $albums[0], included => \@artists } if $path =~ m{\A/albums/12\?};
        if ( $path eq '/albums/12/relationships/items?page=two' ) {
            my $last = catalog_doc( [ '2', 'The Band', 'Last', 'last' ] );
            push @{ $last->{data} }, { type => 'tracks', id => '3' };
            return $last;
        }
        if ( $path =~ m{\A/albums/12/relationships/items\?} ) {
            my $first = catalog_doc( [ '1', 'The Band', 'First', 'first' ] );
            $first->{links}{next} = '/albums/12/relationships/items?page=two';
            return $first;
        }
        if ( $path =~ m{\A/tracks/([^/]+)/relationships/similarTracks\?} ) {
            push @seed_requests, $1;
            return catalog_doc(
                [ '2', 'The Band', 'Last', 'last' ],
                [ '4', 'The Band', 'Last (Remastered)', 'last' ],
                [ '3', 'The Band', 'Missing from album metadata', 'missing' ],
                [ '5', 'New Artist', 'New Song', 'new' ]
            );
        }
        die "Unexpected request: $path\n";
    };
    local *Tidal::Catalog::api = $api;
    local *Tidal::Client::api  = $api;
    local *Tidal::Playlist::progress = sub { };

    eval { album_seeds( 'Album', 'GB' ) };
    like( $@, qr/Multiple TIDAL albums.*\/album\/12.*\/album\/14/s );
    eval { album_seeds( 'The Band - Second Album', 'GB' ) };
    like( $@, qr/No exact album match.*Second Album \(Deluxe Edition\).*\/album\/15/s );
    eval { album_seeds( 'https://example.com/album/12', 'GB' ) };
    like( $@, qr/Not a TIDAL album URL/ );
    for my $selector ('12', 'https://tidal.com/browse/album/12?u') {
        my ( $album, $tracks ) = album_seeds( $selector, 'GB' );
        is( $album->{id}, '12' );
        is_deeply( [ map { $_->{id} } @$tracks ], [qw(1 2 3)], 'reads the full album in order' );
    }

    my $result = discover({
        album => 'The Band - Album', country => 'GB', name => 'Album discovery', count => 1,
        'seed-limit' => 1, pages => 1, mood => [], 'exclude-playlist' => []
    });
    is_deeply( \@seed_requests, ['1'] );
    is_deeply( $result->{unavailable_seeds}, ['3'] );
    is( $result->{tracks}[0]{id}, '5', 'album tracks and their alternate editions are excluded' );
    is_deeply( load($result->{plan})->{source_album}, {
        id => '12', title => 'Album', artists => ['The Band'], release_date => '1979-06-15'
    } );
};

subtest 'saved ignored artists exclude collaborators and guard older plans before writes' => sub {
    local $ENV{XDG_STATE_HOME} = tempdir( CLEANUP => 1 );
    ignored_artists('Ignored Act');
    my $ignored = ignored_artists( ' ignored act ', 'Other Act' );
    is_deeply( [ sort values %$ignored ], [ 'Ignored Act', 'Other Act' ] );
    is_deeply( ignored_artists(), $ignored, 'names are reused without supplying flags again' );

    my ( $input, $output ) = map { "$ENV{XDG_STATE_HOME}/$_.json" } qw(input output);
    save(
        $input,
        {
            name   => 'Resolved',
            tracks => [
                { artist => 'IGNORED ACT', title => 'Skip directly' },
                { artist => 'Guest',       title => 'Skip collaboration' },
                { artist => 'Allowed',     title => 'Keep' },
            ]
        }
    );
    my $blocked =
        { id => '1', artist => 'Guest, Ignored Act', artists => [ 'Guest', 'Ignored Act' ] };
    my ($allowed) = track_rows( catalog_doc( [ '2', 'Allowed', 'Keep', 'allowed' ] ) );
    local *Tidal::Playlist::progress = sub { };
    local *Tidal::Playlist::search   = sub ( $wanted, $country, $pages ) {
        isnt( $wanted->{artist}, 'IGNORED ACT', 'directly excluded suggestion never hits search' );
        return ( $wanted->{artist} eq 'Guest' ? $blocked : $allowed, [ $blocked, $allowed ] );
    };
    my $result = resolve(
        {
            input           => $input,
            output          => $output,
            country         => 'GB',
            pages           => 1,
            ignored_artists => $ignored
        }
    );
    is( $result->{skipped_ignored}, 2 );
    my $plan = load($output);
    is( $plan->{expected_tracks}, 1 );
    is_deeply( $plan->{entries}[0]{candidates}, [$allowed] );

    $plan->{entries}[0]{selected} = { id => '1' };
    save( $output, $plan );
    local *Tidal::Playlist::track_details = sub ( $id, $country ) { return $blocked };
    local *Tidal::Playlist::api =
        sub { fail('Ignored track must be caught before a write'); die "Unexpected write\n" };
    eval { create( { plan => $output, yes => 1, ignored_artists => $ignored } ) };
    like( $@, qr/Track 1 credits an ignored artist/ );
    ok( !load($output)->{write}{attempted_at} );
};

subtest 'partially expanded and legacy credits are verified before creation' => sub {
    local $ENV{XDG_STATE_HOME} = tempdir( CLEANUP => 1 );
    my $doc = catalog_doc( [ '8', 'Lead', 'Single', 'song' ] );
    push @{ $doc->{included}[0]{relationships}{artists}{data} }, { type => 'artists', id => 'guest' };
    my ($partial) = track_rows($doc);
    is_deeply( $partial->{artist_ids}, ['Lead', 'guest'] );
    ok( !$partial->{artist_credits_complete} );
    my ($lead_only) = track_rows( catalog_doc( [ '8', 'Lead', 'Single', 'song' ] ) );
    push @{ $doc->{included} }, { type => 'artists', id => 'guest', attributes => { name => 'Ignored Guest' } };
    my ($complete) = track_rows($doc);
    ok( $complete->{artist_credits_complete} );

    my $path = "$ENV{XDG_STATE_HOME}/credits-plan.json";
    my $plan = { name => 'Credits', entries => [{ selected => $partial }], write => { create_key => uuid() } };
    my $args = { plan => $path, yes => 1, ignored_artists => { ignoredguest => 'Ignored Guest' } };
    local *Tidal::Playlist::api = sub { fail('unverified track must never be written'); die "Unexpected write\n" };
    my $lookup = $lead_only;
    local *Tidal::Playlist::track_details = sub ( $id, $country ) { return $lookup };
    save( $path, $plan );
    eval { create($args) };
    like( $@, qr/Cannot verify all artist credits/, 'a lookup that loses a known ID remains incomplete' );
    $lookup = $complete;
    eval { create($args) };
    like( $@, qr/credits an ignored artist/, 'a lookup that finds the guest blocks the write' );
    $plan->{entries}[0]{selected} = { id => '8', artist => 'Lead', artists => ['Lead'] };
    save( $path, $plan );
    eval { create($args) };
    like( $@, qr/credits an ignored artist/, 'a populated legacy artist list also gets checked' );
    ok( !load($path)->{write}{attempted_at} );

    my $recommendations = catalog_doc( [ '8', 'Lead', 'Single', 'song' ], [ '9', 'Allowed', 'Other', 'other' ] );
    push @{ $recommendations->{included}[0]{relationships}{artists}{data} }, { type => 'artists', id => 'guest' };
    local *Tidal::Playlist::track_seed = sub { return { id => 'seed' } };
    local *Tidal::Playlist::pages = sub ( $path, $visit, @rest ) { $visit->($recommendations) };
    my $result = discover({
        track => 'seed', country => 'GB', name => 'Verified discovery', count => 1,
        'seed-limit' => 1, pages => 1, mood => [], 'exclude-playlist' => [],
        ignored_artists => $args->{ignored_artists}
    });
    is( $result->{tracks}[0]{id}, '9', 'the recommendation with a hidden ignored artist is excluded' );
};

subtest 'track search checks fallback terms before accepting a remaster' => sub {
    my $remaster = catalog_doc( [ '1', 'Artist', 'Song', 'master' ] );
    $remaster->{included}[0]{attributes}{version} = '2020 Remaster';
    my $original = catalog_doc( [ '2', 'Artist', 'Song', 'original' ] );
    my ( $with_original, @queries );
    local *Tidal::Catalog::api = sub ( $method, $path ) {
        push @queries, $path;
        return { data => { id => scalar @queries } };
    };
    local *Tidal::Catalog::pages = sub ( $path, $visit, @rest ) {
        if ( $path =~ m{/1/} ) { $visit->($remaster) }
        elsif ($with_original) { $visit->($original) }
    };
    my ($selected) = search( { artist => 'Artist', title => 'Song' }, 'GB', 1 );
    is( $selected->{id}, '1', 'the sole remaster still works' );
    is( scalar @queries, 3 );
    @queries = ();
    $with_original = 1;
    ($selected) = search( { artist => 'Artist', title => 'Song' }, 'GB', 1 );
    is( $selected->{id}, '2', 'an original from the fallback wins' );
    is( scalar @queries, 2 );
};

subtest 'unavailable favorites do not consume successful seed slots' => sub {
    local $ENV{XDG_STATE_HOME} = tempdir( CLEANUP => 1 );
    local *Tidal::Playlist::favorite_tracks = sub {
        return ({ id => 'known-unavailable', available => 0 }, { id => 'missing' }, { id => 'playable' });
    };
    my @requested;
    local *Tidal::Playlist::pages = sub ( $path, $visit, @rest ) {
        my ($id) = $path =~ m{\A/tracks/([^/]+)/};
        push @requested, $id;
        die "TIDAL HTTP 410: unavailable\n" if $id eq 'missing';
        $visit->(catalog_doc( [ 'known-unavailable', 'Unavailable', 'Old', '' ], [ 'pick', 'New', 'Other', '' ] ));
    };
    my $result = discover({
        'from-favorites' => 1, country => 'GB', name => 'Favorites', count => 1,
        'seed-limit' => 1, pages => 1, mood => [], 'exclude-playlist' => []
    });
    is_deeply( \@requested, [qw(missing playable)] );
    is_deeply( $result->{unavailable_seeds}, [qw(known-unavailable missing)] );
    is( $result->{tracks}[0]{id}, 'pick', 'unavailable favorite IDs still exclude matching candidates' );
    is_deeply( $result->{tracks}[0]{seeds}, ['playable'] );
};

subtest 'track discovery uses exactly one seed and excludes its recording' => sub {
    local *Tidal::Catalog::api = sub ( $method, $endpoint ) {
        is( $method, 'GET' );
        like( $endpoint, qr{\A/tracks/123\?} );
        return catalog_doc( [ '123', 'Can', 'Song', 'same' ] );
    };
    my @recommendation_requests;
    local *Tidal::Client::api = sub ( $method, $endpoint ) {
        is( $method, 'GET' );
        push @recommendation_requests, $endpoint;
        return catalog_doc( [ '456', 'Can', 'Song (Remastered)', 'same' ],
            [ '789', 'Neu', 'Other', 'new' ] );
    };
    my $path   = "$ENV{XDG_STATE_HOME}/track-discover.json";
    my $result = discover(
        {
            track              => 'https://tidal.com/browse/track/123?u',
            country            => 'GB',
            name               => 'Track discovery',
            count              => 1,
            'seed-limit'       => 12,
            pages              => 2,
            'max-per-artist'   => 1,
            mood               => [],
            'exclude-playlist' => [],
            'allow-previous'   => 1,
            output             => $path
        }
    );
    is( scalar @recommendation_requests, 1 );
    like( $recommendation_requests[0], qr{\A/tracks/123/relationships/similarTracks\?} );
    ok( !$result->{created} );
    my $plan = load($path);
    is( $plan->{source_track}{id},         '123' );
    is( $plan->{entries}[0]{selected}{id}, '789' );
    is_deeply( $plan->{entries}[0]{seed_track_ids}, ['123'] );
    is( track_seed( '123', 'GB', 2 )->{id}, '123' );
    eval { track_seed( 'https://example.org/track/123', 'GB', 2 ) };
    like( $@, qr/Not a TIDAL track URL/ );

    local *Tidal::Catalog::search = sub ( $wanted, $country, $limit ) {
        is_deeply( $wanted, { artist => 'Can', title => 'Song - Part Two' } );
        is( $country, 'GB' );
        is( $limit,   2 );
        return ( { id => '123' }, [] );
    };
    is( track_seed( 'Can - Song - Part Two', 'GB', 2 )->{id}, '123' );
};

subtest 'track and artist use the track seed and filter candidates by credited artist ID' => sub {
    local *Tidal::Playlist::track_seed = sub ( $value, $country, $limit ) {
        is( $value, '123' );
        return ( track_rows( catalog_doc( [ '123', 'Seed Act', 'Seed Song', 'source' ] ) ) )[0];
    };
    local *Tidal::Playlist::artist_match = sub ( $name, $country ) {
        is( $name, 'Target Act' );
        return { id => 'Target Act', name => 'Target Act' };
    };
    local *Tidal::Client::api = sub ( $method, $endpoint ) {
        is( $method, 'GET' );
        like( $endpoint, qr{\A/tracks/123/relationships/similarTracks\?} );
        my $doc = catalog_doc(
            [ '1', 'Namesake',   'Unrelated', 'wrong' ],
            [ '2', 'Target Act', 'First',     'first' ],
            [ '3', 'Target Act', 'Second',    'second' ]
        );
        for my $item ( @{ $doc->{included} } ) {
            $item->{attributes}{name} = 'Target Act' if $item->{id} eq 'Namesake';
        }
        return $doc;
    };

    my $path   = "$ENV{XDG_STATE_HOME}/artist-track-discovery.json";
    my $result = discover(
        {
            track              => '123',
            artist             => 'Target Act',
            country            => 'GB',
            name               => 'Target',
            count              => 20,
            'seed-limit'       => 12,
            pages              => 2,
            mood               => [],
            'exclude-playlist' => [],
            'allow-previous'   => 1,
            output             => $path
        }
    );
    is_deeply( [ map { $_->{id} } @{ $result->{tracks} } ], [ '2', '3' ] );
    my $plan = load($path);
    is( $plan->{source_track}{id},  '123' );
    is( $plan->{output_artist}{id}, 'Target Act' );
};

subtest 'covers require a marked performance of the seed composition and an exact ISRC match' =>
    sub {
    my $song        = { id => 'work-id', title => 'Song' };
    my $performance = sub ( $work, @attributes ) {
        return { type => 'performance', work => $work, attributes => \@attributes };
    };
    my $seed_isrc  = 'USAAA0100001';
    my $cover_isrc = 'USAAA0100002';
    local *Tidal::Playlist::track_seed = sub ( $value, $country, $limit ) {
        is( $value, '123' );
        return ( track_rows( catalog_doc( [ '123', 'Original', 'Song', $seed_isrc ] ) ) )[0];
    };
    local *Tidal::Covers::musicbrainz = sub ( $path, %params ) {
        if ( $path eq "isrc/$seed_isrc" ) {
            return {
                recordings => [ { id => 'original', relations => [ $performance->($song) ] } ] };
        }
        is( $path,         'recording' );
        is( $params{work}, $song->{id} );
        my @rows =
            $params{offset} == 0
            ? (
            {
                id        => 'original',
                isrcs     => [ $seed_isrc, 'USAAA0100006' ],
                relations => [ $performance->($song) ]
            },
            {
                id        => 'unrelated',
                isrcs     => ['USAAA0100003'],
                relations => [ $performance->( { id => 'other' }, 'cover' ) ]
            }
            )
            : (
            {
                id        => 'cover',
                isrcs     => [ $cover_isrc, 'USAAA0100007' ],
                relations => [ $performance->( $song, 'cover' ) ]
            },
            {
                id        => 'karaoke',
                isrcs     => ['USAAA0100004'],
                relations => [ $performance->( $song, 'cover', 'karaoke' ) ]
            },
            { id => 'unmarked', isrcs => ['USAAA0100005'], relations => [ $performance->($song) ] }
            );

        return { recordings => \@rows, 'recording-count' => 5 };
    };
    local *Tidal::Client::api = sub ( $method, $endpoint ) {
        is( $method, 'GET' );
        is( $endpoint,
            '/tracks?countryCode=GB&filter%5Bisrc%5D=USAAA0100002%2CUSAAA0100007&include=artists' );
        return catalog_doc(
            [ '456', 'Cover Artist',     'Song',              $cover_isrc ],
            [ '500', 'Another Credit',   'Alternative Title', 'USAAA0100007' ],
            [ '789', 'Unrelated Artist', 'Song',              'USAAA0100003' ]
        );
    };
    my $path   = "$ENV{XDG_STATE_HOME}/covers.json";
    my $result = discover(
        {
            covers             => '123',
            country            => 'GB',
            name               => 'Covers',
            count              => 12,
            pages              => 2,
            'max-per-artist'   => 1,
            mood               => [],
            'exclude-playlist' => [],
            'allow-previous'   => 1,
            output             => $path
        }
    );
    is_deeply( [ map { $_->{id} } @{ $result->{tracks} } ], ['456'] );
    ok( !$result->{created} );
    my $plan = load($path);
    is_deeply( $plan->{musicbrainz_work}, $song );
    is( $plan->{entries}[0]{selected}{musicbrainz_recording_id}, 'cover' );
    };

subtest 'off-origin pagination does not send a request' => sub {
    local *Tidal::Client::api = sub { die "Unexpected request\n" };
    eval {
        Tidal::Client::pages( 'https://example.com/path', sub { fail('Unexpected document') } );
    };
    like( $@, qr/off-origin/ );
};

subtest 'OAuth refresh preserves existing state and replays the write key' => sub {
    my $path = Tidal::Client::state_dir() . '/tokens.json';
    save(
        $path,
        {
            access_token  => 'old',
            refresh_token => 'refresh',
            client_id     => 'client',
            scope         => 'playlists.write',
            expires_at    => time + 600
        }
    );
    my @calls;
    local *Tidal::Client::transport = sub ( $method, $url, $headers, $body ) {
        push @calls, [ $method, $url, $headers, $body ];
        return ( 401, '{}',                     undef ) if @calls == 1;
        return ( 200, '{"access_token":"new"}', undef ) if @calls == 2;
        return ( 204, '',                       undef );
    };
    is_deeply( Tidal::Client::api( 'DELETE', '/playlists/test', undef, key => 'same-key' ), {} );
    is( $calls[0][2]{'Idempotency-Key'}, $calls[2][2]{'Idempotency-Key'} );
    is( $calls[2][2]{Authorization},     'Bearer new' );
    is( load($path)->{refresh_token},    'refresh' );
    is( ( stat($path) )[2] & 0777,       0600 );
};

subtest 'delete sends its saved key and verifies absence' => sub {
    my $path = "$ENV{XDG_STATE_HOME}/delete.json";
    my $key  = uuid();
    save(
        $path,
        {
            kind        => 'delete',
            playlist_id => 'example',
            name        => 'Example',
            tracks      => [],
            write       => { create_key => $key }
        }
    );
    my @methods;
    local *Tidal::Playlist::api = sub ( $method, $endpoint, $payload = undef, %options ) {
        push @methods, $method;
        die "TIDAL HTTP 404: Missing\n" if $method eq 'GET';
        is( load($path)->{write}{create_key}, $options{key}, 'key was saved before deletion' );
        return {};
    };
    is( delete_playlist( { resume => $path, yes => 1 } )->{deleted}, 'example' );
    is_deeply( \@methods, [ 'DELETE', 'GET' ] );
    ok( load($path)->{write}{complete} );
};

subtest 'deletion backups are preserved but do not add to recommendation history' => sub {
    local $ENV{XDG_STATE_HOME} = tempdir( CLEANUP => 1 );
    my $key  = uuid();
    my $path = "$ENV{XDG_STATE_HOME}/delete.json";
    save($path, {
        kind => 'delete', playlist_id => 'manual', name => 'Manual',
        tracks => [ { id => 'removed' } ], write => { create_key => $key }
    });
    save( state_dir() . '/records/create.json', { kind => 'create', tracks => [{ id => 'history' }] } );
    local *Tidal::Playlist::api = sub ( $method, $endpoint, $payload = undef, %options ) {
        die "TIDAL HTTP 404: Missing\n" if $method eq 'GET';
        return {};
    };
    my $result = delete_playlist({ resume => $path, yes => 1 });
    is( load($result->{backup})->{tracks}[0]{id}, 'removed' );
    is( load(state_dir() . "/records/$key.json")->{kind}, 'delete' );
    local *Tidal::Playlist::track_seed = sub { return { id => 'seed' } };
    local *Tidal::Playlist::pages = sub ( $path, $visit, @rest ) {
        $visit->(catalog_doc( [ 'history', 'Heard', 'Song', '' ], [ 'removed', 'Fresh', 'Song', '' ] ));
    };
    my $discovery = discover({
        track => 'seed', country => 'GB', name => 'History', count => 1,
        'seed-limit' => 1, pages => 1, mood => [], 'exclude-playlist' => []
    });
    is( $discovery->{tracks}[0]{id}, 'removed', 'the created track stays excluded and the deleted track can be picked' );
};

subtest 'audio measurements preserve silence and detect rhythmic attacks' => sub {
    my @samples = (0) x ( 22_050 * 5 );
    my $silent  = Tidal::Audio::measurements( \@samples );
    is( $silent->{bpm}, undef );
    is_deeply( $silent->{moods}, [] );
    for ( my $beat = 0 ; $beat < @samples ; $beat += 11_025 ) {
        $samples[ $beat + $_ ] = sin( $_ * .2 ) * exp( -$_ / 100 ) for 0 .. 299;
    }
    my $rhythm = Tidal::Audio::measurements( \@samples );
    ok(
        defined( $rhythm->{bpm} )
            && ( abs( $rhythm->{bpm} - 60 ) < 3 || abs( $rhythm->{bpm} - 120 ) < 3 ),
        'recognizes 120 bpm or half tempo'
    ) or diag explain $rhythm;
};

done_testing;

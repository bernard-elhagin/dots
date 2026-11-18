use v5.36;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Time::HiRes qw(time);
use Tidal::Client qw(save load legacy_digest uuid);
use Tidal::Catalog qw(track_rows track_seed);
use Tidal::IgnoredArtists qw(ignored_artists);
use Tidal::Playlist qw(create append delete_playlist discover resolve);
use Tidal::Audio ();

local $ENV{XDG_STATE_HOME} = tempdir(CLEANUP => 1);
no warnings 'redefine';

sub catalog_doc(@rows) {
    my (@data, @included);
    for my $row (@rows) {
        my ($id, $artist, $title, $isrc) = @$row;
        push @data, {type => 'tracks', id => $id};
        push @included, {type => 'tracks', id => $id, attributes => {
            title => $title, isrc => $isrc, availability => ['STREAM'],
        }, relationships => {artists => {data => [{type => 'artists', id => $artist}]}}},
        {type => 'artists', id => $artist, attributes => {name => $artist}};
    }

    return {data => \@data, included => \@included};
}

subtest 'Python fingerprint and saved plan stay readable' => sub {
    my $payload = {name => 'Música — test', description => '', ids => ['1', '2']};
    is(legacy_digest($payload), 'c5958597b1536efc109fb4d78ba86204eff65cb347518f1158979bdd5c85c9d6');
    my $path = "$ENV{XDG_STATE_HOME}/old-plan.json";
    save($path, {%$payload, entries => [map { {selected => {id => $_}} } @{$payload->{ids}}],
        write => {create_key => uuid(), playlist_id => 'legacy', attempted_at => time,
            complete => JSON::PP::true, fingerprint => legacy_digest($payload)}});
    local *Tidal::Playlist::api = sub { die "Completed legacy plan must not make a request\n" };
    is(create({plan => $path, yes => 1})->{tracks}, 2);
};

subtest 'interrupted create reuses batch keys and verifies order' => sub {
    my $path = "$ENV{XDG_STATE_HOME}/create.json";
    my @ids = map { "$_" } 1..51;
    my $plan = {name => 'Recovery', entries => [map { {selected => {id => $_}} } @ids],
        write => {create_key => uuid(), add_key => uuid()}};
    save($path, $plan);
    my (@tracked, $creates, @batch_keys);
    local *Tidal::Playlist::playlist_tracks = sub { return map { {id => $_} } @tracked };
    local *Tidal::Playlist::api = sub ($method, $endpoint, $payload, %options) {
        is($method, 'POST');
        if ($endpoint eq '/playlists') {
            ++$creates;
            return {data => {id => 'example'}};
        }
        my @items = map { $_->{id} } @{$payload->{data}};
        push @batch_keys, $options{key};
        if (@batch_keys == 2) {
            die "Simulated lost batch response\n";
        }
        push @tracked, @items;

        return {data => $payload->{data}};
    };
    eval { create({plan => $path, yes => 1}) };
    like($@, qr/lost batch response/);
    is(load($path)->{write}{added}, 50);
    is(create({plan => $path, yes => 1})->{tracks}, 51);
    is($batch_keys[1], $batch_keys[2], 'retry reused key');
    is($creates, 1, 'only one playlist creation');
    is_deeply(\@tracked, \@ids);
};

subtest 'append deduplication and delete preview' => sub {
    my @before = track_rows(catalog_doc(['old', 'Can', 'Song', 'original']));
    my @source = track_rows(catalog_doc(
        ['duplicate', 'Can', 'Song (Remastered)', 'original'], ['new', 'Neu', 'Other', 'next']));
    local *Tidal::Playlist::playlist_id = sub ($name, $country) { return $name };
    local *Tidal::Playlist::playlist_tracks = sub ($id, $country) { return $id eq 'source' ? @source : @before };
    local *Tidal::Playlist::api = sub ($method, $endpoint) {
        is($method, 'GET', 'preview only makes a read request');
        return {data => {attributes => {name => 'Destination'}}};
    };
    my $preview = append({source => 'source', destination => 'dest', country => 'GB'});
    is_deeply([map { $_->{id} } @{$preview->{append}}], ['new']);
    is(delete_playlist({playlist => 'dest', country => 'GB'})->{tracks}, 1);
};

subtest 'artist discovery saves a local plan with exclusions' => sub {
    my @seeds = track_rows(catalog_doc(['seed', 'Can', 'Song', 'same']));
    local *Tidal::Playlist::artist_seeds = sub { return ({id => 'artist', name => 'Can'}, \@seeds) };
    local *Tidal::Client::api = sub ($method, $endpoint) {
        is($method, 'GET');
        like($endpoint, qr{/tracks/seed/relationships/similarTracks\?});
        return catalog_doc(['copy', 'Can', 'Song', 'same'], ['blocked', 'Ignored Act', 'Other', 'blocked'],
            ['pick', 'Neu', 'Other', 'new']);
    };
    my $path = "$ENV{XDG_STATE_HOME}/discover.json";
    my $result = discover({artist => 'Can', country => 'GB', name => 'Discovery', count => 1,
        'seed-limit' => 12, pages => 2, 'max-per-artist' => 1, mood => [], 'exclude-playlist' => [],
        'allow-previous' => 1, output => $path, ignored_artists => {ignoredact => 'Ignored Act'}});
    ok(!$result->{created});
    is(load($path)->{source_artist}{name}, 'Can');
    is($result->{tracks}[0]{id}, 'pick');
};

subtest 'saved ignored artists exclude collaborators and guard older plans before writes' => sub {
    local $ENV{XDG_STATE_HOME} = tempdir(CLEANUP => 1);
    ignored_artists('Ignored Act');
    my $ignored = ignored_artists(' ignored act ', 'Other Act');
    is_deeply([sort values %$ignored], ['Ignored Act', 'Other Act']);
    is_deeply(ignored_artists(), $ignored, 'names are reused without supplying flags again');

    my ($input, $output) = map { "$ENV{XDG_STATE_HOME}/$_.json" } qw(input output);
    save($input, {name => 'Resolved', tracks => [
        {artist => 'IGNORED ACT', title => 'Skip directly'},
        {artist => 'Guest', title => 'Skip collaboration'},
        {artist => 'Allowed', title => 'Keep'},
    ]});
    my $blocked = {id => '1', artist => 'Guest, Ignored Act', artists => ['Guest', 'Ignored Act']};
    my $allowed = {id => '2', artist => 'Allowed', artists => ['Allowed']};
    local *Tidal::Playlist::progress = sub {};
    local *Tidal::Playlist::search = sub ($wanted, $country, $pages) {
        isnt($wanted->{artist}, 'IGNORED ACT', 'directly excluded suggestion never hits search');
        return ($wanted->{artist} eq 'Guest' ? $blocked : $allowed, [$blocked, $allowed]);
    };
    my $result = resolve({input => $input, output => $output, country => 'GB', pages => 1, ignored_artists => $ignored});
    is($result->{skipped_ignored}, 2);
    my $plan = load($output);
    is($plan->{expected_tracks}, 1);
    is_deeply($plan->{entries}[0]{candidates}, [$allowed]);

    $plan->{entries}[0]{selected} = {id => '1'};
    save($output, $plan);
    local *Tidal::Playlist::track_details = sub ($id, $country) { return $blocked };
    local *Tidal::Playlist::api = sub { fail('Ignored track must be caught before a write'); die "Unexpected write\n" };
    eval { create({plan => $output, yes => 1, ignored_artists => $ignored}) };
    like($@, qr/Track 1 credits an ignored artist/);
    ok(!load($output)->{write}{attempted_at});
};

subtest 'track discovery uses exactly one seed and excludes its recording' => sub {
    local *Tidal::Catalog::api = sub ($method, $endpoint) {
        is($method, 'GET');
        like($endpoint, qr{\A/tracks/123\?});
        return catalog_doc(['123', 'Can', 'Song', 'same']);
    };
    my @recommendation_requests;
    local *Tidal::Client::api = sub ($method, $endpoint) {
        is($method, 'GET');
        push @recommendation_requests, $endpoint;
        return catalog_doc(['456', 'Can', 'Song (Remastered)', 'same'], ['789', 'Neu', 'Other', 'new']);
    };
    my $path = "$ENV{XDG_STATE_HOME}/track-discover.json";
    my $result = discover({track => 'https://tidal.com/browse/track/123?u', country => 'GB',
        name => 'Track discovery', count => 1, 'seed-limit' => 12, pages => 2, 'max-per-artist' => 1,
        mood => [], 'exclude-playlist' => [], 'allow-previous' => 1, output => $path});
    is(scalar @recommendation_requests, 1);
    like($recommendation_requests[0], qr{\A/tracks/123/relationships/similarTracks\?});
    ok(!$result->{created});
    my $plan = load($path);
    is($plan->{source_track}{id}, '123');
    is($plan->{entries}[0]{selected}{id}, '789');
    is_deeply($plan->{entries}[0]{seed_track_ids}, ['123']);
    is(track_seed('123', 'GB', 2)->{id}, '123');
    eval { track_seed('https://example.org/track/123', 'GB', 2) };
    like($@, qr/Not a TIDAL track URL/);

    local *Tidal::Catalog::search = sub ($wanted, $country, $limit) {
        is_deeply($wanted, {artist => 'Can', title => 'Song - Part Two'});
        is($country, 'GB');
        is($limit, 2);
        return ({id => '123'}, []);
    };
    is(track_seed('Can - Song - Part Two', 'GB', 2)->{id}, '123');
};

subtest 'covers require a marked performance of the seed composition and an exact ISRC match' => sub {
    my $song = {id => 'work-id', title => 'Song'};
    my $performance = sub ($work, @attributes) {
        return {type => 'performance', work => $work, attributes => \@attributes};
    };
    my $seed_isrc = 'USAAA0100001';
    my $cover_isrc = 'USAAA0100002';
    local *Tidal::Playlist::track_seed = sub ($value, $country, $limit) {
        is($value, '123');
        return (track_rows(catalog_doc(['123', 'Original', 'Song', $seed_isrc])))[0];
    };
    local *Tidal::Covers::musicbrainz = sub ($path, %params) {
        if ($path eq "isrc/$seed_isrc") {
            return {recordings => [{id => 'original', relations => [$performance->($song)]}]};
        }
        is($path, 'recording');
        is($params{work}, $song->{id});
        my @rows = $params{offset} == 0
            ? ({id => 'original', isrcs => [$seed_isrc, 'USAAA0100006'], relations => [$performance->($song)]},
               {id => 'unrelated', isrcs => ['USAAA0100003'],
                   relations => [$performance->({id => 'other'}, 'cover')]})
            : ({id => 'cover', isrcs => [$cover_isrc, 'USAAA0100007'], relations => [$performance->($song, 'cover')]},
               {id => 'karaoke', isrcs => ['USAAA0100004'], relations => [$performance->($song, 'cover', 'karaoke')]},
               {id => 'unmarked', isrcs => ['USAAA0100005'], relations => [$performance->($song)]});

        return {recordings => \@rows, 'recording-count' => 5};
    };
    local *Tidal::Client::api = sub ($method, $endpoint) {
        is($method, 'GET');
        is($endpoint, '/tracks?countryCode=GB&filter%5Bisrc%5D=USAAA0100002%2CUSAAA0100007&include=artists');
        return catalog_doc(['456', 'Cover Artist', 'Song', $cover_isrc],
            ['500', 'Another Credit', 'Alternative Title', 'USAAA0100007'],
            ['789', 'Unrelated Artist', 'Song', 'USAAA0100003']);
    };
    my $path = "$ENV{XDG_STATE_HOME}/covers.json";
    my $result = discover({covers => '123', country => 'GB', name => 'Covers', count => 12,
        pages => 2, 'max-per-artist' => 1, mood => [], 'exclude-playlist' => [],
        'allow-previous' => 1, output => $path});
    is_deeply([map { $_->{id} } @{$result->{tracks}}], ['456']);
    ok(!$result->{created});
    my $plan = load($path);
    is_deeply($plan->{musicbrainz_work}, $song);
    is($plan->{entries}[0]{selected}{musicbrainz_recording_id}, 'cover');
};

subtest 'off-origin pagination does not send a request' => sub {
    local *Tidal::Client::api = sub { die "Unexpected request\n" };
    eval { Tidal::Client::pages('https://example.com/path', sub { fail('Unexpected document') }) };
    like($@, qr/off-origin/);
};

subtest 'OAuth refresh preserves existing state and replays the write key' => sub {
    my $path = Tidal::Client::state_dir() . '/tokens.json';
    save($path, {access_token => 'old', refresh_token => 'refresh', client_id => 'client',
        scope => 'playlists.write', expires_at => time + 600});
    my @calls;
    local *Tidal::Client::transport = sub ($method, $url, $headers, $body) {
        push @calls, [$method, $url, $headers, $body];
        return (401, '{}', undef) if @calls == 1;
        return (200, '{"access_token":"new"}', undef) if @calls == 2;
        return (204, '', undef);
    };
    is_deeply(Tidal::Client::api('DELETE', '/playlists/test', undef, key => 'same-key'), {});
    is($calls[0][2]{'Idempotency-Key'}, $calls[2][2]{'Idempotency-Key'});
    is($calls[2][2]{Authorization}, 'Bearer new');
    is(load($path)->{refresh_token}, 'refresh');
    is((stat($path))[2] & 0777, 0600);
};

subtest 'delete sends its saved key and verifies absence' => sub {
    my $path = "$ENV{XDG_STATE_HOME}/delete.json";
    my $key = uuid();
    save($path, {kind => 'delete', playlist_id => 'example', name => 'Example', tracks => [],
        write => {create_key => $key}});
    my @methods;
    local *Tidal::Playlist::api = sub ($method, $endpoint, $payload = undef, %options) {
        push @methods, $method;
        die "TIDAL HTTP 404: Missing\n" if $method eq 'GET';
        is(load($path)->{write}{create_key}, $options{key}, 'key was saved before deletion');
        return {};
    };
    is(delete_playlist({resume => $path, yes => 1})->{deleted}, 'example');
    is_deeply(\@methods, ['DELETE', 'GET']);
    ok(load($path)->{write}{complete});
};

subtest 'audio measurements preserve silence and detect rhythmic attacks' => sub {
    my @samples = (0) x (22_050 * 5);
    my $silent = Tidal::Audio::measurements(\@samples);
    is($silent->{bpm}, undef);
    is_deeply($silent->{moods}, []);
    for (my $beat = 0; $beat < @samples; $beat += 11_025) {
        $samples[$beat + $_] = sin($_ * .2) * exp(-$_ / 100) for 0..299;
    }
    my $rhythm = Tidal::Audio::measurements(\@samples);
    ok(defined($rhythm->{bpm}) && (abs($rhythm->{bpm} - 60) < 3 || abs($rhythm->{bpm} - 120) < 3),
        'recognizes 120 bpm or half tempo') or diag explain $rhythm;
};

done_testing;

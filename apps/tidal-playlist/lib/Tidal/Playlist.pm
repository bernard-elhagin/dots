package Tidal::Playlist;
use v5.36;
use utf8;
use Exporter 'import';
use List::Util  qw(min uniq);
use JSON::PP    ();
use POSIX       qw(strftime);
use Time::HiRes qw(time);
use Tidal::Client
    qw(api pages data_list load save digest legacy_digest state_dir escape query uuid progress http_status);
use Tidal::Catalog
    qw(normalize identities track_rows album_seeds artist_match artist_seeds favorite_tracks playlist_id playlist_tracks
    search matches_features track_seed track_details);
use Tidal::Covers         qw(cover_candidates);
use Tidal::IgnoredArtists qw(ignored_track);

our @EXPORT_OK = qw(resolve discover create append delete_playlist import_plan);

sub plan_path( $args, $name ) {
    return $args->{output} if defined $args->{output};
    my $slug = fc($name) =~ s/[^a-z0-9]+/-/gr;
    $slug =~ s/^-|-$//g;

    return
          state_dir()
        . '/plans/'
        . ( substr( $slug, 0, 60 ) || 'playlist' ) . '-'
        . substr( uuid(), 0, 8 ) . '.json';
}

sub new_write() {
    { create_key => uuid(), add_key => uuid(), fingerprint_format => 'perl-json-v1' }
}

sub new_plan( $args, $name, $entries, $description = '' ) {
    die "Playlist name must contain 1–250 characters.\n"
        unless defined($name) && !ref($name) && $name =~ /\S/ && length($name) <= 250;
    die "Description must contain at most 500 characters.\n"
        if ref($description) || length($description) > 500;

    return {
        name        => $name,
        description => $description,
        entries     => $entries,
        country     => $args->{country},
        write       => new_write()
    };
}

sub write_key( $write, $field = 'create_key' ) {
    my $key = $write->{$field};
    die "Invalid saved write key.\n" unless defined($key) && $key =~ /\A[A-Za-z0-9-]{1,100}\z/;

    return $key;
}

sub archive_path($plan) {
    return state_dir() . '/plans/record-' . write_key( $plan->{write} ) . '.json';
}

sub archive_plan($plan) {
    save( archive_path($plan), $plan );
}

sub checkpoint( $path, $document ) {
    archive_plan($document) if exists $document->{entries};
    save( $path, $document );
}

sub remember( $kind, $write, $tracks, %fields ) {
    save(
        state_dir() . '/records/' . write_key($write) . '.json',
        {
            %fields,
            kind        => $kind,
            tracks      => $tracks,
            recorded_at => strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime ),
        }
    );
}

sub recommended_keys() {
    my %keys;
    for my $directory (qw(plans records)) {
        my $path = state_dir() . "/$directory";
        next unless -d $path;
        opendir( my $dir, $path ) or die "Cannot read $path: $!\n";
        for my $file ( grep { /\.json\z/ } readdir($dir) ) {
            my $doc  = load("$path/$file");
            next if ( $doc->{kind} // '' ) eq 'delete';
            my @rows = map { $_->{selected} // () } @{ $doc->{entries} // [] };
            push @rows, @{ $doc->{tracks} // [] };
            for my $row (@rows) {
                $keys{$_} = 1 for identities($row);
            }
        }
        closedir $dir;
    }

    return %keys;
}

sub artist_credit_status( $row, $ignored, $country, $lookup ) {
    return 'allowed' unless keys %$ignored;
    return 'ignored' if ignored_track( $row, $ignored );
    return 'allowed' if $row->{artist_credits_complete};

    my $id = $row->{id};
    unless ( exists $lookup->{$id} ) {
        my ($credited) = eval { track_details( $id, $country ) };
        my $error = $@;
        die $error if $error && http_status($error) !~ /\A(?:404|410)\z/;
        $lookup->{$id} = $credited;
    }
    my $credited = $lookup->{$id};
    return 'unknown' unless $credited;
    return 'ignored' if ignored_track( $credited, $ignored );
    return 'unknown' unless $credited->{artist_credits_complete};
    my %ids = map { $_ => 1 } @{ $credited->{artist_ids} };
    return 'unknown' if grep { !$ids{$_} } @{ $row->{artist_ids} // [] };

    my @fields = qw(artist artists artist_ids artist_credits_complete);
    @{$row}{@fields} = @{$credited}{@fields};
    return 'allowed';
}

sub resolve($args) {
    my $source = load( $args->{input} );
    my $tracks = $source->{tracks};
    die "Supply 1–1000 tracks.\n"
        unless ref($tracks) eq 'ARRAY' && @$tracks >= 1 && @$tracks <= 1000;
    for my $track (@$tracks) {
        die "Each track needs a nonempty artist and title.\n"
            unless ref($track) eq 'HASH'
            && !grep { !defined( $track->{$_} ) || ref( $track->{$_} ) || $track->{$_} !~ /\S/ }
            qw(artist title);
    }
    my $plan = new_plan( $args, $source->{name}, [], $source->{description} // '' );
    $plan->{expected_tracks}     = scalar @$tracks;
    $plan->{resolution_complete} = JSON::PP::false;
    my $path = plan_path( $args, $plan->{name} );
    die "Output already exists. Choose another path.\n" if -e $path || -l $path;
    my ( %seen, %credit_lookup, $review, $skipped );
    my $ignored = $args->{ignored_artists} // {};
    my $country = $args->{country};

    for my $track (@$tracks) {
        if ( ignored_track( $track, $ignored ) ) {
            ++$skipped;
            next;
        }
        my ( $selected, $candidates ) = search( $track, $country, $args->{pages} );
        my $status = $selected
            ? artist_credit_status( $selected, $ignored, $country, \%credit_lookup )
            : 'unknown';
        if ( $status eq 'ignored' ) {
            ++$skipped;
            next;
        }
        $selected = undef if $status eq 'unknown' || grep { $seen{$_} } identities($selected);
        my @review_candidates;
        for my $candidate (@$candidates) {
            next unless artist_credit_status( $candidate, $ignored, $country, \%credit_lookup ) eq 'allowed';
            push @review_candidates, $candidate;
            last if @review_candidates == 20;
        }
        if ($selected) {
            $seen{$_} = 1 for identities($selected);
        } else {
            ++$review;
        }
        push @{ $plan->{entries} },
            { requested => $track, selected => $selected, candidates => \@review_candidates };
        save( $path, $plan );
        progress( ( $selected ? 'OK ' : 'REVIEW ' ) . "$track->{artist} — $track->{title}" );
    }
    die "All suggested tracks credit ignored artists.\n" unless @{ $plan->{entries} };
    $plan->{expected_tracks}     = scalar @{ $plan->{entries} };
    $plan->{resolution_complete} = JSON::PP::true;
    save( $path, $plan );
    archive_plan($plan);

    return {
        plan            => $path,
        review          => $review  // 0,
        skipped_ignored => $skipped // 0,
        created         => JSON::PP::false
    };
}

sub similar_candidates( $args, $seeds, $seen, $credit_lookup, $artist_id = undef ) {
    my $country = $args->{country};
    my $ignored = $args->{ignored_artists} // {};
    my ( %pool, @unavailable );
    my @eligible;
    for my $seed (@$seeds) {
        if ( defined( $seed->{available} ) && !$seed->{available} ) {
            push @unavailable, $seed->{id};
            progress("Skipping unavailable seed: $seed->{id}");
        } else {
            push @eligible, $seed;
        }
    }
    my $count = min( $args->{'seed-limit'}, scalar @eligible );
    # Try the evenly spaced sample first and use remaining seeds for failed slots.
    my @positions = map { int( $_ * @eligible / $count ) } 0 .. $count - 1;
    my %sampled   = map { $_ => 1 } @positions;
    push @positions, grep { !$sampled{$_} } 0 .. $#eligible;
    my $successful = 0;
    for my $index (@positions) {
        last if $successful == $count;
        my $seed = $eligible[$index];
        my $path =
              '/tracks/'
            . escape( $seed->{id} )
            . '/relationships/similarTracks?'
            . query( countryCode => $country, include => 'similarTracks.artists' );
        my @rows;
        my $ok = eval {
            pages(
                $path,
                sub ($doc) { push @rows, track_rows( $doc, $artist_id ) },
                $args->{pages},
                1
            );
            1;
        };
        unless ($ok) {
            my $error  = $@;
            my $status = http_status($error);
            die $error unless $status == 404 || $status == 410;
            push @unavailable, $seed->{id};
            progress("Skipping unavailable seed: $seed->{id}");
            next;
        }
        my $rank = 0;
        for my $row (@rows) {
            ++$rank;
            next if !$row->{available} || grep { $seen->{$_} } identities($row);
            next unless artist_credit_status( $row, $ignored, $country, $credit_lookup ) eq 'allowed';
            next unless @{ $row->{artists} } && matches_features( $row, $args );
            my $item = $pool{ $row->{id} } //=
                { %$row, score => 0, seeds => [], seed_position => $index };
            $item->{seed_position} = min( $item->{seed_position}, $index );
            $item->{score} += 1 / ( $rank + 2 );
            push @{ $item->{seeds} }, $seed->{id}
                unless grep { $_ eq $seed->{id} } @{ $item->{seeds} };
        }
        progress( 'Discovery seed ' . ++$successful . "/$count" );
    }

    return ( \%pool, \@unavailable );
}

sub discover($args) {
    my $country = $args->{country};
    my $ignored = $args->{ignored_artists} // {};
    my ( $source, $album, $artist, $track, $output_artist, @seeds );
    if ( defined( $args->{track} ) || defined( $args->{covers} ) ) {
        if ( defined $args->{artist} ) {
            $output_artist = artist_match( $args->{artist}, $country );
            die "$output_artist->{name} is on your saved ignore list.\n"
                if ignored_track( { artist => $output_artist->{name} }, $ignored );
        }
        $track = track_seed( $args->{track} // $args->{covers}, $country, $args->{pages} );
        @seeds = ($track);
    } elsif ( defined $args->{artist} ) {
        my ( $found, $tracks ) = artist_seeds( $args->{artist}, $country );
        $artist = $found;
        @seeds  = @$tracks;
    } elsif ( defined $args->{album} ) {
        my $tracks;
        ( $album, $tracks ) = album_seeds( $args->{album}, $country );
        @seeds = @$tracks;
    } elsif ( $args->{'from-favorites'} ) {
        $source = 'favorites';
        @seeds  = favorite_tracks();
    } else {
        $source = playlist_id( $args->{source}, $country );
        @seeds  = playlist_tracks( $source, $country );
    }
    die "Seed source is empty.\n" unless @seeds;
    my @excluded = @seeds;
    push @excluded, favorite_tracks()
        if $args->{'exclude-favorites'} && ( $source // '' ) ne 'favorites';
    for my $playlist ( @{ $args->{'exclude-playlist'} } ) {
        push @excluded, playlist_tracks( playlist_id( $playlist, $country ), $country );
    }
    my %seen = $args->{'allow-previous'} ? () : recommended_keys();
    for my $row (@excluded) {
        $seen{$_} = 1 for identities($row);
    }
    my ( $work, $pool, $unavailable, %credit_lookup );
    if ( defined $args->{covers} ) {
        my ( $composition, $rows ) = cover_candidates( $track, $country, $args->{pages} );
        $work        = $composition;
        $unavailable = [];
        $pool        = {};
        for my $row (@$rows) {
            next if !$row->{available} || grep { $seen{$_} } identities($row);
            next unless artist_credit_status( $row, $ignored, $country, \%credit_lookup ) eq 'allowed';
            next unless @{ $row->{artists} } && matches_features( $row, $args );
            $pool->{ $row->{id} } =
                { %$row, score => 0, seeds => [ $track->{id} ], seed_position => 0 };
        }
    } else {
        ( $pool, $unavailable ) = similar_candidates( $args, \@seeds, \%seen, \%credit_lookup,
            $output_artist ? $output_artist->{id} : undef );
    }
    my $max_per_artist = $args->{'max-per-artist'} // ( $output_artist ? $args->{count} : 1 );
    my ( @selected, %artist_counts );
    for my $row (
        sort {
                   $b->{score}      <=> $a->{score}
                || $b->{popularity} <=> $a->{popularity}
                || $a->{id}         cmp $b->{id}
        } values %$pool
    ) {
        my @keys = identities($row);
        push @keys, 'musicbrainz:' . $row->{musicbrainz_recording_id} if $work;
        my @names = uniq map { normalize($_) } @{ $row->{artists} };
        next if grep { $seen{$_} } @keys;
        next if grep { ( $artist_counts{$_} // 0 ) >= $max_per_artist } @names;
        push @selected, $row;
        $seen{$_} = 1 for @keys;
        ++$artist_counts{$_} for @names;
        last if @selected == $args->{count};
    }
    die
        "No eligible covers found in the $country TIDAL catalog. Try more pages or relax the filters.\n"
        if $work && !@selected;
    die
        "No eligible recommendations credited to $output_artist->{name}. Try more pages or a different seed track.\n"
        if $output_artist && !@selected;
    die 'Only '
        . scalar(@selected)
        . " candidates meet the constraints. Request fewer tracks or expand seeds/pages.\n"
        if !$work && !$output_artist && @selected < $args->{count};
    @selected =
        sort { $a->{seed_position} <=> $b->{seed_position} || $b->{score} <=> $a->{score} }
        @selected
        unless $work;
    my @entries = map {
        {
            requested      => { artist => $_->{artist}, title => $_->{title} },
            selected       => $_,
            seed_track_ids => $_->{seeds}
        }
    } @selected;
    my $description =
          $album         ? "Discovery based on $album->{title}."
        : $artist        ? "Discovery based on tracks by $artist->{name}."
        : $output_artist ? "Track recommendations credited to $output_artist->{name}."
        : $work          ? 'Cover recordings identified by MusicBrainz.'
        : $track         ? 'Discovery based on a single track.'
        :                  'Discovery based on a seed playlist.';
    $description .= ' Excludes seed recordings.';
    $description .= ' Excludes previously recommended recordings.' unless $args->{'allow-previous'};
    my $plan = new_plan( $args, $args->{name}, \@entries, $description );
    $plan->{unavailable_seeds} = $unavailable;
    $plan->{musicbrainz_work}  = { map { $_ => $work->{$_} } qw(id title) } if $work;
    $plan->{output_artist}     = $output_artist                             if $output_artist;

    if ($album) {
        $plan->{source_album} = $album;
    } elsif ($artist) {
        $plan->{source_artist} = $artist;
    } elsif ($track) {
        $plan->{source_track} = { map { $_ => $track->{$_} } qw(id artist title version) };
    } else {
        $plan->{source_playlist} = $source;
    }
    my $path = plan_path( $args, $args->{name} );
    die "Output already exists. Choose another path.\n" if -e $path || -l $path;
    save( $path, $plan );
    archive_plan($plan);

    return {
        plan              => $path,
        tracks            => \@selected,
        unavailable_seeds => $unavailable,
        created           => JSON::PP::false
    };
}

sub checked_entries($plan) {
    die "Resolution was interrupted. Finish resolving before creating a playlist.\n"
        if exists( $plan->{resolution_complete} ) && !$plan->{resolution_complete};
    my @entries = @{ $plan->{entries} // [] };
    die "Resolve every track first. Review candidates or remove unresolved entries.\n"
        if !@entries || grep { !$_->{selected} } @entries;
    my @rows = map { $_->{selected} } @entries;
    my %ids;
    die "Plan must contain 1–1000 distinct track IDs.\n"
        if @rows > 1000
        || grep { !defined( $_->{id} ) || ref( $_->{id} ) || $_->{id} eq '' || $ids{ $_->{id} }++ }
        @rows;

    return @rows;
}

sub fingerprint( $write, $payload ) {
    return legacy_digest($payload)
        if !defined( $write->{fingerprint_format} ) && $write->{fingerprint};
    die "Unsupported write fingerprint format.\n"
        if defined( $write->{fingerprint_format} )
        && $write->{fingerprint_format} ne 'perl-json-v1';

    return digest($payload);
}

sub check_fingerprint( $write, $payload ) {
    my $expected = fingerprint( $write, $payload );
    if ( $write->{fingerprint} && $write->{fingerprint} ne $expected ) {
        die
            "Saved legacy write fingerprint does not match. Inspect the saved operation and playlist in TIDAL before retrying.\n"
            unless defined $write->{fingerprint_format};
        die "Plan changed after a write attempt. Restore it before retrying.\n";
    }

    return $expected;
}

sub guard_write( $write, $payload ) {
    my $expected = check_fingerprint( $write, $payload );
    die "Write recovery window expired. Inspect TIDAL before starting another operation.\n"
        if defined( $write->{attempted_at} ) && time - $write->{attempted_at} > 3500;
    $write->{fingerprint_format} = 'perl-json-v1' unless $write->{fingerprint};
    $write->{attempted_at} //= time;
    $write->{fingerprint} = $expected;
}

sub same_order( $actual, $expected ) {
    return @$actual == @$expected && !grep { $actual->[$_] ne $expected->[$_] } 0 .. $#$actual;
}

sub verify_order( $id, $expected, $country ) {
    my @actual = map { $_->{id} } playlist_tracks( $id, $country );
    die "Saved playlist differs from the expected order. Inspect before retrying.\n"
        unless same_order( \@actual, $expected );
}

sub add_batches( $id, $rows, $write, $path, $document, $expected = undef ) {
    $write->{batches} //= {};
    for ( my $offset = $write->{added} // 0 ; $offset < @$rows ; $offset += 50 ) {
        my @ids = map { "$_->{id}" } @$rows[ $offset .. min( $offset + 49, $#$rows ) ];
        if ($expected) {
            my $prefix_length = @$expected - @$rows + $offset;
            my @prefix = @$expected[ 0 .. $prefix_length - 1 ];
            my @actual = map { $_->{id} } playlist_tracks( $id, $document->{country} );
            # A saved key and the exact next prefix also cover a lost acknowledgement.
            if ( $write->{batches}{$offset} && same_order( \@actual, [ @prefix, @ids ] ) ) {
                $write->{added} = $offset + @ids;
                checkpoint( $path, $document );
                next;
            }
            die "Destination playlist changed since the append was saved. Inspect before retrying.\n"
                unless same_order( \@actual, \@prefix );
        }
        $write->{batches}{$offset} //= $offset == 0 ? ( $write->{add_key} // uuid() ) : uuid();
        checkpoint( $path, $document );
        my $result = api(
            'POST', '/playlists/' . escape($id) . '/relationships/items',
            { data => [ map { { type => 'tracks', id => $_ } } @ids ] },
            key      => $write->{batches}{$offset},
            deadline => $write->{attempted_at} + 3500
        );
        my @ack = map { "$_->{id}" } data_list($result);
        die "TIDAL did not acknowledge the full batch in order. Inspect the saved operation.\n"
            if @ack != @ids || grep { $ack[$_] ne $ids[$_] } 0 .. $#ids;
        $write->{added} = $offset + @ids;
        checkpoint( $path, $document );
    }
}

sub create($args) {
    my $path = $args->{plan};
    my $plan = load($path);
    my @rows = checked_entries($plan);
    die "Review the plan, then pass --yes to create the playlist.\n" unless $args->{yes};
    my $payload = {
        name        => $plan->{name},
        description => $plan->{description} // '',
        ids         => [ map { "$_->{id}" } @rows ]
    };
    my $archive = archive_path($plan);
    if ( -f $archive ) {
        my $durable = load($archive);
        if ( $durable->{write}{attempted_at} ) {
            check_fingerprint( $durable->{write}, $payload );
            $plan = $durable;
            @rows = checked_entries($plan);
        }
    }
    my $write = $plan->{write};
    check_fingerprint( $write, $payload );
    unless ( $write->{complete} ) {
        my $ignored = $args->{ignored_artists} // {};
        if ( keys %$ignored ) {
            my %lookup;
            for my $row (@rows) {
                my $status = artist_credit_status( $row, $ignored, $plan->{country} // 'GB', \%lookup );
                next if $status eq 'allowed';
                die "Cannot verify all artist credits for track $row->{id}.\n" if $status eq 'unknown';
                my $action =
                    $write->{attempted_at}
                    ? 'Inspect the incomplete playlist and its saved operation.'
                    : 'Remove that entry from the plan and retry.';
                die "Track $row->{id} credits an ignored artist. $action\n";
            }
        }
        guard_write( $write, $payload );
        checkpoint( $path, $plan );
        unless ( $write->{playlist_id} ) {
            my $result = api(
                'POST',
                '/playlists',
                {
                    data => {
                        type       => 'playlists',
                        attributes => {
                            name        => $payload->{name},
                            description => $payload->{description},
                            accessType  => 'UNLISTED',
                        }
                    }
                },
                key      => write_key($write),
                deadline => $write->{attempted_at} + 3500
            );
            die "TIDAL did not return a playlist ID.\n" unless $result->{data}{id};
            $write->{playlist_id} = "$result->{data}{id}";
            checkpoint( $path, $plan );
        }
        progress("Playlist recovery plan: $path");
        add_batches( $write->{playlist_id}, \@rows, $write, $path, $plan );
        verify_order( $write->{playlist_id}, $payload->{ids}, $plan->{country} // 'GB' );
        $write->{complete} = JSON::PP::true;
        checkpoint( $path, $plan );
    }
    archive_plan($plan);
    remember(
        'create', $write, \@rows,
        playlist_id => $write->{playlist_id},
        name        => $plan->{name}
    );

    return {
        playlist => 'https://tidal.com/playlist/' . $write->{playlist_id},
        tracks   => scalar(@rows),
        complete => JSON::PP::true
    };
}

sub append($args) {
    my $country = $args->{country};
    my ( $operation, $path );
    if ( $args->{resume} ) {
        $path      = $args->{resume};
        $operation = load($path);
        die "Not an append operation record.\n" unless ( $operation->{kind} // '' ) eq 'append';
    } else {
        die "Specify source and destination, or --resume OPERATION.json.\n"
            unless ( $args->{source} || $args->{track} ) && $args->{destination};
        my $track = $args->{track};
        my $source = $track ? "track:$track->{id}" : playlist_id( $args->{source}, $country );
        my $destination = playlist_id( $args->{destination}, $country );
        my @before      = playlist_tracks( $destination, $country );
        my @source_tracks = $track ? ($track) : playlist_tracks( $source, $country );
        my ( %seen, @additions );
        for my $row (@before) {
            $seen{$_} = 1 for identities($row);
        }
        for my $row (@source_tracks) {
            my @keys = identities($row);
            next if grep { $seen{$_} } @keys;
            push @additions, $row;
            $seen{$_} = 1 for @keys;
        }
        return { destination => $destination, append => \@additions, write => JSON::PP::false }
            unless $args->{yes};
        return { playlist => $destination, appended => 0 } if $track && !@additions;
        $operation = {
            kind        => 'append',
            source      => $source,
            destination => $destination,
            country     => $country,
            before      => [ map { $_->{id} } @before ],
            tracks      => \@additions,
            write       => new_write()
        };
        $path = state_dir() . '/operations/append-' . write_key( $operation->{write} ) . '.json';
    }
    die "Pass --yes to resume the append operation.\n" unless $args->{yes};
    my $write   = $operation->{write};
    my %payload = map { $_ => $operation->{$_} } qw(source destination country before tracks);
    unless ( $write->{complete} ) {
        guard_write( $write, \%payload );
        save( $path, $operation );
        progress("Append recovery record: $path");
        my @expected = ( @{ $operation->{before} }, map { "$_->{id}" } @{ $operation->{tracks} } );
        add_batches( $operation->{destination}, $operation->{tracks}, $write, $path, $operation, \@expected );
        verify_order( $operation->{destination}, \@expected, $operation->{country} );
        $write->{complete} = JSON::PP::true;
        save( $path, $operation );
    }
    remember( 'append', $write, $operation->{tracks}, playlist_id => $operation->{destination} );

    return {
        playlist  => $operation->{destination},
        appended  => scalar( @{ $operation->{tracks} } ),
        operation => $path
    };
}

sub delete_playlist($args) {
    my ( $operation, $path );
    if ( $args->{resume} ) {
        $path      = $args->{resume};
        $operation = load($path);
        die "Not a delete operation record.\n" unless ( $operation->{kind} // '' ) eq 'delete';
    } else {
        die "Specify a playlist, or --resume OPERATION.json.\n" unless $args->{playlist};
        my $pid      = playlist_id( $args->{playlist}, $args->{country} );
        my $metadata = api( 'GET', '/playlists/' . escape($pid) );
        my $name     = $metadata->{data}{attributes}{name};
        my @tracks   = playlist_tracks( $pid, $args->{country} );
        return {
            delete => $pid,
            name   => $name,
            tracks => scalar(@tracks),
            write  => JSON::PP::false
            }
            unless $args->{yes};
        $operation = {
            kind        => 'delete',
            playlist_id => $pid,
            name        => $name,
            tracks      => \@tracks,
            write       => new_write()
        };
        $path = state_dir() . '/operations/delete-' . write_key( $operation->{write} ) . '.json';
    }
    die "Pass --yes to resume deletion.\n" unless $args->{yes};
    my $write   = $operation->{write};
    my %payload = map { $_ => $operation->{$_} } qw(playlist_id name tracks);
    unless ( $write->{complete} ) {
        guard_write( $write, \%payload );
        save( $path, $operation );
        progress("Deletion backup/recovery record: $path");
        my $endpoint = '/playlists/' . escape( $operation->{playlist_id} );
        eval {
            api(
                'DELETE', $endpoint, undef,
                key      => write_key($write),
                deadline => $write->{attempted_at} + 3500
            );
        };
        die $@ if $@ && http_status($@) != 404;
        my $visible = eval { api( 'GET', $endpoint ); 1 };
        die $@ if $@ && http_status($@) != 404;
        die "Playlist remains visible. Retry the saved deletion operation to verify.\n" if $visible;
        $write->{complete} = JSON::PP::true;
        save( $path, $operation );
    }
    remember(
        'delete', $write, $operation->{tracks},
        playlist_id => $operation->{playlist_id},
        name        => $operation->{name}
    );

    return { deleted => $operation->{playlist_id}, name => $operation->{name}, backup => $path };
}

sub import_plan($args) {
    my $plan = load( $args->{plan} );
    checked_entries($plan);
    my $destination = archive_path($plan);
    if ( -f $destination ) {
        my $existing = load($destination);
        die "A newer durable operation already exists. Refusing to replace its recovery state.\n"
            if $existing->{write}{attempted_at} && digest($existing) ne digest($plan);
    }
    archive_plan($plan);

    return { imported => $args->{plan}, history_updated => JSON::PP::true };
}

1;

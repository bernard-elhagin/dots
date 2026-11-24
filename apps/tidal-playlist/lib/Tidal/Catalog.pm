package Tidal::Catalog;
use v5.36;
use utf8;
use Exporter 'import';
use POSIX              qw(isfinite);
use Scalar::Util       qw(looks_like_number);
use Unicode::Normalize qw(NFKD);
use Tidal::Client
    qw(api pages data_list escape query state_dir load legacy_digest json http_status progress);

our @EXPORT_OK =
    qw(normalize identities track_rows artist_match artist_seeds favorite_tracks playlist_id
    playlist_tracks owned_playlists search effective_features matches_features catalog_features track_details track_seed);
my $variants =
    qr/\b(live|remix(?:ed)?|mix|karaoke|tribute|instrumental|acoustic|edit|demo|radio|rerecord(?:ed|ing)?|re-record(?:ed|ing)?)\b/i;
my $remaster = qr/\bremaster(?:ed)?\b/i;

sub normalize($text) {
    return fc( NFKD( $text // '' ) ) =~ s/[^\p{L}\p{N}!]//gr;
}

sub title_base($title) {
    $title =~ s/(\([^)]*\)|\[[^]]*\])/$1 =~ $remaster ? '' : $1/ge;
    $title =~ s/\s*[-–—]\s*(?:(?:\d{4})\s+)?remaster(?:ed)?(?:\s+\d{4})?\s*$//i;
    return normalize($title);
}

sub identities($row) {
    my @keys = ( json()->encode( [ 'id', "$row->{id}" ] ) );
    push @keys, json()->encode( [ 'isrc', $row->{isrc} ] ) if $row->{isrc};
    if ( $row->{title} ) {
        for my $name ( @{ $row->{artists} || [ $row->{artist} ] } ) {
            push @keys, json()->encode( [ 'name', normalize($name), title_base( $row->{title} ) ] )
                if $name;
        }
    }

    return @keys;
}

sub catalog_features($attributes) {
    my $bpm = $attributes->{bpm};
    $bpm = undef
        unless defined($bpm)
        && !ref($bpm)
        && looks_like_number($bpm)
        && isfinite($bpm)
        && $bpm > 0;
    my ( $key, $scale ) = @{$attributes}{qw(key keyScale)};
    return {
        bpm    => $bpm,
        key    => ( $key   // 'UNKNOWN' ) eq 'UNKNOWN' ? undef : $key,
        scale  => ( $scale // 'UNKNOWN' ) eq 'UNKNOWN' ? undef : $scale,
        moods  => [ grep { defined && !ref } @{ $attributes->{toneTags} // [] } ],
        source => 'tidal_metadata',
    };
}

sub track_rows( $doc, $artist_id = undef ) {
    my %included = map { ( $_->{type} . ':' . $_->{id} ) => $_ } @{ $doc->{included} // [] };
    my @rows;
    for my $ref ( data_list($doc) ) {
        next unless $ref->{type} eq 'tracks';
        my $track      = $included{ 'tracks:' . $ref->{id} } // $ref;
        my $attributes = $track->{attributes}                // {};
        next unless $attributes->{title};
        my $credits    = ( $track->{relationships} // {} )->{artists} // {};
        my @credit_ids = map { "$_->{id}" } @{ $credits->{data} // [] };
        next if defined($artist_id) && !grep { $_ eq $artist_id } @credit_ids;
        my @names = grep { length } map {
            ( ( $included{"artists:$_"} // {} )->{attributes} // {} )->{name} // ''
        } @credit_ids;
        my $complete_credits = @names && @names == @credit_ids
            && !( $credits->{links} // {} )->{next};
        my $available = !defined( $attributes->{availability} )
            || grep { $_ eq 'STREAM' } @{ $attributes->{availability} };
        push @rows,
            {
            id                      => "$track->{id}",
            artist                  => join( ', ', @names ),
            artists                 => \@names,
            artist_ids              => \@credit_ids,
            artist_credits_complete => $complete_credits ? JSON::PP::true : JSON::PP::false,
            title                   => $attributes->{title},
            version                 => $attributes->{version} // '',
            isrc                    => $attributes->{isrc},
            popularity              => $attributes->{popularity} // 0,
            audio_features          => catalog_features($attributes),
            available               => $available ? JSON::PP::true : JSON::PP::false,
            };
    }

    return @rows;
}

sub catalog_relation( $path, $country, $include = undef ) {
    return "$path?"
        . query( countryCode => $country, defined($include) ? ( include => $include ) : () );
}

sub track_details( $id, $country ) {
    return track_rows(
        api( 'GET', catalog_relation( '/tracks/' . escape($id), $country, 'artists' ) ) );
}

sub collection_rows( $path, $allow_mixed = 0 ) {
    my @result;
    pages(
        $path,
        sub ($doc) {
            my %rows = map { $_->{id} => $_ } track_rows($doc);
            for my $ref ( data_list($doc) ) {
                if ( $ref->{type} ne 'tracks' ) {
                    next if $allow_mixed;
                    die
                        "Playlist contains non-track items. This operation supports music tracks only.\n";
                }
                my $id = "$ref->{id}";
                push @result,
                    $rows{$id} // {
                    id      => $id,
                    title   => '',
                    artists => [],
                    $allow_mixed ? () : ( artist => '' )
                    };
            }
        }
    );
    return @result;
}

sub favorite_tracks() {
    my @rows = eval {
        collection_rows( '/userCollectionTracks/me/relationships/items?include=items.artists', 1 );
    };
    my $error = $@;
    die
        "Favorites need collection.read. Enable it in your TIDAL developer app, then run login again.\n"
        if http_status($error) == 403;
    die $error if $error;

    return @rows;
}

sub playlist_tracks( $id, $country ) {
    return collection_rows(
        catalog_relation(
            '/playlists/' . escape($id) . '/relationships/items',
            $country, 'items.artists'
        )
    );
}

sub owned_playlists($country) {
    my @rows;
    pages(
        '/playlists?' . query( 'filter[owners.id]' => 'me', countryCode => $country ),
        sub ($doc) {
            push @rows,
                map { { id => "$_->{id}", name => ( $_->{attributes} // {} )->{name} // '' } }
                data_list($doc);
        }
    );

    return @rows;
}

sub playlist_id( $value, $country ) {
    if ( $value =~ m{\Ahttps?://}i ) {
        my ($id) =
            $value =~ m{\Ahttps?://(?:www\.|listen\.)?tidal\.com/[^?#]*?\bplaylist/([^/?#]+)}i;
        die "Not a TIDAL playlist URL.\n" unless defined $id;

        return $id;
    }
    my $uuid = $value =~ s/\Aurn:uuid://r;
    $uuid =~ s/[{}-]//g;
    return lc join( '-', $1, $2, $3, $4, $5 )
        if $uuid =~ /\A([a-f0-9]{8})([a-f0-9]{4})([a-f0-9]{4})([a-f0-9]{4})([a-f0-9]{12})\z/i;
    my @matches = grep { fc( $_->{name} ) eq fc($value) } owned_playlists($country);
    die 'Playlist name matched ' . scalar(@matches) . " owned playlists. Use an exact ID or URL.\n"
        unless @matches == 1;

    return $matches[0]{id};
}

sub effective_features($row) {
    my $catalog = $row->{audio_features} // catalog_features( {} );
    my $path    = state_dir() . '/audio/' . legacy_digest("$row->{id}") . '.json';
    return $catalog unless -f $path;
    my $local    = load($path);
    my %combined = ( %$local, sources => {}, source => 'local_audio_with_catalog_fallback' );
    for my $field (qw(bpm key scale moods)) {
        my $value     = $local->{$field};
        my $use_local = defined($value) && ( ref($value) ne 'ARRAY' || @$value );
        $combined{$field} = $use_local ? $value : $catalog->{$field};
        $combined{sources}{$field} = $use_local ? 'local_audio' : 'tidal_metadata';
    }

    return \%combined;
}

sub matches_features( $row, $args ) {
    my $values = effective_features($row);
    my $bpm    = $values->{bpm};
    return 0 if defined( $args->{'bpm-min'} ) && ( !defined($bpm) || $bpm < $args->{'bpm-min'} );
    return 0 if defined( $args->{'bpm-max'} ) && ( !defined($bpm) || $bpm > $args->{'bpm-max'} );
    return 0 if $args->{key}   && normalize( $values->{key} ) ne normalize( $args->{key} );
    return 0 if $args->{scale} && ( $values->{scale} // '' ) ne $args->{scale};
    my %moods = map { normalize($_) => 1 } @{ $values->{moods} // [] };
    return 0 if @{ $args->{mood} } && !grep { $moods{ normalize($_) } } @{ $args->{mood} };
    $row->{effective_features} = $values;

    return 1;
}

sub search_root( $term, $country ) {
    my ($result) = data_list(
        api(
            'GET', '/searchResults?' . query( 'filter[query]' => $term, countryCode => $country )
        )
    );
    return $result ? '/searchResults/' . escape( $result->{id} ) . '/relationships/' : undef;
}

sub rank_rows(@rows) {
    return sort {
               $b->{safe}         <=> $a->{safe}
            || $a->{edition_rank} <=> $b->{edition_rank}
            || $b->{popularity}   <=> $a->{popularity}
            || $a->{id}           cmp $b->{id}
    } @rows;
}

sub search( $wanted, $country, $limit ) {
    my ( %rows, %terms );
    my ( $selected, @ranked );
    for my $term ( "$wanted->{artist} $wanted->{title}", $wanted->{title}, $wanted->{artist} ) {
        next if $terms{$term}++;
        my $root = search_root( $term, $country );
        next unless defined $root;
        pages(
            catalog_relation( $root . 'tracks', $country, 'tracks.artists' ),
            sub ($doc) {
                for my $row ( track_rows($doc) ) {
                    my $expected  = $wanted->{version} // '';
                    my $label     = "$row->{title} $row->{version}";
                    my $versioned = $expected ne '' || $wanted->{title} =~ $variants;
                    my $title_ok =
                        $versioned
                        ? normalize( $row->{title} ) eq normalize( $wanted->{title} )
                        : title_base( $row->{title} ) eq title_base( $wanted->{title} );
                    my $version_ok =
                        $versioned
                        ? normalize( $row->{version} ) eq normalize($expected)
                        : $label !~ $variants
                        && ( !$row->{version}
                        || $row->{version} =~ $remaster
                        || fc( $row->{version} ) =~
                        /\A(?:original|original version|album version)\z/ );
                    my $artist_ok = grep { normalize($_) eq normalize( $wanted->{artist} ) }
                        @{ $row->{artists} };
                    $row->{safe} =
                           $title_ok
                        && $version_ok
                        && $artist_ok
                        && $row->{available} ? JSON::PP::true : JSON::PP::false;
                    $row->{edition_rank} = $label =~ $remaster ? 1 : 0;
                    my $previous = $rows{ $row->{id} };
                    next if $previous && !$row->{artist_credits_complete}
                        && ( $previous->{artist_credits_complete} || ( $previous->{safe} && !$row->{safe} ) );
                    $rows{ $row->{id} } = $row;
                }
            },
            $limit,
            1
        );
        @ranked = rank_rows( values %rows );
        my @good = grep { $_->{safe} && $_->{edition_rank} == $ranked[0]{edition_rank} } @ranked;
        my %recordings = map { ( $_->{isrc} || "id:$_->{id}" ) => 1 } @good;
        $selected = keys(%recordings) == 1 ? $good[0] : undef;
        last if $selected && ( !$selected->{edition_rank} || length( $wanted->{version} // '' ) );
    }

    return ( $selected, \@ranked );
}

sub track_seed( $value, $country, $limit ) {
    $value =~ s/^\s+|\s+$//g;
    my $id;
    if ( $value =~ /\A[0-9]+\z/ ) {
        $id = $value;
    } elsif ( $value =~ m{\Ahttps?://}i ) {
        ($id) = $value =~ m{\Ahttps?://(?:www\.|listen\.)?tidal\.com/
            (?:browse/)?(?:album/[0-9]+/)?track/([0-9]+)/?(?:[?#].*)?\z}ix;
        die "Not a TIDAL track URL. Use a link to an individual track.\n" unless defined $id;
    } else {
        my ( $artist, $title ) = split /\s+[-–—]\s+/, $value, 2;
        die "Use a TIDAL track ID, a TIDAL track URL, or \"Artist - Track title\".\n"
            unless defined($title) && $artist =~ /\S/ && $title =~ /\S/;
        my ($track) = search( { artist => $artist, title => $title }, $country, $limit );
        die
            "Could not identify a single playable recording for '$value' in the $country catalog. Use its track ID or URL.\n"
            unless $track;

        return $track;
    }

    my ($track) = track_details( $id, $country );
    die "Track $id is unavailable in the $country catalog.\n" unless $track && $track->{available};

    return $track;
}

sub artist_match( $name, $country ) {
    my $wanted = normalize($name);
    die "Enter an artist name.\n" unless length $wanted;
    my $root = search_root( $name =~ s/^\s+|\s+$//gr, $country );
    my %matches;
    if ($root) {
        pages(
            catalog_relation( $root . 'artists', $country, 'artists' ),
            sub ($doc) {
                my %included = map { $_->{id} => $_ }
                    grep { $_->{type} eq 'artists' } @{ $doc->{included} // [] };
                for my $ref ( data_list($doc) ) {
                    my $artist = $included{ $ref->{id} } // $ref;
                    my $found  = ( $artist->{attributes} // {} )->{name};
                    $matches{ $artist->{id} } = $found if normalize($found) eq $wanted;
                }
            },
            3,
            1
        );
    }
    die "No exact artist match for '$name' in the $country catalog search.\n" unless keys %matches;
    die "Multiple TIDAL artists match '$name'.\n" unless keys(%matches) == 1;
    my ($id) = keys %matches;

    return { id => "$id", name => $matches{$id} };
}

sub artist_seeds( $name, $country ) {
    my $artist = artist_match( $name, $country );
    my $id     = $artist->{id};
    my ( @albums, %albums_seen, @seeds, %seen );
    pages(
        catalog_relation( '/artists/' . escape($id) . '/relationships/albums', $country ),
        sub ($doc) {
            push @albums, map { "$_->{id}" }
                grep { $_->{type} eq 'albums' && !$albums_seen{ $_->{id} }++ } data_list($doc);
        },
        3,
        1
    );
    splice @albums, 12 if @albums > 12;
    for my $album (@albums) {
        pages(
            catalog_relation(
                '/albums/' . escape($album) . '/relationships/items',
                $country, 'items.artists'
            ),
            sub ($doc) {
                for my $row ( track_rows( $doc, $id ) ) {
                    my @keys = identities($row);
                    next if !$row->{available} || !@{ $row->{artists} } || grep { $seen{$_} } @keys;
                    push @seeds, $row;
                    $seen{$_} = 1 for @keys;
                }
            },
            3,
            1
        );
    }
    die "No playable seed tracks found for $artist->{name} in the $country catalog.\n"
        unless @seeds;
    progress( 'Found ' . scalar(@seeds) . " seed recordings for $artist->{name}." );

    return ( $artist, \@seeds );
}

1;

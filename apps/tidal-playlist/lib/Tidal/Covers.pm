package Tidal::Covers;
use v5.36;
use Exporter 'import';
use List::Util qw(uniq);
use Time::HiRes qw(clock_gettime sleep CLOCK_MONOTONIC);
use Tidal::Client qw(json pages query);
use Tidal::Catalog qw(track_rows);

our @EXPORT_OK = qw(cover_candidates);

my $next_request = 0;
my $isrc_pattern = qr/\A[A-Z]{2}[A-Z0-9]{3}[0-9]{7}\z/;

sub musicbrainz($path, %params) {
    my $url = "https://musicbrainz.org/ws/2/$path?" . query(fmt => 'json', %params);
    my $headers = {'User-Agent' => 'tidal-playlist/1.0 (personal playlist generator)', Accept => 'application/json'};
    my ($status, $body);
    for my $attempt (1..3) {
        my $delay = $next_request - clock_gettime(CLOCK_MONOTONIC);
        sleep($delay) if $delay > 0;
        $next_request = clock_gettime(CLOCK_MONOTONIC) + 1.1;
        ($status, $body) = Tidal::Client::transport('GET', $url, $headers, undef);
        last if $attempt == 3 || ($status // 0) !~ /\A(?:429|503)\z/;
        $next_request = clock_gettime(CLOCK_MONOTONIC) + 2 ** $attempt;
    }
    return {} if ($status // 0) == 404 && $path =~ m{\Aisrc/};
    die "MusicBrainz lookup failed" . ($status ? " (HTTP $status)" : '') . ". Try again later.\n"
        unless ($status // 0) == 200;

    return json()->decode($body);
}

sub cover_candidates($seed, $country, $limit) {
    my $seed_isrc = uc($seed->{isrc} // '');
    die "The seed track has no valid ISRC. Try another release of the song.\n" unless $seed_isrc =~ $isrc_pattern;
    my $lookup = musicbrainz("isrc/$seed_isrc", inc => 'work-rels');
    my (%works, %seed_recordings);
    for my $recording (@{$lookup->{recordings} // []}) {
        $seed_recordings{$recording->{id}} = 1;
        for my $rel (@{$recording->{relations} // []}) {
            next unless $rel->{type} eq 'performance' && $rel->{work}{id};
            next if grep { /\A(?:medley|partial|karaoke)\z/ } @{$rel->{attributes} // []};
            $works{$rel->{work}{id}} = $rel->{work};
        }
    }
    die "MusicBrainz links this ISRC to no single composition. Try another release of the song.\n"
        unless keys(%works) == 1;
    my ($work_id) = keys %works;
    my %recordings_by_isrc;
    my $offset = 0;
    for (1..$limit) {
        my $doc = musicbrainz('recording', work => $work_id, inc => 'isrcs+work-rels', limit => 100, offset => $offset);
        my @recordings = @{$doc->{recordings} // []};
        for my $recording (@recordings) {
            my $id = $recording->{id};
            my @relations = grep { $_->{type} eq 'performance' && ($_->{work}{id} // '') eq $work_id }
                @{$recording->{relations} // []};
            my $cover = !$seed_recordings{$id} && grep {
                my %attributes = map { $_ => 1 } @{$_->{attributes} // []};
                $attributes{cover} && !$attributes{karaoke} && !$attributes{medley} && !$attributes{partial};
            } @relations;
            for my $isrc (map { uc } @{$recording->{isrcs} // []}) {
                next unless $isrc =~ $isrc_pattern && $isrc ne $seed_isrc;
                $recordings_by_isrc{$isrc}{$id} = $cover;
            }
        }
        $offset += @recordings;
        last if !@recordings || $offset >= $doc->{'recording-count'};
    }

    my %cover_ids;
    for my $isrc (keys %recordings_by_isrc) {
        my $recordings = $recordings_by_isrc{$isrc};
        my @ids = keys %$recordings;
        $cover_ids{$isrc} = $ids[0] if @ids == 1 && $recordings->{$ids[0]};
    }
    my @isrcs = sort keys %cover_ids;
    my @rows;
    while (@isrcs) {
        my @batch = splice @isrcs, 0, 20;
        my %requested = map { $_ => 1 } @batch;
        my $endpoint = '/tracks?' . query(countryCode => $country, include => 'artists', 'filter[isrc]' => join(',', @batch));
        pages($endpoint, sub ($doc) {
            for my $row (track_rows($doc)) {
                my $isrc = uc($row->{isrc} // '');
                next unless $requested{$isrc};
                push @rows, {%$row, musicbrainz_recording_id => $cover_ids{$isrc}};
            }
        });
    }

    return ($works{$work_id}, \@rows);
}

1;

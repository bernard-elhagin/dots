#!/usr/bin/env perl
use v5.36;
use utf8;
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use Encode        qw(decode FB_CROAK);
use Getopt::Long  qw(GetOptionsFromArray);
use POSIX         qw(isfinite);
use Tidal::Client qw(json state_dir lock_state login legacy_digest save progress);
use Tidal::Catalog
    qw(owned_playlists favorite_tracks playlist_id playlist_tracks track_details effective_features);
use Tidal::IgnoredArtists qw(ignored_artists);
use Tidal::Playlist       qw(resolve discover create append delete_playlist import_plan);

my %commands = (
    login   => [ 'Authorize through a local callback', [], 'client-id=s' ],
    resolve => [
        'Match artist/title suggestions and save a plan',
        ['input'], 'output=s', 'pages=i', 'ignore=s@'
    ],
    create    => [ 'Create an unlisted playlist from a plan', ['plan'], 'yes', 'ignore=s@' ],
    ignore    => [ 'List or save artists excluded from generated playlists', [], 'ignore=s@' ],
    playlists => [ 'List your owned playlists',                              [] ],
    favorites => [ 'Read your favorite tracks',                              [] ],
    features  => [ 'Read BPM, key and mood data', ['target'], 'playlist' ],
    'analyze-audio' => [
        'Estimate tempo, key and mood from a local audio file',
        ['file'], 'seconds=f', 'track-id=s', 'output=s'
    ],
    tracks => [ 'Read all tracks in a playlist', ['playlist'] ],
    append => [
        'Append a playlist without duplicate recordings', [ 'source?', 'destination?' ],
        'resume=s',                                       'yes'
    ],
    delete   => [ 'Delete a playlist and save a local backup', ['playlist?'], 'resume=s', 'yes' ],
    discover => [
        'Generate a local discovery plan', ['source?'],
        'from-favorites',                  'artist=s',
        'track=s@',                        'covers=s@',
        'exclude-favorites',               'bpm-min=f',
        'bpm-max=f',                       'key=s',
        'scale=s',                         'mood=s@',
        'name=s',                          'count=i',
        'seed-limit=i',                    'pages=i',
        'max-per-artist=i',                'exclude-playlist=s@',
        'allow-previous',                  'output=s',
        'ignore=s@'
    ],
    'import-plan' => [ 'Preserve a legacy plan and recommendation history', ['plan'] ],
);

my %without_country = map { $_ => 1 } qw(login create ignore favorites analyze-audio import-plan);

sub usage( $command = undef ) {
    if ( !defined $command ) {
        say "Usage: tidal-playlist [--json] COMMAND [OPTIONS]\n";
        printf "  %-15s %s\n", $_, $commands{$_}[0] for sort keys %commands;
        return;
    }

    my ( $description, $positionals, @options ) = @{ $commands{$command} };
    my @names = map { /\?\z/ ? '[' . substr( $_, 0, -1 ) . ']' : uc($_) } @$positionals;

    say join ' ', 'Usage: tidal-playlist [--json]', $command, @names, '[OPTIONS]';
    say $description;

    push @options, 'country=s' unless $without_country{$command};

    for my $option (@options) {
        my ( $flag, $value ) = split /=/, $option;
        say "  --$flag" . ( defined $value ? ' VALUE' : '' );
    }

    if ( $command eq 'discover' ) {
        say
            'Choose one seed source: SOURCE, --artist NAME, --track TRACK, --covers TRACK, or --from-favorites.';
        say 'TRACK is a TIDAL track ID, track URL, or "Artist - Track title".';
        say
            'Combine --track TRACK with --artist NAME to return only recommendations credited to that artist.';
        say '--covers finds covers of the seed composition, up to --count tracks.';
    }

    say 'Repeat --ignore ARTIST to save multiple artists.' if grep { $_ eq 'ignore=s@' } @options;
}

sub options( $command, @argv ) {
    my ( undef, $positionals, @flags ) = @{ $commands{$command} };
    my %args = ( country => 'GB' );

    if ( $command eq 'discover' ) {
        %args = (
            %args,
            'count'            => 20,
            'pages'            => 2,
            'seed-limit'       => 12,
            'mood'             => [],
            'exclude-playlist' => []
        );
    }

    $args{pages}   = 3   if $command eq 'resolve';
    $args{seconds} = 120 if $command eq 'analyze-audio';

    push @flags, 'country=s' unless $without_country{$command};

    Getopt::Long::Configure(qw(no_auto_abbrev no_ignore_case permute));

    die "Invalid options. Run tidal-playlist $command --help.\n"
        unless GetOptionsFromArray( \@argv, \%args, @flags, 'help|h' );

    return { help => 1 } if $args{help};

    for my $positional (@$positionals) {
        my $name = $positional =~ s/\?\z//r;

        die "Missing $name. Run tidal-playlist $command --help.\n"
            unless @argv || $positional ne $name;

        $args{$name} = shift @argv if @argv;
    }

    die "Unexpected positional arguments. Run tidal-playlist $command --help.\n" if @argv;

    $args{country} = uc $args{country};
    $args{country} = 'GB' if $args{country} eq 'UK';

    die "Use a two-letter country code, e.g. GB.\n" unless $args{country} =~ /\A[A-Z]{2}\z/;

    for my $flag (qw(pages count seed-limit max-per-artist bpm-min bpm-max seconds)) {
        next unless defined $args{$flag};
        die "--$flag must be a finite positive number.\n"
            unless isfinite( $args{$flag} ) && $args{$flag} > 0;
    }

    if ( $command eq 'discover' ) {
        for my $flag (qw(track covers)) {
            next unless defined $args{$flag};

            die "Supply --$flag only once.\n" if @{ $args{$flag} } != 1;

            $args{$flag} = $args{$flag}[0];
        }

        my $sources = grep { defined $args{$_} } qw(source artist track covers);

        $sources-- if defined( $args{track} ) && defined( $args{artist} );
        $sources++ if $args{'from-favorites'};

        die
            "discover requires one of a source playlist, --artist, --track, --covers, or --from-favorites.\n"
            if $sources != 1;

        die "Playlist name is required. Use --name.\n" unless defined $args{name};

        die "--bpm-min must not exceed --bpm-max.\n"
            if defined( $args{'bpm-min'} )
            && defined( $args{'bpm-max'} )
            && $args{'bpm-min'} > $args{'bpm-max'};

        die "Invalid --key.\n"
            if defined( $args{key} )
            && $args{key} !~ /\A(?:C|CSharp|D|Eb|E|F|FSharp|G|Ab|A|Bb|B)\z/;

        $args{scale} = uc $args{scale} if defined $args{scale};

        die "Invalid --scale.\n"
            if defined( $args{scale} )
            && $args{scale} !~
            /\A(?:MAJOR|MINOR|AEOLIAN|BLUES|DORIAN|LOCRIAN|LYDIAN|MIXOLYDIAN|PENTATONIC_MAJOR|PENTATONIC_MINOR|HARMONIC_MINOR|MELODIC_MINOR)\z/;
    }

    return \%args;
}

sub command( $name, $args ) {
    if ( $name =~ /\A(?:discover|resolve|create|ignore)\z/ ) {
        $args->{ignored_artists} = ignored_artists( @{ $args->{ignore} // [] } );
        return { ignored_artists =>
                [ map { $args->{ignored_artists}{$_} } sort keys %{ $args->{ignored_artists} } ] }
            if $name eq 'ignore';
    }

    return login( $args->{'client-id'} // 'OJ1xYPEKAPDjLC7r' ) if $name eq 'login';
    return resolve($args)                                      if $name eq 'resolve';
    return create($args)                                       if $name eq 'create';
    return append($args)                                       if $name eq 'append';
    return delete_playlist($args)                              if $name eq 'delete';
    return discover($args)                                     if $name eq 'discover';
    return import_plan($args)                                  if $name eq 'import-plan';
    return [ owned_playlists( $args->{country} ) ]             if $name eq 'playlists';
    return { tracks => [ favorite_tracks() ] }                 if $name eq 'favorites';

    if ( $name eq 'tracks' ) {
        my $id = playlist_id( $args->{playlist}, $args->{country} );
        return { id => $id, tracks => [ playlist_tracks( $id, $args->{country} ) ] };
    }

    if ( $name eq 'features' ) {
        my @rows =
            $args->{playlist}
            ? playlist_tracks( playlist_id( $args->{target}, $args->{country} ), $args->{country} )
            : track_details( $args->{target}, $args->{country} );

        return {
            tracks => [
                map {
                    { %$_, effective_features => effective_features($_) }
                } @rows
            ]
        };
    }

    require Tidal::Audio;
    my $result = Tidal::Audio::analyze_file( $args->{file}, $args->{seconds} );

    if ( $args->{'track-id'} ) {
        $result->{track_id}    = $args->{'track-id'};
        $result->{association} = 'user-supplied; recording identity not independently verified';
        save( state_dir() . '/audio/' . legacy_digest( $args->{'track-id'} ) . '.json', $result );
    }

    save( $args->{output}, $result ) if defined $args->{output};

    return $result;
}

sub main(@argv) {
    my $machine = @argv && $argv[0] eq '--json';

    shift @argv if $machine;

    my $name = shift @argv;

    if ( defined($name) && $name =~ /\A--ignore(?:=|\z)/ ) {
        unshift @argv, $name;
        $name = 'ignore';
    }

    if ( !defined($name) || $name eq '--help' || $name eq '-h' ) {
        usage();

        return defined($name) ? 0 : 2;
    }

    unless ( exists $commands{$name} ) {
        progress("Unknown command '$name'. Run tidal-playlist --help.");

        return 2;
    }

    my $args = eval { options( $name, @argv ) };

    if ($@) {
        progress( $@ =~ s/\s+\z//r );

        return 2;
    }

    if ( $args->{help} ) {
        usage($name);

        return 0;
    }

    local $SIG{INT} =
        sub { progress('Cancelled. Saved plans and operation records are retained.'); exit 130 };

    my $result = eval {
        my $lock = lock_state();
        command( $name, $args );
    };

    if ($@) {
        my $error = $@ =~ s/\s+\z//r;

        if ($machine) {
            binmode STDERR, ':raw';
            say STDERR json()->encode( { error => $error } );
        } else {
            progress("Error: $error");
        }

        return 1;
    }

    say json()->pretty( !$machine )->encode($result) =~ s/\n\z//r;

    return 0;
}

binmode STDOUT, ':raw';
binmode STDERR, ':encoding(UTF-8)';

exit main( map { decode( 'UTF-8', $_, FB_CROAK ) } @ARGV );

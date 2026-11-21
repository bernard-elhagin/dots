package Tidal::IgnoredArtists;
use v5.36;
use Exporter 'import';
use Tidal::Client  qw(load save state_dir);
use Tidal::Catalog qw(normalize);

our @EXPORT_OK = qw(ignored_artists ignored_track);

sub ignored_artists(@additions) {
    my $path  = state_dir() . '/ignored-artists.json';
    my $saved = -e $path ? load($path) : [];
    die "Ignored artists must be a JSON array of artist names in $path.\n"
        unless ref($saved) eq 'ARRAY';

    my %names;
    for my $name ( @$saved, @additions ) {
        die "Use a nonempty artist name with --ignore.\n"
            unless defined($name) && !ref($name) && length( normalize($name) );
        my $trimmed = $name =~ s/^\s+|\s+$//gr;
        $names{ normalize($trimmed) } //= $trimmed;
    }
    if (@additions) {
        save( $path, [ map { $names{$_} } sort keys %names ] );
    }

    return \%names;
}

sub ignored_track( $track, $names ) {
    return 0 unless keys %$names;
    return
        scalar grep { exists $names->{ normalize($_) } }
        ( $track->{artist}, @{ $track->{artists} // [] } );
}

1;

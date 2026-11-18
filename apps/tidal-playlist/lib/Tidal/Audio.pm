package Tidal::Audio;
use v5.36;
use Exporter 'import';
use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use List::Util qw(max min sum);
use POSIX qw(isfinite);

our @EXPORT_OK = qw(analyze_file);
use constant SAMPLE_RATE => 22050;
use constant FFT_SIZE => 4096;
use constant HOP => 256;
my @notes = qw(C CSharp D Eb E F FSharp G Ab A Bb B);
my @major = (6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88);
my @minor = (6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17);

sub round_to($value, $digits) { return 0 + sprintf("%.*f", $digits, $value) }

sub fft_tables() {
    my $pi = 4 * atan2(1, 1);
    my (@reversed, @cosine, @sine, @window);
    my $reverse = 0;
    for my $index (0..FFT_SIZE-1) {
        push @reversed, $reverse;
        push @window, .5 - .5 * cos(2 * $pi * $index / (FFT_SIZE - 1));
        my $bit = FFT_SIZE >> 1;
        while ($bit && ($reverse & $bit)) {
            $reverse ^= $bit;
            $bit >>= 1;
        }
        $reverse ^= $bit;
    }
    for my $index (0..FFT_SIZE/2-1) {
        push @cosine, cos(-2 * $pi * $index / FFT_SIZE);
        push @sine, sin(-2 * $pi * $index / FFT_SIZE);
    }

    return (\@reversed, \@cosine, \@sine, \@window);
}

sub spectrum($samples, $offset, $mean, $reversed, $cosine, $sine, $window) {
    my (@real, @imaginary);
    for my $index (0..FFT_SIZE-1) {
        $real[$reversed->[$index]] = ($samples->[$offset + $index] - $mean) * $window->[$index];
    }
    @imaginary = (0) x FFT_SIZE;
    for (my $span = 2; $span <= FFT_SIZE; $span *= 2) {
        my $half = $span / 2;
        my $step = FFT_SIZE / $span;
        for (my $base = 0; $base < FFT_SIZE; $base += $span) {
            for my $index (0..$half-1) {
                my $left = $base + $index;
                my $right = $left + $half;
                my $angle = $index * $step;
                my $r = $real[$right] * $cosine->[$angle] - $imaginary[$right] * $sine->[$angle];
                my $i = $real[$right] * $sine->[$angle] + $imaginary[$right] * $cosine->[$angle];
                $real[$right] = $real[$left] - $r;
                $imaginary[$right] = $imaginary[$left] - $i;
                $real[$left] += $r;
                $imaginary[$left] += $i;
            }
        }
    }

    return map { sqrt($real[$_] ** 2 + $imaginary[$_] ** 2) } 0..FFT_SIZE/2;
}

sub correlation($left, $right) {
    my ($mean_left, $mean_right) = (sum(@$left) / @$left, sum(@$right) / @$right);
    my ($cross, $square_left, $square_right) = (0, 0, 0);
    for my $index (0..$#$left) {
        my $x = $left->[$index] - $mean_left;
        my $y = $right->[$index] - $mean_right;
        $cross += $x * $y;
        $square_left += $x * $x;
        $square_right += $y * $y;
    }

    return $square_left && $square_right ? $cross / sqrt($square_left * $square_right) : 0;
}

sub measurements($samples) {
    my $length = @$samples;
    die "Provide at least five seconds of finite audio.\n"
        if $length < SAMPLE_RATE * 5 || grep { !isfinite($_) } @$samples;
    my $mean = sum(@$samples) / $length;
    my $squares = 0;
    $squares += ($_ - $mean) ** 2 for @$samples;
    my $rms = sqrt($squares / $length);
    my $result = {bpm => undef, key => undef, scale => undef, moods => [],
        source => 'local_audio', seconds_analyzed => round_to($length / SAMPLE_RATE, 2)};
    if ($rms < 1e-6) {
        return {%$result, tempo_strength => 0, key_correlation => 0, key_margin => 0,
            note => 'Audio is silent; no musical estimates.'};
    }
    my @tables = fft_tables();
    my @energy = (0) x (FFT_SIZE / 2 + 1);
    my (@previous, @flux);
    my ($total, $weighted) = (0, 0);
    for (my $offset = 0; $offset + FFT_SIZE <= $length; $offset += HOP) {
        my @amplitudes = spectrum($samples, $offset, $mean, @tables);
        my $change = 0;
        for my $bin (0..$#amplitudes) {
            my $amp = $amplitudes[$bin];
            $energy[$bin] += $amp * $amp;
            $total += $amp;
            $weighted += $amp * $bin;
            my $value = log(1 + $amp);
            $change += max(0, $value - $previous[$bin]) if defined $previous[$bin];
            $previous[$bin] = $value;
        }
        push @flux, $change / @amplitudes if $offset;
    }
    my @sorted = sort { $a <=> $b } @flux;
    my $percentile = .95 * $#sorted;
    my $lower = int($percentile);
    my $flux_mean = sum(@flux) / @flux;
    my $prominence = ($sorted[$lower] + ($percentile - $lower) * ($sorted[$lower + 1] - $sorted[$lower]))
        / max($flux_mean, 1e-12);
    $_ -= $flux_mean for @flux;
    my $baseline = sum(map { $_ * $_ } @flux) / @flux;
    my $strength = 0;
    if ($baseline > 1e-12 && $prominence >= 2.5) {
        my ($best, $best_lag) = (-1e30, 0);
        for my $lag (round_to(60 * SAMPLE_RATE / (HOP * 200), 0) .. round_to(60 * SAMPLE_RATE / (HOP * 50), 0)) {
            my $cross = 0;
            $cross += $flux[$_] * $flux[$_ + $lag] for 0..$#flux-$lag;
            $cross /= @flux - $lag;
            ($best, $best_lag) = ($cross, $lag) if $cross > $best;
        }
        $strength = min(1, max(0, $best / $baseline));
        $result->{bpm} = round_to(60 * SAMPLE_RATE / (HOP * $best_lag), 1) if $strength >= .08;
    }
    my @chroma = (0) x 12;
    for my $bin (1..$#energy) {
        my $frequency = $bin * SAMPLE_RATE / FFT_SIZE;
        next unless $frequency >= 55 && $frequency <= 5000;
        my $pitch = round_to(69 + 12 * log($frequency / 440) / log(2), 0) % 12;
        $chroma[$pitch] += $energy[$bin];
    }
    my @scores;
    for my $scale ('MAJOR', 'MINOR') {
        my $profile = $scale eq 'MAJOR' ? \@major : \@minor;
        for my $tonic (0..11) {
            my @rotated = map { $profile->[($_ - $tonic) % 12] } 0..11;
            push @scores, [correlation(\@chroma, \@rotated), $notes[$tonic], $scale];
        }
    }
    @scores = sort { $b->[0] <=> $a->[0] || $b->[1] cmp $a->[1] || $b->[2] cmp $a->[2] } @scores;
    my ($score, $key, $scale) = @{$scores[0]};
    my $margin = $score - $scores[1][0];
    @{$result}{qw(key scale)} = ($key, $scale) if $score >= .5 && $margin >= .03;
    my $centroid = $weighted / max($total, 1e-12) * SAMPLE_RATE / FFT_SIZE;
    push @{$result->{moods}}, 'bright' if $centroid > 2500;
    push @{$result->{moods}}, 'dark' if $centroid < 1200;
    my $bpm = $result->{bpm};
    push @{$result->{moods}}, 'energetic' if defined($bpm) && $bpm >= 115 && $strength >= .15;
    push @{$result->{moods}}, 'calm' if defined($bpm) && $bpm <= 95 && $centroid < 2000;

    return {%$result, tempo_strength => round_to($strength, 3), onset_prominence => round_to($prominence, 3),
        key_correlation => round_to($score, 3), key_margin => round_to($margin, 3),
        spectral_centroid_hz => round_to($centroid, 0),
        note => 'Estimated tempo/key; half/double tempo is possible. Mood labels describe tempo/brightness heuristics, not emotions.'};
}

sub analyze_file($filename, $seconds) {
    $filename =~ s{\A~(?=/)}{$ENV{HOME}};
    my $path = realpath($filename);
    die "Audio input must be a local file.\n" unless defined($path) && -f $path;
    die "Analyze between 5 and 300 seconds.\n" unless $seconds >= 5 && $seconds <= 300;
    open my $audio, '-|', 'timeout', '120', 'ffmpeg', '-nostdin', '-v', 'error',
        '-protocol_whitelist', 'file,pipe', '-i', $path, '-t', "$seconds", '-vn',
        '-ac', '1', '-ar', SAMPLE_RATE, '-f', 'f32le', 'pipe:1'
        or die "Cannot run FFmpeg: $!\n";
    binmode $audio, ':raw';
    local $/;
    my $bytes = readline($audio) // '';
    close $audio or die "FFmpeg could not decode this local file within 120 seconds.\n";
    my $signature = sha256_hex($bytes);
    my @samples = unpack 'f<*', $bytes;
    undef $bytes;
    my $result = measurements(\@samples);
    $result->{audio_segment_sha256} = $signature;

    return $result;
}

1;

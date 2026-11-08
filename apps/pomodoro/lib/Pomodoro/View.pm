package Pomodoro::View;
use strict;
use warnings;
use utf8;
use POSIX qw(ceil);

my %digits = (
    '0' => ['█████','█   █','█   █','█   █','█████'],
    '1' => ['  █  ',' ██  ','  █  ','  █  ','█████'],
    '2' => ['█████','    █','█████','█    ','█████'],
    '3' => ['█████','    █',' ████','    █','█████'],
    '4' => ['█   █','█   █','█████','    █','    █'],
    '5' => ['█████','█    ','█████','    █','█████'],
    '6' => ['█████','█    ','█████','█   █','█████'],
    '7' => ['█████','    █','   █ ','  █  ','  █  '],
    '8' => ['█████','█   █','█████','█   █','█████'],
    '9' => ['█████','█   █','█████','    █','█████'],
    ':' => ['   ',' █ ','   ',' █ ','   '],
);

sub render {
    my ($class, %args) = @_;
    my ($timer, $cols, $rows) = @args{qw(timer columns rows)};
    $cols = 80 unless $cols && $cols > 0;
    $rows = 24 unless $rows && $rows > 0;
    my $width = $cols < 72 ? $cols : 72;
    my $color = $args{color};
    my $accent = $timer->paused ? '38;5;179'
        : $timer->phase eq 'work' ? '38;5;210' : '38;5;115';
    my %style = (accent => $accent, bright => '1', shortcuts => '1;97', duration => '33', muted => '38;5;245', rule => '38;5;238');
    my @lines;
    my $line = sub {
        my ($text, $style, $align) = @_;
        $text //= '';
        $text = substr($text, 0, $width);
        my $padding = $align && $align eq 'left' ? 0 : int(($width - length($text)) / 2);
        my $value = (' ' x $padding) . $text;
        if ($color && $style) {
            if ($style eq 'shortcuts') {
                $value =~ s/\b(SPACE|RR|N|Q)\b/\e[$style{shortcuts}m$1\e[0;$style{muted}m/g;
                $value = "\e[$style{muted}m$value\e[0m";
            } elsif ($style eq 'schedule') {
                $value =~ s/(\d+(?:\.\d+)?m)\b/\e[$style{duration}m$1\e[0;$style{muted}m/g;
                $value = "\e[$style{muted}m$value\e[0m";
            } else {
                $value = "\e[$style{$style}m$value\e[0m";
            }
        }
        push @lines, $value;
    };
    my %label = (work => 'F O C U S', short => 'S H O R T   B R E A K', long => 'L O N G   B R E A K');
    my $seconds = ceil($timer->remaining);
    my $clock = sprintf('%02d:%02d', int($seconds / 60), $seconds % 60);
    my $compact = $cols < 58 || $rows < 23;
    $line->('P O M O D O R O', 'bright');
    $line->('one thing at a time', 'muted') unless $compact;
    $line->();
    $line->($label{$timer->phase}, 'accent');
    $line->($timer->paused ? 'Ⅱ  PAUSED' : '●  IN PROGRESS', 'muted');
    $line->();
    if ($compact) {
        $line->($clock, 'accent');
    } else {
        for my $row (0 .. 4) {
            $line->(join('  ', map { $digits{$_}[$row] } split //, $clock), 'accent');
        }
    }
    $line->();
    my $progress = 1 - $timer->remaining / $timer->duration;
    $progress = 0 if $progress < 0;
    $progress = 1 if $progress > 1;
    my $bar_width = $width > 48 ? 40 : ($width > 8 ? $width - 8 : 1);
    my $filled = int($progress * $bar_width);
    $line->(('━' x $filled) . ('─' x ($bar_width - $filled)), 'accent');
    my $opts = $args{options};
    my $cycle = $timer->completed % $opts->{every};
    my $marks = $opts->{every} <= 12
        ? join(' ', map { $_ <= $cycle ? '●' : '○' } 1 .. $opts->{every})
        : "$cycle / $opts->{every}";
    $line->("$marks   ·   " . $timer->completed . ' completed', 'muted');
    $line->();
    $line->("$opts->{work}m focus   /   $opts->{short}m break   /   $opts->{long}m long break", 'schedule') unless $compact;
    $line->($args{message}, 'muted');
    $line->();
    $line->('SPACE pause   N skip   RR reset   Q quit', 'shortcuts');

    # Tiny terminals keep the essentials instead of clipping the countdown.
    if ($rows < @lines) {
        @lines = ();
        $line->($label{$timer->phase} . ($timer->paused ? ' · PAUSED' : ''), 'accent');
        $line->($clock, 'bright');
        $line->('SPACE pause · N skip · Q quit', 'shortcuts') if $rows >= 3;
    }
    my $top = int(($rows - @lines) / 2);
    $top = 0 if $top < 0;
    my $left = int(($cols - $width) / 2);
    my $frame = '';
    for my $row (0 .. $rows - 1) {
        my $index = $row - $top;
        my $text = $index >= 0 && $index < @lines ? (' ' x $left) . $lines[$index] : '';
        $frame .= sprintf("\e[%d;1H\e[K%s", $row + 1, $text);
    }
    return $frame;
}

1;

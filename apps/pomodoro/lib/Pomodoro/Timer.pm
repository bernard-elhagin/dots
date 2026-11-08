package Pomodoro::Timer;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        durations => { work => 60 * ($args{work} // 25),
                       short => 60 * ($args{short} // 5),
                       long => 60 * ($args{long} // 15) },
        every => $args{every} // 4,
        phase => 'work', completed => 0, paused => 0,
    }, $class;
    $self->{remaining} = $self->duration;
    return $self;
}

sub phase { $_[0]->{phase} }
sub completed { $_[0]->{completed} }
sub paused { $_[0]->{paused} }
sub remaining { $_[0]->{remaining} }
sub duration { $_[0]->{durations}{$_[0]->{phase}} }
sub toggle_pause { $_[0]->{paused} = !$_[0]->{paused} }
sub reset { $_[0]->{remaining} = $_[0]->duration }

sub advance {
    my ($self, $finished) = @_;
    if ($self->{phase} eq 'work') {
        $self->{completed}++ if $finished;
        $self->{phase} = $finished && $self->{completed} % $self->{every} == 0
            ? 'long' : 'short';
    } else {
        $self->{phase} = 'work';
    }
    $self->reset;
}

# Discard overrun at phase boundaries: a delayed terminal should not silently
# consume a whole break before the user has even seen its notification.
sub tick {
    my ($self, $elapsed) = @_;
    return 0 if $self->{paused} || $elapsed <= 0;
    $self->{remaining} -= $elapsed;
    return 0 if $self->{remaining} > 0;
    $self->advance(1);
    return 1;
}

1;

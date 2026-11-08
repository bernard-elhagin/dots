package Pomodoro::Sound;
use strict;
use warnings;
use File::Spec;
use POSIX qw(WNOHANG);

sub new {
    my ($class, %args) = @_;
    my $self = bless { directory => $args{directory}, silent => $args{silent} }, $class;
    return $self if $self->{silent};
    for my $name (qw(pw-play paplay afplay aplay)) {
        for my $directory (File::Spec->path) {
            my $path = File::Spec->catfile($directory, $name);
            if (-f $path && -x $path) {
                $self->{player} = $path;
                last;
            }
        }
        last if $self->{player};
    }
    return $self;
}

sub play {
    my ($self, $phase) = @_;
    return if $self->{silent};
    $self->poll;
    return if $self->{pid};
    my $file = File::Spec->catfile($self->{directory}, $phase eq 'work' ? 'focus.wav' : 'break.wav');
    unless ($self->{player} && -r $file) {
        print "\a";
        return;
    }
    my $pid = fork;
    unless (defined $pid) {
        print "\a";
        return;
    }
    if ($pid == 0) {
        # Never let a player consume keyboard input or write over the dashboard.
        $SIG{$_} = 'DEFAULT' for qw(INT TERM HUP TSTP CONT WINCH);
        open STDIN, '<', File::Spec->devnull or POSIX::_exit(1);
        open STDOUT, '>', File::Spec->devnull or POSIX::_exit(1);
        open STDERR, '>', File::Spec->devnull or POSIX::_exit(1);
        exec {$self->{player}} $self->{player}, $file or POSIX::_exit(1);
    }
    $self->{pid} = $pid;
}

sub poll {
    my ($self) = @_;
    return unless $self->{pid};
    my $result = waitpid($self->{pid}, WNOHANG);
    if ($result > 0) {
        my $failed = $? != 0;
        delete $self->{pid};
        if ($failed) {
            delete $self->{player};
            print "\a" unless $self->{silent};
        }
    } elsif ($result == -1) {
        delete $self->{pid};
    }
}

sub stop {
    my ($self) = @_;
    $self->poll;
    if (my $pid = delete $self->{pid}) {
        kill 'KILL', $pid;
        waitpid($pid, 0);
    }
}

1;

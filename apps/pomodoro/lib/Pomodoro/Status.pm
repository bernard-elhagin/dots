package Pomodoro::Status;
use strict;
use warnings;
use Fcntl qw(:flock);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP;
use POSIX qw(ceil strftime);

sub new {
    my ($class, %args) = @_;
    my $base = $ENV{XDG_CACHE_HOME}
        || File::Spec->catdir($ENV{HOME}, '.cache');
    my $dir = $args{directory} || File::Spec->catdir($base, 'pomodoro');
    make_path($dir, { mode => 0700 });
    return bless { directory => $dir, clock => $args{clock} || sub { time } }, $class;
}

sub date_key { strftime('%Y-%m-%d', localtime($_[0]->{clock}->())) }

sub completed_today {
    my ($self) = @_;
    open my $input, '<', "$self->{directory}/daily.json" or return 0;
    local $/;
    my $daily = eval { decode_json(<$input>) };
    return 0 unless ref($daily) eq 'HASH' && ($daily->{date} // '') eq $self->date_key;
    return ($daily->{count} // '') =~ /^\d+$/ ? 0 + $daily->{count} : 0;
}

sub record_completions {
    my ($self, $completed) = @_;
    my $previous = $self->{last_completed} // $completed;
    $self->{last_completed} = $completed;
    return unless $completed > $previous;
    my $daily = { date => $self->date_key, count => $self->completed_today + $completed - $previous };
    my $temp = "$self->{directory}/daily.$$.tmp";
    open my $output, '>', $temp or die "Cannot write daily Pomodoro count: $!\n";
    chmod 0600, $temp;
    print {$output} encode_json($daily);
    close $output or die "Cannot finish daily Pomodoro count: $!\n";
    rename $temp, "$self->{directory}/daily.json" or die "Cannot publish daily Pomodoro count: $!\n";
}

sub acquire {
    my ($self) = @_;
    open my $lock, '>>', "$self->{directory}/lock" or die "Cannot open timer lock: $!\n";
    flock($lock, LOCK_EX | LOCK_NB) or die "Pomodoro is already running. Use its taskbar button to pause/resume.\n";
    $self->{lock} = $lock;
}

sub publish {
    my ($self, $timer) = @_;
    $self->record_completions($timer->completed);
    my $seconds = ceil($timer->remaining);
    my $state = { running => JSON::PP::true, pid => $$, updated => time,
        phase => $timer->phase, paused => $timer->paused ? JSON::PP::true : JSON::PP::false,
        completed => $timer->completed, completedToday => $self->completed_today,
        remaining => $seconds, duration => $timer->duration,
        text => sprintf('%02d:%02d', int($seconds / 60), $seconds % 60) };
    # Stable key order makes the unchanged-status comparison meaningful.
    my $json = JSON::PP->new->utf8->canonical->encode($state);
    return if ($self->{last} // '') eq $json;
    my $temp = "$self->{directory}/status.$$.tmp";
    open my $output, '>', $temp or die "Cannot write timer status: $!\n";
    chmod 0600, $temp;
    print {$output} $json;
    close $output or die "Cannot finish timer status: $!\n";
    rename $temp, "$self->{directory}/status.json" or die "Cannot publish timer status: $!\n";
    $self->{last} = $json;
}

sub read {
    my ($self) = @_;
    my $inactive = { running => JSON::PP::false, text => 'POMO', completedToday => $self->completed_today };
    open my $input, '<', "$self->{directory}/status.json" or return $inactive;
    local $/;
    my $state = eval { decode_json(<$input>) };
    return $inactive unless ref($state) eq 'HASH' && ($state->{pid} // '') =~ /^\d+$/
        && $state->{pid} > 1 && time - ($state->{updated} // 0) <= 5;
    # The lock distinguishes a live timer from a stale file or a reused PID.
    open my $lock, '>>', "$self->{directory}/lock" or return $inactive;
    return $inactive if flock($lock, LOCK_EX | LOCK_NB);
    return $inactive unless kill 0, $state->{pid};
    $state->{completedToday} = $self->completed_today;
    return $state;
}

sub clear {
    my ($self) = @_;
    return unless $self->{lock};
    unlink "$self->{directory}/status.json";
    close delete $self->{lock};
}

1;

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::Local qw(timelocal);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Pomodoro::Status;
use Pomodoro::Timer;

my $directory = tempdir(CLEANUP => 1);
my $now = timelocal(0, 0, 12, 15, 0, 2026);
my $status = Pomodoro::Status->new(directory => $directory, clock => sub { $now });
$status->acquire;
my $timer = Pomodoro::Timer->new;
$status->publish($timer);
is($status->completed_today, 0, 'new day has no completions');
$timer->advance(0);
$status->publish($timer);
is($status->completed_today, 0, 'skipped focus session does not count');
$timer->advance(1); # Finish break.
$status->publish($timer);
$timer->advance(1); # Finish focus.
$status->publish($timer);
is($status->read->{completedToday}, 1, 'completed focus session counts');
$status->publish($timer);
is($status->completed_today, 1, 'repeated publication does not double count');
$status->clear;
is($status->read->{completedToday}, 1, 'daily total survives stopping timer');
$status = Pomodoro::Status->new(directory => $directory, clock => sub { $now });
$status->acquire;
$timer = Pomodoro::Timer->new;
$status->publish($timer);
$timer->advance(1);
$status->publish($timer);
is($status->completed_today, 2, 'daily total survives a new timer process');
$now = timelocal(0, 0, 0, 16, 0, 2026);
is($status->read->{completedToday}, 0, 'daily count rolls over at local midnight');
$timer->advance(1); # Finish break.
$status->publish($timer);
$timer->advance(1); # Finish focus on new day.
$status->publish($timer);
is($status->completed_today, 1, 'new day counts only its completed focus sessions');
$status->clear;
done_testing;

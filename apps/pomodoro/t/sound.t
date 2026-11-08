use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use Time::HiRes qw(time sleep);
use lib "$FindBin::Bin/../lib";
use Pomodoro::Sound;

my $dir = tempdir(CLEANUP => 1);
my $log = "$dir/played";
local $ENV{PATH} = $dir;
local $ENV{POMODORO_TEST_LOG} = $log;
open my $player, '>', "$dir/pw-play" or die $!;
print {$player} "#!/bin/sh\nprintf '%s\\n' \"\$1\" >> \"\$POMODORO_TEST_LOG\"\n";
close $player;
chmod 0755, "$dir/pw-play";
my $assets = "$FindBin::Bin/../assets";
my $sound = Pomodoro::Sound->new(directory => $assets);
is($sound->{player}, "$dir/pw-play", 'discovers installed audio player');
for my $phase (qw(short work)) {
    $sound->play($phase);
    my $deadline = time + 3;
    while ($sound->{pid} && time < $deadline) { sleep .01; $sound->poll }
    ok(!$sound->{pid}, 'reaps player without blocking the timer');
}
open my $played, '<', $log or die $!;
my @files = <$played>;
like($files[0], qr/break\.wav/, 'break transition plays break chime');
like($files[1], qr/focus\.wav/, 'focus transition plays focus chime');
my $silent = Pomodoro::Sound->new(directory => $assets, silent => 1);
$silent->play('work');
ok(!$silent->{pid}, 'silent mode does not start a player');

{
    local $ENV{PATH} = '';
    my $fallback = Pomodoro::Sound->new(directory => $assets);
    my $output = '';
    open my $capture, '>', \$output or die $!;
    local *STDOUT = $capture;
    $fallback->play('work');
    is($output, "\a", 'missing player falls back to terminal bell');
}

done_testing;

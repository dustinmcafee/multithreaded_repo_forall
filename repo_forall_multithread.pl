#!/usr/bin/perl
use warnings;
use strict;
use threads;
use Cwd;

# (1) quit unless we have the correct number of command-line args
my $num_args = $#ARGV + 1;
if ($num_args != 2) {
    print "\nUsage: repo_forall_multithread.pl <command> <number of threads>\n";
    exit;
}

# (2) we got two command line args, so assume they are the
# first name and last name
my $COMMAND=$ARGV[0];
my $NO_THREADS=$ARGV[1];


$\ = "\n";

my $repolist = `repo list`;
my @arr = split /\n/, $repolist, 1000;
my $it = 0;
my @array;
foreach my $element (@arr) {
	if(!$element eq ""){
		$array[$it] = $element;
		$it ++;
	}
}
my $chunksize = 0;
{
	use integer;
	$chunksize = $it / $NO_THREADS;
}

my $iter = $NO_THREADS;
while ($iter > 0)
{
    threaded_task();
    $iter --;
}
exit;

sub threaded_task {
    threads->create(sub { 
        my $thr_id = threads->self->tid;
        print "Starting thread $thr_id ... forking...\n";
	my $pid = fork();
	die if not defined $pid;
	if (not $pid) {
		if($thr_id != $NO_THREADS){
			for(my $i = $chunksize * ($thr_id - 1); $i < $chunksize * $thr_id; $i++){
#				print $i . "/" . (($chunksize * $thr_id) - 1);
				do_command($array[$i]);
#				print $array[$i];
			}
		} else {
			for(my $i = $chunksize * ($thr_id - 1); $i < $it; $i++){
#				print $i . "/" . ($it - 1);
				do_command($array[$i]);
#				print $array[$i];
			}
		}
	        sleep 2; 
	        print "Ending child process $pid from parent: $thr_id\n";
		exit;
	}

        print "Detaching parent process $thr_id\n";
        threads->detach(); #End thread.
    });
}

sub do_command {
	my $line = $_[0];
	if($line =~ m#(^.*?) \: (.*?)$#){
		my $path = $1;
		my $cwd = getcwd();
		chdir($path);
		system($COMMAND);
		chdir($cwd);
	}
}


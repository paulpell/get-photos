#!/usr/bin/perl

##
## Script written by paul pellegrini, to help downloading pictures from a camera using PTP. Go wiki if you don't know what it is.
## 
## WARNING! It needs evince (to view the photos) and gphoto2.
## gphoto2:         2.4.10
## libgphoto2:      2.4.10.1
## libgphoto2_port: 0.8.0
##
## Maybe with other versions the output will not be formatted in the same way, and therefore it would not work anymore.
##
## You can freely take and adapt this code. No license.
##

use warnings;
use strict;

my $check = `gphoto2 --summary 2>&1`;
if ($check =~ /.*Error.*/) {
	print("no camera\n");
	exit 1;
}


#we must be in X environment, to use evince
$check = `env | grep DISPLAY`;
if ($check eq "") {
	print "Sorry, but you must be in graphics mode.\n";
	exit 1;
}

#let's begin the serious work
#print "What default folder to use to put the photos? ";
#chomp(my $defaultFolder = <>);

#if ( ! -d $defaultFolder ) {
#	print "Please go in a folder where the folder \"${defaultFolder}\" does exist, or create it\n";
#	exit 1;
#}


# get the file list on the camera
my $fileList = `gphoto2 --list-files 2>&1`;

my @lines = split /\n/, $fileList;

my $count = 0;
# find number of waiting pictures
foreach (@lines) {
	$count++ if /^#\d+/;
}

# for delete time, count in which folder how many files there are
my %forDel = ();
foreach (@lines) {
	if ($_ =~ /^There.+\d+\sfile/) {
		my @foo = split /'/, $_;
		my $key = $foo[1];
		s/^There.+\s(\d+)\sfile.+/$1/; # substitution operates on $_
		$forDel{$key} = $_;
	}
}

my $defaultFolder = '.';

foreach my $num (1 .. $count) {
	my $pictName = "";
	# timeout at line below is in case a file with the same name than the picture would already be in the current folder.
	# Then gphoto2 prompts for overwriting. We don't care, and hope it is the same photo. We will work on that name anyway.
	my $oasijd = `timeout 3 gphoto2 --get-file $num 2>&1`;
	@lines = split /\n/, $oasijd;
	@lines = split / /, $lines[1];
	if ($oasijd =~ /.+exists.+Overwrite/s) {
		chomp($pictName = `ls --sort=time tmp* | head -n1`);
	}
	else {
		$pictName = $lines[3];
	}
	print "Showing the picture in evince. Close it to continue.\n"; `evince $pictName`;
	print "Just downloaded $pictName. Rename it to (empty to not keep it): "; chomp(my $newName = <>);

	if ($newName eq "") {
		`rm $pictName`;
	}
	else {
		print "Put the picture in the folder: (default=${defaultFolder}) "; chomp(my $folder = <>);
		print "Give a description for that picture: "; chomp(my $descr = <>);

		$folder = $defaultFolder if $folder =~ /^\s*$/;
		$newName = $pictName if $newName =~ /^\s*$/;
		while (-e "$folder/$newName") {
			print "ALREADY USED: $newName in folder $folder\n";
			print "Enter the name (current=$newName, empty for same): "; chomp(my $tmpName = <>);
			print "In folder (current=$folder, empty for same): "; chomp(my $tmpFolder = <>);
			$folder = $tmpFolder if ($tmpFolder !~ /^\s*$/);
			$newName = $tmpName if ($tmpName !~ /^\s*$/);
		} 

		# do the asked things
		`mkdir $folder` if (! -d $folder);
		`mv $pictName $folder/$newName`;
		open(my $fh, ">>", "$folder/descriptions");
		print $fh "$newName $descr\n";

		$defaultFolder = $folder;
	}
}

print "Do you want to remove all the pictures (it's that or nothing) (enter y)? ";
chomp(my $remAll = <>);
if ($remAll =~ /[yY]/) {
	print "Removing everything\n";
	foreach my $dir (keys %forDel) {
		foreach my $file (1 .. %forDel{$_}) {
			`gphoto2 --folder $dir --delete-file 1`;
		}
	}
}
else {
	print "I let you do that stuff.\n";
}





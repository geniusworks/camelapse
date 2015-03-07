#!/usr/bin/perl -w

# Camelapse Daily Time Lapse Movie Maker
# Turn your webcam's still images into daily time lapse movies
#
# Copyright (c) 2015 by Martin Diekhoff
# http://www.geniusworks.com
#
# Github: https://github.com/geniusworks/camelapse
#

use strict;
use warnings;

use Date::Manip;
use File::Basename;

#
# Begin customizable values
#

# Mandatory customization
my $dir_web = '/home/{yourname}/public_html'; # path to public htdocs folder
my $dir_scripts = '/home/{username}'; # path to script folder
my $base_url = 'http://{yourdomain}/videos'; # your site's domain name
my $email = 'yourname@example.com'; # your email (for notifications)
my $ffmpeg = '/usr/local/bin/ffmpeg'; # change to your ffmpeg's installed path
my $fileprefix = "MyWebcamSnap_"; # same as the prefix of your still images

# Optional customization
my $movie_expiration = 30; # number of days movies should be retained
my $dir_photos = $dir_web . '/camelapse/snap'; # password-protected folder
my $dir_videos = $dir_web . '/videos'; # password-protected folder
my $dir_photo_prep = "$dir_scripts/camelapse/photos"; # common path
my $dir_video_prep = "$dir_scripts/camelapse/videos"; # common path

#
# End customizable values
#

# System-defined values
my $count = 0;
my $countstring = '';
my $date = ParseDate("yesterday");
my $year = substr $date, 0, 4;
my $month = substr $date, 4, 2;
my $day = substr $date, 6, 2;
my $refdate = "$year$month$day";
my $cmd = '';
my @files = ();
my @files_to_use = ();

# get yesterday's images
opendir(PHOTOS, $dir_photos);
@files = readdir PHOTOS;
closedir PHOTOS;
@files_to_use = sort @files;
foreach (@files_to_use) {

	chomp;

	my $compare1 = "$fileprefix$refdate";
	my $compare2 = substr $_, 0, length($compare1);

	# deal with today's files only
	if ($compare1 eq $compare2) {

		# update counts
		$count++;
		$countstring = sprintf("%05d", $count);

		# move file to photos folder
		my $fname = $_;
		my $ext = ($fname =~ m/([^.]+)$/)[0];
		if ($ext eq 'jpg') {
			$cmd = "mv $dir_photos/$_ $dir_photo_prep/image$countstring.jpg";
			system($cmd);
		}

	}

}

# make movie
my $movie = "$dir_video_prep/$refdate.mpg";
$cmd = "$ffmpeg -y -f image2 -i $dir_photo_prep/image%05d.jpg $movie";
system($cmd);
system("touch '$movie'");

# if movie has been created, delete source files
if (-f $movie) {

	# move movie to http location
	$cmd = "mv $movie $dir_videos/$refdate.mpg";
	system($cmd);

	# remove previous still images
	$cmd = 'find ' . $dir_photo_prep . ' -name "*.jpg" -exec rm -f {} \;';
	print "$cmd\n";
	system($cmd);

	# remove sources older than 1 day
	$cmd = 'find ' . $dir_photos . ' -name "*.jpg" -mtime 1 -exec rm -f {} \;';
	print "$cmd\n";
	system($cmd);
	$cmd = 'find ' . $dir_video_prep . ' -name "*.mpg" -exec rm -f {} \;';
	print "$cmd\n";
	system($cmd);

	# send confirmation email with link
	$cmd = "echo '$base_url\/$refdate\.mpg' | mail -s 'Camelapse Daily Video' $email";
	system($cmd);

}

# remove movie files older than {$movie_expiration} days
$cmd = 'find ' . $dir_web . '/videos/*.mpg -mtime ' . $movie_expiration . ' -exec rm -f {} \;';
system($cmd);

exit;



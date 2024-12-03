#!/usr/bin/perl -w

# Camelapse v0.2 Daily Time Lapse Movie Maker
# Turn your webcam's still images into daily time lapse movies
#
# Copyright (c) 2015 Martin Diekhoff. All rights reserved.
# Licensed under the MIT License.

use strict;
use warnings;
use autodie qw(:all);
use feature qw(say);
use Path::Tiny;

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
my $photos_dir = path($dir_photos);
my @files = $photos_dir->children;
my @files_to_use = sort @files;

say "Processing $count files";
foreach my $file (@files_to_use) {
    chomp $file;

    my $compare1 = "$fileprefix$refdate";
    my $compare2 = substr $file, 0, length($compare1);

    # deal with today's files only
    if ($compare1 eq $compare2) {

        # update counts
        $count++;
        $countstring = sprintf("%05d", $count);

        say "Processing file $file";
        # move file to photos folder
        my $fname = $file;
        my $ext = (split /\./, $fname)[-1];
        if ($ext eq 'jpg') {
            my $photo_prep_dir = path($dir_photo_prep);
            $photo_prep_dir->child("image$countstring.jpg")->move($photos_dir->child($fname));
            say "Moved file to photos folder";
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
	my $photo_prep_dir = path($dir_photo_prep);
    $photo_prep_dir->children(qr/\.jpg$/)->remove;
    say "Removed previous still images";

	# remove sources older than 1 day
	$photos_dir->children(qr/\.jpg$/)->remove;
    $photo_prep_dir->children(qr/\.mpg$/)->remove;
    say "Removed sources older than 1 day";

	# send confirmation email with link
	$cmd = "echo '$base_url\/$refdate\.mpg' | mail -s 'Camelapse Daily Video' $email";
	system($cmd);

}

# remove movie files older than {$movie_expiration} days
my $videos_dir = path($dir_videos);
my @movies = $videos_dir->children(qr/\.mpg$/);

say "Removing movie files older than $movie_expiration days";
foreach my $movie (@movies) {
    my $mtime = $movie->stat->mtime;
    my $age = time - $mtime;
    my $days = int($age / (24 * 60 * 60));

    if ($days > $movie_expiration) {
        $movie->remove;
        say "Removed movie file $movie";
    }
}

exit;



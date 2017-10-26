#!/usr/bin/perl
#======File: TagUnlabeledDataDirectory.pl=======
#Title:        TagUnlabeledDataDirectory.pl - POS Tag Unlabeled Data Directory.
#Description:  POS tags unlabeled plaintext documents and produces output data in a tokenized tab separated format. The Tag.pm module is used for POS tagging.
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 27.06.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
use strict;
use warnings;
use Encode;
use encoding "UTF-8";
use File::Basename;

BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Add this path to places where perl is searching for modules.
}

use Tag;

#Checking if all required parameters are set.
if (not(defined($ARGV[0])
	&& defined($ARGV[1])
	&& defined($ARGV[2])
	&& defined($ARGV[3])
	&& defined($ARGV[4])
	&& defined($ARGV[5])
	&& defined($ARGV[6])))
{ 
	print STDERR  "Usage perl ./TagUnlabeledDataDirectory.pl [ARGS]\nARGS:\n\t1. [Language] - The tagger language (en|lv|et..).\n\t2. [POS Tagger] - The POS tagger to use (POS|Tree|Tagger).\n\t3. [Input Directory] - Input data directory.\n\t4. [Output Directory] - Output data directory.\n\t5. [Input Extension] - Extension of the input files.\n\t6. [Output Extension] - Extension of the output files.\n\t7. [Delete Temp Files] - deletes temporary files if \"1\", keeps if \"0\".\n\t\n";
	print STDERR "possible Tagger-languge combinations Tree-[en|de|es|fr|it|el|et|bg] POS-[lv|lt|et] Tagger-[lv|lt|et]\n";
	die;
}

#Set the parameters.
my $language = $ARGV[0]; #POS tagging language.
my $tagger = $ARGV[1]; #POS tagger.

my $inputDir = $ARGV[2]; #Input directory (change slash format from "\" to "/" and add a slash at the end).
$inputDir =~ s/\\/\//g;
if ($inputDir !~ /.*\/$/)
{
	$inputDir .= "/";
}
unless(-d  $inputDir){ die "[TagUnlabeledDataDirectory] Cannot find input directory \"$inputDir\".";}
my $outputDir = $ARGV[3]; #Output directory (change slash format from "\" to "/" and add a slash at the end).
$outputDir =~ s/\\/\//g;
if ($outputDir !~ /.*\/$/)
{
	$outputDir .= "/";
}
unless(-d  $outputDir){mkdir  $outputDir or die "[TagUnlabeledDataDirectory] Cannot find nor create output directory \"$outputDir\".";}
my $inExt = $ARGV[4]; #Input file extension.
my $outExt = $ARGV[5]; #Output file extension.
my $deleteTempFiles = $ARGV[6]; #"1" - temp files will be deleted; "0" - temp files will be kept.

#POS tag each file of the specified extension from the input directory.
opendir(DIR, $inputDir) or die "[TagUnlabeledDataDirectory] Can't open directory \"$inputDir\": $!";
while (defined(my $file = readdir(DIR)))
{
	my $ucFile = uc($file);
	my $ucExt = uc($inExt);
	#Only use valid files with the correct extension!
	if ($ucFile =~ /.*\.$ucExt$/)
	{
		print STDERR "[TagUnlabeledDataDirectory] Tagging file: $file\n";
		my $inFile = $inputDir.$file;
		my ($inputFileName,$inputFilePath,$inputFileSuffix) = fileparse($inFile,qr/\.[^.]*/);
		my $outFile = $outputDir.$inputFileName.".".$outExt;
		#if (-e $outFile)
		#{
		#	print STDERR "[TagUnlabeledDataDirectory] Skipping file: $file\n";
		#}
		#else
		#{
		Tag::TagText($language, $tagger, $inFile, $outFile, $deleteTempFiles,2);
		#}
	}
	else
	{
		#All other files (with the wrong extension) will be left untouched.
		print STDERR "[TagUnlabeledDataDirectory] Skipping file: $file\n";
	}
}
close DIR;
exit;
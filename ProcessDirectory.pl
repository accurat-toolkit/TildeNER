#!/usr/bin/perl
#===========File: ProcessDirectory.pl===========
#Title:        ProcessDirectory.pl - Execute a Process on a Directory
#Description:  Executes a process on each file on a directory. Input and output directories, file extensions and additional process attributes have to be specified.
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 04.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================

use strict;
use warnings;
use Encode;
use File::Basename;
use encoding "UTF-8";

if (not(defined($ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2])&&defined($ARGV[3])&&defined($ARGV[4]))) # Cheking if all parematers exist.
{ 
	print "usage: perl ProcessDirectory.pl [ARGS]\nARGS:\n\t1. [Input directory] - directory from which to read files.\n\t2. [Output directory] - directory to which the process will write files.\n\t3. [Input extension] - extension of the input files.\n\t4. [Output extension] - extension of the output files.\n\t5. [Process] - the process to run (with before input file parameters)\n\t6. [Middle par.] - parameters between input and output files (optional).\n\t7. [End par.] - parameters after the output file (optional).\n"; die;
}

my $inputDir = $ARGV[0];
$inputDir =~ s/\\/\//g;
if ($inputDir !~ /.*\/$/)
{
	$inputDir = $inputDir."/";
}
my $outputDir = $ARGV[1];
$outputDir =~ s/\\/\//g;
if ($outputDir !~ /.*\/$/)
{
	$outputDir = $outputDir."/";
}
my $programToRun = $ARGV[4]; #With arguments if such exist before IN and OUT files (which have to be the last two arguments)!
my $inExt = $ARGV[2]; #Has to be without punctuation!
my $outExt = $ARGV[3]; #Has to be without punctuation!
my $middleParams = "";

#If the 6th argument is given, middle parameters are added.
if ( defined $ARGV[5])
{
	$middleParams = $ARGV[5];
}
my $endParams = "";
#If the 7th argument is given, end parameters are added.
if (defined $ARGV[6])
{
	$endParams = $ARGV[6];
}

binmode STDOUT, ":utf8";

print STDERR "[ProcessDirectory] Starting to process directory: $inputDir\n";

#For each file in the directory execute the specified process.
opendir(DIR, $inputDir) or die "[ProcessDirectory] Can't open directory \"$inputDir\": $!";
while (defined(my $file = readdir(DIR)))
{
	my $inFile = $inputDir.$file;
	#Only use valid files with the correct extension and that it is not a directory!
	my $ucFile = uc($file);
	my $ucExt = uc($inExt);
	if ($ucFile =~ /.*\.$ucExt$/ && not(-d $inFile))
	{
		print STDERR "[ProcessDirectory] Processing file: $file\n";
		my $outFile = $file;
		my ($inputFileName,$inputFilePath,$inputFileSuffix) = fileparse($inFile,qr/\.[^.]*/);
		my $outFile = $outputDir.$inputFileName.".".$outExt;
		print STDERR "[ProcessDirectory] Executing: $programToRun \"$inFile\" $middleParams \"$outFile\" $endParams\n\n";
		
		#Execute the specified process and print results to STDOUT.
		my $res = `$programToRun "$inFile" $middleParams "$outFile" $endParams`;
		print $res;
	}
	else
	{
		#All other files (with the wrong extension) will be left untouched.
		print STDERR "[ProcessDirectory] Skipping file: $file\n";
	}
}
exit;
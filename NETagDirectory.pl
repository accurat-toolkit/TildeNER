#!/usr/bin/perl
#============File: NETagDirectory.pl============
#Title:        NETagDirectory.pl - Tag a Directory for Named Entities
#Description:  Tags a directory containing preprocessed data (in the format of PrepareNEData.pl resultfiles) and optionally evaluates results if a 6th parameter is specified.
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 20.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================

use strict;
use warnings;
use Encode;
use encoding "UTF-8";
use File::Basename;

BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Adds the path of this file to places where Perl is searching for modules.
}
$Bin =~ s/\\/\//g;

use NERefinements;

if (not((defined$ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2])&&defined($ARGV[3])&&defined($ARGV[4])&&defined($ARGV[5]))) #Cheking if all required parematers exist.
{ 
	print "usage: perl NETagDirectory.pl [ARGS]\nARGS:\n\t1. [NE model path] - path to the NE model.\n\t2. [Input directory] - directory from which to read files\n\t\t(without slash ending!).\n\t3. [Output directory] - directory to which the NE tagged files\n\t\twill be written (without slash ending!).\n\t4. [Input extension] - extension of the input files.\n\t5. [Output extension] - extension of the output files.\n\t6. [Property file] - path to the NE tagging properties file.\n\t7. [Evaluation file] - evaluation file path (optional and\n\t\tonly if test data is passed! May be empty if the 8th parameter is needed).\n\t8. [Refinement order definition string] - defines the order,\n\t\tin which refinements are executed on NE tagged data.\n"; die;
}

my $modelPath = $ARGV[0]; #Full path to a Stanford NER model.
$modelPath =~ s/\\/\//g;
my $inputDir = $ARGV[1];
$inputDir =~ s/\\/\//g;
if ($inputDir !~ /.*\/$/)
{
	$inputDir .= "/";
}
my $outputDir = $ARGV[2];
$outputDir =~ s/\\/\//g;
if ($outputDir !~ /.*\/$/)
{
	$outputDir .= "/";
}
my $outputRawDir = $outputDir."ne_temp/";
unless(-d $outputDir){mkdir $outputDir or die "[NETagDirectory] Cannot find nor create output directory \"$outputDir\".";}
unless(-d $outputRawDir){mkdir $outputRawDir or die "[NETagDirectory] Cannot find nor create output temporary directory \"$outputRawDir\".";}
my $inExt = $ARGV[3]; #Has to be without punctuation!
my $outExt = $ARGV[4]; #Has to be without punctuation!
my $propFile = $ARGV[5]; #Full path to a property file.
$propFile =~ s/\\/\//g;
my $evalFile = "";

print STDERR "[NETagDirectory] Starting to Tag NE's and Evaluate results on directory: $inputDir\n";
#Execute the Stanford NER on all files in the specified directory.
my $process = "java -cp \\\"$Bin/stanford-ner.jar\\\" edu.stanford.nlp.ie.crf.CRFClassifier -prop \\\"$propFile\\\" -loadClassifier \\\"$modelPath\\\" -testFile";
my $middleParams = "-resultFile";
my $res = `perl "$Bin/ProcessDirectory.pl" "$inputDir" "$outputRawDir" $inExt $outExt "$process" $middleParams`;
print $res;

if (defined($ARGV[6]) && $ARGV[6] ne "") #If an evaluation file is specified, the data is evaluated after NE tagging!
{
	$evalFile = $ARGV[6];
	$evalFile =~ s/\\/\//g;
	my $rawEvalFile = $evalFile."_raw";
	#Evaluating the results (comparison of input and output data on a directory).
	print STDERR "[NETagDirectory] Starting to evaluate raw results on directories:\n\tGold: $inputDir\n\tTest results: $outputRawDir\n";
	my $res = `perl "$Bin/NEEvaluation_v2.pl" "$inputDir" "$outputRawDir" "$rawEvalFile"`;
	print $res;
}

#For all files in the tagged directory perform refinements.
opendir(DIR, $outputRawDir) or die "[NETagDirectory] Can't open directory \"$outputRawDir\": $!";
while (defined(my $file = readdir(DIR)))
{
	my $ucFile = uc($file);
	my $ucExt = uc($outExt);
	#Only use valid files with the correct extension!
	if ($ucFile =~ /.*\.$ucExt$/)
	{
		print STDERR "[NETagDirectory] Refining file: $file\n";
		my $outFile = $file;
		my ($outputFileName,$outputFilePath,$outputFileSuffix) = fileparse($outFile,qr/\.[^.]*/);
		my $inFile = $outputRawDir.$file;
		my $posTaggedFile = $inputDir.$outputFileName.".".$inExt;
		if (!(-e $posTaggedFile))
		{
			die "[NETagDirectory] ERROR: POS tagged file $posTaggedFile cannot be found.";
		}
		$outFile = $outputDir.$outFile;
		if (defined($ARGV[7])&& $ARGV[7] ne "")
		{
			NERefinements::CombinedRefsOnFile($inFile,$outFile,$posTaggedFile, $ARGV[7]);
		}
		else
		{
			NERefinements::CombinedRefsOnFile($inFile,$outFile,$posTaggedFile);
		}
	}
	else
	{
		#All other files (with the wrong extension) will be left untouched.
		print STDERR "[NETagDirectory] Skipping file: $file\n";
	}
}

if (defined($ARGV[6]) && $ARGV[6] ne "") #If an evaluation file is specified, the data is evaluated also after NE refinements!
{
	#Evaluating the results (comparison of input and output data on a directory).
	print STDERR "[NETagDirectory] Starting to evaluate raw results on directories:\n\tGold: $inputDir\n\tTest results: $outputDir\n";
	my $res = `perl "$Bin/NEEvaluation_v2.pl" "$inputDir" "$outputDir" "$evalFile"`;
	print $res;
}

exit;

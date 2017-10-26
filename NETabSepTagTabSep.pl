#!/usr/bin/perl
#==========File: NETabSepTagTabSep.pl===========
#Title:        NETabSepTagTabSep.pl - Named Entity Tab Separated document Tagger (the result file is also tab separated and tokenized).
#Description:  Tags a UTF-8 encoded tab separated document for named entities and returns results in a tokenized and tab separated format.
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 20.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================

use strict;
use warnings;
use File::Basename;
use File::Path;
use Encode;
use encoding "UTF-8";

BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Adds the path of this file to places where Perl is searching for modules.
}
$Bin =~ s/\\/\//g;

#Include toolkit modules for data preprocessing and postprocessing.
use NEPreprocess;
use NERefinements;

if (not(defined($ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2])&&defined($ARGV[3]))) # Cheking if required parematers exist.
{ 
	print "usage: perl NETabSepTagTabSep.pl [ARGS]\nARGS:\n\t1. [NE model path] - path to the NE model.\n\t2. [Input file] - file to NE tag.\n\t3. [Output file] - file where results will be written.\n\t4. [Property file] - NE tagging property file.\n\t5. [Keep temp files] - if \"1\" temp files will be kept (optional)!\n\t6. [Refinement order definition string] - defines the order, in which refinements are executed on NE tagged data.\n"; die;
}

my $modelPath = $ARGV[0]; #Full path to a NE tagging model (Stanford NER model).
$modelPath =~ s/\\/\//g;
my $inputFile = $ARGV[1]; #The input tab separated document.
$inputFile =~ s/\\/\//g;
my $outputFile = $ARGV[2]; #The output text with tab separated mark-up.
$outputFile =~ s/\\/\//g;
my $propFile = $ARGV[3]; #The NE tagging property file for the Stanford NE classifier.
$propFile =~ s/\\/\//g;
print STDERR "[NETabSepTagTabSep] Starting to process tab separated document in \"$inputFile\"\n";
my $refDefString = ""; #Refinement order definition string.
if (defined($ARGV[5]))
{
	$refDefString = $ARGV[5];
}

#Split output file to get the directory, file name and extension separated.
my ($outputFileName,$outputFilePath,$outputFileSuffix) = fileparse($outputFile,qr/\.[^.]*/);
my ($inputFileName,$inputFilePath,$inputFileSuffix) = fileparse($inputFile,qr/\.[^.]*/);
#Create the temp file directory if non-existing.
unless(-d  $outputFilePath."data/"){mkdir  $outputFilePath."data/" or die "[NETabSepTagTabSep] Cannot find nor create output directory \"$outputFilePath"."data\".";}
my $tempFile = $outputFilePath."data/".$outputFileName.".temp";
my $posNeTaggedFile = $outputFilePath."data/".$outputFileName.".pos_ne";
my $workingDir = $outputFilePath."data/";
#Removes all single empty lines (two or more subsequent empty lines are kept).
NEPreprocess::RemoveEmptyLines($inputFile, $tempFile, "2");

#Check whether the POS tagging was successful.
if (-e $tempFile)
{
	#Tag the POS tagged text for named entities.
	print STDERR "[NETabSepTagPlaintext] Starting to Tag NE's using the module \"$modelPath\" and the property file \"$propFile\". The results will be saved in \"$posNeTaggedFile\"\n";
	my $res = `java -Xms32m -Xmx1300m  -cp "$Bin/stanford-ner.jar" edu.stanford.nlp.ie.crf.CRFClassifier -prop "$propFile" -loadClassifier "$modelPath" -testFile "$tempFile" -resultFile "$posNeTaggedFile"`;
	print $res;
	#Check if NE tagging was successful.
	if (-e $posNeTaggedFile)
	{
		#As the NE tagging removes all empty lines, these have to be added back after NE tagging according to the POS tagged data file.
		print STDERR "[NETabSepTagPlaintext] Starting to postprocess NE tagged file \"$posNeTaggedFile\" and the POS tagged file \"$inputFile\". The results will be saved in \"$outputFile\"\n";
		NERefinements::CombinedRefsOnFile( $posNeTaggedFile, $outputFile, $inputFile, $refDefString);
		if (!(-e $outputFile))
		{
			print STDERR "[NEMuc7TagPlaintext] NE Markup (\"$posNeTaggedFile\") finalization with the POS tagged file (\"$tempFile\") failed! File \"$outputFile\" is missing.\n";
		}
		#Delete the NE tagged temp file if not explicitly required to keep it.
		if (!defined($ARGV[4]) || $ARGV[4] ne "1"){ unlink($posNeTaggedFile); }
	}
	else
	{
		print STDERR "[NETabSepTagPlaintext] NE tagging of \"$tempFile\" failed! File \"$posNeTaggedFile\" is missing.\n";
	}
	#Delete the POS tagged tab separated file if not explicitly required to keep it.
	if (!defined($ARGV[4]) || $ARGV[4] ne "1"){ unlink($tempFile); }
}
else
{
	print STDERR "[NETabSepTagPlaintext] Removal of empty lines in file \"$inputFile\" failed! File \"$tempFile\" is missing.\n";
}
if (!defined($ARGV[4]) || $ARGV[4] ne "1"){ rmtree([$workingDir]); }
exit;
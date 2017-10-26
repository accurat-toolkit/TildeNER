#!/usr/bin/perl
#=========File: NETabSepTagPlaintext.pl=========
#Title:        NETabSepTagPlaintext.pl - Named Entity Plaintext Tagger (the result file is tab separated and tokenized).
#Description:  Tags a UTF-8 encoded plaintext document for named entities and returns results in a tokenized and tab separated format.
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

#Include toolkit modules for data preprocessing.
use Tag;
use NERefinements;

if (not(defined($ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2])&&defined($ARGV[3])&&defined($ARGV[4])&&defined($ARGV[5]))) # Cheking if required parematers exist.
{ 
	print "usage: perl NETabSepTagPlaintext.pl [ARGS]\nARGS:\n\t1. [NE model path] - path to the NE model.\n\t2. [Input file] - file to NE tag.\n\t3. [Output file] - file where results will be written.\n\t\tTab separated file with NE, POS tags and corresponding lemmas.\n\t4. [Property file] - NE tagging property file.\n\t5. [Language] - POS tagger language.\n\t6. [POS tagger code] - The POS tagger to use.\n\t\tPossible values:\n\t\t\t\"Tree\" for bg, de, el, en, es, et, fr and it.\n\t\t\t\"Tagger\" for et, lt and lv.\n\t7. [Keep temp files] - if \"1\" temp files will be kept (optional)!\n\t8. [Refinement order definition string] - defines the order, in which refinements are executed on NE tagged data.\n"; die;
}

my $modelPath = $ARGV[0]; #Full path to a NE tagging model (Stanford NER model).
$modelPath =~ s/\\/\//g;
my $inputFile = $ARGV[1]; #The input plaintext.
$inputFile =~ s/\\/\//g;
my $outputFile = $ARGV[2]; #The output text with tab separated mark-up.
$outputFile =~ s/\\/\//g;
my $propFile = $ARGV[3]; #The NE tagging property file for the Stanford NE classifier.
$propFile =~ s/\\/\//g;
my $PosTaggerLang = $ARGV[4]; #POS tagger language ("bg", "de", "el", "en", "es", "et", "fr", "it", "lt" or "lv").
my $POSTaggerCode = $ARGV[5]; #The POS tagger to use ("POS" for lv,lt and et - won't be included in the toolkit; "Tree" for bg, de, el, en, es, et, fr and it; "Tagger" for et, lt and lv (the same results as for POS)).
my $refDefString = ""; #Refinement order definition string.
if (defined($ARGV[7]))
{
	$refDefString = $ARGV[7];
}
print STDERR "[NETabSepTagPlaintext] Starting to process plaintext in \"$inputFile\"\n";

#Split output file to get the directory, file name and extension separated.
my ($outputFileName,$outputFilePath,$outputFileSuffix) = fileparse($outputFile,qr/\.[^.]*/);
my ($inputFileName,$inputFilePath,$inputFileSuffix) = fileparse($inputFile,qr/\.[^.]*/);
#Create the temp file directory if non-existing.
unless(-d  $outputFilePath."data/"){mkdir  $outputFilePath."data/" or die "[NETabSepTagPlaintext] Cannot find nor create output directory \"$outputFilePath"."data\".";}
my $posTaggedTempFile = $outputFilePath."data/".$inputFileName.".temp";
my $tokenizedTempFile = $outputFilePath."data/".$inputFileName.".tokenized";
my $posTaggedFile = $outputFilePath."data/".$outputFileName.".pos";
my $posTaggedFile2 = $outputFilePath."data/".$outputFileName.".pos2"; #has removed empty lines within one directory.
my $posNeTaggedFile = $outputFilePath."data/".$outputFileName.".pos_ne";
#POS tag the plaintext according to the specified tagger and language. Deletes temporary files (the parameter at the end) created in the process if the 7th argument will be equal to "1".
print STDERR "[NETabSepTagPlaintext] POS tagging with the tagger \"$POSTaggerCode\" and language \"$PosTaggerLang\". The output will be saved in \"$posTaggedFile\".\n";

Tag::TagText($PosTaggerLang, $POSTaggerCode, $inputFile, $posTaggedFile, "", "2");

#Check whether the POS tagging was successful.
if (-e $posTaggedFile)
{
	#Tag the POS tagged text for named entities.
	print STDERR "[NETabSepTagPlaintext] Starting to Tag NE's using the module \"$modelPath\" and the property file \"$propFile\". The results will be saved in \"$posNeTaggedFile\"\n";
	my $res = `java -Xms32m -Xmx1300m -cp "$Bin/stanford-ner.jar" edu.stanford.nlp.ie.crf.CRFClassifier -prop "$propFile" -loadClassifier "$modelPath" -testFile "$posTaggedFile" -resultFile "$posNeTaggedFile"`;
	print $res;
	#Check if NE tagging was successful.
	if (-e $posNeTaggedFile)
	{
		#As the NE tagging removes all empty lines, these have to be added back after NE tagging according to the POS tagged data file.
		print STDERR "[NETabSepTagPlaintext] Starting to postprocess NE tagged file \"$posNeTaggedFile\" and the POS tagged file \"$posTaggedTempFile\". The results will be saved in \"$outputFile\"\n";
		NERefinements::CombinedRefsOnFile( $posNeTaggedFile, $outputFile,$posTaggedTempFile, $refDefString);
		if (!(-e $outputFile))
		{
			print STDERR "[NEMuc7TagPlaintext] NE Markup (\"$posNeTaggedFile\") finalization with the POS tagged file (\"$posTaggedFile\") failed! File \"$outputFile\" is missing.\n";
		}
		#Delete the NE tagged temp file if not explicitly required to keep it.
		if (!defined($ARGV[6]) || $ARGV[6] ne "1"){ unlink($posNeTaggedFile); }
	}
	else
	{
		print STDERR "[NETabSepTagPlaintext] NE tagging of \"$posTaggedFile\" failed! File \"$posNeTaggedFile\" is missing.\n";
	}
	#Delete the POS tagged tab separated file if not explicitly required to keep it.
	if (!defined($ARGV[6]) || $ARGV[6] ne "1"){ unlink($posTaggedFile); }
}
else
{
	print STDERR "[NETabSepTagPlaintext] POS tagging of \"$inputFile\" failed! File \"$posTaggedFile\" is missing.\n";
}
#If not explicitly defined, POS Tagging temp files are deleted.
if (!defined($ARGV[6]) || $ARGV[6] ne "1")
{
	rmtree([$outputFilePath."data/"]);
}
exit;
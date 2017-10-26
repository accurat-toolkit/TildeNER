#!/usr/bin/perl
#======File: NEMuc7TagPlaintextList.pl.pl=======
#Title:        NEMuc7TagPlaintextList.pl - Named Entity Plaintext File Tagger (the result files are in a plaintext format marked with MUC-7 NE tags).
#Description:  Tags a UTF-8 encoded plaintext documents from a list file for named entities and adds MUC-7 named entity tags within the plaintext documents.
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      12.08.2011.
#Last Changes: 12.08.2011. by Mārcis Pinnis, SIA Tilde.
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
	push @INC, "$Bin";  #Adds the path to places whre Perl is searching for modules.
}
$Bin =~ s/\\/\//g;

if (not(defined($ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2])&&defined($ARGV[3])&&defined($ARGV[4]))) # Cheking if required parematers exist.
{ 
	print "usage: perl NEMuc7TagPlaintextList.pl [ARGS]\nARGS:\n\t1. [NE model path] - path to the NE model.\n\t2. [File Pair List] - file path to the file pair list.\n\t3. [Property file] - NE tagging property file.\n\t4. [Language] - POS tagger language.\n\t5. [POS tagger code] - The POS tagger to use.\n\t\tPossible values:\n\t\t\t\"Tree\" for bg, de, el, en, es, et, fr and it.\n\t\t\t\"Tagger\" for et, lt and lv.\n\t6. [Refinement order definition string] - defines the order, in which refinements are executed on NE tagged data.\n"; die;
}

my $modelPath = $ARGV[0]; #Full path to a NE tagging model (Stanford NER model).
$modelPath =~ s/\\/\//g;
my $inputFileList = $ARGV[1]; #The input plaintext file list (one pair contains input and output files - tab separated).
$inputFileList =~ s/\\/\//g;
my $propFile = $ARGV[2]; #The NE tagging property file for the Stanford NE classifier.
$propFile =~ s/\\/\//g;
my $PosTaggerLang = $ARGV[3]; #POS tagger language ("bg", "de", "el", "en", "es", "et", "fr", "it", "lt" or "lv").
my $POSTaggerCode = $ARGV[4]; #The POS tagger to use ("POS" for lv,lt and et - won't be included in the toolkit; "Tree" for bg, de, el, en, es, et, fr and it; "Tagger" for et, lt and lv (the same results as for POS)).
my $refDefString = ""; #Refinement order definition string.
if (defined($ARGV[5]))
{
	$refDefString = $ARGV[5];
}
if (-e $inputFileList)
{
	print STDERR "[NEMuc7TagPlaintextList] Starting to process plaintext documents from \"$inputFileList\"\n";
	open(INFILE, "<:encoding(UTF-8)", $inputFileList);
	while (<INFILE>)
	{
		my $line = $_;
		$line =~ s/^\x{FEFF}//; # cuts BOM
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		if ($line ne "" && $line !~ /#.*/)
		{
			my ($sourceFile, $targetFile) = split(/\t/, $line, 2);
			$sourceFile =~ s/^\s+//;
			$sourceFile =~ s/\s+$//;
			$targetFile =~ s/^\s+//;
			$targetFile =~ s/\s+$//;
			if (defined ($sourceFile) && defined ($targetFile))
			{
				my $res = `perl "$Bin/NEMuc7TagPlaintext.pl" "$modelPath" "$sourceFile" "$targetFile" "$propFile" $PosTaggerLang $POSTaggerCode "" "$refDefString"`;
				print $res;
			}
		}
	}
}
else
{
	print STDERR "[NEMuc7TagPlaintextList] File \"$inputFileList\" is missing. NE-tagging aborted.\n";
}
close INFILE;

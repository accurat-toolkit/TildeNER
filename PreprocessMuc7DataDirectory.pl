#!/usr/bin/perl
#======File: PreprocessMuc7DataDirectory.pl=====
#Title:        PreprocessMuc7DataDirectory.pl - Preprocess MUC-7 Annotated Plaintext Documents for NE Training and Testing.
#Description:  POS tags MUC-7 annotated plaintext documents and produces output data in a tokenized tab separated format including NE tags.
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 04.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================

use strict;
use warnings;
use Encode;
use encoding "UTF-8";
binmode STDOUT, ":utf8";

BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
}
$Bin =~ s/\\/\//g;

if (not(defined($ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2])&&defined($ARGV[3])&&defined($ARGV[4])&&defined($ARGV[5]))) #Cheking if all required parematers exist.
{
	print "usage: perl PreprocessMuc7DataDirectory.pl [ARGS]\nARGS:\n\t1. [Input directory] - directory from which to read files.\n\t2. [Output directory] - directory to which the preprocessed files\n\t\twill be written.\n\t3. [Input extension] - extension of the input files.\n\t4. [Output extension] - extension of the output files.\n\t5. [Language] - et, lt, lv or other supported language.\n\t6. [Tagger] - POS tagger to use for processing.\n\t\tFor \"et\",\"lt\" and \"lv\" use \"Tagger\" (or \"POS\" if available).\n\t\tFor \"bg\", \"de\", \"el\", \"en\", \"es\", \"et\", \"fr\" and \"it\" use \"Tree\".\n"; die;
}

my $inputDir = $ARGV[0]; #Without slash ending.
$inputDir =~ s/\\/\//g;
my $outputDir = $ARGV[1]; #Without slash ending.
$outputDir =~ s/\\/\//g;
unless(-d $outputDir){mkdir $outputDir or die "[PreprocessMuc7DataDirectory] Cannot find nor create output directory \"$outputDir\".";}
my $inExt = $ARGV[2]; #has to be without punctuation!
my $outExt = $ARGV[3]; #has to be without punctuation!
$outExt = lc ($outExt);
my $lang = $ARGV[4]; #The language (lv, lt, et - supported by tagger.exe/tagger.sh; other languages supported with treetagger)
my $tagger = $ARGV[5]; #the tagger, with which to tag data "Tagger" (Tilde's external POS tagger), "Tree" (Treetagger) and "POS" (Tilde's internal POS tagger).

print STDERR "[PreprocessMuc7DataDirectory] Starting to Tag NE's and Evaluate results on directory: $inputDir\n";

#Call the directory processing script to preprocess all files from the specified input directory.
my $process = "perl \\\"$Bin/PrepareNEData.pl\\\" $lang $tagger";
my $res = `perl "$Bin/ProcessDirectory.pl" "$inputDir" "$outputDir" $inExt $outExt "$process" "" "-D"`;
print $res;
exit;
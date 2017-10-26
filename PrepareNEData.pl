#!/usr/bin/perl
#===========File: PrepareNEData.pl===============
#Title:        PrepareNEData.pl - Preprocess MUC-7 Annotated Plaintext Document for NE Training and Testing.
#Description:  POS tags MUC-7 annotated plaintext documents and produces output data in a tokenized tab separated format including NE tags.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 20.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
use strict;
use warnings;


 BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Add this path to places where perl is searching for modules.
}
#Checking if all required parameters are set.
if (not(defined($ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2])&&defined($ARGV[3])))
{ 
	print STDERR  "usage perl PrepareNEData.pl [ARGS]\nARGS:\n\t1. [Language] - The tagger language (en|lv|et..).\n\t2. [POS Tagger] - The POS tagger to use (POS|Tree|Tagger).\n\t3. [Input File] - the path to the input file.\n\t4. [Output File] - The path to the output file\n\t5. [Delete temp files] - \"-D\" to delete temporary files (optional).\n";
	die;
}


my $FullIputfilename = $ARGV[2];

#Gets the location where to print temporary files.
my	$outputDir = $ARGV[3]; 
if ($outputDir =~ /[\\\/]/)
{
	$outputDir =~ s/\\/\//gi;
	$outputDir =~ s/\/[^\/]+$//g;
	$outputDir .= "\/data\/";
}
else
{
$outputDir = "data\/";
}
#Creates temp data directory if it does not exist.
unless(-d $outputDir){mkdir $outputDir or die "Cannot find nor create output directory \"$outputDir\".";}

use NEPreprocess;
 
my $Iputfilename = $FullIputfilename;
$Iputfilename=~ s/(.*)(\.[^\.]+$)/$1/g;
$Iputfilename=~ s/\\/\//gi;
$Iputfilename=~ s/.*\/([^\/]+)/$1/g;

my $del =0;	

if(defined ($ARGV[4]) && $ARGV[4] eq "-D") #Deletes the created temp files if option selected.
{ 
	$del=1;
}
NEPreprocess::Detagger( "$FullIputfilename", "$outputDir$Iputfilename.plain", "$outputDir$Iputfilename.tags",); #Splitting tags and plaintext.

use Tag;

my $pie;
Tag::TagText($ARGV[0],$ARGV[1], "$outputDir$Iputfilename.plain", "$outputDir$Iputfilename.POS",$del,2); #Tags text.

NEPreprocess::AddNewTags( "$outputDir$Iputfilename.POS", "$outputDir$Iputfilename.tags" , "$ARGV[3]", "1" ); #Adds NE tags.


#Deletes the temporary files and folder if required.
if($del)
{

	 unlink ("$outputDir$Iputfilename.plain");
	 unlink ("$outputDir$Iputfilename.taggs");
	 unlink ("$outputDir$Iputfilename.POS");
	 unlink ("$outputDir$Iputfilename.tags");
	 rmdir ("$outputDir");
}





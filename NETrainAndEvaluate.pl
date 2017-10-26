#!/usr/bin/perl
#==========File: NETrainAndEvaluate.pl==========
#Title:        NETrainAndEvaluate.pl - Named Entity Training and Evaluation.
#Description:  Trains a Stanford NER model on training directory data and evaluates the model on train and test directory data (separately).
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 27.05.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================

use strict;
use warnings;
use File::Basename;
use File::Copy;
use Encode;
use encoding "UTF-8";


BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Adds the path of this file to places where Perl is searching for modules.
}
$Bin =~ s/\\/\//g;

#Include toolkit modules for data preprocessing.
use NEUtilities;


if (not((defined$ARGV[0])&&defined($ARGV[1])&&defined($ARGV[2])&&defined($ARGV[3])&&defined($ARGV[4])&&defined($ARGV[5])&&defined($ARGV[6])&&defined($ARGV[7])&&defined($ARGV[8])&&defined($ARGV[9]))) # Cheking if all required parematers exist.
{ 
	print "usage: perl NETrainAndEvaluate.pl [ARGS]\nARGS:\n\t1. [Training data directory] - path to the training data.\n\t2. [Testing data directory] - path to the testng data.\n\t3. [Development data directory] - path to the development data.\n\t4. [Training file extension] - extension of the training files.\n\t5. [Testing file extension] - Extension of the testing files.\n\t6. [Development file extension] - Extension of the development files.\n\t7. [Working directory path] - Path to the initial working directory.\n\t8. [Training property template] - Template of the training properties (without file lists).\n\t9. [Testing property template] - Template of the testing properties (without file lists).\n\t10. [Refinement order definition string] - defines the order, in which refinements are executed on NE tagged data.\n"; die;
}

my $trainDataDirectory = $ARGV[0]; #Path to the training data directory.
$trainDataDirectory =~ s/\\/\//g;
my $testDataDirectory = $ARGV[1]; #Path to the test data directory.
$testDataDirectory =~ s/\\/\//g;
my $developmentDataDirectory = $ARGV[2]; #Path to the development data directory.
$developmentDataDirectory =~ s/\\/\//g;
my $trainFileExtension = $ARGV[3]; #The training file extension.
my $testFileExtension = $ARGV[4]; #The test file extension.
my $developmentFileExtension = $ARGV[5]; #The development file extension.
my $workingDirectory = $ARGV[6]; #Path to the working directory. Should be as precise as possible as only fixed name data directories will be created within!!!
$workingDirectory =~ s/\\/\//g;
if ($workingDirectory !~ /.*\/$/)
{
	$workingDirectory .= "/";
}
my $trainingPropertyTemplate = $ARGV[7]; #Full path to the training Stanford NER property template
my $testingPropertyTemplate = $ARGV[8]; #Full path to the testing Stanford NER property template.
my $refDefString = $ARGV[9]; #Refinement order definition string

#Check if property templates exist and copy them to the working directory.
if (!(-e $trainingPropertyTemplate))
{
	print STDERR "[NETrainAndEvaluate] ERROR: Missing training property file template $trainingPropertyTemplate.";
	die;
}
if (!(-e $testingPropertyTemplate))
{
	print STDERR "[NETrainAndEvaluate] ERROR: Missing training property file template $testingPropertyTemplate.";
	die;
}
#Also check whether the working directory exists.
unless(-d  $workingDirectory){mkdir  $workingDirectory or die "[NETrainAndEvaluate] Cannot find nor create output directory \"$workingDirectory\".";}

#Make a copy of the property templates.
my $trainPropFile = $workingDirectory."train.prop";
my $testPropFile = $workingDirectory."test.prop";
copy($trainingPropertyTemplate,$trainPropFile) or die "[NETrainAndEvaluate] Failed to copy the training property file: $!";
copy($testingPropertyTemplate,$testPropFile) or die "[NETrainAndEvaluate] Failed to copy the testing property file: $!";

#Get the training file list and add it to the new property file.
my $trainFileList=NEUtilities::CreateDirectoryFileList($trainDataDirectory,$trainFileExtension);
NEUtilities::AddPropertyToFile($trainPropFile,"trainFileList",$trainFileList);

#Add the model file path to the property file.
my $neModelFile = $workingDirectory."neModel.ser.gz";
NEUtilities::AddPropertyToFile($trainPropFile,"serializeTo",$neModelFile);

#Execute training:
my $res = `java -Xms32m -Xmx4096m -cp "$Bin/stanford-ner.jar" edu.stanford.nlp.ie.crf.CRFClassifier -prop "$trainPropFile"`;
print $res;

#Create tagging directories for training and test data.
#my $trainTaggingDirectory = $workingDirectory."TRAIN_TAGGED";
#unless(-d  $trainTaggingDirectory){mkdir  $trainTaggingDirectory or die "[NETrainAndEvaluate] Cannot find nor create output directory \"$trainTaggingDirectory\".";}
my $testTaggingDirectory = $workingDirectory."TEST_TAGGED";
unless(-d  $testTaggingDirectory){mkdir  $testTaggingDirectory or die "[NETrainAndEvaluate] Cannot find nor create output directory \"$testTaggingDirectory\".";}
my $developmentTaggingDirectory = $workingDirectory."DEVELOPMENT_TAGGED";
unless(-d  $developmentTaggingDirectory){mkdir  $developmentTaggingDirectory or die "[NETrainAndEvaluate] Cannot find nor create output directory \"$developmentTaggingDirectory\".";}

## COMMENTED OUT BY: Mārcis Pinnis;
## REASON: not important. The results will always be over 99% (if decent data is provided).
#Execute tagging of train data on the new model and evaluate results:
#my $trainEvalFile = $workingDirectory."train.eval";
#$res = `perl NETagDirectory.pl "$neModelFile" "$trainDataDirectory" "$trainTaggingDirectory" "$trainFileExtension" "tagged"  "$testPropFile" "$trainEvalFile" "$refDefString"`;
#print $res;

#Execute tagging of test data on the new model and evaluate results:
my $testEvalFile = $workingDirectory."test.eval";
$res = `perl NETagDirectory.pl "$neModelFile" "$testDataDirectory" "$testTaggingDirectory" "$testFileExtension" "tagged"  "$testPropFile" "$testEvalFile" "$refDefString"`;

#Execute tagging of development data on the new model and evaluate results:
my $developmentEvalFile = $workingDirectory."devel.eval";
$res = `perl NETagDirectory.pl "$neModelFile" "$developmentDataDirectory" "$developmentTaggingDirectory" "$developmentFileExtension" "tagged"  "$testPropFile" "$developmentEvalFile" "$refDefString"`;
print $res;

exit;
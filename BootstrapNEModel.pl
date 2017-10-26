#!/usr/bin/perl
#===========File: BootstrapNEModel.pl===========
#Title:        BootstrapNEModel.pl - Bootstrap Named Entity Model.
#Description:  Trains an NE model using bootstrapping with a seed list and a large unannotated data corpus.
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      June, 2011.
#Last Changes: 04.07.2011. by Mārcis Pinnis, SIA Tilde.
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
use BootstrapTools;
use NEUtilities;


if (not(defined($ARGV[0])
	&& defined($ARGV[1])
	&& defined($ARGV[2])
	&& defined($ARGV[3])
	&& defined($ARGV[4])
	&& defined($ARGV[5])
	&& defined($ARGV[6])
	&& defined($ARGV[7])
	&& defined($ARGV[8])
	&& defined($ARGV[9])
	&& defined($ARGV[10])
	&& defined($ARGV[11])
	&& defined($ARGV[12])
	&& defined($ARGV[13])
	&& defined($ARGV[14]))) # Cheking if required parematers exist.
{ 
	print "usage: perl BootstrapNEModel.pl [ARGS]\nARGS:\n\t"
		."1. [Seed List Directory] - Seed list directory path.\n\t"
		."2. [Seed File Extension] - Seed list data file extension.\n\t"
		."3. [Development List Directory] - Development data directory path.\n\t"
		."4. [Development File Extension] - Development list data file extension.\n\t"
		."5. [Test List Directory] - Test data directory path.\n\t"
		."6. [Test File Extension] - Test list data file extension.\n\t"
		."7. [Unlabeled Data Directory] - Unlabeled data directory path.\n\t"
		."8. [Unlabeled File Extension] - Unlabeled list data file extension.\n\t"
		."9. [Training Property File] - The path of the training property file.\n\t"
		."10. [Testing Property File] - The path of the testing property file.\n\t"
		."11. [Working Directory] - Directory where all results of all iterations will be stored.\n\t"
		."12. [Number of Iterations] - Bootstrapping iteration amount.\n\t"
		."13. [Max Docs] - The number of unlabeled documents to be tagged and processed during bootstrapping.\n\t"
		."14. [Docs per Tag] - The number of documents to select for training in a single iteration for each NE Tag.\n\t"
		."15. [Refinement order definition string] - defines the order, in which refinements are executed on NE tagged data.\n\t"
		."16. [Bootstrapped gazetteer file] - address of the gazetteer file for extracted named entity samples.\n\t"
		."17. [Use only positive iterations] - \"1\" if only positive iterations should be kept.\n\t"
		."18. [Positive iterator condition] - \"P\" for precision, \"R\" for recall, \"F\" for F-measure and \"A\" for accuracy, everything else means that all values will be taken into account.\n"; die;
}
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Starting to read input parameters.\n";
my $SeedListDirectory = $ARGV[0]; #Seed list directory path.
$SeedListDirectory =~ s/\\/\//g;
if ($SeedListDirectory !~ /.*\/$/)
{
	$SeedListDirectory .= "/";
}
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Seed list directory: $SeedListDirectory\n";
unless(-d  $SeedListDirectory){die "[BootstrapNEModel] ".NEUtilities::GetTime()." Cannot find seed list directory \"$SeedListDirectory\".";}
my $seedExt = $ARGV[1]; #Seed list file extension.
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Seed list extension: $seedExt\n";
my $DevelopmentListDirectory = $ARGV[2]; #Development list directory path.
$DevelopmentListDirectory =~ s/\\/\//g;
if ($DevelopmentListDirectory !~ /.*\/$/)
{
	$DevelopmentListDirectory .= "/";
}
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Development list directory: $DevelopmentListDirectory\n";
unless(-d  $DevelopmentListDirectory){die "[BootstrapNEModel] ".NEUtilities::GetTime()." Cannot find development list directory \"$DevelopmentListDirectory\".";}
my $developmentExt = $ARGV[3]; #Development list file extension.
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Development list extension: $developmentExt\n";
my $TestListDirectory = $ARGV[4]; #Seed list directory path.
$TestListDirectory =~ s/\\/\//g;
if ($TestListDirectory !~ /.*\/$/)
{
	$TestListDirectory .= "/";
}
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Test list directory: $TestListDirectory\n";
unless(-d  $TestListDirectory){die "[BootstrapNEModel] ".NEUtilities::GetTime()." Cannot find test list directory \"$TestListDirectory\".";}
my $testExt = $ARGV[5]; #Test list file extension.
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Test list extension: $testExt\n";
my $UnlabeledListDirectory = $ARGV[6]; #Seed list directory path.
$UnlabeledListDirectory =~ s/\\/\//g;
if ($UnlabeledListDirectory !~ /.*\/$/)
{
	$UnlabeledListDirectory .= "/";
}
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Unlabeled list directory: $UnlabeledListDirectory\n";
unless(-d  $UnlabeledListDirectory){die "[BootstrapNEModel] ".NEUtilities::GetTime()." Cannot find unlabeled data directory \"$UnlabeledListDirectory\".";}
my $unlabeledExt = $ARGV[7]; #Test list file extension.
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Unlabeled list extension: $unlabeledExt\n";
my $trainPropTemplate = $ARGV[8]; #Stanford NER training property template.
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Training property template: $trainPropTemplate\n";
my $testPropTemplate = $ARGV[9]; #Stanford NER testing property template.
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Testing property template: $testPropTemplate\n";
my $workingDirectory = $ARGV[10]; #Working directory path.
$workingDirectory =~ s/\\/\//g;
if ($workingDirectory !~ /.*\/$/)
{
	$workingDirectory .= "/";
}
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Working directory: $workingDirectory\n";
unless(-d  $workingDirectory){mkdir  $workingDirectory or die "[BootstrapNEModel] Cannot find nor create the working directory \"$workingDirectory\".";}
my $numberOfIterations = $ARGV[11]; #Number of bootstrapping iterations.
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Number of bootstrapping iterations: $numberOfIterations\n";
my $maxUnlabeledDocs = $ARGV[12]; #Number of unlabeled documents/sentences to select in one bootstrapping iteration.
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Number of unlabeled documents to tag in an iteration: $maxUnlabeledDocs\n";
my $docsPerTag = $ARGV[13]; #Number of documents to select for the next iteration for each NE Tag.
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Number of sentences per tag: $docsPerTag\n";
my $refDefString = $ARGV[14]; #Refinement order definition string
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Refinement order definition string: $refDefString\n";
my $gazetteerListFilePath = "";
my $tempGazetteerListFilePath = "";
if (defined($ARGV[15]) && $ARGV[15] ne "")
{
	$gazetteerListFilePath = $ARGV[15];
	$tempGazetteerListFilePath = $gazetteerListFilePath.".temp";
	if (not (-e $gazetteerListFilePath))
	{
		open (OUTFILE, '>'.$gazetteerListFilePath) or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Can't open file $gazetteerListFilePath: $!";
		binmode OUTFILE, ":utf8";
		print OUTFILE "\n";
		close OUTFILE;
	}
	if (not (-e $tempGazetteerListFilePath))
	{
		open (OUTFILE, '>'.$tempGazetteerListFilePath) or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Can't open file $tempGazetteerListFilePath: $!";
		binmode OUTFILE, ":utf8";
		print OUTFILE "\n";
		close OUTFILE;
	}
	my $newTrainPropTemplate = $workingDirectory."train_with_gaz.prop";
	my $newTestPropTemplate = $workingDirectory."test_with_gaz.prop";
	copy($trainPropTemplate,$newTrainPropTemplate) or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Failed to copy the training property file: $!";
	copy($testPropTemplate,$newTestPropTemplate) or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Failed to copy the testing property file: $!";
	my $gazetteerPropStr = NEUtilities::ReadPropertyFromFile($newTrainPropTemplate, "gazette");
	if ($gazetteerPropStr ne "")
	{
		$gazetteerPropStr=$gazetteerPropStr.",".$gazetteerListFilePath.",".$tempGazetteerListFilePath;
	}
	else
	{
		$gazetteerPropStr=$gazetteerListFilePath.",".$tempGazetteerListFilePath;
	}
	NEUtilities::ChangePropertyInFile($newTrainPropTemplate,"gazette",$gazetteerPropStr);
	NEUtilities::ChangePropertyInFile($newTestPropTemplate,"gazette",$gazetteerPropStr);
	$testPropTemplate=$newTestPropTemplate;
	$trainPropTemplate=$newTrainPropTemplate;
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Gazetteer file list path: $gazetteerListFilePath\n";
}
my $useOnlyPositiveIterations = 0;
if (defined($ARGV[16])) #This has been added for reasons when Stanford NER crashes or simply hangs (goes into a seemingly indefinite loop). The user has to prepare a new seed list directory with the latest good (that trained successfully) results, delete the last iteration directory and pass the last iteration number as the new argument. One iteration will be skipped as the new training model will be evaluated, but the results will be saved. You have to make sure, though, that you make a copy of the log file ... if you redirect the STDERR output...
{
	if ($ARGV[16] eq "1")
	{
		$useOnlyPositiveIterations = 1;
	}
}
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Use only positive iterations: $useOnlyPositiveIterations\n";
my $positiveIterationCondition = "ALL";
if (defined($ARGV[17]))
{
	$positiveIterationCondition = $ARGV[17];
}


print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Positive iteration condition (if positive iteration usage is 1): $positiveIterationCondition\n";
my $iterationCounter = 0;

if (defined ($ARGV[18]))
{
	$iterationCounter = $ARGV[18];
}

my $trainExt="train";
#Set and open for writing the result file for the particular iteration.
my $globalResultsFile = $workingDirectory."results.txt";
open (RESFILE, '>>'.$globalResultsFile) or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Can't open file $globalResultsFile: $!";
binmode RESFILE, ":utf8";

my $positiveChange = 1;
my $wasNegativeResult = 0;
my $previousFMeasure = 0.0;
my $previousRecall = 0.0;
my $previousAccuracy = 0.0;
my $previousPrecision = 0.0;
my @positiveTrainDataArray;
my $previousTrainingDataFile = "";
my $previousGoodModelDirectory = "";
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Bootstrapping started.\n";
while ($iterationCounter<$numberOfIterations)
{
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Bootstrapping iteration: $iterationCounter\n";
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Preparing working directory.\n";
	##Create the iteration directory
	my $iterationDirectory = $workingDirectory."iteration_$iterationCounter/";
	unless(-d  $iterationDirectory){mkdir  $iterationDirectory or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Cannot find nor create the iteration directory \"$iterationDirectory\".";}
	##Create training, development data, model and unlabeled data directories.
	my $trainDataDirectory = $iterationDirectory."TRAIN_DATA/";
	unless(-d  $trainDataDirectory){mkdir  $trainDataDirectory or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Cannot find nor create the iteration training data directory \"$trainDataDirectory\".";}
	my $newTrainDataDirectory = $iterationDirectory."NEW_TRAIN_DATA/";
	unless(-d  $newTrainDataDirectory){mkdir  $newTrainDataDirectory or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Cannot find nor create the iteration new training data directory \"$newTrainDataDirectory\".";}
	my $modelDirectory = $iterationDirectory."CLASSIFIER_MODEL/";
	unless(-d  $modelDirectory){mkdir  $modelDirectory or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Cannot find nor create the iteration model directory \"$modelDirectory\".";}
	my $unlabeledDataDirectory = $iterationDirectory."SELECTED_UNLABELED_DATA/";
	unless(-d  $unlabeledDataDirectory){mkdir  $unlabeledDataDirectory or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Cannot find nor create the unlabeled data iteration directory \"$unlabeledDataDirectory\".";}
	my $neTaggedDataDirectory = $iterationDirectory."TAGGED_UNLABELED_DATA/";
	unless(-d  $neTaggedDataDirectory){mkdir  $neTaggedDataDirectory or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Cannot find nor create the NE tagged unlabeled data iteration directory \"$neTaggedDataDirectory\".";}
	print STDERR "[BootstrapNEModel] Preparing training data.\n";
	#Copy Seed list files to the current training data directory directory.
	NEUtilities::CopyFilesFromDirectory($SeedListDirectory, $trainDataDirectory, $seedExt, $trainExt);
	if ($iterationCounter != 0)
	{
		#Copy previous training list files to the current training data directory.
		NEUtilities::CopyFilesFromArray($trainDataDirectory,@positiveTrainDataArray);
		if ($previousTrainingDataFile ne "")
		{
			my $newTrainingDataFile = $trainDataDirectory."new_training_data.".$trainExt;
			copy($previousTrainingDataFile,$newTrainingDataFile) or die "[BootstrapNEModel] ".NEUtilities::GetTime()." Failed to copy file \"$previousTrainingDataFile\" to \"$newTrainingDataFile\":\n\t$!";
		}
	}
	
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Training and evaluating the classifier.\n";
	##Train the classifier of the current bootstrapping iteration and evaluate on train and test data.
	my $res = `perl "$Bin/NETrainAndEvaluate.pl" "$trainDataDirectory" "$TestListDirectory" "$DevelopmentListDirectory" $trainExt $testExt $developmentExt "$modelDirectory" "$trainPropTemplate" "$testPropTemplate" "$refDefString"`;
	
	##Print the evaluation results to a combined data file.
	my $testEvalFile = $modelDirectory."test.eval";
	my $testTokenRes = NEUtilities::GetTokenTotalResultLine($testEvalFile);
	my $testNERes = NEUtilities::GetNETotalResultLine($testEvalFile);
	my $develEvalFile = $modelDirectory."devel.eval";
	my $develTokenRes = NEUtilities::GetTokenTotalResultLine($develEvalFile);
	my $develTokenRecall = NEUtilities::GetTokenResultEntry($develEvalFile,1);
	my $develTokenPrecision = NEUtilities::GetTokenResultEntry($develEvalFile,2);
	my $develTokenAccuracy = NEUtilities::GetTokenResultEntry($develEvalFile,3);
	my $develTokenFMeasure = NEUtilities::GetTokenResultEntry($develEvalFile,4);
	my $develNERes = NEUtilities::GetNETotalResultLine($develEvalFile);
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Iteration $iterationCounter results: P:$develTokenPrecision R:$develTokenRecall A:$develTokenAccuracy F:$develTokenFMeasure.\n";
	if (($positiveIterationCondition eq "F" && $develTokenFMeasure>=$previousFMeasure) #If only F-measure increase accounts for positive change...
		|| ($positiveIterationCondition eq "R" && $develTokenRecall>=$previousRecall) #If only recall increase accounts for positive change...
		|| ($positiveIterationCondition eq "P" && $develTokenPrecision>=$previousPrecision) #If only precision increase accounts for positive change...
		|| ($positiveIterationCondition eq "A" && $develTokenAccuracy>=$previousAccuracy) #If only accuracy increase accounts for positive change...
		|| ($develTokenFMeasure>=$previousFMeasure && $develTokenRecall>=$previousRecall && $develTokenPrecision>=$previousPrecision && $develTokenAccuracy>=$develTokenAccuracy)) #If all parameter simultaneous increase accounts for positive change...
	{
		print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Iteration $iterationCounter gives a positive increase.\n";
		#Set the new highest values.
		$previousFMeasure = $develTokenFMeasure;
		$previousRecall = $develTokenRecall;
		$previousAccuracy = $develTokenAccuracy;
		$previousPrecision = $develTokenPrecision;
		$positiveChange = 1;
		if ($previousTrainingDataFile ne "")
		{
			print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Adding a new training data file: $previousTrainingDataFile\n";
			push (@positiveTrainDataArray,$previousTrainingDataFile);
		}
		if ($tempGazetteerListFilePath ne "" && -e ($tempGazetteerListFilePath))
		{
			print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Adding new gazetteer data.\n";
			NEUtilities::AppendAFileToAFile($tempGazetteerListFilePath, $gazetteerListFilePath);
		}
		#We set the path of the new good model only if the model exists:
		if (-e $modelDirectory."neModel.ser.gz")
		{
			$previousGoodModelDirectory = $modelDirectory;
		}
		$previousTrainingDataFile="";
	}
	elsif ( $useOnlyPositiveIterations != 0)
	{
		print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Iteration $iterationCounter gives a negative increase.\n";
		#If the observed change is not positive and only positive increases should be accepted, further ignore data updates.
		$positiveChange = 0;
		$previousTrainingDataFile="";
	}
	else
	{
		if ($previousTrainingDataFile ne "")
		{
			print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Adding a new training data file: $previousTrainingDataFile\n";
			push (@positiveTrainDataArray,$previousTrainingDataFile);
		}
		if ($tempGazetteerListFilePath ne "" && -e ($tempGazetteerListFilePath))
		{
			print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Adding new gazetteer data.\n";
			NEUtilities::AppendAFileToAFile($tempGazetteerListFilePath, $gazetteerListFilePath);
		}
		$previousTrainingDataFile="";
		#We set the path of the new good model only if the model exists:
		if (-e $modelDirectory."neModel.ser.gz")
		{
			$previousGoodModelDirectory = $modelDirectory;
		}
		$positiveChange = 1;
	}
	print RESFILE "ITERATION_$iterationCounter\tTEST\t".$testTokenRes."\n";
	print RESFILE "ITERATION_$iterationCounter\tTEST\t".$testNERes."\n";
	print RESFILE "ITERATION_$iterationCounter\tDEVELOPMENT\t".$develTokenRes."\n";
	print RESFILE "ITERATION_$iterationCounter\tDEVELOPMENT\t".$develNERes."\n";
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." TEST results: $testTokenRes\n";
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." TEST results: $testNERes\n";
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Development results: $develTokenRes\n";
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Development results: $develNERes\n";
	
	##NE tag the unlabeled data.
	if ($previousGoodModelDirectory eq "")
	{
		print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." ERROR - previous positive model directory should not have been empty!\n";
		$previousGoodModelDirectory = $modelDirectory;
	}
	
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Preparing unlabeled data.\n";
	##Copy the specified amount ($maxUnlabeledDocs) of unlabeled documents to the current working directory.
	#The returned array is a one dimensional list of file addresses.
	my @unlabeledDocCandidates = NEUtilities::GetRandomFiles($UnlabeledListDirectory,$maxUnlabeledDocs,$unlabeledExt);
	#As we extract unique data, tagging multiple times one document is permitted. (But can be changed to MoveFilesFromArray if preferred).
	NEUtilities::CopyFilesFromArray($unlabeledDataDirectory,@unlabeledDocCandidates);
	
	my $neModelFile = $previousGoodModelDirectory."neModel.ser.gz";
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Tagging unlabeled data with the previous good model $neModelFile.\n";
	$res = `perl NETagDirectory.pl "$neModelFile" "$unlabeledDataDirectory" "$neTaggedDataDirectory" "$unlabeledExt" "tagged"  "$testPropTemplate" "" "$refDefString"`;
	
	##Extract candidate sentences from all documents.
	print STDERR "[BootstrapNEModel] Extracting new training data.\n";
	my @topSentences = BootstrapTools::GetTopSentencesFromDirectory($neTaggedDataDirectory, $docsPerTag, $trainDataDirectory);
	my $numberOfSentences = @topSentences;
	if ($numberOfSentences>0)
	{
		print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Saving new training data.\n";
		$previousTrainingDataFile = $newTrainDataDirectory."iteration_$iterationCounter"."_data.".$trainExt;
		BootstrapTools::PrintSent(\@topSentences,$previousTrainingDataFile);
	}
	else
	{
		print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." New training data not extracted in the current iteration.\n";
		$previousTrainingDataFile = "";
	}
	##If a gazetteer file is defined in the input parameters (13), extract new gazetteer data from the newly created candidates.
	print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Extracting new gazetteer data.\n";
	BootstrapTools::ExtractNewGazetteerData($neTaggedDataDirectory,0.95,$trainPropTemplate,$tempGazetteerListFilePath);
	$iterationCounter++;
}
close RESFILE;
print STDERR "[BootstrapNEModel] ".NEUtilities::GetTime()." Bootstrapping finished.\n";

exit;


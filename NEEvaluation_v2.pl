#!/usr/bin/perl
#===========File: NEEvaluation.pl===============
#Title:        NEEvaluation.pl - Evaluates the Precision, Recall, Accuracy and F-measure of NE Tagged Data on Gold Standard Data
#Description:  Reads NE tags from data files in the first directory (parameter 0) and compares them with NE tags from data files in the second directory (parameter 1). The first directory is referred to as the gold standard directory and the second directory is referred to as the test case result directory. The script produces a result file (parameter 2), which contains evaluation (precision, recall, accuracy and f-measure) of the NER system that produced the test results.
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      28.06.2011
#Last Changes: 01.08.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
BEGIN 
{
	use FindBin '$Bin'; #Gets the path of this file.
	push @INC, "$Bin";  #Add this path to places where perl is searching for modules.
}
use strict;
use warnings;

use NEUtilities;


my $testDir;
my $answerDir;

#Checking if all required parameters are set.	
if(($ARGV[0])&&($ARGV[1])&&($ARGV[2]))
{ 
	$testDir = $ARGV[0];
	$testDir =~ s/\\/\//g; # Normalizes path (for cross platform campatibility).
	if ($testDir !~ /.*\/$/){$testDir .= "/";}
	$answerDir = $ARGV[1];
	$answerDir =~ s/\\/\//g;
	if ($answerDir !~ /.*\/$/){$answerDir .= "/";}
	opendir(TESTDIR,$testDir) or die "can't open dir $testDir: $!"; # Gets file names in folder.
	opendir(ANSWDIR,$answerDir) or die "can't open dir $answerDir: $!";
	open(EVAL, ">:encoding(UTF-8)", $ARGV[2]);
}
else {print STDERR "usage: perl NEEvaluation_v2.pl [ARGS]\nARGS:\n\t1. [Gold data directory] - the path of the human annotated documents.\n\t2. [Test result directory] - the path of the test result documents.\n\t3. [Output file] - the path to the evaluation result output file.\n"; die;}

#%nonRelNotRetr  =(
#					[NE token] => [non retrived count] )
my %nonRelNotRetr = (    
			"B-MON" => 0,
			"I-DATE" => 0,
			"I-PERS" => 0,
			"B-LOC" => 0,
			"B-PERS" => 0,
			"I-LOC" => 0,
			"I-ORG" => 0,
			"I-TIME" => 0,
			"B-ORG" => 0,
			"I-MON" => 0,
			"B-TIME" => 0,
			"B-DATE" => 0,
			"B-PROD" => 0,
			"I-PROD" => 0,
    );
	
	
my $shortTotal = 0;
my $shortAllRelevantRetrieved = 0;
my $shortAllRetrieved = 0;
my $shortAllRelevant = 0;
my $shortAllNonRelNotRetr = 0; 
my %shortRetrieved;
my %shortRelevant;
my %shortRelevantRetrieved;


my $BordersMatch = 0;
my $fullAllRelevantRetrieved = 0;
my $fullAllRetrieved = 0;
my $fullAllRelevant = 0;
my %fullRelevantRetrieved;
my %fullRetrieved ;
my %fullRelevant;


my @answerFiles ;
while (defined(my $answerFile = readdir(ANSWDIR))) #Reads all the tagged data file names in an array.
{
	if (($answerFile ne '.') || ($answerFile ne '.')) { push @answerFiles, $answerFile;}
}


while (defined(my $testFile = readdir(TESTDIR))) #Gets gold data file names.
{

	if( ($testFile eq '.') || ($testFile eq '..') ){ next;}  #Ignores "." or ".." non-file names!
	my $found = 0;
	my $stripedTest = $testFile; #Strips the extension so that file names can be compared.
	$stripedTest =~ s/\.[^\.]+$//;
	
	
	for my $z (0 .. $#answerFiles)  #Iterates through the tagged folder names to find equal file names.
	{

		my $stripedAnsw = $answerFiles[$z];
		$stripedAnsw =~ s/\.[^\.]+$//;
		
		if ($stripedTest eq $stripedAnsw)
		{ 

			if (not(open(TEST, "<:encoding(UTF-8)", $testDir.$testFile ))) { print STDERR  "can't open  $testDir$testFile"; next;}
			if (not(open(ANSWER, "<:encoding(UTF-8)", $answerDir. $answerFiles[$z])))  { print STDERR  "can't open  $testDir$answerFiles[$z]"; next;} 
			
			while (my $answerTokenLine = <ANSWER>)
			{
				my $testTokenLine = "";
				my $isEOF = 0;
				while($answerTokenLine =~ /^\s*$/) {if (not($answerTokenLine = <ANSWER>)) {$isEOF=1;last;} }
				while($testTokenLine =~ /^\s*$/) {if (not($testTokenLine = <TEST>)) {$isEOF=1;last;}}
				if($isEOF) {last;}
				$testTokenLine =~ s/\n//;
				$testTokenLine =~ s/\r//;
				$testTokenLine =~ s/^\x{FEFF}//; #Removes BOM.
				$answerTokenLine =~ s/\n//;
				$answerTokenLine =~ s/\r//;
				$answerTokenLine =~ s/^\x{FEFF}//; #Removes BOM.
				
				my @answerToken = split (/\t/,$answerTokenLine);
				my @testToken = split (/\t/,$testTokenLine);
				
				#Both $answerToken[8] and $testToken[8] vales are NE tags for respective tokens.
				#Gets the required information for NE tag evaluation.
				$shortTotal++;
				for my $NEtag (keys %nonRelNotRetr)
				{
					if (($answerToken[8] ne $NEtag) && ($testToken[8] ne $NEtag))
					{
						$nonRelNotRetr{$NEtag}++;
					}
				}

				
				#If both tokens are tagged as non-entities, count them as non-relevant non-retrieved.
				if (($answerToken[8] eq "O") && ($testToken[8] eq "O")) {$shortAllNonRelNotRetr ++;}
				else
				{
					#If the current NE-tagged token is an NE, count it as retrieved.
					if ($answerToken[8] ne 'O')
					{
						$shortAllRetrieved ++ ;
						#Create a hash value for each NE tag and count how many of each NE tags are there in answer files (retrieved data).
						if (defined  $shortRetrieved{$answerToken[8]}) 
						{
							$shortRetrieved{$answerToken[8]}++;
						}
						else
						{
							$shortRetrieved{$answerToken[8]} = 1;
						}
					}
					
					#If the current gold data token is an NE, count it as relevant.
					if ($testToken[8] ne 'O')
					{
						$shortAllRelevant ++;
						#Create a hash value for each NE tag and count how many of each NE tags are there in test files (relevant data).
						if (defined  $shortRelevant{$testToken[8]})
						{
							$shortRelevant{$testToken[8]}++;
						}
						else
						{
							$shortRelevant{$testToken[8]} = 1;
						}
					}
					
					#If NE tags of both tokens are identical, count them as relevant retrieved.
					if ($testToken[8] eq $answerToken[8])
					{
						$shortAllRelevantRetrieved++;
						#Count relevant retrieved for each token also.
						if (defined  $shortRelevantRetrieved{$testToken[8]})
						{
							$shortRelevantRetrieved{$testToken[8]}++;
						}
						else
						{
							$shortRelevantRetrieved{$testToken[8]} = 1;
						}
					}
					
				}
				
				#Gets the required information for full NE tag evaluation.
				
				#Handles the cases where the NE tag has begun in previous tokens first.
				if ($BordersMatch)
				{
					#If the NE ends at the same position in bouth files and begins at the same position, count it as a  relevant retrieved full NE token.
					if (($answerToken[8] !~ /^I-/ ) && ($testToken[8] !~ /^I-/))
					{ 
						$fullAllRelevantRetrieved++;
						#Saves the count of each relevant retrieved NE in a hash.
						if (defined  $fullRelevantRetrieved{$BordersMatch}) 
						{
							$fullRelevantRetrieved{$BordersMatch}++;
						}
						else
						{
							$fullRelevantRetrieved{$BordersMatch} = 1;
						}
						$BordersMatch = 0;
					}
					#If the NE ends only in one file, change the BordersMatch value to false.
					if ($answerToken[8] ne $testToken[8]) {$BordersMatch=0;}
				}
				
				#If a full NE begins in the tagged data file:
				if ($answerToken[8] =~ /B-/)
				{
					$fullAllRetrieved++;
					#Gets the full NE tag type from the NE token.
					my $fullNETagName = $answerToken[8];
					$fullNETagName =~ s/^B-//;
					$fullNETagName = NEUtilities::GetNEtagType( $fullNETagName );
					
					#Saves the count of each full retrieved NE tag separately in a hash.
					if (defined  $fullRetrieved{$fullNETagName}) 
					{
						$fullRetrieved{$fullNETagName}++;
					}
					else
					{
						$fullRetrieved{$fullNETagName} = 1;
					}
					
				}	
				
				#If a full NE begins in the gold data file:
				if ($testToken[8] =~ /B-/)
				{
					$fullAllRelevant++;
					#Gets the full NE tag type from the NE token.
					my $fullNETagName = $testToken[8];
					$fullNETagName =~ s/^B-//;
					$fullNETagName = NEUtilities::GetNEtagType( $fullNETagName );
					
					#Saves the count of each full relevant NE tag separately in a hash.
					if (defined  $fullRelevant{$fullNETagName}) 
					{
						$fullRelevant{$fullNETagName}++;
					}
					else
					{
						$fullRelevant{$fullNETagName} = 1;
					}

					#If the NE token begins with "B-" and tags match in both files, mark that Full NE tag beginnings match in both files.
					if ($testToken[8] eq $answerToken[8])
					{
					   $BordersMatch = $fullNETagName; 
					}
				}
		
				
			}
			close TEST;
			close ANSWER;

		}
	}
}

if($shortTotal == 0) {die "NEEvaluation.pl: No tokens found!\n";}


#Full NE tag evaluation.
my $fullRecall;
my $fullPrecision;
my $fullF1= "-";
#Handles cases when there are no relevant values separately to avoid division by zero.
if($fullAllRelevant == 0) 
{
	$fullRecall = '-';
}
else
{ 
	#Calculates recall.
	$fullRecall =  sprintf("%.2f", ($fullAllRelevantRetrieved/$fullAllRelevant)*100);
} 
#Handles cases when there are no retrieved values separately to avoid division by zero.
if($fullAllRetrieved == 0) 
{
	$fullPrecision = '-';
}
else
{
	#Calculates precision.
	$fullPrecision =  sprintf("%.2f", ($fullAllRelevantRetrieved/$fullAllRetrieved)*100);
}

#Handles cases when there are no relevant or retreved values separately to avoid division by zero.
if (($fullPrecision ne '-')  && ($fullRecall ne '-') )
{
	if (($fullPrecision != 0)  || ($fullRecall != 0) )
	{
		#Calculates F-measure.
		$fullF1 = sprintf("%.2f", ( ($fullPrecision*$fullRecall)*2/($fullPrecision+$fullRecall) ));
	}
}

#Prints calculated numbers in the result file.
print EVAL "TOTAL_NE\t".$fullRecall."\t".$fullPrecision."\t-\t".$fullF1."\n";

#Uses the list of tags in %nonRelNotRetr to get all possible full NE tags.
for my $NETag (keys %nonRelNotRetr)
{
	#Uses the tag beginning token to get all possible full NE tag names.
	if ($NETag =~ /B-/)
	{
		#Strips NE token beginnings and gets full NE tag names with GetNEtagType.
		my $fullNETag = $NETag;
		$fullNETag =~ s/B-//;
		$fullNETag =  NEUtilities::GetNEtagType($fullNETag);
		
		my $relevantRetrieved;
		my $relevant;
		my $retrieved;
		my $recall;
		my $precision;

		my $F1= "-";
		
		if (defined $fullRelevantRetrieved{$fullNETag})
		{
			$relevantRetrieved = $fullRelevantRetrieved{$fullNETag};
		}
		else {$relevantRetrieved = 0;}
		
		if (defined $fullRelevant{$fullNETag})
		{
			$relevant = $fullRelevant{$fullNETag};
		}
		else {$relevant = 0;}
		
		if (defined $fullRetrieved{$fullNETag})
		{
			$retrieved = $fullRetrieved{$fullNETag};
		}
		else {$retrieved = 0;}
		
		
		if($relevant == 0) {$recall = '-';}
		else{ $recall =  sprintf("%.2f", ($relevantRetrieved/$relevant)*100);}

		if($retrieved == 0) {$precision = '-';}
		else{$precision =  sprintf("%.2f", ($relevantRetrieved/$retrieved)*100);}
		

		
		if (($precision ne '-')  && ($recall ne '-') )
		{
			if (($precision != 0)  && ($recall != 0) )
			{
				$F1 = sprintf("%.2f", ( ($precision*$recall)*2/($precision+$recall) ));
			}
		}
		
		#Prints the full NE tag type and its recall, precision, accuracy(equal to "-" by default) and F-measure.
		print EVAL $fullNETag."\t".$recall."\t".$precision."\t-\t".$F1."\n";
	}
}


#Calculates NE token evaluation values.

my $allRecall;
my $allPrecision;
my $allAccuracy;
my $allF1= "-";

#Handles cases when there are no relevant values separately to avoid division by zero.	
if($shortAllRelevant == 0) 
{
	$allRecall = '-';
}
else
{ 
	#Calculates recall.
	$allRecall =  sprintf("%.2f", ($shortAllRelevantRetrieved/$shortAllRelevant)*100);
} 
#Handles cases when there are no retrieved values separately to avoid division by zero.
if($shortAllRetrieved == 0) 
{
	$allPrecision = '-';
}
else
{
	#Calculates precision.
	$allPrecision =  sprintf("%.2f", ($shortAllRelevantRetrieved/$shortAllRetrieved)*100);
}
#Calculates accuracy.
$allAccuracy = sprintf("%.2f", ( ($shortAllRelevantRetrieved + $shortAllNonRelNotRetr)/$shortTotal)*100 );

#Handles cases when there are no relevant or retrieved values separately to avoid division by zero.
if (($allPrecision ne '-')  && ($allRecall ne '-') )
{
	if (($allPrecision != 0)  && ($allRecall != 0) )
	{
		#Calculates F-measure.
		$allF1 = sprintf("%.2f", ( ($allPrecision*$allRecall)*2/($allPrecision+$allRecall) ));
	}
}

#Prints recall, precision, accuracy and F-measure.
print EVAL "TOTAL_TOKEN\t".$allRecall."\t".$allPrecision."\t".$allAccuracy."\t".$allF1."\n";

#Calculates recall, precision, accuracy and F-measure for each of NE token types separately.
#Uses %nonRelNotRetr keys to iterate through all possible NE tokens.
for my $NETag (keys %nonRelNotRetr)
{
	my $relevantRetrieved;
	my $relevant;
	my $retrieved;
	my $recall;
	my $precision;
	my $accuracy;
	my $F1= "-";
	#If hash value doesn’t exist sets the value to '0'.
	if (defined $shortRelevantRetrieved{$NETag})
	{
		$relevantRetrieved = $shortRelevantRetrieved{$NETag};
	}
	else 
	{
		$relevantRetrieved = 0;
	}
	
	if (defined $shortRelevant{$NETag})
	{
		$relevant = $shortRelevant{$NETag};
	}
	else 
	{
		$relevant = 0;
	}
	
	if (defined $shortRetrieved{$NETag})
	{
		$retrieved = $shortRetrieved{$NETag};
	}
	else 
	{
		$retrieved = 0;
	}
	
	if($relevant == 0) 
	{
		$recall = '-';
	}
	else
	{ 
		$recall =  sprintf("%.2f", ($relevantRetrieved/$relevant)*100);
	} 

	if($retrieved == 0) 
	{
		$precision = '-';
	}
	else
	{
		$precision =  sprintf("%.2f", ($relevantRetrieved/$retrieved)*100);
	}
	
	$accuracy = sprintf("%.2f", ( ($relevantRetrieved + $nonRelNotRetr{$NETag})/$shortTotal)*100 );
	
	if (($precision ne '-')  && ($recall ne '-') )
	{
		if (($precision != 0)  && ($recall != 0) )
		{
			$F1 = sprintf("%.2f", ( ($precision*$recall)*2/($precision+$recall) ));
		}
	}

	
	print EVAL $NETag."\t".$recall."\t".$precision."\t".$accuracy."\t".$F1."\n";
}


close EVAL;
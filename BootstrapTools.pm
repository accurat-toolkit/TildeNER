#===========File: BootstrapTools.pm===============
#Title:        BootstrapTools.pm
#Description:  The Module contains tools for bootstrapping
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      16.06.2011
#Last Changes: 21.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================

package BootstrapTools;

use strict;
use warnings;
use NEUtilities;
use NERefinements;
use Data::Dumper;

#=========Method: GetTopNECandidateFileNames==========
#Title:        GetTopNECandidateFileNames
#Description:  Returns top ranked file addresses in an arryay from a NE tagged data directory (argument 0). For each NE token type a maximum number (argument 1) of file names is returned.
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      16.06.2011
#Last Changes: 21.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================

sub GetTopNECandidateFileNames
{
 
	if (not(($_[0])&&($_[1]))) #Cheking if all required parematers exist.
	{ 
		print STDERR "usage: GetTopNECandidateFileNames [Foloder Name] [File Count Per NeTag] [Min NE Count Per File](optional)\n"; 
		die;
	}

	my %possibleNETags;
	my $minTagCount;
	if($_[2])#Saves the optional parameter if it exists.
	{
		$minTagCount = $_[2];
	}  
	else
	{
		$minTagCount = 1;
	}

	my $filesPerTagCount = $_[1];

	my $dir = $_[0]; 
	$dir =~ s/\\/\//g; #Normalize path slashes.
	if ($dir !~ /.*\/$/)
	{
		$dir .= "/"; 
	}
	 opendir(DIR,$dir) or die "can't open dir : $!";
	 
	my  %files;
	#Finds NE tags and stores their name and count in hash.
	while (defined(my $file = readdir(DIR))) #Reads all filenames in an array.
	{
		if( ($file eq '.') || ($file eq '..') ){ next;}  #Ignores filenames if they are "." or "..".
		open(FIN, "<:encoding(UTF-8)", $dir.$file )or next;
		my %tags; 
		while(my $line = <FIN>)
		{
			$line =~ s/^\x{FEFF}//;# Strips the BOM symbol.
			$line =~ s/\n//;
			$line =~ s/\r//;
			if (($line!~ /\t/) || ($line =~ /^\s*$/)) {next;} #Skip if empty line found or the format is incorrect.
			my @token = split(/\t/,$line );
			
			#token[8] - tokens NE tag
			if (defined  $tags{$token[8]})
			{
				$tags{$token[8]}[0] ++;
				$tags{$token[8]}[1] += $token[9];	
			}
			else
			{
				$tags{$token[8]} =  ();
				push @{$tags{$token[8]}} , (1,$token[9]);	
			}
			#Saves all unique names encountered.
			if(not(defined  $possibleNETags{$token[8]})) {$possibleNETags{$token[8]} = 0;}
		}
		

		my @probabilities;
		my $count=0;
		#Calculates the probabilities for each NE token type in file.
		#Gets probabilities for each tag and stores them in an array.
		for my $key  (keys %tags)
		{	
			$count++;
			push @probabilities, ($tags{$key}[1]/$tags{$key}[0]);
		}
		#Calculates the sum of all NE tag probabilities.
		my $sum;
		$sum += $_ for @probabilities; 
		
		#Gets the average probity of all NE tags in file which is the file quality rating.
		my $rating = 0;
		if ($count != 0)
		{
			$rating = $sum/$count;
		}
		
		#Stores the file rating and NE tag names found in file in a hash linking these values to file name.
		$files{$file} =  ();
		push @{$files{$file}} , ($rating,\%tags);	
		
		close FIN;	
	}

	my %finalFilehash;

	#Finds with the highes qulity containe each of the encountered NE tags in all files.
	for my $NEtag (keys %possibleNETags)
	{
		#Sorts the files by their quality and the iterate trough them.
		for my $key (sort {$files{$b}[0] <=> $files{$a}[0]}(keys %files))
		{
			## <for debuging
			
			# print FOUT $key."\t".$files{$key}[0]."\n"."\n";
			# for $key2 (keys %{$files{$key}[1]})
			# {
				
				# print FOUT $key2."\t".$files{$key}[1]{$key2}[0]."\n";
			# }
			
			## END  
			
			#Adds best file names with the best probabilities that have at least the minimum tags in file (optional argument 2) of the NE tag into a hash(only unique file names are preserved) until the required amount of files (argument 1) are gathered.
			if (defined $files{$key}[1]{$NEtag})
			{
				if ($files{$key}[1]{$NEtag}[0] >= $minTagCount)
				{
					if (not(defined $finalFilehash{$key})){$finalFilehash{$key}=()}
					$possibleNETags{$NEtag}++
				}
				if ($possibleNETags{$NEtag} >= $filesPerTagCount) {last;}
			}
		}
	}

	#Returns an array of file paths.
	my @finalFileNames;
	for my $fileName (keys %finalFilehash)
	{
		push (@finalFileNames, $dir.$fileName);
	}
	return @finalFileNames;

}

#=========Method: GetSentencesAboveThreshold==========
#Title:        GetSentencesAboveThreshold
#Description:  Gets sentences with NE tags from tokens (argument 0), with the probity of each token being tagged right higher than argument 1
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      16.06.2011
#Last Changes: 20.06.2011. by Kârlis Gediòð, SIA Tilde.
#===============================================

sub GetSentencesAboveThreshold
{

	if (not((defined $_[0])&&(defined $_[1]))) #Cheking if all required parematers exist.
	{ 
		print STDERR "usage: GetSentencesAboveThreshold [Reference To Array Of Tokens] [Min Possibility Of NE Tags In Sentence] [Skip Sentences With No NE Tag](optional)\n"; 
		die;
	}

	my @tokens = @{$_[0]};
	my $minPossibility = $_[1];

	
	my @sentences;
	my @sent;
	my $isAcceptable = 1;
	my $containsNE = 0; 
	#Puts tokens in sentence arrays until the end of sentence or line.
	#The sentence arrays are then put in result array if the probability of all tokens in sentence is higher than threshold (argument 1).
	for my $i (0 .. $#tokens )
	{
		push @sent, $tokens[$i]; #Puts token in sentence.
		
		# token[9] -  NE tagd Possibility of being correct according to the tagger
		#If a token has a lower probability than threshold (argument 1) mark it mark it in order for whole the sentence of tokens not to be accepted
		if ($tokens[$i][9] < $minPossibility) {$isAcceptable = 0;}
		#token [8] -NE tag
		#If [Skip Sentences With No NE Tag](argument 3) value defined and true and token assigned NE token not empty assign $containsNE a true value.
		if($_[2])
		{
			if($tokens[$i][8] ne "O") {$containsNE = 1;}
		}
		# If it's the end of line save sentence in result array if all tonkens have the probability above threshold (argument 1).
		if(defined $tokens[$i+1])
		{
			#token[5]-starting line
			if ($tokens[$i][4] != $tokens[$i+1][4])
			{
				if($_[2]) # If [Skip Sentences With No NE Tag](argument 3) value defined and true.
				{
					if ($isAcceptable)
					{
						if ($containsNE)
						{
							push @sentences, [@sent];
							#Empty $sent variable, set the empty sentence to be acceptable, and go to next token.
							undef @sent;
							$isAcceptable = 1;
							$containsNE = 0;							
							next;
						}
					}
					else
					{
						
						undef @sent;
						$isAcceptable = 1;
						$containsNE = 0;
						next;
					}
				}
				else
				{
					if ($isAcceptable)
					{
						push @sentences, [@sent];
						#Empty $sent variable, set the empty sentence to be acceptable, and go to next token.
						undef @sent;
						$isAcceptable = 1; 
						next;
					}
					else
					{
						
						undef @sent;
						$isAcceptable = 1;
						next;
					}
				}
				
			}
		}
		else #If it's the last token save sentence if the sentence is acceptable.
		{
				if($_[2]) # If [Skip Sentences With No NE Tag](argument 3) value defined and true.
				{
					if ($isAcceptable)
					{
						if ($containsNE)
						{
							push @sentences, [@sent];
							#Empty $sent variable, set the empty sentence to be acceptable, and go to next token.
							undef @sent;
							$isAcceptable = 1;
							$containsNE = 0;							
							next;
						}
					}
					else
					{
						
						undef @sent;
						$isAcceptable = 1;
						$containsNE = 0;
						next;
					}
				}
				else
				{
					if ($isAcceptable)
					{
						push @sentences, [@sent];
						#Empty $sent variable, set the empty sentence to be acceptable, and go to next token.
						undef @sent;
						$isAcceptable = 1; 
						next;
					}
					else
					{
						undef @sent;
						$isAcceptable = 1;
						next;
					}
				}
				
			}
		
		
			#If its the last token in sentence save sentence if the sentence is acceptable.
			# token[1]- POS tag.
			if ($tokens[$i][1] eq "SENT")  
			{	
				#If the sentence breaks NE tag ignore the end of sentence.
				if (defined $tokens[$i+1]){ if ($tokens[$i+1][8] =~ /^I.*/) {next;}} 
					
				if($_[2]) #If [Skip Sentences With No NE Tag](argument 3) value defined and true.
				{
					if ($isAcceptable)
					{
						if ($containsNE)
						{
							push @sentences, [@sent];
							#Empty $sent variable, set the empty sentence to be acceptable, and go to next token.
							undef @sent;
							$isAcceptable = 1;
							$containsNE = 0;							
							next;
						}
					}
					else
					{
						undef @sent;
						$isAcceptable = 1;
						$containsNE = 0;
						next;
					}
				}
				else
				{
					if ($isAcceptable)
					{
						push @sentences, [@sent];
						#Empty $sent variable, set the empty sentence to be acceptable, and go to next token.
						undef @sent;
						$isAcceptable = 1; 
						next;
					}
					else
					{
						undef @sent;
						$isAcceptable = 1;
						next;
					}
				}
					
			}
				
		}
		
	
	
	#Returns the array of accepted tokens.
	return @sentences;
	
}

#======Method: GetTopSentencesFromDirectory=====
#Title:        GetTopSentencesFromDirectory
#Description:  Analyzes all files within a directory (argument 0) and returns an array, which has at most N (argument 1) top ranked sentences for each NE token. Only sentences with unique morphological tags are used. If the POS tagger does not support Morpho-tags, the uniqueness constraint is not used.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      05.07.2011
#Last Changes: 05.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub GetTopSentencesFromDirectory
{
	if (not(defined($_[0])&&defined($_[1])&&defined($_[2]))) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: GetTopSentencesFromDirectory [Input Directory] [Maximum number of sentences per NE token] [Current iteration training data directory]\n"; 
		die;
	}
	# %possibleNESentences - stores an array of sentences for each NE token type (B-ORG, I-ORG, etc.).
	# Structure of the key/value pair of the hash table is as follows:
	#	(NE Token Type => [
	#		[0:NE Token Probability for Sentence 1, 1:Sentence 1],
	#		...
	#		[0:NE Token Probability for Sentence N, 1:Sentence N]]
	#	)
	# The sentence is a two dimensional array, which contains tokens of a single sentence:
	#	[0] - token, [1] – POS tag, [2] - lemma, [3] - morphological tag, [4] - token start position(in text) in line, [5] - starting line, [6] - token end position, [7] - end line, [8] – NE tag, [9] - NE token probability
	my %possibleNESentences;
	my %alreadyPresentData;
	my $trainingDataDirectory = $_[2]; 
	$trainingDataDirectory =~ s/\\/\//g;
	if ($trainingDataDirectory !~ /.*\/$/)
	{
		$trainingDataDirectory .= "/"; 
	}
	
	#
	opendir(DIR,$trainingDataDirectory) or die "can't open input directory \"$trainingDataDirectory\": $!";
	while (defined(my $file = readdir(DIR)))
	{
		#Check if the directory object is a file.
		if (-d $trainingDataDirectory.$file|| not(-e $trainingDataDirectory.$file))
		{
			next;
		}
		my $fullPath = $trainingDataDirectory.$file;
		#The @arrayOfTokens is a one dimensional array, which contains all tokens of a single document (see above %possibleNESentences for an example).
		my @arrayOfTokens = NERefinements::LoadTabSepFile($fullPath);
		my $currentSentence = "";
		my $previousLine = "-1";
		for my $i (0 .. $#arrayOfTokens )
		{
			#If by any chance the current token is invalid (does not contain all tab separated data), skip it.
			if (!defined($arrayOfTokens[$i][1]) || $arrayOfTokens[$i][1] eq ""
				|| !defined($arrayOfTokens[$i][3]) || $arrayOfTokens[$i][3] eq ""
				|| !defined($arrayOfTokens[$i][4]) || $arrayOfTokens[$i][4] eq "") { next; }
			my $morphoTag = $arrayOfTokens[$i][3];
			my $currentLine = $arrayOfTokens[$i][4];
			my $currentPOSTag = $arrayOfTokens[$i][1];
			#If the current token is from a different line in the source text:
			if ($currentLine ne $previousLine)
			{
				if ($currentSentence ne "")
				{
					#Add the morpho tag sequence to the hash table.
					if (defined ($alreadyPresentData{$currentSentence}))
					{
						$alreadyPresentData{$currentSentence}++;
					}
					else
					{
						$alreadyPresentData{$currentSentence} = 1;
					}
				}
				$currentSentence = $morphoTag;
				$previousLine = $currentLine;
			}
			#If the current token is the last token of the sentence:
			elsif ($currentPOSTag eq "SENT")
			{
				$currentSentence = $currentSentence." ".$morphoTag;
				if ($currentSentence ne "")
				{
					if (defined ($alreadyPresentData{$currentSentence}))
					{
						$alreadyPresentData{$currentSentence}++;
					}
					else
					{
						$alreadyPresentData{$currentSentence} = 1;
					}
				}
				$currentSentence = "";
			}
			#If the current token is in the middle of the sentence.
			else
			{
				#Simply add the morpho tag to the sentence's morpho tag sequence.
				if ($currentSentence ne "")
				{
					$currentSentence = $currentSentence." ".$morphoTag;
				}
				else
				{
					$currentSentence = $morphoTag;
				}
			}
		}
	}
	close DIR;
	
	##Set and clean the input directory path.
	my $inputDirectory = $_[0]; 
	$inputDirectory =~ s/\\/\//g;
	if ($inputDirectory !~ /.*\/$/)
	{
		$inputDirectory .= "/"; 
	}
	##Read each file from the directory and acquire all sentences that have NE tags.
	opendir(DIR,$inputDirectory) or die "can't open input directory \"$inputDirectory\": $!";
	while (defined(my $file = readdir(DIR)))
	{
		#Check if the directory object is a file.
		if (-d $inputDirectory.$file|| not(-e $inputDirectory.$file))
		{
			next;
		}
		#The @sent is a one dimensional array, which contains tokens of a single sentence (see above %possibleNESentences for an example).
		my @sent;
		# %currentSentenceNeTagHash - contains NE token types of a single sentence.
		# Structure of the key/value pair is as follows: (NE Token Type => Integer Value). The integer value is not used as the hash is used to indicate, which NE token types a sentence contains.
		my %currentSentenceNeTagHash;
		my $fullPath = $inputDirectory.$file;
		#The @arrayOfTokens is a one dimensional array, which contains all tokens of a single document (see above %possibleNESentences for an example).
		my @arrayOfTokens = NERefinements::LoadTabSepFile($fullPath);
		#Find the sentences containing NE token tags.
		for my $i (0 .. $#arrayOfTokens )
		{
			#If by any chance the current token is invalid (does not contain all tab separated data), skip it.
			if (!defined($arrayOfTokens[$i][4]) || $arrayOfTokens[$i][4] eq "") { next; }
			my $neTag = $arrayOfTokens[$i][8];
			#Add the current NE token type (non "O") to the current tag type hash and initiate the sentence list hash for the current tag type if not defined.
			if ($neTag ne "O" && !defined ($currentSentenceNeTagHash{$neTag}))
			{
				$currentSentenceNeTagHash{$neTag}=1;
				if (!defined ($possibleNESentences{$neTag}))
				{
					$possibleNESentences{$neTag}=();
				}
			}
			#Add the current token to the sentence array.
			push @sent, $arrayOfTokens[$i];
			#As some tokens may be corrupt (missing some tab separated data), check whether the next token is valid and if not find a valid next token.
			my $validNextIdx = 1;
			while (defined $arrayOfTokens[$i+$validNextIdx] && (!defined($arrayOfTokens[$i+$validNextIdx][4])||$arrayOfTokens[$i+$validNextIdx][4] eq ""))
			{
				$validNextIdx++;
			}
			#If the next valid token exists:
			if(defined $arrayOfTokens[$i+$validNextIdx])
			{
				#Check if the next valid token starts a new sentence.
				if ($arrayOfTokens[$i][4] != $arrayOfTokens[$i+$validNextIdx][4]||($arrayOfTokens[$i][1] eq "SENT" && $arrayOfTokens[$i+$validNextIdx][8] !~ /^I.*/))
				{
					#Check if the sentence contains at least one NE token.
					if (keys( %currentSentenceNeTagHash )>0)
					{
						#For each NE token type, add the sentence to the particular sentence list.
						for my $neTagInSent (keys %currentSentenceNeTagHash)
						{
							my $sentValue = 0;
							my $tokCount = 0;
							my $sentMorphoString = "";
							my $minNeProb = 1;
							#Calculate the average probability of the current sentence's NE tokens of the particular type.
							for my $token (@sent)
							{
								if (@$token[8] eq $neTagInSent)
								{
									$sentValue+=@$token[9];
									$tokCount++;
								}
								elsif (@$token[9]<$minNeProb) #We also use a threshold for the sentence. We do not want unreliable data to be extracted, therefore, we ignore low probability sentences.
								{
									$minNeProb = @$token[9];
								}
								if (defined @$token[3])
								{
									if ($sentMorphoString ne "")
									{
										$sentMorphoString = $sentMorphoString." ".@$token[3];
									}
									else
									{
										$sentMorphoString = @$token[3];
									}
								}
							}
							my $prob =0;
							if ($tokCount>0)
							{
								$prob = $sentValue/($tokCount);
							}
							#Add the sentence to the NE token type sentence array only if it contains more than 3 tokens (in order to not allow minimal data noise) and it contains a unique morpho string sequence.
							if ($minNeProb> 0.8 && @sent>3 && ($sentMorphoString eq "" || !defined($alreadyPresentData{$sentMorphoString})||$alreadyPresentData{$sentMorphoString}<3))
							{
								if (!defined ($alreadyPresentData{$sentMorphoString}))
								{
									$alreadyPresentData{$sentMorphoString} = 1;
								}
								else
								{
									$alreadyPresentData{$sentMorphoString}++;
								}
								my @sentEntry = ($prob,[@sent]);
								push @{$possibleNESentences{$neTagInSent}}, [@sentEntry];
							}
						}
					}
					#Clear all current sentence data before processing the next sentence.
					@sent = ();
					for (keys %currentSentenceNeTagHash)
					{
						delete $currentSentenceNeTagHash{$_};
					}
				}
			}
			else #In the case if the last token is processed, the last sentence is also added to the correct sentence arrays.
			{
				if (keys( %currentSentenceNeTagHash )>0)
				{
					for my $neTagInSent (keys %currentSentenceNeTagHash)
					{
						my $sentValue = 0;
						my $tokCount = 0;
						my $sentMorphoString = "";
						my $minNeProb = 1;
						for my $token (@sent)
						{
							if (@$token[8] eq $neTagInSent)
							{
								$sentValue+=@$token[9];
								$tokCount++;
							}
							elsif (@$token[9]<$minNeProb)
							{
								$minNeProb = @$token[9];
							}
							if (defined @$token[3])
							{
								if ($sentMorphoString ne "")
								{
									$sentMorphoString = $sentMorphoString." ".@$token[3];
								}
								else
								{
									$sentMorphoString = @$token[3];
								}
							}
						}
						my $prob =0;
						if ($tokCount>0)
						{
							$prob = $sentValue/($tokCount);
						}
						if ($minNeProb> 0.8 && @sent>3 && ($sentMorphoString eq "" || !defined($alreadyPresentData{$sentMorphoString})||$alreadyPresentData{$sentMorphoString}<3))
						{
							if (!defined ($alreadyPresentData{$sentMorphoString}))
							{
								$alreadyPresentData{$sentMorphoString} = 1;
							}
							else
							{
								$alreadyPresentData{$sentMorphoString}++;
							}
							my @sentEntry = ($prob,[@sent]);
							push @{$possibleNESentences{$neTagInSent}}, [@sentEntry];
						}
					}
				}
				@sent = ();
				for (keys %currentSentenceNeTagHash)
				{
					delete $currentSentenceNeTagHash{$_};
				}
			}
		}
	}
	close DIR;
	
	# %sentStrHash - stores information about, which sentences have been added to the resulting sentence array.
	# The structure of the key/value pair is as follows: (Sentence String => Integer Value). The integer value is not used.
	my %sentStrHash;
	#The result sentence array. The array is a three dimensional array:
	# Dimension 1: Sentence
	# Dimension 2: Tokens in a sentence
	# Dimension 3: Token data (see %possibleNESentences above for an example)
	my @returnArray;
	
	#For each NE token type, find the top (defined by argument 1) sentences and add them to the result array.
	for my $neTag (keys %possibleNESentences)
	{
		if (!defined $possibleNESentences{$neTag})
		{
			next;
		}
		#The following arrays one after another are used to read through the %possibleNESentences hash.
		my $entryArrayRef = $possibleNESentences{$neTag};
		#Entry array represents one token types sentence and their assigned probability array.
		my @entryArray = @$entryArrayRef;
		#print Dumper(@entryArray);
		#exit;
		#Sort the Sentences descending according to NE token type probabilities.
		my @sortedEntryArray = sort { my $n_a=$a->[0]; my $n_b = $b->[0]; $n_b <=> $n_a } @entryArray;
		my $counter = 0;
		#Get the top sentences for the current NE token type:
		for my $sentence (@sortedEntryArray)
		{
			$counter++;
			#SentArr contains the NE token type sentence's probability (0) and the array of sentence tokens (1).
			my @sentArr = @$sentence;
			my $prob = $sentArr[0];
			my $sentRef = $sentArr[1];
			#RealSent contains an array of sentence tokens.
			my @realSent = @$sentRef;
			my $sentStr = "";
			#Get the sentence string, that is used to validate whether the sentence hasn't been already added to the results.
			for my $tokens (@realSent)
			{
				my @tokenArr = @$tokens;
				$sentStr.=$tokenArr[0];
			}
			#If not present in the results, add the sentence to the result array.
			if (!defined ($sentStrHash{$sentStr}))
			{
				$sentStrHash{$sentStr} = 1;
				push @returnArray, [@realSent];
			}
			#Continue with the next NE token type, if enough sentences have been processed.
			if ($counter>=$_[1])
			{
				last;
			}
		}
	}
	return @returnArray;
}

#========Method: ExtractNewGazetteerData========
#Title:        ExtractNewGazetteerData
#Description:  Extracts new gazetteer data from a directory of files (argument 0) into a target file (argument 3). Only those named entities are extracted, which are considered the most likely using a threshold (argument 1) and are unique and non existing in the gazetteer data files defined in the property file (argument 2).
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      07.07.2011
#Last Changes: 18.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================

sub ExtractNewGazetteerData
{
	if (not(defined($_[0])&&defined($_[1])&&defined($_[2])&&defined($_[3]))) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: ExtractNewGazetteerData [Input directory] [Threshold] [Property file] [Output file]\n"; 
		die;
	}
	##Set and clean the input directory path.
	my $inputDirectory = $_[0]; 
	$inputDirectory =~ s/\\/\//g;
	if ($inputDirectory !~ /.*\/$/)
	{
		$inputDirectory .= "/"; 
	}
	my $gazetteerPropStr = NEUtilities::ReadPropertyFromFile($_[2], "gazette");
	my %existingHash = NEUtilities::ReadExistingGazetteerData($gazetteerPropStr);
	my $threshold = $_[1];
	
	open(FOUT, ">:encoding(UTF-8)", $_[3]);
	##Read each file from the directory and acquire all NE tags above the threshold.
	opendir(DIR,$inputDirectory) or die "can't open input directory \"$inputDirectory\": $!";
	while (defined(my $file = readdir(DIR)))
	{
		my $fullPath = $inputDirectory.$file;
		#Check if the directory object is a file.
		if (-d $fullPath|| not(-e $fullPath))
		{
			next;
		}
		#The @arrayOfTokens is a two dimensional array, which contains tokens of the current document:
		#	[0] - token, [1] – POS tag, [2] - lemma, [3] - morphological tag, [4] - token start position(in text) in line, [5] - starting line, [6] - token end position, [7] - end line, [8] – NE tag, [9] - NE token probability
		my @arrayOfTokens = NERefinements::LoadTabSepFile($fullPath);
		
		my $currentNETag = "";
		my $withinATag = 0;
		my $neString = "";
		my $length = 0;
		my $probSum = 0.0;
		
		for my $j (0 .. $#arrayOfTokens) 
		{
			if ($withinATag == 1 && $arrayOfTokens[$j][8] =~ /I-$currentNETag/)
			{
				if ($neString ne "")
				{
					$neString.= " ".$arrayOfTokens[$j][0];
				}
				else
				{
					$neString = $arrayOfTokens[$j][0];
				}
				$length++;
				$probSum += $arrayOfTokens[$j][9];
			}
			elsif ($withinATag == 1)
			{
				$neString =~ s/^\s+//;
				$neString =~ s/\s+$//;
				if ($neString ne ""
					&& !defined $existingHash{$currentNETag."\t".$neString}
					&& $neString ne lc $neString
					&& NEUtilities::IsValidGazetteerType($currentNETag))
				{
					my $avgProb=0;
					if ($length>0&&$length<=10)
					{
						$avgProb = $probSum/$length;
						if ($avgProb>=$threshold)
						{
							#print $currentNETag."\t".$neString."\t".$avgProb."\n";
							print FOUT $currentNETag."\t".$neString."\n";
							$existingHash{$currentNETag."\t".$neString} = 1;
						}
					}
				}
				$probSum = 0;
				$length = 0;
				$neString = "";
				$withinATag = 0;
				$currentNETag = "";
			}
			
			if ($arrayOfTokens[$j][8] =~ /B-.*/)
			{
				$withinATag = 1;
				$neString = $arrayOfTokens[$j][0];
				$length=1;
				$currentNETag = $arrayOfTokens[$j][8];
				$currentNETag =~ s/^B-//;
				$probSum = $arrayOfTokens[$j][9];
			}
		}
	}
	close DIR;
	close FOUT;

}

#=========Method: PrintSent==========
#Title:        PrintSent
#Description:  Print sentences from an array (argument 0) in a file (argument 1) with a newline after each line in original text.
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      17.06.2011
#Last Changes: 20.06.2011. by Kârlis Gediòð, SIA Tilde.
#===============================================

sub PrintSent
{
	my @arr =  @{$_[0]};
	 
	open(FOUT, ">:encoding(UTF-8)", $_[1]);
	#Iterates trough sentences.
	for my $i (0 .. $#arr)  
	{	
		#Iterates trough tokens.
		for my $j (0 .. $#{$arr[$i]}) 
		{	
			#Changes line number of each token to the sentence position in the array to get unique line/position combinations.
		    $arr[$i][$j][4] = $i;
		    $arr[$i][$j][6] = $i;
			#Prints tokens.
			print FOUT join("\t",@{$arr[$i][$j]})."\n"; 

		}
		#Separates sentence with a newline.
		print FOUT "\n";

	}
	close FOUT;

}



1;
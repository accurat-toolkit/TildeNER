#!/usr/bin/perl
#===========File: NERefinements.pm===============
#Title:        NERefinements.pm
#Description:  The Module contains data refinement methods for NE tagging.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      08.06.2011
#Last Changes: 14.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
use strict;
use warnings;
package NERefinements;

use File::Basename;
use NEUtilities;

#==========Method: CombinedRefsOnFile===========
#Title:        CombinedRefsOnFile
#Description:  Calls all refinement methods on one file (saves processing time by reading the file only once).
#Author:       Mārcis Pinnis, SIA Tilde.
#Created:      10.06.2011
#Last Changes: 04.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
sub CombinedRefsOnFile
{
	#Checking if all required parameters are set.
	if (not(defined($_[0])&&defined($_[1])&&defined($_[2])))
	{ 
		print STDERR "Usage: CombinedRefsOnFile [Input file] [Output file] [POS Tagged file with original newlines] [Refinement order definition string - optional]\n\tThe refinement order definition string has to be in the following form \"P1 P2 ... Pn\", where Pn is a refinement parameter. Available parameters are:\n\t\tA - Add missing line breaks (Other parameters after this one will be ignored).\n\t\tC - Consolidate equal entities.\n\t\tL - Clean brackets and quotation marks.\n\t\tN - Removes NEs, which contain more than a fixed number of strings (for example - persons and \"/\" string).\n\t\tS - Removes corrupt string tokens, for instance web addresses from NEs.\n\t\tR_0.# - Remove low probability NE tags (\"#\" have to be digits after 0).\n\t\tT_0.# - Tag equal lemmas (\"#\" have to be digits after 0).\n"; die;
	}
	my $inFile = $_[0];
	my $outFile = $_[1];
	my ($inputFileName,$inputFilePath,$inputFileSuffix) = fileparse($inFile,qr/\.[^.]*/);
	my $tempFile = $inputFilePath.$inputFileName.".ref_temp";
	my $posTaggedFile = $_[2];
	my $refDefString = "";
	
	#The combined refinements can also be run using a refinement order definition string, but if such is not given, a default approach is used to maximize precision (evaluated on Latvian development data).
	if (!defined($_[3]) || $_[3] eq "")
	{
		$refDefString = "L N S R_0.7 C T_0.90";
	}
	else
	{
		#Set the refinement order definition string (argument 3).
		$refDefString = $_[3];
	}
	my @refDefArray = split(/ /,$refDefString );
	#Load the input file.
	#Argument 0 - @arr - an array of tokens.
	# @arr[$i] - @token.
	# @token[$i] has values: [0] - token, [1] – POS tag, [2] - lemma, [3] - morphological tag, [4] - token start position(in text) in line, [5] - starting line, [6] - token end position, [7] - end line, [8] – NE tag, [9] - NE Tag probability.
	my @arr = NERefinements::LoadTabSepFile($inFile);
	my $saved = 0;
	#Run all refinements in the order defined by the refinement order definition string.
	for my $configParam ( @refDefArray  )
	{
		if ($configParam =~ /T.*/)
		{
			#Tag Equal lemmas below the threshold, which is defined within the parameter ("T_0.#", where "#" are decimal digits of the parameter).
			my $probab = $configParam;
			$probab =~ s/^T_//g;
			NERefinements::TagEqualLemmas(\@arr, $probab);
		}
		elsif ($configParam =~ /C.*/)
		{
			@arr = NERefinements::ConsolidateEqualEntities(\@arr);
		}
		elsif ($configParam =~ /R.*/)
		{
			#Remove NE tags below the threshold, which is defined within the parameter ("R_0.#", where "#" are decimal digits of the parameter).
			my $probab = $configParam;
			$probab =~ s/^R_//g;
			@arr = NERefinements::RemoveLowProbNETags(\@arr,0,$probab);
		}
		elsif ($configParam =~ /L.*/)
		{
			NERefinements::CleanBracketsAndQuotations(\@arr);
		}
		elsif ($configParam =~ /S.*/)
		{
			NERefinements::RemoveCorruptStringTokensFromNETags(\@arr);
		}
		elsif ($configParam =~ /N.*/)
		{
			NERefinements::RemoveCorruptStringNETags(\@arr);
		}
		elsif ($configParam =~ /A.*/)
		{
			#Add missing line breaks, which are defined in the input data, but are not defined in the NE tagged results.
			NERefinements::SaveTabSepDoc(\@arr,$tempFile);
			NEUtilities::AddMissingLineBreaks($posTaggedFile, $tempFile, $outFile);
			unlink ($tempFile);
			$saved = 1;
			#As after adding line breaks, the file is saved, no further refinements may be carried out (simply because these would again remove all line breaks).
			last;
		}
	}
	if ($saved == 0)
	{
		NERefinements::SaveTabSepDoc(\@arr,$outFile);
	}
}

#====Method: ConsolidateEqualEntitiesOnFile=====
#Title:        ConsolidateEqualEntitiesOnFile
#Description:  Calls the consolidation of equal entities method on a single file (argument 0) and writes the results to a file (argument 1).
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      09.06.2011
#Last Changes: 09.06.2011. by Kārlis Gediņš, SIA Tilde.
#===============================================
sub ConsolidateEqualEntitiesOnFile
{
	if (not(defined($_[0])&&defined($_[1])))
	{ 
		print STDERR "Usage: ConsolidateEqualEntitiesOnFile [Input file] [Output file]\n"; die;
	}
	
	my @arr= NERefinements::LoadTabSepFile($_[0]);
	@arr = NERefinements::ConsolidateEqualEntities(\@arr);
	NERefinements::SaveTabSepDoc(\@arr,$_[1]);
}

#=========Method: CalculateProbibility==========
#Title:        CalculateProbibility
#Description: Calculates the overall probability of a full NE tag from separate NE token probabilities (argument 0).
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      09.06.2011
#Last Changes: 04.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
sub CalculateProbibility
{
	if (!defined($_[0]))
	{ 
		print STDERR "Usage: CalculateProbibility [Probability array]\n"; die;
	}
	my @Probabilities = @{$_[0]};
	#The array @Probabilities is a one dimensional array containing decimal values.
	my $arrLen = @Probabilities;
	my $Probability = 0;
	#Sum all probabilities.
	for my $i (0 .. $#Probabilities)
	{
		 $Probability += $Probabilities[$i];
	}
	#Return 0 if no values defined or the sum is 0.
	if ($Probability == 0 || $arrLen == 0)
	{
		return 0;
	}
	#Return the average if at least one non-zero probability exists.
	return $Probability/($arrLen);
}

#=========Method: LoadTabSepFile==========
#Title:        LoadTabSepFile
#Description:  Reads all tokens form a tab separated file (argument 0) into an array.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      09.06.2011
#Last Changes: 04.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
sub LoadTabSepFile
{
	if (!defined($_[0]))
	{ 
		print STDERR "Usage: LoadTabSepFile [Input file]\n"; die;
	}
	open(FIN, "<:encoding(UTF-8)", $_[0]);
	my @tokens;
	#The array @tokens may contain tab separated values of any length and amount.
	
	#Read each line of the tab separated file.
	while (my $line = <FIN>)
	{
		$line =~ s/^\x{FEFF}//;# Strips BOM symbol.
		$line =~ s/\n//;
		$line =~ s/\r//;
		if ($line =~ /^\s*$/) {next;}
		my @token = split(/\t/,$line );
		push @tokens , [@token];
	}
	close FIN;
	return @tokens;
}

#=========Method: SaveTabSepDoc==========
#Title:        SaveTabSepDoc
#Description:  Saves the values of an array (argument 0) into a tab separated file (argument 1).
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      09.06.2011
#Last Changes: 04.07.2011. by Mārcis Pinnis, SIA Tilde.
#===============================================
sub SaveTabSepDoc
{
	if (not(defined($_[0])&& defined($_[1])))
	{ 
		print STDERR "Usage: SaveTabSepDoc [Array of tokens] [Output file]\n"; die;
	}
	my @arr =  @{$_[0]};
	#The array @arr may be a two dimensional array of any length or structure (as long as its second dimension is supported by the "join" function).
	 
	open(FOUT, ">:encoding(UTF-8)", $_[1]);
	#Print each token to the output file.
	for my $i (0 .. $#arr)
	{	
		#Tab separators are automatically added by the join function.
		print FOUT join("\t",@{$arr[$i]})."\n";
	}
	close FOUT;
}


#=========Method: GetFullNETagsFromTokens==========
#Title:        GetFullNETagsFromTokens
#Description:  Iterates trough an array of tokens (argument 0) and finds full NE tags from NE tokens and returns them as an array.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      09.06.2011
#Last Changes: 09.06.2011. by Kārlis Gediņš, SIA Tilde.
#===============================================
sub GetFullNETagsFromTokens
{
	if (not(defined($_[0])))
	{ 
		print STDERR "Usage: GetFullNETagsFromTokens [Reference To An Array Of Tokens] [Min Avereage Probability](optional) [Min First NE Token Probability](optional)\n"; die;
	}
	my @NEtags;
	#Iterates trough an array of tokens (argument 0).
	#Argument 0 - @{$_[0]} - an array of tokens.
	# @{$_[0]}[$i] - @token.
	# @token[$i] has values: [0] - token, [1] – POS tag, [2] - lemma, [3] - morphological tag, [4] - token start position(in text) in line, [5] - starting line, [6] - token end position, [7] - end line, [8] – NE tag, [9] - NE Tag probability (optional).
	#Usage:
	#	The array of Tokens is used to search for NE tags.
	#	Each token contains a value that holds NE tags(${$_[0]}[][8]) and from these values Full NE tags are extracted and their positions saved.
	for my $i (0 .. $#{$_[0]}) 
	{
		# NE tokens beginning with "B-" indicate full NE tag beggining. 
		if(${$_[0]}[$i][8]=~ /^B/) 
		{
			my $pos=1;
			my $endPos = ${$_[0]}[$i][6];
			my $endLine = ${$_[0]}[$i][7];
			
			my $lemmas = ${$_[0]}[$i][2];
			my @probabilities;
			push @probabilities, ${$_[0]}[$i][9];
			
			# If this is not the last token, search for full NE tag ending.
			if($i+$pos <= $#{$_[0]} ) 
			{	
				#Finds full NE tag end position (all trailing tokens with NE tag starting whit 'I')			
				while (${$_[0]}[$i+$pos][8] =~ /^I/) 
				{							
					$endPos = ${$_[0]}[$i+$pos][6];
					$endLine = ${$_[0]}[$i+$pos][7];
					#Combines the lemmas in a string separated with a white space.
					$lemmas .= " ".${$_[0]}[$i+$pos][2]; 
					push @probabilities, ${$_[0]}[$i+$pos][9]; #Saves the NE token probabilities in an array.
					$pos++;
					if($i+$pos > $#{$_[0]} ){last;} 
				}
			}
			
			#Gets full NE tag name from the NE token of the first token.
			my $NETagName = ${$_[0]}[$i][8]; 
			$NETagName =~ s/^B-//;
			$NETagName =  NEUtilities::GetNEtagType($NETagName);
			#Calculates full NE tag probability from all NE token probabilities in the full tag.
			my $AvgProb = CalculateProbibility(\@probabilities);
			#If optional argument 1 defined and not "0" replaces all tags with full NE tag probability lower than the arguments value whit an empty tag.
			if ($_[1])
			{ 
				if ( $_[1] > $AvgProb ) {$NETagName = "O";}
			}
			#If optional argument 2 defined and not "0" replaces all tags with first NE token probability lower than the arguments value whit an empty tag.
			if ($_[2])
			{ 
				if ( $_[2] > ${$_[0]}[$i][9] ) {$NETagName = "O";}
			}
			#Saves the NE tags:  [0-3] - positions, [4] - lemmas separated by a white space ,[5] NE tag name, [6] NE Tag probability.
			my @NETag =(${$_[0]}[$i][4], ${$_[0]}[$i][5], $endPos, $endLine, $lemmas,$NETagName,$AvgProb); 
			
			push @NEtags , [@NETag];
		}
		
	}
	return @NEtags;
}


#=========Method: WriteNEtagsInTokens==========
#Title:        WriteNEtagsInTokens
#Description:  Writes full NE tags (from an array (argument 1)) as NE tokens assigned to tokens in to token array (argument 0).  
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      09.06.2011
#Last Changes: 09.06.2011. by Kārlis Gediņš, SIA Tilde.
#===============================================
sub WriteNEtagsInTokens
{
	#Argument 0 - @{$_[0]} - reference to an array of tokens.
	# @{$_[0]}[$i] - @token.
	# @token has values: [0] - token, [1] – POS tag, [2] - lemma, [3] - morphological tag, [4] - token start position(in text) in line, [5] - starting line, [6] - token end position, [7] - end line, [8] – NE tag, [9] - NE Tag probability (optional).
	#Usage:
	#	In the array of tokens, the method changes NE tags (${$_[0]}[][8]) of those tokens, whose positions match with an NE tag form the array defined by argument 1.
	
	##<== FOR DEBUGING
	# open (ERRO,">:encoding(UTF-8)", "test.log");
		# for my $j (0 .. $#{$_[0]}) 
		# {	
			# print ERRO  join("\t",@{${$_[0]}[$j]})."\n";
		# }	
		# print ERRO "\n\n\n\n\n\n";
		# for my $j (0 .. $#{$_[1]}) 
		# {	
			# print ERRO  join("\t",@{${$_[1]}[$j]})."\n";
		# }
	##<==END
		
	for my $i (0 .. $#{$_[0]})  
	{
		#Argument 1 - @{$_[1]} - reference to an array of NE Tags.
		# @{$_[1]}[$i] - @NETag.
		# @NETag has values:[0] - start line, [1] - start position, [2] - end line, [3] - end position, [4] - lemmas separated by a white space ,[5] NE tag name, [6] NE Tag probability.
		#Usage: @NETags array is used to search for position matchch with a token(argument 1). In case of a match the token is assigned with the NE tag it matches.
		for my $j (0 .. $#{$_[1]}) 
		{	
			#Finds tokens that have the same starting positions as NE tags.
			if ((${$_[0]}[$i][4] == ${$_[1]}[$j][0]) && (${$_[0]}[$i][5] == ${$_[1]}[$j][1]) ) 
			{
				#Changes the NE tag to the new one.
				my $pr=0;
							
				#Changes the first NE token to the Full NE tags respective short version.
				if ( ${$_[1]}[$j][5] ne "O" ) { ${$_[0]}[$i][8] = 'B-'.NEUtilities::GetShortTagType(${$_[1]}[$j][5]); }
				#Handles empty tag separately because it has no short form.
				else {  ${$_[0]}[$i][8] = "O"; }
				
				my $cont=0;
				while (1)
				{	
					#Adds trailing NE tags until full NE tag positions matches with token end position.
					#print ERRO "${$_[0]}[$i + $cont][6] == ${$_[1]}[$j][2] and (${$_[0]}[$i + $cont][7] == ${$_[1]}[$j][3]) \n";
					if ((${$_[0]}[$i + $cont][6] == ${$_[1]}[$j][2]) && (${$_[0]}[$i + $cont][7] == ${$_[1]}[$j][3])) {last;}
					$cont++;
					
					#if ($pr==1){ #<==FOR DEBUGGING!
					#print STDERR ${$_[0]}[$i + $cont][0]." ".${$_[1]}[$j][5]."\n";} #<==FOR DEBUGGING!
					
					if (${$_[1]}[$j][5] ne "O") {${$_[0]}[$i + $cont][8] = 'I-'.NEUtilities::GetShortTagType(${$_[1]}[$j][5]);}
					else {${$_[0]}[$i + $cont][8]="O";}
				}
			}
		}
	}
	
	# close ERRO;#<==FOR DEBUGGING!
}

#=========Method: ConsolidateEqualEntities==========
#Title:        ConsolidateEqualEntities
#Description:  Finds NE tags with equal lemmas and overwrites their tags with the ones that have the highest NE Tag probability.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      09.06.2011
#Last Changes: 09.06.2011. by Kārlis Gediņš, SIA Tilde.
#===============================================
sub ConsolidateEqualEntities
{

	if (not($_[0])){die " ERR:No paramters given to ConsolidateEqualEntities\n";}
	
	#Argument 0 - reference to an array of tokens.
	#Token array has values: [0] - token, [1] – POS tag, [2] - lemma, [3] - morphological tag, [4] - token start position(in text) in line, [5] - starting line, [6] - token end position, [7] - end line, [8] – NE tag, [9] - NE Tag probability.
	#Usage: Argument 0 is reference to an array contains a list of tokens and all changes made to NE tags are saved in this array. It is also used to extract current Ne tags assigned to tokens.
	my @tokens = @{$_[0]};
	
	#Gets an array of NE tags.
	# @NETags - A array of @NETag arrays.
	# @NETag has values:[0] - start line, [1] - start position, [2] - end line, [3] - end position, [4] - lemmas separated by a white space ,[5] NE tag name, [6] NE Tag probability.
	#Usage:@NETags is used to get unique lemmas and their NE tags and NE tag probability.
	my @NEtags = GetFullNETagsFromTokens(\@tokens); 

	# %neProbabHash: {first key} - lemma, {second key} - NE tag, [0] - count of occurrences, [1] - minimum NE Tag probability, [2] maximum NE Tag probability, [3] - the sum of all NE Tag probability values.
	#Usage: Used to find and evaluate different NE tags for the same lemmas.
	my %neProbabHash;
	
	#Puts NE tag lammas and full NE tags in hashes.
	for my $i (0 .. $#NEtags)  
	{
		my $lemmaKey = $NEtags[$i][4];#Lemma as primary hash key.
		my $NEKey = $NEtags[$i][5]; #Ne tag name as hash key that is linked to the lemma.
		#Creates a hash of hashes to link NE tagged lemmas separated by a space with possible NE tag types assigned to these lemmas. Saves the NE tag count, sum of probabilities and maximum and minimum probability values in an array linked to NE tag type keys.
		if (defined  $neProbabHash{$lemmaKey}) 
		{
			if (defined  $neProbabHash{$lemmaKey}{$NEKey})
			{
				$neProbabHash{$lemmaKey}{$NEKey}[0]++;
				if ($neProbabHash{$lemmaKey}{$NEKey}[1] > $NEtags[$i][6])
				{
					$neProbabHash{$lemmaKey}{$NEKey}[1] = $NEtags[$i][6];
				}
				if ($neProbabHash{$lemmaKey}{$NEKey}[2] < $NEtags[$i][6])
				{
					$neProbabHash{$lemmaKey}{$NEKey}[2] = $NEtags[$i][6];
				}
				$neProbabHash{$lemmaKey}{$NEKey}[3] += $NEtags[$i][6];
			}
			else
			{
				$neProbabHash{$lemmaKey}{$NEKey} =  ();
				push @{$neProbabHash{$lemmaKey}{$NEKey}} , (1,$NEtags[$i][6],$NEtags[$i][6],$NEtags[$i][6]);	
			}
			
			
		}
		else
		{
			$neProbabHash{$lemmaKey} =  ();
			$neProbabHash{$lemmaKey}{$NEKey} =  ();
			push @{$neProbabHash{$lemmaKey}{$NEKey}} , (1,$NEtags[$i][6],$NEtags[$i][6],$NEtags[$i][6]);	
			
		}
		
	}
	
	
	#Iterates trough lemmas. Keys1- NE tagged lemmas.
	foreach my $keys1 (keys %neProbabHash )
	{	
		my $count = 0 ; 
		#Mārcis: Added counting of NE occurrances regardless of type.
		#$count++ foreach keys %{$neProbabHash{$keys1}}; #Count possible Ne tags for a lemma.
		my $countOfOccurs = 0;
		for my $keys2 (keys %{$neProbabHash{$keys1}})
		{
			$count++;
			$countOfOccurs += $neProbabHash{$keys1}{$keys2}[0];
		}
		#Mārcis: end of changes
		
		#if ($keys1=~/.*Lattelecom.*/) {print $keys1."\n";} #<==FOR DEBUGGING!
		#If there is more than a single NE tag for the same lemma calculate which has the highest NE Tag probability.
		if($count > 1) 
		{
			my @maxVal = ([-1,"1"],[-1,"2"],[-1,"3"]); # 0 - MAX AVG 1 - MAX MIN 2- MAX MAX
				
			for my $keys2 (keys %{$neProbabHash{$keys1}})
			{
				#if ($keys1=~/.*Lattelecom.*/) {print "\t".$keys2."\n";} #<==FOR DEBUGGING!
				#Finds the NE tag with the highest minimum NE Tag probability.
				if($maxVal[2][0] < $neProbabHash{$keys1}{$keys2}[2]) 
				{ 
					$maxVal[2][0] = $neProbabHash{$keys1}{$keys2}[2]; 
					$maxVal[2][1] = $keys2;  
				}
				
				#Finds the NE tag with the highest maximum NE Tag probability.
				if($maxVal[1][0] < $neProbabHash{$keys1}{$keys2}[1]) 
				{ 
					$maxVal[1][0] = $neProbabHash{$keys1}{$keys2}[1]; 
					$maxVal[1][1] = $keys2;  
				}
				
				#Finds the NE tag with the highest average NE Tag probability.
				#Mārcis: Changed the algorithm to favour higher frequency NEs.
				#if( $maxVal[0][0] < ($neProbabHash{$keys1}{$keys2}[3]/$neProbabHash{$keys1}{$keys2}[0]) )
				if( $maxVal[0][0] < ($neProbabHash{$keys1}{$keys2}[3]/$countOfOccurs) )
				{ 
					$maxVal[0][0] = $neProbabHash{$keys1}{$keys2}[3]/$countOfOccurs; 
					$maxVal[0][1] = $keys2;  
				}
				#If two NE Tags have the same probability don’t retag anything.  
				if( $maxVal[0][0] == ($neProbabHash{$keys1}{$keys2}[3]/$countOfOccurs))
				{
					#Equals to 5 because five is greater than one, which is the highest probability to a NE tag.
					$maxVal[0][0] = 5; 
					$maxVal[0][1] = "NotEquaToAnyThing";  
				}
				
			}
			
			
			#Finds the NE tag with the highest NE Tag probability changes the ne tags for all the lemmas ne NE tag array.
			if (($maxVal[0][1] eq $maxVal[1][1]) || ($maxVal[0][1] eq $maxVal[2][1]) )
			{
				for my $i (0 .. $#NEtags) 
				{
					 if ($NEtags[$i][4] eq $keys1) 
					 {
						$NEtags[$i][5] = $maxVal[0][1]; 
					 }
				}
			}

		}
	}

	WriteNEtagsInTokens(\@tokens,\@NEtags);
	
	return @tokens;

}
#=========Method: RemoveLowProbNETags==========
#Title:        RemoveLowProbNETags
#Description:  Removes NE tags with probably lower than a number (argument 0) and returns the changed array.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      09.06.2011
#Last Changes: 09.06.2011. by Kārlis Gediņš, SIA Tilde.
#===============================================

sub RemoveLowProbNETags
{	
	if (not($_[0])){print STDERR "Usage: RemoveLowProbNETags [Array Of Tokens] [Min Avereage Probability](optional) [Min First NE Token Probability](optional)\n"; die;}
	#Argument 0 - reference to an array of tokens.
	#Each token has values: [0] - token, [1] – POS tag, [2] - lemma, [3] - morphological tag, [4] - token start position(in text) in line, [5] - starting line, [6] - token end position, [7] - end line, [8] – NE tag, [9] - NE Tag probability.
	#Usage: 
	#	The array of Tokens is used to extract NE tags from them and then write new ones in to them.
	#	Each token conatins a value that holds NE tags(${$_[0]}[][8]) is changed if NE Tag probability of the full NE tag id below threshold.
	
	my @tokens  = @{$_[0]};
	my @NEtags = GetFullNETagsFromTokens(\@tokens,$_[1],$_[2]);

	WriteNEtagsInTokens(\@tokens,\@NEtags);
	return @tokens;
}
#=========Method: TagEqualLemmas==========
#Title:        TagEqualLemmas
#Description:  Tags untagged lemmas if the same lemmas have been tagged in other places with probability above threshold (argument 1). Changes the array passed doesn’t return anything.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      17.06.2011
#Last Changes: 20.06.2011. by Kārlis Gediņš, SIA Tilde.
#===============================================

sub TagEqualLemmas
{
	if(not(($_[0])&&($_[1])))
	{
		die "usage TagEqualLemmas [reference To Array Of Tokens] [Threshold]";
	}
	#Argument 0 - @{$_[0]} - reference to an array of tokens.
	# @{$_[0]}[$i] - @token.
	# @token has values: [0] - token, [1] – POS tag, [2] - lemma, [3] - morphological tag, [4] - token start position(in text) in line, [5] - starting line, [6] - token end position, [7] - end line, [8] – NE tag, [9] - NE Tag probability (optional).
	#Usage:
	#	The array of Tokens is used to extract lemmas linked to NE tags and write new NE tags in them.
	#	Each token contains a value that holds NE tag(${$_[0]}[][8]) which is saved in an array of full NE tags and is changed if positions match with new NE Tag (argument 1).

	
	#Gets an array of full NE tags.
	# @NETags -A list of @NETag arrays.
	# @NETag has values:[0] - start line, [1] - start position, [2] - end line, [3] - end position, [4] - lemmas separated by a white space ,[5] NE tag name, [6] NE Tag probability.
	#Usage: Contains full NE tags extracted from tokens. A hash of unique Lemmas and their NE probabilities is extracted from this array.
	my @NEtags = GetFullNETagsFromTokens(\@{$_[0]});
	
	#%lemmaHash: {key} - lemmas inside NE tag separated my a spece, [0] NE tag, [1] array of lemmas , [2] - lemma count, [3] - possibly of NE tag being correct
	#Usage: Used to save unique lemmas and thier NE tags un NE tag probobility.
	my %lemmaHash;
	
	#Puts lemmas as keys in hashes where they are linked to their NE tags and the probability of these tags.
	for my $i (0 .. $#NEtags)  
	{
		my $lemmaKey = $NEtags[$i][4]; 
		if (defined  $lemmaHash{$lemmaKey}) #If the tagged lemma exists corrects the tags probability
		{
			#Checks NE tags match - if not, doesn't tag the lemmas.
			if ($lemmaHash{$lemmaKey}[0] ne $NEtags[$i][5] )  
			{
				$lemmaHash{$lemmaKey}[0] = "TagMismatch";
			}
			#Gets tag count and sum of probabilities to get average possibly of the tag being correct.
			$lemmaHash{$lemmaKey}[2]++;
			$lemmaHash{$lemmaKey}[3] += $NEtags[$i][6]; 
		}
		else#If the tagged lemma doesn’t exist creates a hash value.
		{
			$lemmaHash{$lemmaKey} =  ();
			my @splitLemaKey = split (/ /,$lemmaKey); #Saves split lemmas for code optimization. 
			#Saves hash.
			push @{$lemmaHash{$lemmaKey}} , ($NEtags[$i][5],\@splitLemaKey,1,$NEtags[$i][6]);	
			
		}	
	}
	

	#Tags the longest lemmas first to avoid tagging lemmas that are part of other lemmas.
	for my $lemas (sort {length($b) <=> length($a)}(keys %lemmaHash))
	{
		#Ignores lemmas whose tags have mismatched.
		if($lemmaHash{$lemas}[0] eq "TagMismatch"){next;} 
		#Skip if NE tag average probability is smaller than threshold.
		if ($lemmaHash{$lemas}[3]/$lemmaHash{$lemas}[2] < $_[1]){next;} 
		
		for my $i (0 .. $#{$_[0]})  
		{
			#Checks all untagged tokens.
			if(${$_[0]}[$i][8] eq "O")
			{
				#Searches for tokens whose lemmas match NE tags first lemma.
				if ($lemmaHash{$lemas}[1][0] eq ${$_[0]}[$i][2]) 
				{
					#Trailing lemmas mismatch indicator.
					my $matches = 1; 
					#Compare the rest of NE tag's lemmas to trailing token lemmas.
					for my $j (1 .. $#{$lemmaHash{$lemas}[1]}) 
					{
						if(defined ${$_[0]}[$i+$j]) 
						{ 
							if (${$_[0]}[$i+$j] ne $lemmaHash{$lemas}[1][$j]) {$matches=0; last;}
							#Break if trailing token lemma is already tagged.
							if(${$_[0]}[$i+$j][8] ne "O") {$matches=0; last;}	
						}
						else {$matches=0; last;} #Stops comparing and saves a false value if a mismatch occurs.
					}
					
					if ($matches) # If NE tag lemmas match token lemmas adds NE tags to tokens.
					{
						#Gets the short NE tag name and adds "B-" to mark NE tag beginning.
						${$_[0]}[$i][8] = "B-".NEUtilities::GetShortTagType($lemmaHash{$lemas}[0]);
						#Gets the short NE tag name and adds "I-" to all trailing tokens with the same tag.
						for my $j (1 .. $#{$lemmaHash{$lemas}[1]})
						{
							${$_[0]}[$i+$j][8] = "I-".NEUtilities::GetShortTagType($lemmaHash{$lemas}[0]);
						}
					}	
				}	
			
			}
		
		}
	}
	

}

#=========Method: CleanBracketsAndQuotations==========
#Title:        CleanBracketsAndQuotations
#Description:  Finds NE tags with brackets or quotation marks as tokens (argument 0). If the bracket or quotation mark is in the middle, the method tries to find nearly located opening or closing bracket or quotation mark (depending on the found one) token and tag the sequence till the quotation mark or bracket (including) as a part of the named entity.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      13.07.2011
#Last Changes: 13.07.2011. by Kārlis Gediņš, SIA Tilde.
#===============================================
sub CleanBracketsAndQuotations
{
	#@tokens -a list of tokens (see desccription above)
	my @tokens = @{$_[0]};
	# %bracketHash =(
	#					[opening brakets] => [closing brakets]
	#Usage: used to link starting brackets with closing brakes and to find out whether they are unopened or unclosed.
	my $leftEgeLength = 3;
	my %bracketHash =(
						"[" => ["]",0],
						"(" => [")",0],
						"{" => ["}",0]
						);
	# %qouteMarkList =(
	#					[qoute mark] => [nothing]
	#Usage: used to check if token is one of possible quote marks.
	my %qouteMarkList =(
					"\"" => "",
					"\x{201C}" => "",
					"\x{201D}" => "",
					"\x{201E}" => "",
					"\x{00AB}" => "",
					"\x{00BB}" => "",
					"\x{2033}" => ""
					);
	
	for my $i (0 .. $#tokens)
	{
		#Finds NE tag beggining.
		if ($tokens[$i][8] =~ /^B/)
		{
			#$qouteMarks is used to count qoute marks in NE tag.
			my $qouteMarks = 0;
			#$NETagLenght is used in combination with $i to find out NE Tag position in @tokens array.
			my $NETagLenght = 1;
			
			#Looks for all brackets and increases the number asigned to the braket in hash by 1 if the current token is an opening bracket and decreases by 1 if it is a closing bracket. This is done to find missing opening or closing brackets.
			for my $startBraketKey (keys %bracketHash)
			{
				if ($tokens[$i][0] eq $startBraketKey) 
				{
					$bracketHash{$startBraketKey}[1]++;
				}
				if ($tokens[$i][0] eq $bracketHash{$startBraketKey}[0]) 
				{
					$bracketHash{$startBraketKey}[1]--;
				}
			}
			#If the current tokens is a qoute mark increases $qouteMarks counter by one.
			if(defined( $qouteMarkList{$tokens[$i][0]} )) {$qouteMarks ++;}
			#If the first token in NE tag is not the last token look for trailing NE tokens and count quote marks and brackets in them.
			if ($i+$NETagLenght <= $#tokens)
			{
				while ($tokens[$i+$NETagLenght][8] =~ /^I/)
				{
					#Looks for all brackets and increases the number asigned to the braket in hash by 1 if the current token is an opening bracket and decreases by 1 if it is a closing bracket. This is done to find missing opening or closing brackets.
					for my $startBraketKey (keys %bracketHash)
					{
						if ($tokens[$i+$NETagLenght][0] eq $startBraketKey) 
						{
							$bracketHash{$startBraketKey}[1]++;
						}
						if ($tokens[$i+$NETagLenght][0] eq $bracketHash{$startBraketKey}[0]) 
						{
							$bracketHash{$startBraketKey}[1]--;
						}
					}
					#If the current tokens is a qoute mark increases $qouteMarks counter by one.
					if(defined( $qouteMarkList{$tokens[$i+$NETagLenght][0]} )) {$qouteMarks ++;}
					#Counts tokens in NE tag.
					$NETagLenght++;
					if($i+$NETagLenght >= $#tokens){last;}
				}
				#Decreases $NETagLenght to get accurate NE tag position.
				$NETagLenght--;
				
				#Handles bracket or quote mismatch cases.
				
				#Counts both unclosed brakes and qoutes. If there is more than one unclosed braket or qoute remove the whole NE tag.
				my $unclosedCount = 0;
				for my $startBraketKey (keys %bracketHash)
				{
						#Counts absolute values to count both missing opening and closing brackets.
						$unclosedCount += abs($bracketHash{$startBraketKey}[1]);
				}
				if ($qouteMarks % 2) {$unclosedCount++;}
				
				if ($unclosedCount == 0){next;}
				elsif($unclosedCount > 1)
				{
					#Removes The NE tag.
					for my $g ($i .. ($i+$NETagLenght))
					{
						$tokens[$g][8] = "O";
					}
					next;
				}
				
				#Handles unopened or unclosed brackets.
				
				for my $startBraketKey (keys %bracketHash)
				{
					#If there is a missing opening bracket:
					if ($bracketHash{$startBraketKey}[1] > 0)
					{
						#Removes starting token from the NE tag if it is an opening bracket.
						if ($tokens[$i][0] eq $startBraketKey)
						{
							if ($NETagLenght > 0)
							{
								$tokens[$i+1][8] = $tokens[$i][8];
							}
							$tokens[$i][8] = "O";
						}
						#Removes end token from the NE tag if it is an opening braked.
						elsif ($tokens[$i + $NETagLenght][0] eq $startBraketKey)
						{	
							$tokens[$i+$NETagLenght][8] = "O";
						}
						#Looks for a closing bracket to the right (in text) of the NE tag and if one is found add it to the NE tag.
						else
						{
							my $goRight = 1;
							#$foundMatch - false by default.
							my $foundMatch = 0;
							#Iterates trough the tokens to the right.
							while (($i+$goRight+$NETagLenght) < $#tokens)
							{
								#Exits loop after pre-defined number ($leftEgeLength) of tokens have been checked.
								if (($leftEgeLength-$goRight) <= 0) {last;}
								#Exits the loop if the current token is inside another NE tag.
								if ($tokens[$i+$goRight+$NETagLenght][8] ne "O") {last;}
								#If current token is a closing bracket - save the position and exit loop.
								if ($tokens[$i+$goRight+$NETagLenght][0] eq $bracketHash{$startBraketKey}[0]) 
								{
									$foundMatch = $i+$goRight+$NETagLenght; last;
								}
								#Go to next token.
								$goRight++;
							}
							#If match found add it to the NE tag.
							if ($foundMatch)
							{
								#Get NE tag type and replace the starting NE token with trailing NE token.
								my $tokenNEtag = $tokens[$i][8];
								$tokenNEtag =~s/^B/I/;
								#Add token until the closing bracket to the NE tag.
								for my $z (1 .. ($foundMatch-$NETagLenght-$i))
								{
						
									$tokens[$i+$z+$NETagLenght][8] = $tokenNEtag;
								}
							}
						}
												
					}
					#If there is a missing closing bracket:
					elsif ($bracketHash{$startBraketKey}[1] < 0)
					{
						#Removes starting token from the NE tag if it is an closing bracket.
						if ($tokens[$i][0] eq $bracketHash{$startBraketKey})
						{
							if ($NETagLenght > 0)
							{
								$tokens[$i+1][8] = $tokens[$i][8];
							}
							$tokens[$i][8] = "O";
						}
						#Removes starting token from the NE tag if it is an closing bracket.
						elsif ($tokens[$i + $NETagLenght][0] eq $bracketHash{$startBraketKey})
						{
							$tokens[$i+$NETagLenght][8] = "O";
						}
						#Looks for an opening bracket to the right (in text) of the NE tag and if one is found add it to the NE tag.
						else
						{
							my $goLeft = -1;
							my $foundMatch = -1;
							#Iterates trough the tokens to the left.
							while (($i+$goLeft)>=0)
							{
								#Exits loop after pre-defined number ($leftEgeLength) of tokens have been checked.
								if (($goLeft+$leftEgeLength) <= 0) {last;}
								#Exits the loop if the current token is inside another NE tag.
								if ($tokens[$i+$goLeft][8] ne "O") {last;}
								#If current token is a closing bracket - save the position and exit loop.
								if ($tokens[$i+$goLeft][0] eq $startBraketKey) {$foundMatch = $i+$goLeft}
								$goLeft--;
							}
							#If match found add it to the NE tag.
							if ($foundMatch != -1)
							{
								#Get NE tag type and replace the starting NE token with trailing NE token.
								my $tokenNEtag = $tokens[$i][8];
								$tokenNEtag =~ s/^B/I/ ;
								for my $z (($foundMatch-$i) .. 0 )
								{
									#Add a starting NE token ($tokens[$i][8] - NE the beginning before changes) to the first token.
									if($z == ($foundMatch-$i)) {$tokens[$i+$z][8] = $tokens[$i][8]}
									else 
									{
										$tokens[$i+$z][8] = $tokenNEtag;
									}
								}
							}
						}
					}
					
					$bracketHash{$startBraketKey}[1] = 0;
				}
				
				#If there is an odd number of qoutes in NE tag:
				if ($qouteMarks % 2)
				{
					#If both starting tag and end tags are quote marks remove the NE tag from the token that has another quote mark next to it. 
					if ( (defined( $qouteMarkList{$tokens[$i+$NETagLenght][0]})) && (defined( $qouteMarkList{$tokens[$i][0]} )) )
					{		
						if ($NETagLenght == 0){ $tokens[$i+$NETagLenght][8] = "O"; }
						else
						{
							
							if($tokens[$i][0]  eq $tokens[$i+1][0])
							{
								$tokens[$i+1][8] = $tokens[$i][8];
								$tokens[$i][8] = "O";	
							}
							else
							{
								$tokens[$i+$NETagLenght][8] = "O";
							}
						}
					}
					#.
					elsif (defined( $qouteMarkList{$tokens[$i+$NETagLenght][0]} ))
					{
						$tokens[$i+$NETagLenght][8] = "O";
					}
					#Removes starting token from the NE tag if it is a quote mark.
					elsif (defined( $qouteMarkList{$tokens[$i][0]} ))
					{
						if ($NETagLenght > 0)
						{
							$tokens[$i+1][8] = $tokens[$i][8];
						}
						$tokens[$i][8] = "O";
					}
					#Looks for a quote mark to the right (in text) of the NE tag and if one is found add it to the NE tag.
					#If one is not found looks for one left (in text) (done the same way as with the brackets).
					else
					{
						my $goRight = 1;
						my $foundRightMatch = 0;
						while (($i+$goRight+$NETagLenght)<$#tokens)
						{
							if (($leftEgeLength-$goRight) <= 0) {last;}
							if ($tokens[$i+$goRight+$NETagLenght][8] ne "O") {last;}
							if (defined( $qouteMarkList{$tokens[$i+$goRight+$NETagLenght][0]} )) {$foundRightMatch = $i+$goRight+$NETagLenght; last;}
							$goRight++;
						}
						
						if ($foundRightMatch)
						{
							my $tokenNEtag = $tokens[$i][8];
							$tokenNEtag =~s/^B/I/;
							for my $z (1 .. ($foundRightMatch-$NETagLenght-$i))
							{
									$tokens[$i+$z+$NETagLenght][8] = $tokenNEtag;
				
							}
						}
						else
						{
							my $goLeft = -1;
							my $foundLeftMatch = -1;
							while (($i+$goLeft)>0)
							{
								if (($goLeft+$leftEgeLength) <= 0) {last;}
								if ($tokens[$i+$goLeft][8] ne "O") {last;}
								if (defined( $qouteMarkList{$tokens[$i+$goLeft][0]} )) {$foundLeftMatch = $i+$goLeft}
								$goLeft--;
							}
							if ($foundLeftMatch != -1)
							{
								my $tokenNEtag = $tokens[$i][8];
								$tokenNEtag =~ s/^B/I/ ;
								for my $z (($foundLeftMatch-$i) .. 0 )
								{
									if($z == ($foundLeftMatch-$i)) {$tokens[$i+$z][8] = $tokens[$i][8]}
									else 
									{
										$tokens[$i+$z][8] = $tokenNEtag;
									}
								}
							}
						}
					}
	
				}
			}				
		
		}
	
	}
	
}

#=========Method: RemoveCorruptStringTokensFromNETags==========
#Title:        RemoveCorruptStringTokensFromNETags
#Description:  Removes tokens containing defined strings from NE tags if they are in the beginning or at the end of the NE tag. Removes the whole NE tag if in they are in the middle of the NE tag. 
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      14.07.2011
#Last Changes: 14.07.2011. by Kārlis Gediņš, SIA Tilde.
#===============================================	
sub RemoveCorruptStringTokensFromNETags 
{
	#@tokens -a list of tokens (see desccription above)
	my @tokens = @{$_[0]};
	
	# @faultyStrings - strings to look for to remove NE tags.
	my @faultyStrings =  (":\/\/");
	#Combines the array of multiple strings in to a single pattern.
	my $patern = join ("\|",@faultyStrings);
	#Gets full NE tagd positions.
	for my $i (0 .. $#tokens)
	{
		
		if ($tokens[$i][8] =~ /^B/)
		{
			#$NETagLenght is used in combination with $i to find out NE Tag position in @tokens array.
			my $NETagLenght = 1;
			if ($i+$NETagLenght <= $#tokens)
			{
				while ($tokens[$i+$NETagLenght][8] =~ /^I/)
				{
					#Counts tokens in NE tag.
					$NETagLenght++;
					if($i+$NETagLenght >= $#tokens){last;}
				}
				#Reduces the $NETagLenght so that $tokens[$i + $NETagLenght] would be the last token in NE tag.
				$NETagLenght--;
			}
			
			#Iterates trough tokens in NE tag. Looks for the string pattern in the token and removes the NE token or the whole NE tag according to the token position in NE tag.
			for my $j ($i .. ($i+$NETagLenght))
			{
				#If matches one of the paterns.
				if($tokens[$j][0] =~ /(?:$patern)/) 
				{
					#Removes NE tag the form token if the token is at the beginning or end of the NE tag.
					if($j == $i)
					{
						if ($NETagLenght > 0)
						{
							$tokens[$j+1][8] = $tokens[$j][8];
						}
						$tokens[$j][8] = "O";
					}
					elsif ($j ==($i+$NETagLenght) )
					{
						$tokens[$j][8] = "O";
					}
					#Removes the whole NE tag if the string is at the middle of the NE tag.
					else
					{
						for my $g ($i .. ($i+$NETagLenght))
						{
							$tokens[$g][8] = "O";
						}
						last;
					}
				}
			}
		}
	}
}

#=========Method: RemoveCorruptStringNETags==========
#Title:        RemoveCorruptStringNETags
#Description:  Removes NE tag if tokens in this tag contain some defined amount of a string value.
#Author:       Kārlis Gediņš, SIA Tilde.
#Created:      14.07.2011
#Last Changes: 14.07.2011. by Kārlis Gediņš, SIA Tilde.
#===============================================		
sub RemoveCorruptStringNETags
{
	#@tokens -a list of tokens (see desccription above)
	my @tokens = @{$_[0]};
	
	#The hash key is the NE type to which a limitation is applied. The value consists of a two element array - a text fragment, which occurrence count is limited within a single NE by the second element (allowed are the number minus one occurrence).		
	#Usage: is used to store patterns and number of maximum matches for the patterns assigned to NE tag types.
	my %Paterns =(
				"PERS" => [["\/",2]],
				"ORG" => [["\/",2]]
				);
				

	#Iterates trough tokens to look for NE tags.
	for my $i (0 .. $#tokens)
	{

		#If the current token is the beginning of a NE tag:
		if ($tokens[$i][8] =~ /^B/)
		{
			# $currentNETagType – the short form of the NE tag.
			my $currentNETagType = $tokens[$i][8];
			$currentNETagType =~ s/^B-//;
			my $NETagLenght = 1;
			
			# $tokens - tokens separated by a white space.
			my $tokens = $tokens[$i][0];
			#If the current token is not the last token in the token array save all the tokens in the NE tag and save NE tag length.
			if ($i+$NETagLenght <= $#tokens)
			{
				while ($tokens[$i+$NETagLenght][8] =~ /^I/)
				{
					$tokens .= " ".$tokens[$i+$NETagLenght][0];
					$NETagLenght++;
					if($i+$NETagLenght >= $#tokens){last;}
				}	
			}
			#Reduces the $NETagLenght so that $tokens[$i + $NETagLenght] would be the last token in NE tag.
			$NETagLenght--;
			
			for my $NETagsTypes (keys %Paterns)
			{
				#If the NE tag is in the %Pattern hash:
				 if ($NETagsTypes eq $currentNETagType)
				 {
					#Look for all the patterns in the tokens.
					for my $g (0 .. $#{$Paterns{$NETagsTypes}})
					{
						#Split the lemmas in with the pattern to count how many times it matches.
						my $patern = $Paterns{$NETagsTypes}[$g][0];
						my @temp = split (/$patern/,$tokens);
						#Remove the NE tag if the pattern has matched more times than the member of maximum matches.
						if ($#temp >= $Paterns{$NETagsTypes}[$g][1])
						{
							for my $z ($i .. ($i+$NETagLenght))
							{
								$tokens[$z][8] = "O";
							}
							last;
						}
					}
				 }
			}
		}
	}

}

1;
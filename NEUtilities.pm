#!/usr/bin/perl
#=============File: NEUtilities.pm==============
#Title:        NEUtilities.pm - Utility Functions for NE Training, Result Postprocessing and Testing.
#Description:  The Module contains data processing utilities used in NE training, result postprocessing and testing purposes.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 04.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================

package NEUtilities;

use File::Basename;
use File::Copy;
use strict;
use warnings;
use Switch;


#=========Method: GetShortTagType==========
#Title:        GetShortTagType
#Description:  Returns 1 if the short NE tag (argument 0) is valid for gazetteer extraction. If not - returns 0.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      08.07.2011.
#Last Changes: 08.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub IsValidGazetteerType
{
	if (not(defined $_[0])) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: IsValidGazetteerType [Short NE Tag Type]\n"; 
		die;
	}
	#Tag types (if new ones are added they should be put here)
	switch ($_[0]) 
	{
		case ("LOC")	{ return 1;}
		case ("ORG")	{ return 1;}
		case ("PERS")	{ return 1;}
		case ("PROD")	{ return 0;}
		case ("DATE")	{ return 0;}
		case ("TIME")	{ return 0;}
		case ("MON")	{ return 0;}
		else		{return 0; }
	}
}

#=========Method: GetShortTagType==========
#Title:        GetShortTagType
#Description:  Returns a short NE tag type from a MUC-7 NE tag type (argument 0)
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      09.06.2011.
#Last Changes: 01.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub GetShortTagType
{
	if (not(defined $_[0])) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: GetShortTagType [MUC-7 NE Tag Type]\n"; 
		die;
	}
	#Tag types (if new ones are added they should be put here)
	switch ($_[0]) 
	{
		case ('LOCATION')	{ return "LOC";}
		case ('ORGANIZATION')	{ return "ORG";}
		case ('PERSON')	{ return "PERS";}
		case ('PRODUCT')	{ return "PROD";}
		case ('DATE')	{ return "DATE";}
		case ('TIME')	{ return "TIME";}
		case ('MONEY')	{ return "MON";}
		else		{return ""; }
	}
}

#=========Method: GetNEtagType==========
#Title:        GetNEtagType
#Description:  Returns a MUC-7 NE tag type from a short NE tag type (argument 0).
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      09.06.2011.
#Last Changes: 01.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub GetNEtagType
{
	if (not(defined $_[0])) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: GetNEtagType [Short NE Tag Type]\n"; 
		die;
	}
	switch ($_[0]) 
	{
	case ("LOC")	{ return 'LOCATION';}
	case ("ORG")	{ return 'ORGANIZATION';}
	case ("PERS")	{ return 'PERSON';}
	case ("PROD")	{ return 'PRODUCT';}
	case ("DATE")	{ return 'DATE';}
	case ("TIME")	{ return 'TIME';}
	case ("MON")	{ return 'MONEY';}
	else		{return ""; }
	}
}

#=========Method: GetMucTagName==========
#Title:        GetMucTagName
#Description:  Returns a MUC-7 tag name from a short NE tag type (argument 0).
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      09.06.2011.
#Last Changes: 01.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub GetMucTagName
{
	if (not(defined $_[0])) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: GetMucTagName [Short NE Tag Type]\n"; 
		die;
	}
	switch ($_[0]) 
	{
	case ("LOC")	{ return 'ENAMEX';}
	case ("ORG")	{ return 'ENAMEX';}
	case ("PERS")	{ return 'ENAMEX';}
	case ("PROD")	{ return 'ENAMEX';}
	case ("DATE")	{ return 'TIMEX';}
	case ("TIME")	{ return 'TIMEX';}
	case ("MON")	{ return 'NUMEX';}
	else		{return ""; }
	}
}

#=========Method: AddMissingLineBreaks==========
#Title:        AddMissingLineBreaks
#Description:  Postprocesses POS tagged (argument 0) and NE tagged (argument 1) files and creates a result file (argument 2), which contains NE tagged data from the NE tagged file including empty lines from the POS tagged document. 
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      25.05.2011.
#Last Changes: 30.05.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub AddMissingLineBreaks
{
	#Checking if all required parameters are set.
	if (defined($_[0])&&defined($_[1])&&defined($_[2]))
	{ 
		open(POS_TAGGED, "<:encoding(UTF-8)", $_[0]);
		open(NE_TAGGED, "<:encoding(UTF-8)", $_[1]);
		open(RES_FILE, ">:encoding(UTF-8)", $_[2]);
	}
	else {print STDERR "Usage: AddMissingLineBreaks [POS tagged file] [NE tagged file] [Result file]\n"; die;}
	
	#Read all lines from the POS tagged file.
	my $printSpace = 0;
	my $printNull = 0;
	while (<POS_TAGGED>)
	{
		my $line = $_;
		$line =~ s/^\x{FEFF}//; # cuts BOM
		$line =~ s/\n//;
		$line =~ s/\r//;
		#In the case of an empty line print an empty line in the result file.
		if ($line eq "")
		{
			$printSpace++;
		}
		else
		{
			#If the current pos tagged file line is non-empty, print the first non-empty NE tagged file line in the result file.
			my $line2;
			while (<NE_TAGGED>)
			{
				$line2 = $_;
				$line2 =~ s/^\x{FEFF}//; # cuts BOM
				$line2 =~ s/\n//;
				$line2 =~ s/\r//;
				if ($line2 ne "") #Checking, whether the current line is a non-empty line.
				{
					# @lineData is a two dimensional array. The First dimension represents a single token, but the second dimension represents the token attributes. The attributes (array columns) are as follows:
					# [[0:Token], [1:POS], [2:Lemma], [3:Morpho Tag], [4:Row From], [5:Column From], [6:Row To], [7:Column To], [8: NE Tag], [9: NE Tag Probability]]
					my @lineData = split(/\t/,$line2);
					my $len = @lineData;
					my $changeToB = 0;
					#If empty lines were found in the POS file, these have to be either added or ignored (if within one line named entities span over two sentences).
					if ($printSpace>0)
					{
						if ($len>=9)
						{
							if (!($lineData[8] =~ /^I.*$/))
							{
								#If emty lines are present and the current non-empty line is not a middle entity, print out empty lines.
								while ($printSpace>0)
								{
									print RES_FILE "\n";
									$printSpace--;
								}
							}
							elsif ($printSpace>1)
							{
								#If empty lines (more than one indicates newlines in input data) are present and the current is a middle entity, the empty lines are printed out.
								while ($printSpace>0)
								{
									print RES_FILE "\n";
									$printSpace--;
								}
								my $probab = $lineData[9];
								#If the probability of the predicted token is more than 0.8 (a simple threshold), the current token will be (re)tagged as a NE beginning.
								if ($probab >0.8)
								{
									$changeToB = 1;
									$printNull = 0;
								}
								#Othervise, if the threshold is not reached, the entity ending will be removed and replaced with non-entity mark-up ("O").
								else
								{
									$printNull = 1;
									$changeToB = 0;
								}
							}
						}
						$printSpace = 0;
					}
					if ($changeToB==1) # Changes the entity type to a beginning entity (if the threshold was met - see above).
					{
						my $tag = $lineData[8];
						$tag =~ s/I-/B-/g;
						print RES_FILE $lineData[0]."\t".$lineData[1]."\t".$lineData[2]."\t".$lineData[3]."\t".$lineData[4]."\t".$lineData[5]."\t".$lineData[6]."\t".$lineData[7]."\t".$tag."\t".$lineData[9]."\n";
						$printNull = 0;
					}
					elsif ($printNull==1) #Removes the NE tag of all next line middle entity tokens that are spanning from the previous non-empty line if the probability of the NE tag of the first entity of the next line was less than the threshold (see above).
					{
						if ($lineData[8] =~ /^I.*$/)
						{
							#Instead of the marked NE tag, print "O".
							print RES_FILE $lineData[0]."\t".$lineData[1]."\t".$lineData[2]."\t".$lineData[3]."\t".$lineData[4]."\t".$lineData[5]."\t".$lineData[6]."\t".$lineData[7]."\tO\t".$lineData[9]."\n";
						}
						else
						{
							#If a valid entity (either "B-..." or "O") is found, reset the requirement to remove NE mark-up.
							$printNull = 0;
							print RES_FILE $line2."\n";
						}
					}
					else
					{
						print RES_FILE $line2."\n";
					}
					last; #Print only one non-empty line in each NE tagged file reading loop.
				}
			}
		}
	}
	#Add trailing empty lines if any present in the POS tagged document.
	if ($printSpace> 0)
	{
		while ($printSpace>0)
		{
			print RES_FILE "\n";
			$printSpace--;
		}
	}
	#Closing all files!
	close POS_TAGGED;
	close NE_TAGGED;
	close RES_FILE;
}

#========Method: CreateDirectoryFileList========
#Title:        CreateDirectoryFileList
#Description:  Creates a comma separated list of file addresses in a directory and returns the result as a string.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      26.05.2011.
#Last Changes: 26.05.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub CreateDirectoryFileList
{
	#Checking if all required parameters are set.
	my $directoryPath="";
	my $fileList = "";
	my $inExt = ".*";
	if (defined($_[0])&& defined($_[1]))
	{
		$directoryPath=$_[0];
		$inExt = $_[1];
	}
	else
	{
		#If even one input parameter is missing print a usage comment and close the application.
		print STDERR "Usage: CreateDirectoryFileList [Directory path] [File extension]";
		die;
	}
	
	#Convert path to UNIX style directory path and add a slash at the end (if missing).
	$directoryPath =~ s/\\/\//g;
	if ($directoryPath !~ /.*\/$/)
	{
		$directoryPath = $directoryPath."/";
	}
	#Create the list of file paths.
	opendir(DIR, $directoryPath) or die "[NEUtilities::CreateDirectoryFileList] Can't opendir $directoryPath: $!";
	while (defined(my $file = readdir(DIR)))
	{
		my $fileAddress = $directoryPath.$file;
		#Check for the correct extension. Also check that the entry is not a directory.
		my $ucFile = uc($file);
		my $ucExt = uc($inExt);
		if ($ucFile =~ /.*\.$ucExt$/ && not(-d $fileAddress))
		{
			#Add the file path to the list.
			if ($fileList eq "")
			{
				$fileList=$directoryPath.$file;
			}
			else
			{
				$fileList.=",".$directoryPath.$file;
			}
		}
	}
	#Return the comma separated file path list.
	return $fileList;
}

#===========Method: AddPropertyToFile===========
#Title:        AddPropertyToFile
#Description:  Adds a property at the end of the property file as a new line.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      26.05.2011.
#Last Changes: 26.05.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub AddPropertyToFile
{
	my $propFile = "";
	my $propName = "";
	my $propValue = "";
	
	if (defined($_[0])&& defined($_[1])&& defined($_[2]))
	{
		$propFile=$_[0];
		$propName = $_[1];
		$propValue = $_[2];
	}
	else
	{
		#If even one input parameter is missing print a usage comment and close the application.
		print STDERR "Usage: AddPropertyToFile [Property file path] [Property name] [Property value]";
		die;
	}
	#Trimming both ends to check for empty parameters.
	$propName =~ s/^\s+//;
	$propName =~ s/\s+$//;
	$propValue =~ s/^\s+//;
	$propValue =~ s/\s+$//;
	if ($propName eq "" || $propValue eq "")
	{
		#If even one input parameter is empty print a usage comment and close the application.
		print STDERR "Usage: AddPropertyToFile [Property file path] [Property name] [Property value]";
		die;
	}
	open (OUTFILE, '>>'.$propFile) or die "[NEUtilities::AddPropertyToFile] Can't open file $propFile: $!";
	binmode OUTFILE, ":utf8";
	print OUTFILE "\n".$propName." = ".$propValue."\n";
	close OUTFILE;
}

#=========Method: ReadPropertyFromFile==========
#Title:        ReadPropertyFromFile
#Description:  Reads a property (argument 1) value from the property file (argument 0).
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      08.07.2011.
#Last Changes: 08.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub ReadPropertyFromFile
{
	my $propFile = "";
	my $propName = "";
	
	if (defined($_[0])&& defined($_[1]))
	{
		$propFile=$_[0];
		$propName = $_[1];
	}
	else
	{
		#If even one input parameter is missing print a usage comment and close the application.
		print STDERR "Usage: ReadPropertyFromFile [Property file path] [Property name]";
		die;
	}
	#Trimming both ends to check for empty parameters.
	$propName =~ s/^\s+//;
	$propName =~ s/\s+$//;
	if ($propName eq "")
	{
		#If even one input parameter is empty print a usage comment and close the application.
		print STDERR "Usage: ReadPropertyFromFile [Property file path] [Property name]";
		die;
	}
	
	open (IN, $propFile);
	binmode IN, ":utf8";
	my $result = "";
	while (<IN>)#Reading each line of the file.
	{
		my $line = $_;
		#Remove BOM and trim both ends of the line.
		$line =~ s/^\x{FEFF}//g;
		$line =~ s/^\s+//g;
		$line =~ s/\s+$//g;
		#Split the line in two parts ([Property name] = [Property value]). If the value contains "=", ignore such entries (won't be supported by this method).
		my @splitLine = split (/=/,$line);
		if (@splitLine==2)
		{
			my $currPropName = $splitLine[0];
			$currPropName =~ s/^\s+//g;
			$currPropName =~ s/\s+$//g;
			my $currPropValue = $splitLine[1];
			$currPropValue =~ s/^\s+//g;
			$currPropValue =~ s/\s+$//g;
			#Once the property names are equal, return the value to the user.
			if ($currPropName eq $propName)
			{
				$result = $currPropValue;
				last;
			}
		}
	}
	close IN;
	return $result;
}


#=========Method: ChangePropertyInFile==========
#Title:        ChangePropertyInFile
#Description:  Changes a property (argument 1) value (argument 2) in the property file (argument 0).
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      08.07.2011.
#Last Changes: 08.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub ChangePropertyInFile
{
	my $propFile = "";
	my $propName = "";
	my $propValue = "";
	
	if (defined($_[0])&& defined($_[1])&& defined($_[2]))
	{
		$propFile=$_[0];
		$propName = $_[1];
		$propValue = $_[2];
	}
	else
	{
		#If even one input parameter is missing print a usage comment and close the application.
		print STDERR "Usage: ChangePropertyInFile [Property file path] [Property name] [Property value]";
		die;
	}
	#Trimming both ends to check for empty parameters.
	$propName =~ s/^\s+//;
	$propName =~ s/\s+$//;
	$propValue =~ s/^\s+//;
	$propValue =~ s/\s+$//;
	if ($propName eq "" || $propValue eq "" )
	{
		#If even one input parameter is empty print a usage comment and close the application.
		print STDERR "Usage: ReadPropertyFromFile [Property file path] [Property name]";
		die;
	}
	
	my $newPropString = "";
	my $added = 0;
	
	open (IN, $propFile);
	binmode IN, ":utf8";
	
	
	while (<IN>)#Reading each line of the file.
	{
		my $line = $_;
		#Remove BOM and trim both ends of the line.
		$line =~ s/^\x{FEFF}//g;
		$line =~ s/^\s+//g;
		$line =~ s/\s+$//g;
		#Split the line in two parts ([Property name] = [Property value]). If the value contains "=", ignore such entries (won't be supported by this method).
		my @splitLine = split (/=/,$line);
		if (@splitLine==2)
		{
			my $currPropName = $splitLine[0];
			$currPropName =~ s/^\s+//g;
			$currPropName =~ s/\s+$//g;
			my $currPropValue = $splitLine[1];
			$currPropValue =~ s/^\s+//g;
			$currPropValue =~ s/\s+$//g;
			#Once the property names are equal, change the output line with the given.
			if ($currPropName eq $propName)
			{
				$newPropString.=$propName." = ".$propValue."\n";
				$added = 1;
			}
			else
			{
				$newPropString.=$line."\n";
			}
		}
		else
		{
			$newPropString.=$line."\n";
		}
	}
	close IN;
	
	if ($added == 0)
	{
		$newPropString.=$propName." = ".$propValue."\n";
	}
	
	open (OUTFILE, '>'.$propFile) or die "[NEUtilities::ChangePropertyInFile] Can't open file $propFile: $!";
	binmode OUTFILE, ":utf8";
	print OUTFILE $newPropString;
	close OUTFILE;
}

#==========Method: AppendAFileToAFile===========
#Title:        AppendAFileToAFile
#Description:  Appends a file (argument 0) contents to another file (argument 1).
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      18.07.2011.
#Last Changes: 18.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub AppendAFileToAFile
{
	my $inputFile = "";
	my $outputFile = "";
	if (defined($_[0]) && defined($_[1]))
	{
		$inputFile=$_[0];
		$outputFile=$_[1];
	}
	else
	{
		print STDERR "Usage: AppendFileToAFile [Input file] [Output file]";
		die;
	}	
	open(OUT, ">>:encoding(UTF-8)", $outputFile);
	open (IN, $inputFile);
	binmode IN, ":utf8";
	while (<IN>)#Reading each line of the file.
	{
		my $line = $_;
		#Remove BOM and trim both ends of the line.
		$line =~ s/^\x{FEFF}//g;
		$line =~ s/^\s+//g;
		$line =~ s/\s+$//g;
		#Append the line to the output file;
		print OUT $line."\n";
	}
	close IN;
	close OUT;
}

#=======Method: ReadExistingGazetteerData=======
#Title:        ReadExistingGazetteerData
#Description:  Reads all lines of the tab-separated gazetteer files (argument 0) and returns a hash table containing unique lines.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      08.07.2011.
#Last Changes: 08.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub ReadExistingGazetteerData
{
	my $propFiles = "";
	if (defined($_[0]))
	{
		$propFiles=$_[0];
	}
	else
	{
		print STDERR "Usage: ReadExistingGazetteerData [Property file paths separated by a comma]";
		die;
	}
	#Trimming both ends to check for empty parameters.
	$propFiles =~ s/^\s+//;
	$propFiles =~ s/\s+$//;
	my %returnHash;
	if ($propFiles eq "")
	{
		return %returnHash;
	}
	my @fileArray = split (/[;,]/,$propFiles);
	for my $file (@fileArray)
	{
		$file =~ s/^\s+//g;
		$file =~ s/\s+$//g;
		open (IN, $file);
		binmode IN, ":utf8";
		while (<IN>)#Reading each line of the file.
		{
			my $line = $_;
			#Remove BOM and trim both ends of the line.
			$line =~ s/^\x{FEFF}//g;
			$line =~ s/^\s+//g;
			$line =~ s/\s+$//g;
			#Add the line to the hash table.
			if (!defined($returnHash{$line}))
			{
				$returnHash{$line} = 1;
			}
		}
		close IN;
	}
	return %returnHash;
}

#========Method: CopyFilesFromDirectory=========
#Title:        CopyFilesFromDirectory
#Description:  Copies files with the specified extension (argument 2) from one directory (argument 0) to another (argument 1), thereby changing the file extension to a new extension (argument 3).
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      01.07.2011.
#Last Changes: 01.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub CopyFilesFromDirectory
{
	#Validate input parameters.
	if (not(defined($_[0])&& defined($_[1])&& defined($_[2])&& defined($_[3])))
	{
		print STDERR "Usage: CopyFilesFromDirectory [Source directory] [Target directory] [Source extension] [Target extension]";
		die;
	}
	#Set and clean the directory from which to copy files.
	my $directoryFrom = $_[0];
	$directoryFrom =~ s/\\/\//g;
	if ($directoryFrom !~ /.*\/$/)
	{
		$directoryFrom .= "/";
	}
	#Set and clean the directory to which to copy files.
	my $directoryTo = $_[1];
	$directoryTo =~ s/\\/\//g;
	if ($directoryTo !~ /.*\/$/)
	{
		$directoryTo .= "/";
	}
	my $fromExt = $_[2]; #Set the source file extension.
	my $toExt = $_[3]; #Set the target file extension.
	
	#Copy each file that matches the source extension from the source directory to the target directory.
	opendir(DIR, $directoryFrom) or die "[NEUtilities::CopyFilesFromDirectory] Can't open directory \"$directoryFrom\": $!";
	while (defined(my $file = readdir(DIR)))
	{
		my $fullNameFrom = $directoryFrom.$file;
		#Only use valid files with the correct extension! Also check that the entry is not a directory.
		my $ucFile = uc($file);
		my $ucExt = uc($fromExt);
		if ($ucFile =~ /.*\.$ucExt$/ && not(-d $fullNameFrom))
		{
			my $fileTo = $file;
			$fileTo =~ s/$fromExt/$toExt/g;
			my $fullNameTo = $directoryTo.$fileTo;
			copy($fullNameFrom,$fullNameTo) or die "[NEUtilities::CopyFilesFromDirectory] Failed to copy file \"$fullNameFrom\" to \"$fullNameTo\":\n\t$!";
		}
	}
	close DIR;
}
#========Method: MoveFilesFromDirectory=========
#Title:        MoveFilesFromDirectory
#Description:  Moves files with the specified extension (argument 2) from one directory (argument 0) to another (argument 1), thereby changing the file extension to a new extension (argument 3).
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      01.07.2011.
#Last Changes: 01.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub MoveFilesFromDirectory
{
	#Validate input parameters.
	if (not(defined($_[0])&& defined($_[1])&& defined($_[2])&& defined($_[3])))
	{
		print STDERR "Usage: MoveFilesFromDirectory [Source directory] [Target directory] [Source extension] [Target extension]";
		die;
	}
	#Set and clean the directory from which to move files.
	my $directoryFrom = $_[0];
	$directoryFrom =~ s/\\/\//g;
	if ($directoryFrom !~ /.*\/$/)
	{
		$directoryFrom .= "/";
	}
	#Set and clean the directory to which to move files.
	my $directoryTo = $_[1];
	$directoryTo =~ s/\\/\//g;
	if ($directoryTo !~ /.*\/$/)
	{
		$directoryTo .= "/";
	}
	my $fromExt = $_[2]; #Set the source file extension.
	my $toExt = $_[3]; #Set the target file extension.
	
	#Move each file that matches the source extension from the source directory to the target directory.
	opendir(DIR, $directoryFrom) or die "[NEUtilities::MoveFilesFromDirectory] Can't open directory \"$directoryFrom\": $!";
	while (defined(my $file = readdir(DIR)))
	{
		my $fullNameFrom = $directoryFrom.$file;
		#Only use valid files with the correct extension! Also check that the entry is not a directory.
		my $ucFile = uc($file);
		my $ucExt = uc($fromExt);
		if ($ucFile =~ /.*\.$fromExt$/ && not(-d $fullNameFrom))
		{
			my $fileTo = $file;
			$fileTo =~ s/$fromExt/$toExt/g;
			my $fullNameTo = $directoryTo.$fileTo;
			move($fullNameFrom,$fullNameTo) or die "[NEUtilities::MoveFilesFromDirectory] Failed to move file \"$fullNameFrom\" to \"$fullNameTo\":\n\t$!";
		}
	}
	close DIR;
}

#==========Method: CopyFilesFromArray===========
#Title:        CopyFilesFromArray
#Description:  Copies files specified in the array (argument 1) to the target directory (argument 0). File extensions are not changed.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      01.07.2011.
#Last Changes: 01.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub CopyFilesFromArray
{
	#Set the target directory and the array, which contains files that have to be copied.
	# The array @filesToCopy is a one dimensional array containing file addresses.
	my ($directoryTo, @filesToCopy) = @_;
	$directoryTo =~ s/\\/\//g;
	if ($directoryTo !~ /.*\/$/)
	{
		$directoryTo .= "/";
	}
	
	#Validate input parameters.
	if (not(defined($directoryTo)))
	{
		print STDERR "Usage: CopyFilesFromDirectory [Target directory] [Source file array]";
		die;
	}
	
	#Copy each file from the array to the target directory.
	foreach my $fileFrom (@filesToCopy)
	{
		#Check that the entry is not a directory.
		if (not(-d $fileFrom))
		{
			my ($fromFileName,$fromFilePath,$fromFileSuffix) = fileparse($fileFrom,qr/\.[^.]*/);
			my $fileTo = $directoryTo.$fromFileName.$fromFileSuffix;
			copy($fileFrom,$fileTo) or die "[NEUtilities::CopyFilesFromArray] Failed to copy file \"$fileFrom\" to \"$fileTo\":\n\t$!";
		}
		else
		{
			print STDERR "[NEUtilities::CopyFilesFromArray] Array contains an entry that is not a file: \"$fileFrom\".\n";
		}
	}
}

#==========Method: MoveFilesFromArray===========
#Title:        MoveFilesFromArray
#Description:  Moves files specified in the array (argument 1) to the target directory (argument 0). File extensions are not changed.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      01.07.2011.
#Last Changes: 01.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub MoveFilesFromArray
{
	#Set the target directory and the array, which contains files that have to be moved.
	# The array @filesToMove is a one dimensional array containing file addresses.
	my ($directoryTo, @filesToMove) = @_;
	$directoryTo =~ s/\\/\//g;
	if ($directoryTo !~ /.*\/$/)
	{
		$directoryTo .= "/";
	}
	
	#Validate input parameters.
	if (not(defined($directoryTo)))
	{
		print STDERR "Usage: MoveFilesFromDirectory [Target directory] [Source file array]";
		die;
	}
	
	#Move each file from the array to the target directory.
	foreach my $fileFrom (@filesToMove)
	{
		#Check that the entry is not a directory.
		if (not(-d $fileFrom))
		{
			my ($fromFileName,$fromFilePath,$fromFileSuffix) = fileparse($fileFrom,qr/\.[^.]*/);
			my $fileTo = $directoryTo.$fromFileName.$fromFileSuffix;
			move($fileFrom,$fileTo) or die "[NEUtilities::MoveFilesFromArray] Failed to move file \"$fileFrom\" to \"$fileTo\":\n\t$!";
		}
		else
		{
			print STDERR "[NEUtilities::MoveFilesFromArray] Array contains an entry that is not a file: \"$fileFrom\".\n";
		}
	}
}

#============Method: GetRandomFiles=============
#Title:        GetRandomFiles
#Description:  Returns a number (argument 1) of random file addresses with the specified extension (argument 2) from a directory (argument 0).
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      27.06.2011
#Last Changes: 01.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub GetRandomFiles
{
	
	if (not((defined $_[0])&&(defined $_[1])&&(defined $_[2]))) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: GetRandomFiles [Folder] [Number Of Files] [Extension]\n"; 
		die;
	}
	#Set the source directory and normalize its directory separating characters.
	my $directory= $_[0];
	$directory =~ s/\\/\//g;
	if ($directory !~ /.*\/$/)
	{
		$directory .= "/"; 
	}
	#The array @files is a one dimensional array containing file names.
	my @files;
	my $extension = $_[2];
	$extension =~ s/^\.//g;
	opendir(DIR,$directory) or die "can't open $directory : $!\n";
	while (defined(my $file = readdir(DIR))) #Reads all file names in an array.
	{
		if( ($file eq '.') || ($file eq '..') ){ next;}  #Ignores file names if they are "." or "..".
		my $ucFile = uc($file);
		my $ucExt = uc($extension);
		if ($ucFile =~ /\.$ucExt/) {push @files, $file; }
	}
	#The array @resultFileNames is a one dimensional array containing file addresses.
	my @resultFileNames;
	for my $i (1 .. $_[1])
	{
		# my $resultFile
		#Saves a random filename in the result array and deletes it from the initial array so they don’t repeat.
		push(@resultFileNames,$directory.splice(@files,int(rand($#files)),1));
	}
	## FOR DEBUGING
	# print "\n";
	# for my $i (0 .. $#resultFileNames)
	# {
		# print $resultFileNames[$i]."\n";
	# }
	## END
	return @resultFileNames;
}

#========Method: GetTokenTotalResultLine========
#Title:        GetTokenTotalResultLine
#Description:  Finds and returns the line containing token total evaluation results in a given evaluation file (argument 0).
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      01.07.2011.
#Last Changes: 01.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub GetTokenTotalResultLine
{
	if (not(defined $_[0])) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: GetTokenTotalResultLine [Evaluation input file]\n"; 
		die;
	}
	my $file = $_[0];
	open (IN, $file);
	binmode IN, ":utf8";
	my $totalToken = "";
	my $totalNe = "";
	while (<IN>)#Reading each line of the file.
	{
		my $line = $_;
		#Remove BOM, replace decimal character "." to "," (LV local) and trim both ends of the line.
		$line =~ s/^\x{FEFF}//g;
		$line =~ s/\./,/g; # COMMENT LINE FOR EN LOCAL (or if your local decimal separator is a point - ".")!
		$line =~ s/^\s+//g;
		$line =~ s/\s+$//g;
		#If the desired line is found, Return the result.
		if ($line =~ /^TOTAL_TOKEN.*/)
		{
			#$line =~ s/TOTAL_TOKEN//g; #Commented out as the total type information needs to be preserved.
			#$line =~ s/^\s+//g;
			$totalToken = $line;
			last;
		}
	}
	close IN;
	return $totalToken;
}


#==========Method: GetTokenResultEntry==========
#Title:        GetTokenResultEntry
#Description:  Finds and returns a specific token total result entry in a given evaluation file (argument 0). The result entry is specified by the column number (argument 1). The column numbers are: 1 - recall, 2 - precision, 3 - accuracy, 4 - F-measure. 
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      09.07.2011.
#Last Changes: 13.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub GetTokenResultEntry
{
	if (not(defined $_[0] && defined $_[1])) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: GetTokenResultEntry [Evaluation input file] [Column number]\n"; 
		die;
	}
	my $file = $_[0];
	my $column = $_[1];
	open (IN, $file);
	binmode IN, ":utf8";
	my $totalToken = 0;
	while (<IN>)#Reading each line of the file.
	{
		my $line = $_;
		#Remove BOM, trim both ends of the line.
		$line =~ s/^\x{FEFF}//g;
		$line =~ s/^\s+//g;
		$line =~ s/\s+$//g;
		#If the desired line is found, Return the result.
		if ($line =~ /^TOTAL_TOKEN.*/)
		{
			my @lineArray = split (/\t/,$line);
			if (!defined $lineArray[$column] || $lineArray[$column] eq "-")
			{
				$totalToken = 0.0;
			}
			else
			{
				$totalToken = $lineArray[$column];
			}
			last;
		}
	}
	close IN;
	return $totalToken;
}

#==========Method: GetNETotalResultLine=========
#Title:        GetNETotalResultLine
#Description:  Finds and returns the line containing full named entity total evaluation results in a given evaluation file (argument 0).
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      01.07.2011.
#Last Changes: 01.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub GetNETotalResultLine
{
	if (not(defined $_[0])) #Cheking if all required parematers exist.
	{ 
		print STDERR "Usage: GetNETotalResultLine [Evaluation input file]\n"; 
		die;
	}
	my $file = $_[0];
	open (IN, $file);
	binmode IN, ":utf8";
	my $totalToken = "";
	my $totalNe = "";
	while (<IN>)#Reading each line of the file.
	{
		my $line = $_;
		#Remove BOM, replace decimal character "." to "," (LV local) and trim both ends of the line.
		$line =~ s/^\x{FEFF}//g;
		$line =~ s/\./,/g; # COMMENT LINE FOR EN LOCAL (or if your local decimal separator is a point - ".")!
		$line =~ s/^\s+//g;
		$line =~ s/\s+$//g;
		#If the desired line is found, Return the result.
		if ($line =~ /^TOTAL_NE.*/)
		{
			#$line =~ s/TOTAL_NE//g; #Commented out as the total type information needs to be preserved.
			#$line =~ s/^\s+//g;
			$totalToken = $line;
			last;
		}
	}
	close IN;
	return $totalToken;
}

#=================Method: GetTime===============
#Title:        GetTime
#Description:  For logging purposes returns the current system time.
#Author:       Mârcis Pinnis, SIA Tilde.
#Created:      21.07.2011.
#Last Changes: 22.07.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================
sub GetTime
{
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	my $year = 1900 + $yearOffset;
	$month++;
	return "$dayOfMonth.$month.$year $hour:$minute:$second";
}

1;

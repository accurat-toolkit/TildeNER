#!/usr/bin/perl
#===========File: Tag.pm===============
#Title:        Tag.pm - text tagging Module for Tilde's POS Taggers.
#Description:  The Module contains text Tagger method.
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 03.08.2011. by Mârcis Pinnis, SIA Tilde.
#===============================================

package Tag;

use strict;
use warnings;
#=========Method: Tag==========
#Title:        Tag
#Description:  POS tags a document (parameter 2) using a specified POS tagger (parameter 0) and language code (parameter 1). The results are saved in a data file (parameter 3). Deletes temp files if argument 5 exists and true, and removes empty lines if specified (argument 6).
#Author:       Kârlis Gediòð, SIA Tilde.
#Created:      May, 2011.
#Last Changes: 26.05.2011. by Kârlis Gediòð, SIA Tilde.
#===============================================
sub TagText 
{
	if (not( (defined $_[0]) && (defined $_[1]) && (defined $_[2]) && (defined $_[3]) ))
	{
		die "Usage: Tag::TagText [POS Tagger Name] [Language] [Palaintext File] [Output File]\n";
	}
	
	BEGIN 
	{
		use FindBin '$Bin'; #Gets the path of this file.
		push @INC, "$Bin";  #Add this path to places where perl is searching for modules.
	}
	my @agrs;
	my	$outputDir = $_[3];
	#Gets output file path if it is passed.
	if ($outputDir =~ /[\\\/]/)
	{
		$outputDir =~ s/\\/\//gi;
		$outputDir =~ s/\/[^\/]+$//gi;
		$outputDir.="\/";
	}
	else
	{
	$outputDir = "";
	}

	if (defined $outputDir && $outputDir ne "")
	{
		unless(-d $outputDir){mkdir $outputDir or die "Cannot find or create output directory \"$outputDir\".";}
	}	
	#Gets filename if output file parameter has a path.
	my $filename =$_[2]; 
	$filename =~ s/^.*\/([^\/]+)$/$1/gi;
	$filename =~ s/\.[^\.]+$//g;
	use NEPreprocess;
	
	my $uTagger = uc ($_[1]);
	my $uLang = uc ($_[0]);

	if ($uTagger eq "TREE") #Tree tagger option.
	{
		my @tokAgrs;
		my $tagData;
		if($uLang eq 'EN') #Checks language options and sets the needed parameters to call the tagger for English.
		{
			@tokAgrs=($Bin."/Treetagger/tokenize.pl",$_[2] ,"$outputDir$filename.tokenized","-e","-a","$Bin/Treetagger/english-abbreviations");
			$tagData ="$Bin/Treetagger/english.par";
		}
			elsif($uLang eq 'ES')  #Checks language options and sets the needed parameters to call the tagger for Spanish.
		{
			@tokAgrs=($Bin."/Treetagger/tokenize.pl","$_[2]" ,"$outputDir$filename.tokenized","","-a","$Bin/Treetagger/spanish-abbreviations");
			$tagData = "$Bin/Treetagger/spanish-utf8.par";
			undef @tokAgrs;
		}
		elsif($uLang eq 'EL') #Checks language options and sets the needed parameters to call the tagger for Greek.
		
		{
			@tokAgrs=( $Bin."/Treetagger/tokenize.pl","$_[2]" ,"$outputDir$filename.tokenized");
			$tagData ="$Bin/Treetagger/greek-utf8.par";
		}
		elsif($uLang eq 'IT') #Checks language options and sets the needed parameters to call the tagger for Itlaian.
		{
			@tokAgrs=($Bin."/Treetagger/tokenize.pl","$_[2]" ,"$outputDir$filename.tokenized","-i","-a","$Bin/Treetagger/italian-abbreviations");
			$tagData = "$Bin/Treetagger/italian-utf8.par";
		}
		elsif($uLang eq 'DE') #Checks language options and sets the needed parameters to call the tagger for German.
		{
			@tokAgrs=($Bin."/Treetagger/tokenize.pl","$_[2]" ,"$outputDir$filename.tokenized","","-a","$Bin/Treetagger/german-abbreviations");
			$tagData = "$Bin/Treetagger/german-utf8.par";
		}
		elsif($uLang eq 'FR') #Checks language options and sets the needed parameters to call the tagger for Friench.
		{
			@tokAgrs=($Bin."/Treetagger/tokenize.pl","$_[2]" ,"$outputDir$filename.tokenized","-f","-a","$Bin/Treetagger/french-abbreviations");
			$tagData = "$Bin/Treetagger/french-utf8.par";
		}
		elsif($uLang eq 'ET') #Checks language options and sets the needed parameters to call the tagger for Estonian.
		{
			@tokAgrs=( $Bin."/Treetagger/tokenize.pl","$_[2]" ,"$outputDir$filename.tokenized");
			$tagData ="$Bin/Treetagger/estonian.par";
		}
		elsif($uLang eq 'BG') #Checks language options and sets the needed parameters to call the tagger for Bulgarian.
		{
			@tokAgrs=($Bin."/Treetagger/tokenize.pl","$_[2]" ,"$outputDir$filename.tokenized");
			$tagData = "$Bin/Treetagger/bulgarian.par";
		}
		else
		{
			print STDERR "[Tag::TagText] ERROR: no such tagger-language combination: \"$_[1]\"-\"$_[0]\"";
			die;
		}
		
		system "perl",@tokAgrs; 	#Calling the tokenizer with the language options that where acquired above to tokenize plaintext.
		@agrs=("-token", "-lemma",$tagData , "$outputDir$filename.tokenized", "$outputDir$filename.Tree");
		if ($^O eq "MSWin32")
		{
			system $Bin."/Treetagger/tree-tagger.exe",@agrs; 	# calling tree tagger to tag the tokeinized file with langugae specific paramters (note: UTF-8 parameter files are used).
		}
		else	#If current operating system is not Windows tries the Linux alternative.
		{
				system $Bin."/Treetagger/tree-tagger",@agrs;  	
		}
		#Adds token positions to existing Token file using plaintext file un creates a file with the same structure as the out from POS tagger.
		NEPreprocess::FindTokenPos("$_[2]" ,"$outputDir$filename.Tree","$outputDir$filename.temp"); 
	}
	elsif ($uTagger eq "POS") # POS tagger - > Tilde's internal POS tagger.
	{
		if($uLang eq 'LV') # POS tagging for Latvian ("lv").
		{
			 @agrs=("1062" ,"/S","$_[2]","$outputDir$filename.temp"); # calls Pos tagger to  tokenize and tag plaintext
			system $Bin."/POSTaggerCOMTest.exe",@agrs;
		}
		elsif($uLang eq 'ET') # POS tagging for Estonian ("et").
		{
			 @agrs=("1061" ,"/S","$_[2]","$outputDir$filename.temp");
			system $Bin."/POSTaggerCOMTest.exe",@agrs;	
		}
		elsif($uLang eq 'LT') # POS tagging for Lithuanian ("lt").
		{
			@agrs=("1063" ,"/S","$_[2]","$outputDir$filename.temp");
			system $Bin."/POSTaggerCOMTest.exe",@agrs;
		}
		else
		{
			print STDERR "[Tag::TagText] ERROR: no such tagger-language combination  combination: \"$_[1]\"-\"$_[0]\"";
			die;
		}
	}
	elsif ($uTagger eq "TAGGER") # Tagger - > Tilde's external POS tagger (through a web service).
	{
		if ($^O eq "MSWin32") # If windows uses Teger.exe.
		{
			if($uLang eq 'LV') # POS tagging for Latvian ("lv").
			{
				#Calls POS tagger to  tokenize and tag plaintext.
				@agrs=("treetagger", "lv", "accurat", "tr\@nsl\@tion","$_[2]","$outputDir$filename.Tree"); 
				system $Bin."/Tagger.exe",@agrs; 
				#Adds token positions to existing Token file using plaintext file un creates a file with the same structure as the out from POS tagger.
				NEPreprocess::FindTokenPos("$_[2]" ,"$outputDir$filename.Tree","$outputDir$filename.temp"); 
				
			}
			elsif($uLang eq 'ET') # POS tagging for Estonian ("et")
			{
				@agrs=("treetagger", "et", "accurat", "tr\@nsl\@tion","$_[2]","$outputDir$filename.Tree");
				system $Bin."/Tagger.exe",@agrs;
				NEPreprocess::FindTokenPos("$_[2]" ,"$outputDir$filename.Tree","$outputDir$filename.temp");
				
			}
			elsif($uLang eq 'LT') # POS tagging for Lithuanian("lt")
			{
				@agrs=("treetagger", "lt", "accurat", "tr\@nsl\@tion","$_[2]","$outputDir$filename.Tree");
				system $Bin."/Tagger.exe",@agrs;
				NEPreprocess::FindTokenPos("$_[2]" ,"$outputDir$filename.Tree","$outputDir$filename.temp"); 				
			}
			else # if not any of the above:
			{
				print STDERR "[Tag::TagText] ERROR: no such tagger-language combination: \"$_[1]\"-\"$_[0]\"";
				die;
			}
		}
		
		else  #If current operating system is not Windows tries the Linux alternative.
		{
			use IPC::Open2;
			use encoding "UTF-8";
			if($uLang eq 'LV') #POS tagging for Latvian ("lv").
			{
				#Opens stream to pass pliantext to tagger.sh as STDIN and get tokenized and tagged text from it as STDOUT.
				my $pid = open2(*Reader, *Writer, "./tagger.sh","treetagger", "lv", "accurat", "tr\@nsl\@tion" );
				#Encodes "tagger.sh" passed stream in UTF-8.
				binmode Reader, ":utf8"; 
				binmode Writer, ":utf8";
		
				open(FIN, "<:encoding(UTF-8)", "$_[2]");
				open(FOUT, ">:encoding(UTF-8)", "$outputDir$filename.Tree");
				
				#Reads plaintext file.
				while(<FIN>) 
				{
					my $line = $_;
					$line =~ s/^\x{FEFF}//; #Handles BOM.
					#Passes the plain text it to stream that was given to "tagger.sh".
					print Writer $line; 
				}
				close(Writer);
				
				while (<Reader>)  #Prints the STDOUT of "tagger.sh" in a file.
				{
					print FOUT $_;
				}
				
				waitpid( $pid, 0 );
				close(Reader);
				close(FIN);
				close(FOUT);
				#Adds token positions to existing Token file using plaintext file un creates a file with the same structure as the out from POS tagger.
				NEPreprocess::FindTokenPos("$_[2]" ,"$outputDir$filename.Tree","$outputDir$filename.temp"); 
			}
			elsif($uLang eq 'ET') #POS tagging for Estonian ("et").
			{
				my $pid = open2(*Reader, *Writer, "./tagger.sh","treetagger", "et", "accurat", "tr\@nsl\@tion" ); 
				
				binmode Reader, ":utf8";
				binmode Writer, ":utf8";
		
				open(FIN, "<:encoding(UTF-8)", "$_[2]");
				open(FOUT, ">:encoding(UTF-8)", "$outputDir$filename.Tree");
				
				while(<FIN>)
				{
					my $line = $_;
					$line =~ s/^\x{FEFF}//;
					print Writer $line;
				}
				close(Writer);
				
				while (<Reader>)
				{
					print FOUT $_;
				}
				
				waitpid( $pid, 0 );
				close(Reader);
				
				close(FIN);
				close(FOUT);
				
				NEPreprocess::FindTokenPos("$_[2]" ,"$outputDir$filename.Tree","$outputDir$filename.temp");
			}
			elsif($uLang eq 'LT') #POS tagging for Lithuanian ("lt").
			{
				my $pid = open2(*Reader, *Writer, "./tagger.sh","treetagger", "lt", "accurat", "tr\@nsl\@tion" );
				binmode Reader, ":utf8";
				binmode Writer, ":utf8";
				open(FIN, "<:encoding(UTF-8)", "$_[2]");
				open(FOUT, ">:encoding(UTF-8)", "$outputDir$filename.Tree");
				while(<FIN>)
				{
					my $line = $_;
					$line =~ s/^\x{FEFF}//;
					print Writer $line;
				}
				close(Writer);
				
				while (<Reader>)
				{
					print FOUT $_;
				}
				waitpid( $pid, 0 );
				close(Reader);
				close(FIN);
				close(FOUT);
				
				NEPreprocess::FindTokenPos("$_[2]" ,"$outputDir$filename.Tree","$outputDir$filename.temp");
			}
			else
			{
				print STDERR "[Tag::TagText] ERROR: no such tagger-language combination: \"$_[1]\"-\"$_[0]\"";
				die;
			}
		}	
	}
	else {die "no such tagger : $_[1]  ";}

	if ($_[5]) #Removes lines with white spaces if necessary.
	{
		NEPreprocess::RemoveEmptyLines("$outputDir$filename.temp","$_[3]",$_[5]);
	}
	else
	{
		NEPreprocess::RemoveEmptyLines("$outputDir$filename.temp","$_[3]",1);
	}
	if($_[4]) #Deletes the created temp files if option selected.
	{
			 unlink ("$outputDir$filename.temp");
			 unlink ("$outputDir$filename.Tree");
			 unlink ("$outputDir$filename.tokenized");
	}
}

1;

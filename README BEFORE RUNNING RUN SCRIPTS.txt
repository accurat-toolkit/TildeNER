The RUN scripts are created for the user to test, whether the TildeNER system operates on the user's system. The scripts are preconfigured for specific tasks on Latvian data and do not require any input parameters.

The scripts make use of input data that is stored in the "TEST" directory (a suffix "in" is used on directories and files located directly in the TEST directory) and model, property and gazetteer files that are stored in the "Sample_Data" directory.
Output data is stored also in the "TEST" directory (a suffix "out" is used on directories and files located directly in the TEST directory).

BAT scripts are meant to be executed on Windows
SH scripts are meant to be executed on Linux

The user won't be able to execute "bat" scripts on Linux and "sh" scripts on Windows.

The provided test scripts execute the "External Execution Scripts" from TildeNER (See section 3.1.4.2 in the ACCURAT project's Deliverable D2.6).

The scripts are as follows:

1) For PreprocessMuc7DataDirectory.pl (See section 3.1.4.2.1 in ACCURAT Deliverable D2.6):
	RUN-PreprocessMuc7DataDirectory.bat
	RUN-PreprocessMuc7DataDirectory.sh
2) For TagUnlabeledDataDirectory.pl (See section 3.1.4.2.2 in ACCURAT Deliverable D2.6):
	RUN-TagUnlabeledDataDirectory.bat
	RUN-TagUnlabeledDataDirectory.sh
3) For BootstrapNEModel.pl (See section 3.1.4.2.3 in ACCURAT Deliverable D2.6):
	RUN-BootstrapNEModel.sh
	Windows executable bat script not provided as training requires a Linux machine.
4) For NEMuc7TagPlaintext.pl (See section 3.1.4.2.4 in ACCURAT Deliverable D2.6):
	RUN-NEMuc7TagPlaintext.bat
	RUN-NEMuc7TagPlaintext.sh
5) For NEMuc7TagPlaintextList.pl (See section 3.1.4.2.5 in ACCURAT Deliverable D2.6):
	RUN-NEMuc7TagPlaintextList.bat
	RUN-NEMuc7TagPlaintextList.sh
6) For NETabSepTagPlaintext.pl (See section 3.1.4.2.6 in ACCURAT Deliverable D2.6):
	RUN-NETabSepTagPlaintext.bat
	RUN-NETabSepTagPlaintext.sh
7) For NETabSepTagTabSep.pl (See section 3.1.4.2.7 in ACCURAT Deliverable D2.6):
	RUN-NETabSepTagTabSep.bat
	RUN-NETabSepTagTabSep.sh

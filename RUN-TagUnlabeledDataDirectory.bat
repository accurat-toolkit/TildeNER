cd %~dp0
@echo off
echo Calling "./TagUnlabeledDataDirectory.pl"

perl ./TagUnlabeledDataDirectory.pl lv Tagger "./TEST/plaintext_in" "./TEST/unannotated_tab_sep_out" txt pos 1

echo TagUnlabeledDataDirectory.pl finished.
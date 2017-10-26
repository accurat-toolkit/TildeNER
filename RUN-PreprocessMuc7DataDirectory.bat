cd %~dp0
@echo off
echo Calling "./PreprocessMuc7DataDirectory.pl"

perl ./PreprocessMuc7DataDirectory.pl "./TEST/gold_muc7_plaintext_in" "./TEST/gold_tab_sep_out" txt gold lv Tagger

echo PreprocessMuc7DataDirectory.pl finished.
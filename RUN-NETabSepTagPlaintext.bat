cd %~dp0
@echo off
echo Calling "./NETabSepTagPlaintext.pl"

perl ./NETabSepTagPlaintext.pl "./Sample_Data/LV_Model_P.ser.gz" "./TEST/plaintext_in.txt" "./TEST/tab_sep_out.txt" "./Sample_Data/LV_P_Tagging_prop_sample.prop" lv Tagger 0 "L N S R_0.7 C T_0.90 A"

echo NETabSepTagPlaintext.pl finished.
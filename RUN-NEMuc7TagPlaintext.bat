cd %~dp0
@echo off
echo Calling "./NEMuc7TagPlaintext.pl"

perl ./NEMuc7TagPlaintext.pl "./Sample_Data/LV_Model_P.ser.gz" "./TEST/plaintext_in.txt" "./TEST/muc-7_plaintext_out.txt" "./Sample_Data/LV_P_Tagging_prop_sample.prop" lv Tagger 0 "L N S R_0.7 C T_0.90 A"

echo NEMuc7TagPlaintext.pl finished.
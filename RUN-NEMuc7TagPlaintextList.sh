#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./NEMuc7TagPlaintextList.pl"

perl ./NEMuc7TagPlaintextList.pl "./Sample_Data/LV_Model_P.ser.gz" "./TEST/plaintextList_in.txt" "./Sample_Data/LV_P_Tagging_prop_sample.prop" lv Tagger 0 "L N S R_0.7 C T_0.90 A"

echo "NEMuc7TagPlaintextList.pl finished."

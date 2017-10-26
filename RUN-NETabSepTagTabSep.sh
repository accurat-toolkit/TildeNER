#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./NETabSepTagTabSep.pl"

perl ./NETabSepTagTabSep.pl "./Sample_Data/LV_Model_P.ser.gz" "./TEST/tab_sep_in.pos" "./TEST/tab_sep_out.pos"  "./Sample_Data/LV_P_Tagging_prop_sample.prop" 0 "L N S R_0.7 C T_0.90 A"

echo "NETabSepTagTabSep.pl finished."
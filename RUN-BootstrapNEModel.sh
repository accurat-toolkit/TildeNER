#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./BootstrapNEModel.pl"

perl ./BootstrapNEModel.pl "./TEST/seed_in" gold "./TEST/dev_in" gold "./TEST/gold_tab_sep_in" gold "./TEST/unannotated_tab_sep_in" pos "./Sample_Data/LV_Training_prop_template.prop" "./Sample_Data/LV_Tagging_prop_template.prop" "./TEST/bootstrap_out" 5 5 1 "L N S R_0.7 C T_0.90 A" "./TEST/bootstrap_out/bootstrapped_gazetteer.txt" 0 P

echo "TagUnlabeledDataDirectory.pl finished."

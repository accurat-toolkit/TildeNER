#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./TagUnlabeledDataDirectory.pl"

perl ./TagUnlabeledDataDirectory.pl lv Tagger "./TEST/plaintext_in" "./TEST/unannotated_tab_sep_out" txt pos 1

echo "TagUnlabeledDataDirectory.pl finished."

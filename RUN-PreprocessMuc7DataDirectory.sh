#!/bin/bash

reldir=`dirname $0`
cd $reldir

echo "Calling ./PreprocessMuc7DataDirectory.pl"

perl ./PreprocessMuc7DataDirectory.pl "./TEST/gold_muc7_plaintext_in" "./TEST/gold_tab_sep_out" txt gold lv Tagger

echo "PreprocessMuc7DataDirectory.pl finished."

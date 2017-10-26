#!/bin/bash

METHOD=$1
LANG=$2
USER=$3
PASS=$4
# count of character that are processed in one request
CHUNK_SIZE=5000
SERVICE_URI=https://www.tilde.com/tagger/Service.asmx
# Create temporay POST data file
POST_FILE=$(mktemp) || exit 1
WGET_PARAM="-O - --http-user=$USER --http-passwd=$PASS --post-file=$POST_FILE -nv"

# Process text function
# Param/-s - text to process
processText()
{
        TEXT="$*"

        # Substitute UNIX type line-ends with Windows (The web service processes Windows type line-ends)
	#    remove CR characters (in case there are some) and convert to DOS line-ends
	#TEXT=$(echo "$TEXT" | tr -d '\r' | sed 's/$'"/`echo \\\r`/")
        # Ignore empty lines
        if [[ -z $TEXT ]]
        then
                echo "$TEXT"
                return
        fi

        # URLEscape input data & write to POST file
        TEXT=`echo "$TEXT" | perl -wple 's/([^\w])/sprintf("%%%02X", ord($1))/eg'`

        echo "lang=$LANG&text=$TEXT">$POST_FILE

        # Execute Web Service method
        case $METHOD in
                tokenize)
                        RESULT=`wget $WGET_PARAM "$SERVICE_URI/Tokenize"`
                        ;;
                break)
                        RESULT=`wget $WGET_PARAM "$SERVICE_URI/BreakSentences"`
                        ;;
                moses)
                        echo "lang=$LANG&outputFormat=moses&text=$TEXT">$POST_FILE
                        RESULT=`wget $WGET_PARAM "$SERVICE_URI/PosTagger"`
                        ;;
                treetagger)
                        echo "lang=$LANG&outputFormat=treetagger&text=$TEXT">$POST_FILE
                        RESULT=`wget $WGET_PARAM "$SERVICE_URI/PosTagger"`
                        ;;
                xces)
                        echo "lang=$LANG&outputFormat=xces&text=$TEXT">$POST_FILE
                        RESULT=`wget $WGET_PARAM "$SERVICE_URI/PosTagger"`
                        ;;
                *)
                        echo "ERROR: Unknown method '$METHOD'!" >&2
                        ;;
        esac

        # Remove XML markup
        RESULT=`echo  "$RESULT" | tail --lines=+2 | sed -r 's/<string [^>]*>//; s/<\/string>//' | sed -e 's/\&lt;/</g; s/\&gt;/>/g; s/\&nbsp;/ /g; s/\&cent;/¢/g; s/\&pound;/£/g; s/\&yen;/?/g; s/\&euro;/<80>/g; s/\&sect;/§/g; s/\&copy;/©/g; s/\&reg;/®/g; s/\&trade;/<99>/g; s/\&amp;/\&/g;'`
        # Output result
        echo "$RESULT" | tr -d '\r'
}

# Main script
# Process all text at once when requesting XCES format
if [ "$METHOD" == "xces" ]; then
        TEXT=`cat /dev/stdin`
        processText $TEXT
else
        # For as many lines as the STDIN has...
        while read LINE; do
		TEXT="$LINE"
		while [ ${#TEXT} -lt $CHUNK_SIZE ] && read LINE ; do
			TEXT="$TEXT"$'\n'"$LINE"
		done
		# check if the last line without new-line character has been read (such a line will not be added to the TEXT)
		if [ ${#TEXT} -lt $CHUNK_SIZE ]; then
			TEXT="$TEXT"$'\n'"$LINE"
		fi
                processText "$TEXT"
        done
	# check if the last line without new-line character has been read (such line might not be processed)
	if [ ${#LINE} -gt 0 ]; then
		processText "$LINE"
	fi
fi


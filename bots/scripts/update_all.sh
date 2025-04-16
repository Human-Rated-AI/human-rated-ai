#!/usr/bin/env bash

NEW_LINE=''

for FILE in *.json; do
    # Extract the docId from the JSON file
    docId=$(jq -r '.docId' "$FILE")
    
    # Only proceed if docId was found
    if [ -n "$docId" ] && [ "$docId" != "null" ]; then
        echo >&2 -e "${NEW_LINE}Processing $FILE with docId: $docId"
        NEW_LINE='\n'

        # Run your update command with the extracted docId
        ~/creators/getoutfit.sh >&2 ~/Downloads/GitHub/Human-Rated-AI/serviceAccount.json aiSettings update "$docId" < "$FILE"
    else
        echo >&2 "Warning: Could not extract docId from $FILE"
    fi
done

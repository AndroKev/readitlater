#!/bin/bash

OUTPUT_FOLDER="" 
SQLITE_DB=""
BOOKMARKFOLDER="Save-To-Read"

OLDIFS=$IFS
IFS=" # "

while read id url title 
 do
    if [ "$title" == "" ]; then
        title=`date +%d.%m.%Y_%H.%M`
    fi

    filename=`echo "$title" | tr -c '[:alnum:]' '_'` # delete spec. char. from the filename!
    filename="$OUTPUT_FOLDER$filename"

    if [ -f "$filename.pdf" ]; then
        time=`date +%N`
        filename="$filename.$time"
    fi

    # wkhtmltopdf "http://google.com/gwt/x?u=${url#https://}" "$filename.pdf"
    wkhtmltopdf --viewport-size 1280x800 --custom-header "User-Agent" "Mozilla/5.0 (Linux; Android 4.2.2; ME173X Build/JDQ39) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.133 Safari/537.36" --custom-header-propagation "http://google.com/gwt/x?u=${url#https://}" "$filename.pdf"
    if [ "$?" == 0 ]; then # check if downloading was ok, and then delete it from the DB!
        sqlite3 "$SQLITE_DB" "DELETE FROM moz_places WHERE moz_places.id = '$id'";
        sqlite3 "$SQLITE_DB" "DELETE FROM moz_bookmarks WHERE moz_bookmarks.fk = '$id'";
    fi
    # echo "${url#https://} $filename.pdf"
 done <<< `sqlite3 "$SQLITE_DB" -separator " # " "SELECT moz_places.id, moz_places.url, moz_bookmarks.title FROM moz_bookmarks, moz_places WHERE moz_places.id = moz_bookmarks.fk AND moz_bookmarks.parent = (SELECT moz_bookmarks.id FROM moz_bookmarks WHERE moz_bookmarks.title = '$BOOKMARKFOLDER');"`

IFS=$OLDIFS

#!/usr/bin/env bash

PSTOPDF="pstopdf -i -o"

for psfile in "$@"
do  pdffile="${psfile%.*}.pdf"
    if [ -e "$pdffile" ]
    then echo >&2 "WARNING: $pdffile exists. Skipping."
    else skip '%ADOBeginClientInjection' '%ADOEndClientInjection' < "$psfile" | $PSTOPDF "$pdffile"
    fi
done
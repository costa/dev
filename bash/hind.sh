#!/bin/bash

### Like `find`, but tries to figure ~/.gitignore

# YUCK!

# BUGBUGBUG Does not handle the '!'s and '/'s of .gitignore
if [ -r $HOME/.gitignore ]
then names="`cat $HOME/.gitignore | egrep -v '^(#.*)?$' | paste -s -d : -`"
fi
if [ "$names" ]
then fstr="( -name ${names//:/ -o -name } ) -prune"
    if [ "$1" ]
    then fstr="$fstr -o"
    fi
fi

fstr=(find $HOME $fstr "$@")

"${fstr[@]}"

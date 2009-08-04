#!/bin/sh

# INTRODUCING TagFSx :-)
# A convention (rather than a system) - backed by this rather POC script -
# providing tagged file system environment for shelling and applications
#
# All terms below (file, directory, symlink etc.) refer an underlying FS
# and depend on its capabilities to manage them as required (sorry, windas).
#
### A filesystem node (file, directory, symlink etc.) MAY have tags
# (and this script provides means of adding, removing and inspecting them).
#
### A directory MAY contain a tagbase (directory)
# (usually called #, but may actually be any relative pathname)
# having a hierarchy of tag(-named) directories containing symlinks (direct
# and chained) to tagged nodes for "static" filesystem navigation.
#
### A node's tagbases are all those located down its path plus those specified.
#
### A node MAY have tags if any subdirectory of it has at least one tagbase.
#
#
# EXAMPLE
# ~/                                  - a home
#  pub/                               - a pub
#     notes/                          - a directory
#          Tagging rules.txt          - a note
#
#$ cd ~/pub                           # gone to the pub
#$ tag -C "notes/Tagging rules".txt tagging 'personal infomgmt' rules
#
# ~/
#  pub/
#     #/
#      personal infomgmt/        - a tag
#                       rules/
#                            tagging/
#                                   Tagging rules.txt -> ../../../Tagging rules.txt
#                            Tagging rules.txt -> ../../Tagging rules.txt
#                       tagging/
#                              rules/
#                                   Tagging rules.txt -> ../../../Tagging rules.txt
#                              Tagging rules.txt -> ../../Tagging rules.txt
#                       Tagging rules.txt -> ../Tagging rules.txt
#      rules/                    - another tag
#           personal infomgmt/
#                            tagging/
#                                   Tagging rules.txt -> ../../../Tagging rules.txt
#                            Tagging rules.txt -> ../../Tagging rules.txt
#           tagging/
#                  personal infomgmt/
#                                   Tagging rules.txt -> ../../../Tagging rules.txt
#                  Tagging rules.txt -> ../../Tagging rules.txt
#           Tagging rules.txt -> ../Tagging rules.txt
#      tagging/                  - yet another tag
#             personal infomgmt/
#                              rules/
#                                   Tagging rules.txt -> ../../../../notes/Tagging rules.txt
#                              Tagging rules.txt -> ../../Tagging rules.txt
#             rules/
#                  personal infomgmt/
#                                   Tagging rules.txt -> ../../../Tagging rules.txt
#                  Tagging rules.txt -> ../../Tagging rules.txt
#             Tagging rules.txt -> ../Tagging rules.txt
#      Tagging rules.txt -> tagging/personal infomgmt/rules/Tagging rules.txt
#     notes/
#          Tagging rules.txt
#
# Yes, there are 31 directories and symlinks created in a single tagbase for
# a single file with three tags, but you see, no magic here...
#
# Whew! Well, sorry for that factorial explosion, but here's how it works,
# and remember that the idea is of real-world personal information management
# (and here it stands for manually managing individual filesystem items)
# The basic idea is one master taglink at the exact "tagpath",
# one main ("empty") taglink at the root, pointing to the master taglink,
# and a utility taglink for every associated tagpath.
#
#
# CAUTION
# Do not operate on broken/open tagbases. If a tagbase directory is writable or
# there is a lock.pid file in it, the chances are that the tagbase is broken and
# subject to check/fix - unless there is a tag (bash) process with the stored
# pid running (which of course means you should wait to finish, or kill it if
# the things gone messy).
#
# NOTES
# It would probably be terribly wonderful to record every tagbase change to
# a source revision control repository. Although it may relay on the already
# developing practical habits of continuous version control of an individual,
# an appropriate dedicated option would probably come handy in the future.
#
# An individual may consider using/setting -L|-P cd options for convenience
#
## Return Values
# 0 - :-)
# 1 - a (syntactical) parameter error
# 2 - a run-time error
# 3 - a run-time warning caused exit
# 255 - an unknown (bug) or rather development-work-in-progress error
#
# TODO
# TAGDEPTH variable to limit the tagbase directory hierarchy depth
#
## Aliases?
# untag: tag -u
# tagls: pipes through ls adding tag information and removing TBs from listing
# tagmv FILENAME1 FILENAME2: tag FILENAME2 `untag FILENAME1`; mv FILENAME1 FILENAME2
# tagcp FILENAME1 FILENAME2: tag FILENAME2 `tag FILENAME1`; cp -R FILENAME1 FILENAME2
# tagrm FILENAME: untag FILENAME; rm -R FILENAME

# source permute_func.sh
# Usage: permute cmd opt_idx el...
function permute() {
    local cmd="$1"; shift
    local opt_idx=$1; shift
    local i
    if $cmd $opt_idx "$@"
    then for (( i=$opt_idx; $i <= $#; i++ ))
        do  permute "$cmd" $(($opt_idx +1)) "${@:1:$opt_idx -1}" "${@:$i:1}" "${@:$opt_idx:$i - $opt_idx}" "${@:$i +1}"
        done
    fi
}


# bread crumbs anyone?
function breadcrumbs() {
    [[ ! $1 || $1 == 0 ]] && return
    local ret='..'
    local i
    for ((i=1; $i < $1; i++))
    do ret="$ret/.."
    done
    echo -n "$ret"
}


# CONFIG

force=0
logl=1
sort=not
tb_dir='#'

all_opts=$TAGOPT
all_opts=($all_opts '')
for opts in "${all_opts[@]}"
do  unset f_was s_was OPTIND  # !!!!!
    while getopts ACcFfhQqsu o $opts
    do  case "$o" in
	    [?]|h)
                cat <<EOF
Usage:  tag OPTIONS FILENAME [TAG ...]
        - tag FILENAME with the TAGs (if none, list current tags on FILENAME)
        untag OPTIONS FILENAME [TAG ...]
        - remove TAGs (or ALL if none specified) from FILENAME and list removed
Options: (WIP)
       -A    update the closest (deepest or see -C) tagbase only (default: all)
       -C    use the tagbase in the current directory, create if doesn't exist
 TBD   -c[c] prior to operation, check for tagbase(s) consistency, correct them
 TBD   -F    fail on the first warning (instead of going interactive)
 TBD   -f[f] force on the first warning, on all of the warnings
       -h    print this and exit
 TBD   -Q    print all commands and comments (debug or paranoia or just fancy)
 TBD   -q[q] be quiet, -er (will still print warnings if going interactive)
 TBD   -s[s] sort tags alphabethically, sort tags by popularity
       -u    The equivalent of the untag command, not applicable to the latter
Directories:
        Tagbase is a # directory on a FILENAME's subpath, containing the managed
        tag hierarchy with symlinks to file system nodes such as FILENAME.
Environment:
        TAGDIR   If defined to a relative pathname, replaces the # (see above)
                 Otherwise, points to an additional (global) tagbase
        TAGOPT   Default OPTIONS (overridden by command line)
Notes:
        The closest (deepest) tagbase is always considered authoritative.
EOF
                [[ "$o" == "h" ]] && exit
                exit 1;;
            A)
                one_tb=1;;
            C)
                cwd_tb=1;;
	    f)
                if [[ $f_was ]]
                then force=1000000 # reasonable infinity
                else force=1
                    f_was=1
                fi;;
	    s)
                if [[ $s_was ]]
                then sort=pop
                else sort=abc
                    s_was=1
                fi;;
            u)
                untag=1;;
	esac
    done
done
shift $(($OPTIND - 1))
filename="$1"; shift

if [[ ! "$filename" ]]
then echo  >&2 "Un/Tag what? Run 'tag -h' for usage information"
    exit 1
fi

## Determining the exact absolute path to the file
[[ "${filename##/*}" ]] && filename="./$filename"  # was a relative path

if (cd "${filename%/*}")
then filename="`cd \"${filename%/*}\"; pwd -P`/${filename##*/}"
else echo >&2 "Cannot reach the directory of $filename"
    exit 2
fi

[[ "${TAGDIR##/*}" ]] && tb_dir="$TAGDIR"  # was a relative path


# COLLECT/CREATE

tbs=()

if [[ $cwd_tb ]]
then wd="`pwd -P`"
    # Creating a tagbase in the current directory
    if [[ ! -e "$wd/$tb_dir" ]]
    then if mkdir -pv "$wd/$tb_dir" && chmod -vv a-w "$wd/$tb_dir"
        then echo >&2 "Tagbase for $wd created"
        else echo >&2 "Error creating tagbase at $wd/$tb_dir!"
            exit 2
        fi
    fi
    tbs[0]="$wd/$tb_dir"
fi

## Collecting the tagbases down the path
currdir="${filename%/*}"
while [[ "$currdir" != "" && ( ! $one_tb || ! ${tbs[0]} ) ]]
# not really allows to have a regular tagbase at /
do  if [[ -d "$currdir/$tb_dir" && "${tbs[0]}" != "$currdir/$tb_dir" ]]
    then tbs[${#tbs[@]}]="$currdir/$tb_dir"  # push
    fi
    currdir="${currdir%/*}"    
done

## (Carefully) adding the global tagbase
if [[ "$TAGDIR" && ! "${TAGDIR##/*}" ]]  # is an absolute path
then for ((i=0; i < ${#tbs[@]}; i++))
    do  [ "${tbs[$i]}" == "$TAGDIR" ] && break
    done
    tbs[$i]="$TAGDIR"
fi


# LOCK

act_tbs=()

for tb in "${tbs[@]}"
do  if [[ -w "$tb" || -e "$tb/lock.pid" ]]
    then echo >&2 "$tb is open, someone or something is working on it!"
        err=3  # TODO warning
    elif chmod u+w "$tb" && set -o noclobber && echo "$$" > "$tb/lock.pid"
    then act_tbs[${#act_tbs[@]}]="$tb"
    else echo >&2 "Error locking $tb!"
        err=3  # TODO warning
    fi
done


if [[ ! $err ]]
then
# CHANGE
#* Always use relative paths when linking

function tag_step() {
    local tags
    tags=( "${@:2:$1 -1}" )

    # BUG! There may be a (very unlikely) tag shuffle here.
    #      I won't currently fix it because bash 2.05b really pisses me off
    #      with the IFS problems. Once its compatibility is given up, uncomment
    #      the two lines below and remove this BUG note.
    # IFS='/'     # The special case of master tag link has already been handled
    [[ "${tags[*]/#[+-]}" == "${new_tags[*]}" ]] && return  # sorry for ugliness
    # unset IFS

    local remove
    local append
    local i
    for ((i=0; i < ${#tags[@]}; i++))
        do  if [[ "${tags[$i]:0:1}" == '-' ]]
        then remove=1
            tags[$i]="${tags[$i]:1}"
        elif [[ "${tags[$i]:0:1}" == '+' ]]
        then append=1
            tags[$i]="${tags[$i]:1}"
        fi
    done
    
    [[ $remove && $append ]] && return 1     # insane!
    
    IFS='/'
# TODO FS operations error checking
    if [[ $append ]]
    then mkdir -p "$tb/${tags[*]}"
        ln -s "`breadcrumbs ${#tags[@]}`/$mainlink" "$tb/${tags[*]}/$mainlink"
    elif [[ $remove ]]
    then if [[ -L "$tb/${tags[*]}/$mainlink" ]]  # silently ignore missing tags
        then rm "$tb/${tags[*]}/$mainlink"
            rmdir -p "$tb/${tags[*]}" 2> /dev/null  # TODO yuck!
        fi
    fi
    unset IFS
    
    # TODO depth check: [[ ${#tags[@]} >= $max_depth ]] && return 1
}


## Iterate through tagbases

for tb in "${act_tbs[@]}"
do
### Determine the relative (to the tagbase) path of FILENAME
    IFS='/'
    tb_dirs=( $tb )
    fn_dirs=()
    i=0
    for dir in ${filename%/*}
    do  if [[ "$dir" == "${tb_dirs[$i]}" ]]
        then ((i++))
        else fn_dirs[${#fn_dirs[@]}]="$dir"
        fi
    done
    rel_path="`breadcrumbs $((${#tb_dirs[@]} - $i))`/${fn_dirs[*]}/${filename##*/}"
    unset IFS

### Determine the taglink name (and the current tags)
    IFS='/'
    for taglink in `ls "$tb/${filename##*/}"* 2> /dev/null`
    do  
        tmp_tgt="`readlink \"$tb/${taglink##*/}\"`"
        old_tags=(${tmp_tgt%/*})
        if [[ "`readlink \"$tb/$tmp_tgt\"`" \
            == "`breadcrumbs ${#old_tags[@]}`/$rel_path" ]]
        then mainlink="${taglink##*/}"
            break
        fi
    done
    unset IFS

    [[ $untag && ! "$mainlink" ]] && break  # See comment on break below

    if (($# == 0))
    then if [[ $untag ]]
        then  set -- "${old_tags[@]}"
        else IFS=$'\n'; echo "${old_tags[*]}"; unset IFS
            break  # Should break on the master tagbase down to unlocking
        fi
    fi

    if [[ ! "$mainlink" ]]
    then # TODO smarter taglink naming
        taglink="${filename##*/}"
        for (( i = 0; i < 1000000; i++ ))
        do if [ ! -e "$tb/$taglink" ]
            then mainlink="$taglink"
                break
            fi
            taglink="${filename##*/}~$i"
        done
    fi
    
## Unify the existing and the new tags to create the all_tags list
# where tags to be really removed/appended are prefixed by -/+ character
    all_tags=()
    if [[ $untag ]]
    then for tag in "${old_tags[@]}"
        do  for rm_tag
            do  [[ "$tag" == "$rm_tag" ]] && break
            done
            if [[ "$tag" == "$rm_tag" ]]
            then all_tags[${#all_tags[@]}]="-$tag"
            else all_tags[${#all_tags[@]}]="$tag"
                new_tags[${#new_tags[@]}]="$tag"
            fi
        done
    else
        tmp_tags=( "${old_tags[@]}" )
        for tag
        do  i=0
            for ex_tag in "${tmp_tags[@]}"
            do  [[ "$tag" == "$ex_tag" ]] && break
                ((i++))
            done
            if [[ "$tag" == "$ex_tag" ]]
            then all_tags[${#all_tags[@]}]="$tag"
                tmp_tags=( "${tmp_tags[@]:0:$i}" "${tmp_tags[@]:$i +1}" )
            else all_tags[${#all_tags[@]}]="+$tag"
            fi
            new_tags[${#new_tags[@]}]="$tag"
        done
        for tag in "${tmp_tags[@]}"
        do  all_tags[${#all_tags[@]}]="$tag"
            new_tags[${#new_tags[@]}]="$tag"
        done
    fi
    
## Create the master and the main link
    IFS='/'
# TODO FS operations error checking
    if ((${#old_tags[@]} > 0))
    then rm "$tb/${old_tags[*]}/$mainlink" "$tb/$mainlink"
        rmdir -p "$tb/${old_tags[*]}" 2> /dev/null  # TODO yuck!
    fi
    if ((${#new_tags[@]} > 0))
    then mkdir -p "$tb/${new_tags[*]}"
        ln -sf "`breadcrumbs ${#new_tags[@]}`/$rel_path" \
            "$tb/${new_tags[*]}/$mainlink"  # TODO yuck? -f for removing tags
        ln -s "${new_tags[*]}/$mainlink" "$tb/$mainlink"
    fi
    unset IFS

### Iterate through all_tags permutations
    permute tag_step 1 "${all_tags[@]}"
done

fi


# UNLOCK

for tb in "${act_tbs[@]}"
do  if [[ "`cat \"$tb/lock.pid\"`" != "$$" ]] ||
        ! rm "$tb/lock.pid" ||
        ! chmod u-w "$tb"
    then echo >&2 "Error unlocking $tb!"
        err=2  # TODO warning
    fi
done

exit $err

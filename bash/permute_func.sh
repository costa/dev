# source permute_func.sh
# Usage: permute cmd opt_idx el...
# Assumed:       cmd opt_idx el...
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

function permute_test() {
    echo "${*:2:$1 -1}"
    return $(($1 > 3))  # e.g. ordered selection of 3
}

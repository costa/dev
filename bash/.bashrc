
if [[ ! $BASHRC_PATH_UPD ]]
then export BASHRC_PATH_UPD="YES"
    export PATH=$HOME/pub/dev/bash:$HOME/local/bin:/opt/local/bin:/opt/local/sbin:$PATH
    export PATH=$PATH:/Applications/Postgres.app/Contents/Versions/9.3/bin
    export RUBYPATH=$HOME/pub/dev/ruby:$RUBYPATH
    export MANPATH=/opt/local/share/man:$MANPATH

    # XXX I couldn't remember where it was needed: export DYLD_FALLBACK_LIBRARY_PATH=/opt/local/lib:$DYLD_FALLBACK_LIBRARY_PATH
fi
#export DISPLAY=:0

HISTFILESIZE=67108864
HISTSIZE=1000000
HISTTIMEFORMAT="%F %T "

function fff() {
    find . -iname "*$1*";
}

function grr() {
    find . -iname "*$2" -type f -exec egrep -qi "$1" {} \; -print
}

function hist() {
    echo "`fc -ln -1` # `date`" >> .history
}

function ordoc() {
    open -a Firefox `gem environment gemdir`/doc/$1-*/rdoc/index.html
}

alias lighthere="sh ~/pub/dev/bash/lighthere.sh" # TODO

# workaround for rvm etc
pushd() { builtin pushd "$@" && cd .; }
popd() { builtin popd "$@" && cd .; }

pd() {
    if [ "$#" -eq "0" ]
    then if popd &> /dev/null && pwd > ~/.pd; then :; else pd "`cat ~/.pd`"; fi
    else pushd "$1" &> /dev/null && pwd > ~/.pd
    fi
}
mpd() { mkdir -p "$@" && pd "${!#}"; }  # TODO find out about that last argument

meteor-pow() {
  [ -r .powenv ] && . .powenv
  [ -r .powrc ] && . .powrc
  options=
  [ -r .meteor-settings ] && options="$options --settings .meteor-settings"
  NODE_OPTIONS='--debug' meteor $options
}

export GEMDIR=/opt/local/lib/ruby/gems/1.8/gems

[ "`pwd`" != "$HOME" ] && [ -r .bashrc ] && . .bashrc

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

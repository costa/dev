#!/usr/bin/env bash

echo "Generating stunnel certificate+configuration..."

# NOTE Tested and found working with:
# stunnel 4.47 on i386-apple-darwin12.3.0 platform
# Compiled/running with OpenSSL 1.0.1e 11 Feb 2013

# XXX check openssl dependency

if [ $# -ne 1 ] && [ $# -ne 3 ]
then
  echo "Usage: stunnello example.com [443 80] (will create var/stunnel/example.com/...)"
  exit 1
fi
dom="$1"
if [ $# -eq 3 ]
then dst="$2"
  src="3"
else dst=443
  src=80
fi

dir="var/stunnel/$dom"
mkdir -p "$dir"

key="$dir/stunnel.key"
openssl genrsa -out "$dir/stunnel.key" 1024

req="$dir/stunnel.csr"
echo "CA
British Columbia

Free Willy

*.$dom
admin@$dom



" | openssl req -new -key "$key" -out "$req"

cert="$dir/stunnel.crt"
openssl x509 -req -days 365 -in "$req" -signkey "$key" -out "$cert"

conf="$dir/stunnel.cnf"

echo "
sslVersion = all
options = NO_SSLv2
cert = `pwd`/$cert
key = `pwd`/$key
pid = `pwd`/$dir/stunnel.pid
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
foreground=yes

[proto]
        accept = $dst
        connect = $src
        TIMEOUTclose = 0
" > "$conf"

echo "
Done! Run: [sudo] stunnel \"$dir/stunnel.cnf\"
"

#!/bin/bash

function errcho() {
    echo >&2 "$@"
}
function shout() {
    errcho "$@"
    "$@"
}

[ ! -x tag.sh ] && errcho "Run me from the directory of tag.sh please" && exit 1

errs=0
failed() {
    errcho "[FAILED] $1 Inspect the diff above." && errs=$(($errs + 1))
}

errcho "1. Creating the repository"
! ( mkdir -p tag_test.d/pub/notes && echo 'Yeah!' > 'tag_test.d/pub/notes/Tagging rules.txt' ) && \
    errcho "tag_test.d directory cannot be created" && exit 2
cd tag_test.d/pub  # Crazy if not successful
shout ../../tag.sh -QAC "notes/Tagging rules.txt" tagging 'personal infomgmt' rules || errcho "[ERROR] Executing test"
cd ../..
# cp -Rp tag_test.d tag_test.d.new && tar cpsvf - tag_test.d.new | bzip2 | uuencode -m tag_test.d.new.tar.bz2 | pbcopy && chmod -R u+w tag_test.d.new && rm -R tag_test.d.new
# then copy-paste below
! ( uudecode -p <<EOF
begin-base64 644 tag_test.d.new.tar.bz2
QlpoOTFBWSZTWVb7H2oAD7d/kMmQAEFpOf/6LqokIPfv3sAEAAAIUAOb3Rg7AANCUqNNBpoAaGTQ
aGhmJGQAAaJ6qDQ0DIGQAMIDCNAAJNKJU9TCGmTAgGhkGTRoyDQ9Q5gAJgACYAAAAABSkgU1I0M1
BtQ1GjAAAAMTX3SBJ4yMQFBRVWDBEiMQ3eGQ5JcVduqUTfHhr3vN5s7aziZ4a8HWtOlVjAwklVJJ
BJBJJLQQBpiIgCWAECKAi243sxMwncGx7LtkLVtmZiUYg8pLCGolmUXfoK2Jf0S0pfsh+cH6d9VN
wyLyWTCwfOQJvhCdYQndADyk2K5rgMXDhTGKWlPt/c5dK1qWrppMYcltqWi51EmkJBIBsmADKpJk
zplc2rbVtVVZVVDVIExqHDRrRbVVCqqGaNaNaNVVDTFVQ8O+cPkAN4CEJOm9XT1TTMGMGC9dsiDM
KElEz4FCsYoWsSIERApAhZJd3g0NZB9LE2zxb77z2RX+CXk8m+tdZrGsee7HdytEtuzscktOjGut
usbsu5w0c8vGHbepwxxOl0S2dbLTjhmTXLluS2MYtGYzXbYjbTrtBrrjfbudc5m2riHPah1vtrnn
N9UWhLlxdc7Nc85tayqa7ZxfdgbbXMzFnUG3i2dCXd26UuFv1xxvrOuejYljS4IzWkbN0o7sVd8H
q+QlsR/8l+UGIfv/iGiXpovnJft7iH3KOMpjEYS5ij+aletQehDXmQ2oPAl7BLdD16D0ocIYh4yX
okXlvQh96HjvSJbyTxEu9D2INkNKH6oYS8ZL1LwEspeIl5UPi8KLshuS8l6SXlgcUgTwSAGuHMn1
TWnzSpUwmEwlSptjbHqxrG+d5LzwfCQ/0XckU4UJBW+x9qA=
====
EOF
    ) | tar xjf - && \
    errcho "tag_test.d.new directory cannot be extracted" && exit 2

! diff -r tag_test.d.new tag_test.d && failed "Creating the repository."

errcho "2. Untagging"
cd tag_test.d/pub  # Crazy if not successful
[[ "`shout ../../tag.sh -uQA 'notes/Tagging rules.txt' 'personal infomgmt'`" \
    == 'personal infomgmt' ]] || errcho "[ERROR] Executing test"
cd ../..
# cp -Rp tag_test.d tag_test.d.untag && tar cpsvf - tag_test.d.untag | bzip2 | uuencode -m tag_test.d.untag.tar.bz2 | pbcopy && chmod -R u+w tag_test.d.untag && rm -R tag_test.d.untag
# then copy-paste below
! ( uudecode -p <<EOF
begin-base64 644 tag_test.d.untag.tar.bz2
QlpoOTFBWSZTWSwGNbYABYx/kMmQAEBoQf+urqiEIPbt3kAEAAAIQAI9pNDAGSo9I0AaaaaDINN6
o9CYTEAiU0JlUaBk0A0AeoDQADGhoaADIaAAAAABSlIpjSHqGIZDQAAaDD1TrUa4vCYwzGMt/LLg
o70TdwpUO9jn4579Hf6clSYxXFtBikQ7KhFCs3gSSMxk8TdgbePMFYDyUZKtIrk0UbKOujSj80z9
ckrRhvMs5y2c1D9qdah4zdWLWLHXRUlU1UlThuDFoKhI0VdQqSSRvJJArm7agvTAQXl0fDk1Vkb5
YoZm0xKISASpICEADqmtCNmFCQMV4JDy2v7CRJlQvY9ahbmTMCoGcW34UqszCRihOxVcEvZQtRGR
NVjWAum8ZvrNzaNtXEMKhinJW90OYpuuDlVtbtrgtcMUKFb1SxQxS3umQTG8Lq2TSBCCjaWI9lNe
mjYr2qPxTE/mUdyPLR1dktuTGWUdsuvDEYYJxyZknPR36N0nZJvtKOG7VGxHFR0U0TfScFHmUa0+
tG6jh5UcSbaNbuo5qetHVJpRrO3H0xrjTGudFPPKv+LuSKcKEgWAxrbA
====
EOF
    ) | tar xjf - && \
    errcho "tag_test.d.untag directory cannot be extracted" && exit 2

! diff -r tag_test.d.untag tag_test.d && failed "Untagging."

errcho "3. Retagging"
cd tag_test.d/pub  # Crazy if not successful
shout ../../tag.sh -QA "notes/Tagging rules.txt" shelling rules ||
errcho "[ERROR] Executing test"
cd ../..
# cp -Rp tag_test.d tag_test.d.retag && tar cpsvf - tag_test.d.retag | bzip2 | uuencode -m tag_test.d.retag.tar.bz2 | pbcopy && chmod -R u+w tag_test.d.retag && rm -R tag_test.d.retag
# then copy-paste below
! ( uudecode -p <<EOF
begin-base64 644 tag_test.d.retag.tar.bz2
QlpoOTFBWSZTWbnfPrUAD2x/kMmQAEDqw//57qiEIPbt3kAEAAAIUAO+yOHMcQ6FCSkmgANNNANA
AG9SAAASTVPTSKABM0AmACYAATCU9JSgAAANAAA0AADAAAAAAAAAAAFKU1Gk0moxqA0egjJkAADa
PU6d6leNZixjMGZWTMWMsu36KG4QrJLK6BIEZrVtNw3EI2dt5ttqpiGN0xxDY7k1M2Y7YgXlJAs8
EKAQsEspwHm2ZkzBthbB4W+QuI68spRgjtJYQ2iWZRfJsqWiXtJbEv5g/rtqpqsi8VkwsM7kWvlF
FeYUV90AbpWZUWBBGLCLCHpYWrSqN3Vlqgqi3lFVhRVCUBADBUqrLwqqKtBQVVQVVWnBZIskWRVQ
u4qhcWSLJFjIqhFc5wVIoRyLVuKGKw54BJA84ASQSPyyS792uVn2ZicwwQEAoEr7MMMT2FnBJAwI
TkhLulOuV5Oxwo5MRswcfLtW4a492pXJa0S7xLzdVvnUS51vNcSXG4LHVmsh5w5upah1nPYzbbdb
Vy2m0pqsTCxgMEKBXYwCjCkrzMhQBhNJZYXKUEuMkgIuYyNu8ERCQKAEK6EsiqTmFiKoBIyqYl2j
uyKUXvZsrEKkmwmAltvmzQ35sybIue/FprgS41pu5IsMEt2mmiPZB0+4loj7xL+IMQ/3CXvovIS/
v9EO9RxxMZRhL9iXupPbkmUWSMqV2UAOMoCFAZKqKiqioiIrSLGMYYZGR9ZL4yXZQaQ+JDvkXjuu
9wltReAl4iXdBpDkoYhhLmS+kS6QeElwJeX56LkhwJdL3kvBB6KL5qDpPsTGn8mNIkS0tO1ImCYJ
aWkSO/QH1EPgLuSKcKEhc759ag==
====
EOF
    ) | tar xjf - && \
    errcho "tag_test.d.retag directory cannot be extracted" && exit 2

! diff -r tag_test.d.retag tag_test.d && failed "Retagging."


if [[ $errs != 0 ]]
then errcho "$errs tests FAILED. Leaving the tag_test.d directories for inspection.
chmod -R u+w tag_test.d* && rm -R tag_test.d* # afterwards"
exit 666
else chmod -R u+w tag_test.d* && rm -R tag_test.d*
fi

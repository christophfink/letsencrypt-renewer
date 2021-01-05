#!/bin/bash

# “strict mode”
set -euo pipefail
IFS=$'\n\t '

#### prelims ####
#openssl genrsa 4096 > account.key
#openssl genrsa 4096 > domain.key
#openssl req -new -sha256 -key domain.key -subj "/" -addext "subjectAltName = DNS:christophfink.com, DNS:www.christophfink.com, DNS:stoph.at, DNS:chri.stoph.at, DNS:www.chri.stoph.at, DNS:austromorph.space, DNS:dev.austromorph.space, DNS:www.austromorph.space, DNS:peippo.at, DNS:baikal.peippo.at, DNS:www.peippo.at" > domain.csr

declare signed="${HOME}/$(date '+signedCertificate_%Y%m%d.crt')"

declare -a domains

# get the domain names of all virtual hosts run by httpd
domains=( $(apachectl -S | grep namevhost | awk '{print $4}' | sort | uniq) )

# prepend the domains with 'DNS:'
for i in $(seq 0 $(expr "${#domains[*]}" - 1)); do
    domains[$i]="DNS:${domains[$i]}"
done

# comma-join domains
declare domains_joined
domains_joined=$(
    (
        IFS=", "
        echo "${domains[*]}"
    )
)

# create certificate signing request
openssl \
    req \
    -new \
    -sha256 \
    -key "${HOME}/domain.key" \
    -subj "/" \
    -addext "subjectAltName = ${domains_joined}" \
>"${HOME}/domain.csr"

# request signed certificate
acme-tiny \
    --account-key "${HOME}/account.key" \
    --csr "${HOME}/domain.csr" \
    --acme-dir "${HOME}/acme-challenge/" \
>"${signed}"

# update symlink to latest certificates
#ln -sf "${signed}" "${HOME}/signedCertificate.crt"

# and adjust the new certificates’ permissions
chmod 0640 "${signed}"

# restart services using certificates
for i in \
    httpd postfix dovecot prosody turnserver
do
    sudo systemctl restart "${i}"
done

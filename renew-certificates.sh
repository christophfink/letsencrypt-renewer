#!/bin/bash

# “strict mode”
set -euo pipefail
IFS=$'\n\t '

#### prelims ####
#openssl genrsa 4096 > account.key
#openssl genrsa 4096 > domain.key
#openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:stoph.at,DNS:chri.stoph.at,DNS:www.chri.stoph.at,DNS:austromorph.space,DNS:dev.austromorph.space,DNS:www.austromorph.space,DNS:peippo.at,www.peippo.at,DNS:baikal.peippo.at,DNS:porem.peippo.at,DNS:christophfink.com,DNS:www.christophfink.com,DNS:mansicca.christophfink.com,DNS:conservationgeography.com,DNS:www.conservationgeography.com")) > domain.csr

declare signed="${HOME}/$(date '+signedCertificate_%Y%m%d.crt')"
declare chained="${HOME}/$(date '+signedAndChainedCertificate_%Y%m%d.crt')"

declare -a domains

# get the domain names of all virtual hosts run by httpd
domains=( $(apachectl -S | grep namevhost | awk '{print $4}' | sort | uniq) )

# prepend the domains with 'DNS:'
for i in $(seq 0 $(expr "${#domains[*]}" - 1)); do
    domains[$i]="DNS:${domains[$i]}"
done

# join domains using a comma
declare domains_joined
domains_joined=$(
    (
        IFS=","
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
    -reqexts SAN \
    -config <(
        cat /etc/ssl/openssl.cnf <(
            printf "[SAN]\nsubjectAltName=${domains_joined}")
    ) \
>"${HOME}/domain.csr"

# request signed certificate
acme-tiny \
    --account-key "${HOME}/account.key" \
    --csr "${HOME}/domain.csr" \
    --acme-dir "${HOME}/acme-challenge/" \
>"${signed}"

# download LE’s intermediate certificate and chain it with our newly signed certificate
curl \
    -s \
    -o "${HOME}/intermediate.pem" \
    https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem

cat \
    "${signed}" \
    "${HOME}/intermediate.pem" \
> "${chained}"

# update symlinks to latest certificates
ln -sf "${signed}" "${HOME}/signedCertificate.crt"
ln -sf "${chained}" "${HOME}/signedAndChainedCertificate.crt"

# and adjust the new certificates’ permissions
chmod 0640 "${signed}" "${chained}"

# restart services using certificates
for i in \
    httpd postfix dovecot prosody turnserver
do
    sudo systemctl restart "${i}"
done

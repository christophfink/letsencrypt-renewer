#!/bin/bash

#### prelims ####
#openssl genrsa 4096 > account.key
#openssl genrsa 4096 > domain.key
#openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:chri.stoph.at,DNS:stoph.at,DNS:austromorph.space,DNS:www.austromorph.space,DNS:peippo.at,DNS:www.peippo.at")) > domain.csr

signed="${HOME}/$(date '+signedCertificate_%Y%m%d.crt')"
chained="${HOME}/$(date '+signedAndChainedCertificate_%Y%m%d.crt')"

acme-tiny --account-key "${HOME}/account.key" --csr "${HOME}/domain.csr" --acme-dir "${HOME}/acme-challenge/" > "${signed}" || exit
wget -q -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > "${HOME}/intermediate.pem"
cat "${signed}" "${HOME}/intermediate.pem" > "${chained}"
ln -sf "${signed}" "${HOME}/signedCertificate.crt"
ln -sf "${chained}" "${HOME}/signedAndChainedCertificate.crt"

sudo service apache2 restart
sudo service postfix restart
sudo service dovecot restart

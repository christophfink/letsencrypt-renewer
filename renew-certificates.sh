#!/bin/bash

#### prelims ####
#openssl genrsa 4096 > account.key
#openssl genrsa 4096 > domain.key
#openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:chri.stoph.at,DNS:stoph.at,DNS:austromorph.space,DNS:www.austromorph.space,DNS:peippo.at,DNS:www.peippo.at,DNS:baikal.peippo.at,DNS:p.peippo.at,DNS:porem.peippo.at,DNS:mansicca.christophfink.com,DNS:musticca.christophfink.com,DNS:christophfink.com,DNS:www.christophfink.com")) > domain.csr

signed="${HOME}/$(date '+signedCertificate_%Y%m%d.crt')"
chained="${HOME}/$(date '+signedAndChainedCertificate_%Y%m%d.crt')"

acme-tiny --account-key "${HOME}/account.key" --csr "${HOME}/domain.csr" --acme-dir "${HOME}/acme-challenge/" > "${signed}" || exit
curl -s https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem -o "${HOME}/intermediate.pem"
cat "${signed}" "${HOME}/intermediate.pem" > "${chained}"
ln -sf "${signed}" "${HOME}/signedCertificate.crt"
ln -sf "${chained}" "${HOME}/signedAndChainedCertificate.crt"

chmod 0640 "${signed}" "${chained}"

sudo systemctl restart httpd
sudo systemctl restart postfix
sudo systemctl restart dovecot
sudo systemctl restart postgresql

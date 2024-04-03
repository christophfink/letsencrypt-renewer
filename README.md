automatic renewal of letsencrypt certificates with an unprivileged user
==============

preparation
-----------

* install acme-tiny
* create a user letsencrypt with home dir /var/lib/letsencrypt (adapt name and home dir to suit your environment)
* grant this user specific sudo rights in /etc/sudoers (use visudo!):
	## allow letsencrypt script to restart apache, postfix, dovecot
	letsencrypt ALL=(ALL) NOPASSWD: /sbin/service apache2 restart
	letsencrypt ALL=(ALL) NOPASSWD: /sbin/service postfix restart
	letsencrypt ALL=(ALL) NOPASSWD: /sbin/service dovecot restart
* point apache/postfix/dovecot’s certificate paths to /var/lib/letsencrypt/signedCertificat.crt, /var/lib/letsencrypt/signedAndChainedCertificate and /var/lib/letsencrypt/intermediate.pem, respectively
* create a symlink from [htdocs]/acme-challenge/ to /var/lib/letsencrypt/acme-challenge/
* generate keys:
	openssl genrsa 4096 > /var/lib/letsencrypt/account.key
	openssl genrsa 4096 > /var/lib/letsencrypt/domain.key
* … and cert signing request (fill in your own domain(s)):
	openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:chri.stoph.at,DNS:stoph.at,DNS:austromorph.space,DNS:www.austromorph.space,DNS:peippo.at,DNS:www.peippo.at,DNS:christophfink.com,DNS:www.christophfink.com")) > /var/lib/letsencrypt/domain.csr
* chown all files in /var/lib/letsencrypt/ to letsencrypt:letsencrypt
* `su - letsencrypt`
* run `./renew-certificates.sh`
* if all went right, have `./renew-certificates.sh` run by cron every other month




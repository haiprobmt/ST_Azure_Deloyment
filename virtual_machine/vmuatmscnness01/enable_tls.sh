#!/bin/bash

# Update OpenSSL configuration to enforce TLS 1.2 or higher
echo "MinProtocol = TLSv1.2" >> /etc/ssl/openssl.cnf
echo "CipherString = DEFAULT@SECLEVEL=2" >> /etc/ssl/openssl.cnf

# Restart services to apply changes
systemctl restart sshd
systemctl restart apache2 || systemctl restart nginx || true

echo "TLS 1.2 or higher has been enabled successfully."

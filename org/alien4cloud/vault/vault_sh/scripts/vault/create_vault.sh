#!/bin/bash -e
source $commons/commons.sh
install_dependencies "unzip"
require_envs "VAULT_DOWNLOAD_URL VAULT_INSTALL_DIR"

if [ ! -d "/var/log/vault" ]; then
  sudo mkdir -p /var/log/vault
fi
if [ ! -d "$VAULT_INSTALL_DIR" ]; then
  sudo mkdir -p ${VAULT_INSTALL_DIR}
fi
if [ ! -d "/etc/vault" ]; then
  sudo mkdir -p /etc/vault
fi
if [ ! -d "/etc/certs" ]; then
  sudo mkdir -p /etc/certs
fi

VAULT_TMP_ZIP=/tmp/consul.zip
download "vault" "${VAULT_DOWNLOAD_URL}" ${VAULT_TMP_ZIP}

echo "Unzipping vault package to /usr/bin"
sudo unzip -o ${VAULT_TMP_ZIP} -d /usr/bin
echo "Unzipped vault package to /usr/bin"

sudo rm ${VAULT_TMP_ZIP}

sudo cp $configs/vault_config.hcl /etc/vault/vault_config.hcl
sudo cp $configs/ldap_config.json /etc/vault/ldap_config.json

echo "Copying the tls certificates files $tls_cert_file and $tls_key_file"
sudo cp $tls_cert_file /etc/certs/vault.crt
sudo cp $tls_key_file /etc/certs/vault.key

echo "Use the mlock syscall without running the process as root"
sudo setcap cap_ipc_lock=+ep $(readlink -f $(which vault))

echo "Update the certificate uploaded for vault"
sudo mkdir /usr/share/ca-certificates/vault
sudo cp /etc/certs/vault.crt /usr/share/ca-certificates/vault/vault-ca.crt
echo "vault/vault-ca.crt" | sudo tee /etc/ca-certificates.conf > /dev/null
sudo update-ca-certificates

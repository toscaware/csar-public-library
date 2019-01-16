#!/bin/bash -e

echo "Loading ssl utils"

# Generate a key pair and keystore with certificat sign by CA.
#
# Need envs to be set :
# - $ssl: ssl dir (including ca key and certificat) location.
# - $CA_PASSPHRASE
#
# ARGS:
# - $1 cn
# - $2 name
# - $3 KEYSTORE_PWD
# - $4 single IP to be put in subjectAltName
#
# Returns a temp folder containing.
# - ${name}-key.pem
# - ${name}-cert.pem
# - ${name}-keystore.p12
# - ca.pem
# - ca.csr
#
# Should be deleted after usage.
generateKeyAndStore() {
	CN=$1
	NAME=$2
	KEYSTORE_PWD=$3
	IP=$4

    CA_PEM_FILE=${CA_PEM:-$ssl/ca.pem}
    CA_KEY_FILE=${CA_KEY:-$ssl/ca-key.pem}

	TEMP_DIR=`mktemp -d`

	# echo "Generate client key"
	# Generate a key pair
	openssl genrsa -out ${TEMP_DIR}/${NAME}-key.pem 4096
	openssl req -subj "/CN=${CN}" -sha256 -new \
		-key ${TEMP_DIR}/${NAME}-key.pem \
		-out ${TEMP_DIR}/${NAME}.csr
	# Sign the key with the CA and create a certificate
	echo "[ ssl_client ]" > ${TEMP_DIR}/extfile.cnf
	echo "extendedKeyUsage=serverAuth,clientAuth" >> ${TEMP_DIR}/extfile.cnf
	if [ "${IP}" ]; then
  	sudo echo "subjectAltName = IP:${IP}" >> ${TEMP_DIR}/extfile.cnf
	fi
	openssl x509 -req -days 365 -sha256 \
	        -in ${TEMP_DIR}/${NAME}.csr -CA ${CA_PEM_FILE} -CAkey ${CA_KEY_FILE} \
	        -CAcreateserial -out ${TEMP_DIR}/${NAME}-cert.pem \
	        -passin pass:$CA_PASSPHRASE \
	        -extfile ${TEMP_DIR}/extfile.cnf -extensions ssl_client

	# poulate key store
	# echo "Generate client keystore using openssl"
	openssl pkcs12 -export -name ${NAME} \
			-in ${TEMP_DIR}/${NAME}-cert.pem -inkey ${TEMP_DIR}/${NAME}-key.pem \
			-out ${TEMP_DIR}/${NAME}-keystore.p12 -chain \
			-CAfile ${CA_PEM_FILE} -caname root \
			-password pass:$KEYSTORE_PWD

	cp ${CA_PEM_FILE} ${TEMP_DIR}/ca.pem
	openssl x509 -outform der -in ${CA_PEM_FILE} -out ${TEMP_DIR}/ca.csr

	# return the directory
	echo ${TEMP_DIR}
}

# Install a CA certificate into the system ca-certificates file
#
# WARNING: only works for Ubuntu os
# TODO: test and adapt for centos
#
# ARGS:
# - $1 path to the CA to install
install_CAcertificate() {
	CAfile=$1
	echo "Installing CA ${CAfile} into the system..."
	sudo cp $CAfile /usr/local/share/ca-certificates/_ca.crt
	sudo update-ca-certificates
	echo "CA ${CAfile} installed"
}

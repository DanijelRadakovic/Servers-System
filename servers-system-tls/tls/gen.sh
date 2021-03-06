#! /bin/sh

KEY_SIZE=${1:-4096}

SERVERS_NAME=${2:-servers}
SERVERS_ALIAS=${3:-servers}
SERVERS_KEYSTORE_PASSWORD=${4:-password}

REPORT_NAME=${5:-report}
REPORT_ALIAS=${6:-report}
REPORT_KEYSTORE_PASSWORD=${7:-password}

CLIENT_NAME=${8:-client}
CLIENT_ALIAS=${9:-client}
CLIENT_KEYSTORE_PASSWORD=${10:-password}

LOGAN_NAME=${11:-logan}
LOGAN_ALIAS=${12:-logan}
LOGAN_KEYSTORE_PASSWORD=${13:-password}

RMQ_NAME=${14:-rabbitmq}


# Root CA
mkdir -p ca/root-ca/private ca/root-ca/db crl certs
chmod 700 ca/root-ca/private

# Create database for Root CA
cp /dev/null ca/root-ca/db/root-ca.db
cp /dev/null ca/root-ca/db/root-ca.db.attr
echo 01 > ca/root-ca/db/root-ca.crt.srl
echo 01 > ca/root-ca/db/root-ca.crl.srl

# Create Root CA request
openssl req \
    -new \
    -nodes \
    -config etc/root-ca.conf \
    -out ca/root-ca.csr \
    -keyout ca/root-ca/private/root-ca.key || exit

# Create Root CA certificate
openssl ca \
    -selfsign \
    -rand_serial \
    -batch \
    -config etc/root-ca.conf \
    -in ca/root-ca.csr \
    -out ca/root-ca.crt \
    -extensions root_ca_ext || exit

# Create initial CRL
openssl ca \
    -gencrl \
    -config etc/root-ca.conf \
    -out crl/root-ca.crl || exit

# TLS CA
mkdir -p ca/tls-ca/private ca/tls-ca/db crl certs
chmod 700 ca/tls-ca/private

# Create database for TLS CA
cp /dev/null ca/tls-ca/db/tls-ca.db
cp /dev/null ca/tls-ca/db/tls-ca.db.attr
echo 01 > ca/tls-ca/db/tls-ca.crt.srl
echo 01 > ca/tls-ca/db/tls-ca.crl.srl

# Create TLS CA request
openssl req \
    -new \
    -nodes \
    -config etc/tls-ca.conf \
    -out ca/tls-ca.csr \
    -keyout ca/tls-ca/private/tls-ca.key || exit

# Create TLS CA certificate
openssl ca \
    -rand_serial \
    -batch \
    -config etc/root-ca.conf \
    -in ca/tls-ca.csr \
    -out ca/tls-ca.crt \
    -extensions signing_ca_ext || exit

# Create initial CRL
openssl ca \
    -gencrl \
    -config etc/tls-ca.conf \
    -out crl/tls-ca.crl || exit

cat ca/tls-ca.crt ca/root-ca.crt > \
    ca/tls-ca-chain.pem

mkdir -p "certs/${SERVERS_NAME}/keystore"

# Create TLS server request
SAN=DNS:green.no,DNS:www.green.no,DNS:localhost \
openssl req \
    -new \
    -nodes \
    -newkey "rsa:${KEY_SIZE}" \
    -config etc/server.conf \
    -out "certs/${SERVERS_NAME}/${SERVERS_NAME}.csr" \
    -keyout "certs/${SERVERS_NAME}/${SERVERS_NAME}.key" \
    -subj "/C=NO/O=Green AS/OU=Green Certificate Authority/CN=servers" || exit

# Create TLS server certificate
openssl ca \
    -rand_serial \
    -batch \
    -config etc/tls-ca.conf \
    -in "certs/${SERVERS_NAME}/${SERVERS_NAME}.csr" \
    -out "certs/${SERVERS_NAME}/${SERVERS_NAME}.crt" \
    -extensions server_ext || exit

# Export TLS server certificate chain to keystore
openssl pkcs12 \
    -export \
    -name "${SERVERS_ALIAS}" \
    -inkey "certs/${SERVERS_NAME}/${SERVERS_NAME}.key" \
    -in "certs/${SERVERS_NAME}/${SERVERS_NAME}.crt" \
    -certfile ca/tls-ca-chain.pem \
    -passout "pass:${SERVERS_KEYSTORE_PASSWORD}" \
    -out "certs/${SERVERS_NAME}/keystore/${SERVERS_NAME}.keystore.p12" || exit


mkdir -p "certs/${REPORT_NAME}/keystore"

# Create TLS report request
SAN=DNS:green.no,DNS:www.green.no,DNS:localhost \
openssl req \
    -new \
    -nodes \
    -newkey "rsa:${KEY_SIZE}" \
    -config etc/server.conf \
    -out "certs/${REPORT_NAME}/${REPORT_NAME}.csr" \
    -keyout "certs/${REPORT_NAME}/${REPORT_NAME}.key" \
    -subj "/C=NO/O=Green AS/OU=Green Certificate Authority/CN=report" || exit

# Create TLS report certificate
openssl ca \
    -rand_serial \
    -batch \
    -config etc/tls-ca.conf \
    -in "certs/${REPORT_NAME}/${REPORT_NAME}.csr" \
    -out "certs/${REPORT_NAME}/${REPORT_NAME}.crt" \
    -extensions server_ext || exit

# Export TLS report certificate chain to keystore
openssl pkcs12 \
    -export \
    -name "${REPORT_ALIAS}" \
    -inkey "certs/${REPORT_NAME}/${REPORT_NAME}.key" \
    -in "certs/${REPORT_NAME}/${REPORT_NAME}.crt" \
    -certfile ca/tls-ca-chain.pem \
    -passout "pass:${REPORT_KEYSTORE_PASSWORD}" \
    -out "certs/${REPORT_NAME}/keystore/${REPORT_NAME}.keystore.p12" || exit


mkdir -p "certs/${LOGAN_NAME}/keystore"

# Create TLS logan request
SAN=DNS:green.no,DNS:www.green.no,DNS:localhost \
openssl req \
    -new \
    -nodes \
    -newkey "rsa:${KEY_SIZE}" \
    -config etc/server.conf \
    -out "certs/${LOGAN_NAME}/${LOGAN_NAME}.csr" \
    -keyout "certs/${LOGAN_NAME}/${LOGAN_NAME}.key" \
    -subj "/C=NO/O=Green AS/OU=Green Certificate Authority/CN=logan" || exit

# Create TLS logan certificate
openssl ca \
    -rand_serial \
    -batch \
    -config etc/tls-ca.conf \
    -in "certs/${LOGAN_NAME}/${LOGAN_NAME}.csr" \
    -out "certs/${LOGAN_NAME}/${LOGAN_NAME}.crt" \
    -extensions server_ext || exit

# Export TLS logan certificate chain to keystore
openssl pkcs12 \
    -export \
    -name "${LOGAN_ALIAS}" \
    -inkey "certs/${LOGAN_NAME}/${LOGAN_NAME}.key" \
    -in "certs/${LOGAN_NAME}/${LOGAN_NAME}.crt" \
    -certfile ca/tls-ca-chain.pem \
    -passout "pass:${LOGAN_KEYSTORE_PASSWORD}" \
    -out "certs/${LOGAN_NAME}/keystore/${LOGAN_NAME}.keystore.p12" || exit


mkdir -p "certs/${RMQ_NAME}"

# Create TLS rabbitmq request
SAN=DNS:green.no,DNS:www.green.no,DNS:localhost \
openssl req \
    -new \
    -nodes \
    -newkey "rsa:${KEY_SIZE}" \
    -config etc/server.conf \
    -out "certs/${RMQ_NAME}/${RMQ_NAME}.csr" \
    -keyout "certs/${RMQ_NAME}/${RMQ_NAME}.key" \
    -subj "/C=NO/O=Green AS/OU=Green Certificate Authority/CN=rabbitmq" || exit

# Create TLS rabbitmq certificate
openssl ca \
    -rand_serial \
    -batch \
    -config etc/tls-ca.conf \
    -in "certs/${RMQ_NAME}/${RMQ_NAME}.csr" \
    -out "certs/${RMQ_NAME}/${RMQ_NAME}.crt" \
    -extensions server_ext || exit

cp ca/tls-ca-chain.pem "certs/${RMQ_NAME}"


mkdir -p "certs/${CLIENT_NAME}"

# Create TLS client request (for web browser)
openssl req \
    -new \
    -nodes \
    -newkey "rsa:${KEY_SIZE}" \
    -config etc/client.conf \
    -out "certs/${CLIENT_NAME}/${CLIENT_NAME}.csr" \
    -keyout "certs/${CLIENT_NAME}/${CLIENT_NAME}.key" \
    -subj "/C=NO/O=Green AS/OU=Green Certificate Authority/CN=Peter Peterson" || exit
    
# Create TLS client certificate (for web browser)
openssl ca \
    -rand_serial \
    -batch \
    -config etc/tls-ca.conf \
    -in "certs/${CLIENT_NAME}/${CLIENT_NAME}.csr" \
    -out "certs/${CLIENT_NAME}/${CLIENT_NAME}.crt" \
    -policy extern_pol \
    -extensions client_ext || exit

# Export TLS client certificate chain to keystore
openssl pkcs12 \
    -export \
    -name "${CLIENT_ALIAS}" \
    -inkey "certs/${CLIENT_NAME}/${CLIENT_NAME}.key" \
    -in "certs/${CLIENT_NAME}/${CLIENT_NAME}.crt" \
    -certfile ca/tls-ca-chain.pem \
    -passout "pass:${CLIENT_KEYSTORE_PASSWORD}" \
    -out "certs/${CLIENT_NAME}/${CLIENT_NAME}.p12" || exit


# Import Root CA, TLS CA, report, rabbitmq and client certificate into server keystore
keytool \
    -importcert \
    -noprompt \
    -alias "root" \
    -file ca/root-ca.crt \
    -storepass "${SERVERS_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${SERVERS_NAME}/keystore/${SERVERS_NAME}.truststore.p12"  && \
keytool \
    -importcert \
    -noprompt \
    -alias "tls" \
    -file ca/tls-ca.crt \
    -storepass "${SERVERS_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${SERVERS_NAME}/keystore/${SERVERS_NAME}.truststore.p12" && \
keytool \
    -importcert \
    -noprompt \
    -alias "${REPORT_ALIAS}" \
    -file "certs/${REPORT_NAME}/${REPORT_NAME}.crt" \
    -storepass "${SERVERS_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${SERVERS_NAME}/keystore/${SERVERS_NAME}.truststore.p12" && \
keytool \
    -importcert \
    -noprompt \
    -alias "${RMQ_NAME}" \
    -file "certs/${RMQ_NAME}/${RMQ_NAME}.crt" \
    -storepass "${SERVERS_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${SERVERS_NAME}/keystore/${SERVERS_NAME}.truststore.p12" && \
keytool \
    -importcert \
    -noprompt \
    -alias "${CLIENT_ALIAS}" \
    -file "certs/${CLIENT_NAME}/${CLIENT_NAME}.crt" \
    -storepass "${SERVERS_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${SERVERS_NAME}/keystore/${SERVERS_NAME}.truststore.p12" || exit


# Import Root CA, TLS CA, servers, rabbitmq and client certificate into report keystore
keytool \
    -importcert \
    -noprompt \
    -alias "root" \
    -file ca/root-ca.crt \
    -storepass "${REPORT_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${REPORT_NAME}/keystore/${REPORT_NAME}.truststore.p12"  && \
keytool \
    -importcert \
    -noprompt \
    -alias "tls" \
    -file ca/tls-ca.crt \
    -storepass "${REPORT_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${REPORT_NAME}/keystore/${REPORT_NAME}.truststore.p12" && \
keytool \
    -importcert \
    -noprompt \
    -alias "${SERVERS_ALIAS}" \
    -file "certs/${SERVERS_NAME}/${SERVERS_NAME}.crt" \
    -storepass "${REPORT_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${REPORT_NAME}/keystore/${REPORT_NAME}.truststore.p12" && \
keytool \
    -importcert \
    -noprompt \
    -alias "${RMQ_NAME}" \
    -file "certs/${RMQ_NAME}/${RMQ_NAME}.crt" \
    -storepass "${REPORT_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${REPORT_NAME}/keystore/${REPORT_NAME}.truststore.p12" && \
keytool \
    -importcert \
    -noprompt \
    -alias "${CLIENT_ALIAS}" \
    -file "certs/${CLIENT_NAME}/${CLIENT_NAME}.crt" \
    -storepass "${REPORT_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${REPORT_NAME}/keystore/${REPORT_NAME}.truststore.p12" || exit


# Import Root CA, TLS CA and rabbitmq certificate into logan keystore
keytool \
    -importcert \
    -noprompt \
    -alias "root" \
    -file ca/root-ca.crt \
    -storepass "${LOGAN_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${LOGAN_NAME}/keystore/${LOGAN_NAME}.truststore.p12"  && \
keytool \
    -importcert \
    -noprompt \
    -alias "tls" \
    -file ca/tls-ca.crt \
    -storepass "${LOGAN_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${LOGAN_NAME}/keystore/${LOGAN_NAME}.truststore.p12" && \
keytool \
    -importcert \
    -noprompt \
    -alias "${RMQ_NAME}" \
    -file "certs/${RMQ_NAME}/${RMQ_NAME}.crt" \
    -storepass "${LOGAN_KEYSTORE_PASSWORD}" \
    -storetype "PKCS12" \
    -keystore "certs/${LOGAN_NAME}/keystore/${LOGAN_NAME}.truststore.p12" || exit
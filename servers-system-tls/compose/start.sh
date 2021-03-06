#! /bin/bash

BASE_DIR="$(pwd)/.."
TLS_DIR=${BASE_DIR}/tls


KEY_SIZE=${3:-4096}

SERVERS_NAME=${4:-servers}
SERVERS_ALIAS=${5:-servers}
SERVERS_KEYSTORE_PASSWORD=${6:-password}

REPORT_NAME=${7:-report}
REPORT_ALIAS=${8:-report}
REPORT_KEYSTORE_PASSWORD=${9:-password}

CLIENT_NAME=${10:-client}
CLIENT_ALIAS=${11:-client}
CLIENT_KEYSTORE_PASSWORD=${12:-password}

LOGAN_NAME=${13:-logan}
LOGAN_ALIAS=${14:-logan}
LOGAN_KEYSTORE_PASSWORD=${15:-password}

RMQ_NAME=${16:-rabbitmq}

function generateEnvironmentFile() {
  # sed on MacOSX does not support -i flag with a null extension. We will use
  # 't' for our back-up's extension and delete it at the end of the function
  ARCH=$(uname -s | grep Darwin)
  if [[ "$ARCH" == "Darwin" ]]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi

  # Copy the template to the file that will be modified to add certificates
  cp "${ENVIROMENT_TEMPLATE}" "${ENVIROMENT_FILE}" || exit

  # The next steps will replace the template's contents with the
  # actual values of the certificates and private key files
  sed ${OPTS} \
      -e "s/SERVERS_NAME/${SERVERS_NAME}/g" \
      -e "s/SERVERS_ALIAS/${SERVERS_ALIAS}/g" \
      -e "s/SERVERS_KEYSTORE_PASSWORD/${SERVERS_KEYSTORE_PASSWORD}/g" \
      -e "s/REPORT_NAME/${REPORT_NAME}/g" \
      -e "s/REPORT_ALIAS/${REPORT_ALIAS}/g" \
      -e "s/REPORT_KEYSTORE_PASSWORD/${REPORT_KEYSTORE_PASSWORD}/g" \
      -e "s/LOGAN_NAME/${LOGAN_NAME}/g" \
      -e "s/LOGAN_ALIAS/${LOGAN_ALIAS}/g" \
      -e "s/LOGAN_KEYSTORE_PASSWORD/${LOGAN_KEYSTORE_PASSWORD}/g" \
      -e "s/RMQ_NAME/${RMQ_NAME}/g" \
      "${ENVIROMENT_FILE}"

  if [[ "$ARCH" == "Darwin" ]]; then
    rm "${ENVIROMENT_FILE}t"
  fi
}

function generateCertificates() {
  # Clean up previous generated certificates
  rm -rf "${TLS_DIR}"/ca "${TLS_DIR}"/certs "${TLS_DIR}"/crl

  docker run \
       -it \
       --rm \
       --entrypoint sh \
       --mount "type=bind,source=${TLS_DIR},destination=/export" \
       --user "$(id -u):$(id -g)" \
       danijelradakovic/openssl-keytool \
       gen.sh "${KEY_SIZE}" \
       "${SERVERS_NAME}" "${SERVERS_ALIAS}" "${SERVERS_KEYSTORE_PASSWORD}" \
       "${REPORT_NAME}"  "${REPORT_ALIAS}"  "${REPORT_KEYSTORE_PASSWORD}"  \
       "${CLIENT_NAME}"  "${CLIENT_ALIAS}"  "${CLIENT_KEYSTORE_PASSWORD}"  \
       "${LOGAN_NAME}"   "${LOGAN_ALIAS}"   "${LOGAN_KEYSTORE_PASSWORD}"   \
       "${RMQ_NAME}"
}

if [[ "${1}" == '-g' ]]; then
  if [[ "${2}" == 'dev' || "${2}" == 'test' || "${2}" == 'prod' ]]; then
    STAGE=${2}
  else
    STAGE='dev'
  fi
  ENVIROMENT_TEMPLATE=${BASE_DIR}/compose/templates/.env.${STAGE}
  ENVIROMENT_FILE=${BASE_DIR}/compose/config/.env.${STAGE}
  generateCertificates
  generateEnvironmentFile
elif [[ "${1}" == 'dev' || "${1}" == 'test' || "${1}" == 'prod' ]]; then
  STAGE=${1}
  ENVIROMENT_FILE=${BASE_DIR}/compose/config/.env.${STAGE}
else
  STAGE='dev'
  ENVIROMENT_FILE=${BASE_DIR}/compose/config/.env.${STAGE}
fi



if [[ "${STAGE}" == 'dev' ]]; then
  docker-compose \
    --env-file ${ENVIROMENT_FILE} \
    up
elif [[ "${STAGE}" == 'test' || "${STAGE}" == 'prod' ]]; then
  docker-compose \
    --env-file ${ENVIROMENT_FILE} \
    -f docker-compose.yml \
    -f docker-compose.${STAGE}.yml \
    up
fi
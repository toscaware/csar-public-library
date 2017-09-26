#!/bin/bash

source ${utils_scripts}/utils.sh
log begin

log info "On $(hostname) Updating Elasticsearch with nb_replicas '${nb_replicas}', index '${index}' and order '${order}'"

if [[ "${index}" != "" ]] && [[ "${index}" != "''" ]]; then
    TEMPLATE_NAME=$(echo "${index}" | sed 's/[^a-zA-Z0-9]//g')
else
    index="*"
    TEMPLATE_NAME="all"
fi

TEMPLATE="http://localhost:9200/_template/${TEMPLATE_NAME}"
CURL='/usr/bin/curl'
OP='-XPUT'
PAYLOAD="{\"template\" : \"${index}\", \"order\" : ${order}, \"settings\" : {\"number_of_shards\" : ${number_of_shards}, \"number_of_replicas\" : ${nb_replicas} }}"
log info "Command: $CURL $OP $TEMPLATE -d '${PAYLOAD}'"
$CURL $OP $TEMPLATE -d "${PAYLOAD}" || error_exit "Failed executing Elasticsearch update with nb_replicas ${nb_replicas}, index ${index}and order ${order}" $?
log end

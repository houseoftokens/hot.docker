#!/bin/bash

SCRIPT_ROOT=/hot/bin

${SCRIPT_ROOT}/logrotate.sh &

# check data directiory
if [ $DATADIR ]
then
    echo "Data Dir: ${DATADIR}"
else
    DATADIR="/hot/data"
    echo "Data Dir: ${DATADIR}"
fi

# make data dir if needed
if [ ! -d $DATADIR ]; then
    mkdir -p $DATADIR;
fi

# check if we have history data
GENESIS_JSON_PARAM=""
if [ -f "${DATADIR}/data/blockchain/blocks/blocks.log" ]
then
    echo "data exist, don't cuse --genesis-json argument."
else
    echo "data not exist, use --genesis-json argument."
    GENESIS_JSON_PARAM="--genesis-json /hot/conf/genesis.json"
fi

if [ $GENESIS_JSON_PATH ]
then
    GENESIS_JSON_PARAM="--genesis-json ${GENESIS_JSON_PATH}"
    echo "using custom genesis json config ${GENESIS_JSON_PATH}"
fi

# check nodehot install path
NODEHOT="/hot/bin/nodehot"
if [ $BIN_PATH ]
then
    NODEHOT="$BIN_PATH/nodehot"
fi
echo "APP path: ${NODEHOT}"

# check if last run quit dirty
if [ -f "${DATADIR}/nodehot.pid" ]; then
    echo "find nodehot.pid, run hard replay"
    HARD_REPLAY=1
fi

HARD_REPLAY_PARAM=""
if [ $HARD_REPLAY ]
then
    HARD_REPLAY_PARAM="--hard-replay-blockchain"
    echo "Use hard replay"
fi

TRUNCATE_AT_BLOCK_PARAM=""
if [ $TRUNCATE_AT_BLOCK ]
then
    TRUNCATE_AT_BLOCK_PARAM="--truncate-at-block ${TRUNCATE_AT_BLOCK}"
    echo "$TRUNCATE_AT_BLOCK_PARAM"
fi

# mongo config
MONGO_PARAM=""
if [ $ENABLE_MONGODB ]
then
    MONGO_PARAM="--plugin eosio::mongo_db_plugin --mongodb-uri=${MONGODB_ADDRESS}"
    echo "${MONGO_PARAM}"
fi

# peers config
PEER_PARAM=""
if [ $PEER_NODES ]
then
    OLD_IFS="$IFS"
    IFS="#"
    ARR_PN=($PEER_NODES)
    for PEER_NODE in ${ARR_PN[@]}
    do
        PEER_PARAM=${PEER_PARAM}" --p2p-peer-address ${PEER_NODE}"
    done
    IFS="$OLD_IFS"
fi
echo "Peers: $PEER_PARAM"

# chain-state-db-size config
CHAIN_STATE_DB_SIZE_PARAM="--chain-state-db-size-mb 8192"
if [ $CHAIN_STATE_DB_SIZE ]
then
    CHAIN_STATE_DB_SIZE_PARAM="--chain-state-db-size-mb ${CHAIN_STATE_DB_SIZE}"
fi
echo "$CHAIN_STATE_DB_SIZE_PARAM"

# index of k8s stateful set
IDX_NUM=${HOSTNAME##*-}

if [ "${ENABLE_STALE}" == "enable" ]
then
    STALE_PRODUCTION=1
fi
echo "ENABLE_STALE: ${ENABLE_STALE}"

# enable-stale-production config
STALE_PRODUCTION_PARAM=""
if [ $STALE_PRODUCTION ]
then
    STALE_PRODUCTION_PARAM="--enable-stale-production"
    echo "Use stale production"
fi

# pubkey config
if [ $PUB_KEY_ARR ]
then
    OLD_IFS="$IFS"
    IFS="#"
    ARR_PK=($PUB_KEY_ARR)
    PUB_KEY=${ARR_PK[${IDX_NUM}]}
    IFS="$OLD_IFS"
fi
echo "Pub key: $PUB_KEY"

# prikey config
if [ $PRI_KEY_ARR ]
then
    OLD_IFS="$IFS"
    IFS="#"
    ARR_PK=($PRI_KEY_ARR)
    PRI_KEY=${ARR_PK[${IDX_NUM}]}
    IFS="$OLD_IFS"
    echo "Pri key: $PRI_KEY"
fi

# producer name config
if [ $PRODUCER_NAME_ARR ]
then
    OLD_IFS="$IFS"
    IFS="#"
    ARR_PN=($PRODUCER_NAME_ARR)
    PRODUCER_NAME=${ARR_PN[${IDX_NUM}]}
    IFS="$OLD_IFS"
    echo "Producer Name: $PRODUCER_NAME"
fi

PRODUCER_NAME_PARAM="--producer-name noname"
if [ $PRODUCER_NAME ]
then
    PRODUCER_NAME_PARAM="--producer-name ${PRODUCER_NAME}"
    echo "PRODUCER_NAME_PARAM: ${PRODUCER_NAME_PARAM}"
fi

# extra plugin config
echo "EXTRA_PLUGIN: ${EXTRA_PLUGIN}"
EXTRA_PLUGIN_PARAM=""
if [ $EXTRA_PLUGIN ]
then
    OLD_IFS="$IFS"
    IFS="#"
    ARR_PN=($EXTRA_PLUGIN)
    for PLUGIN_NAME in ${ARR_PN[@]}
    do
        EXTRA_PLUGIN_PARAM=${EXTRA_PLUGIN_PARAM}' --plugin eosio::'${PLUGIN_NAME}
    done
    IFS="$OLD_IFS"
fi

echo "EXTRA_PLUGIN_PARAM: ${EXTRA_PLUGIN_PARAM}"

cd $DATADIR

# run node by server type
if [ "${NODE_TYPE}" == "producer" ]
then
    # producer node
    ${NODEHOT} \
      --signature-provider ${PUB_KEY}=KEY:${PRI_KEY} \
      --plugin eosio::producer_plugin \
      --plugin eosio::chain_api_plugin \
      --plugin eosio::http_plugin \
      ${EXTRA_PLUGIN_PARAM} \
      ${GENESIS_JSON_PARAM} \
      ${STALE_PRODUCTION_PARAM} \
      ${PEER_PARAM} \
      ${HARD_REPLAY_PARAM} \
      ${TRUNCATE_AT_BLOCK_PARAM} \
      ${CHAIN_STATE_DB_SIZE_PARAM} \
      --data-dir $DATADIR"/data" \
      --blocks-dir "blockchain/blocks" \
      --config-dir $DATADIR"/config" \
      ${PRODUCER_NAME_PARAM} \
      --http-server-address 0.0.0.0:8011 \
      --p2p-listen-endpoint 0.0.0.0:9011 \
      --access-control-allow-origin=* \
      --http-validate-host=false \
    >> $DATADIR"/nodehot.log" 2>&1 & \

    echo $! > $DATADIR"/nodehot.pid"
    echo "producer node started. sign key: ${PRI_KEY}."
else
    # service node
    ${NODEHOT} ${PEER_PARAM} \
      --plugin eosio::chain_api_plugin \
      --plugin eosio::http_plugin \
      --plugin eosio::history_api_plugin \
      --plugin eosio::history_plugin \
      ${EXTRA_PLUGIN_PARAM} \
      ${GENESIS_JSON_PARAM} \
      --data-dir $DATADIR"/data" \
      --blocks-dir "blockchain/blocks" \
      --config-dir $DATADIR"/config" \
      ${HARD_REPLAY_PARAM} \
      ${TRUNCATE_AT_BLOCK_PARAM} \
      ${CHAIN_STATE_DB_SIZE_PARAM} \
      ${MONGO_PARAM} \
      --http-server-address 0.0.0.0:8011 \
      --p2p-listen-endpoint 0.0.0.0:9011 \
      --access-control-allow-origin=* \
      --contracts-console \
      --http-validate-host=false \
      --verbose-http-errors \
      -f "*" \
    >> $DATADIR"/nodehot.log" 2>&1 & \

    echo $! > $DATADIR"/nodehot.pid"
    echo "service node started."
fi

# dead loop to detact node exitance
while true; do
    if [ -f "${DATADIR}/nodehot.pid" ]
    then        
        REC_PID=`cat ${DATADIR}/nodehot.pid`
        LIVE_PID=`pgrep nodehot`
        if [ "${REC_PID}" != "${LIVE_PID}" ]
        then
            echo "[ERROR] cannot find pid: ${REC_PID}, live pid: ${LIVE_PID}"
            break
        fi
        sleep 1
    else
        echo "nodehot has been stoped gracefully."
        break
    fi
done

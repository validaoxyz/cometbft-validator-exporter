#!/bin/bash
MISSED_BLOCKS_FILE_PATH="/tmp/node_exporter_custom_metrics/missed_blocks_${NETWORK_NAME}.prom"
JAILED_FILE_PATH="/tmp/node_exporter_custom_metrics/jailed_status_${NETWORK_NAME}.prom"
BONDING_STATUS_FILE_PATH="/tmp/node_exporter_custom_metrics/bonding_status_${NETWORK_NAME}.prom"
BONDED_TOKENS_FILE_PATH="/tmp/node_exporter_custom_metrics/bonded_tokens_${NETWORK_NAME}.prom"
DELEGATOR_COUNT_FILE_PATH="/tmp/node_exporter_custom_metrics/delegator_count_${NETWORK_NAME}.prom"
VALCONSPUB=''


if [ -z "$VALCONSPUB" ]; then
        VALCONSPUB=$($BINARY q staking validator $VALOPER -o json | jq -r '.consensus_pubkey' | tr -d '\n' | tr -d ' ') 
fi

if [ ! -d $(dirname $MISSED_BLOCKS_FILE_PATH) ]; then
        mkdir $(dirname $MISSED_BLOCKS_FILE_PATH)
fi 

while true; do
        #Path of your chain-main application
        MISSED_BLOCKS=$($BINARY query slashing signing-info $VALCONSPUB -o json | jq -r '.missed_blocks_counter')
        JAILED_STATUS=$($BINARY query staking validator $VALOPER -o json | jq -r '.jailed')
        BONDING_STATUS=$($BINARY query staking validator $VALOPER -o json | jq -r '.status')
        BONDED_TOKENS=$($BINARY query staking validator $VALOPER -o json | jq -r '.tokens')
        DELEGATOR_COUNT=$($BINARY query staking delegations-to $VALOPER --count-total -o json | jq -r '.pagination.total')

        # convert to gauge
        if [ $JAILED_STATUS == "true" ]; then
                JAILED_STATUS=1
        elif [ $JAILED_STATUS == "false" ]; then
                JAILED_STATUS=0
        fi

        # convert to gauge
        if [ $BONDING_STATUS == "BOND_STATUS_BONDED" ]; then
                BONDING_STATUS=1
        elif [ $BONDING_STATUS == "BOND_STATUS_UNBONDING" ]; then
                BONDING_STATUS=0
        fi

        # echo missed blocks
        echo "" > $MISSED_BLOCKS_FILE_PATH
        echo "# HELP missed_blocks Total number of missed blocks" >> $MISSED_BLOCKS_FILE_PATH
        echo "# TYPE missed_blocks counter" >> $MISSED_BLOCKS_FILE_PATH
        echo "missed_blocks{validator=\"$NETWORK_NAME\"} $MISSED_BLOCKS" >> $MISSED_BLOCKS_FILE_PATH

        # echo jailed status
        echo "" > $JAILED_FILE_PATH
        echo "# HELP jailed_status Whether the validator is jailed, 1=jailed" >> $JAILED_FILE_PATH
        echo "# TYPE jailed_status gauge" >> $JAILED_FILE_PATH
        echo "jailed_status{validator=\"$NETWORK_NAME\"} $JAILED_STATUS" >> $JAILED_FILE_PATH

        # echo bonding status
        echo "" > $BONDING_STATUS_FILE_PATH
        echo "# HELP bonding_status If validator is active or not, 1=active" >> $BONDING_STATUS_FILE_PATH
        echo "# TYPE bonding_status gauge" >> $BONDING_STATUS_FILE_PATH
        echo "bonding_status{validator=\"$NETWORK_NAME\"} $BONDING_STATUS" >> $BONDING_STATUS_FILE_PATH

        # echo tokens staked
        echo "" > $BONDED_TOKENS_FILE_PATH
        echo "# HELP bonded_tokens The amount of coins staked to our validator" >> $BONDED_TOKENS_FILE_PATH
        echo "# TYPE bonded_tokens gauge" >> $BONDED_TOKENS_FILE_PATH
        echo "bonded_tokens{validator=\"$NETWORK_NAME\"} $BONDED_TOKENS" >> $BONDED_TOKENS_FILE_PATH

        # echo delegator count
        echo "" > $DELEGATOR_COUNT_FILE_PATH
        echo "# HELP delegator_count The amount of individual wallets staked to our validator" >> $DELEGATOR_COUNT_FILE_PATH
        echo "# TYPE delegator_count gauge" >> $DELEGATOR_COUNT_FILE_PATH
        echo "delegator_count{validator=\"$NETWORK_NAME\"} $DELEGATOR_COUNT" >> $DELEGATOR_COUNT_FILE_PATH

        sleep 5;

#!/bin/sh
set -e

apk -q --no-cache add curl jq

pip -q install s3cmd

for file in NA12878.bam NA12878_20k_b37.bam; do
    curl -s -L -o $file "https://github.com/ga4gh/htsget-refserver/raw/main/data/gcp/gatk-test-data/wgs_bam/$file"

    yes | /shared/crypt4gh encrypt -p /shared/c4gh.pub.pem -f $file
    ENC_SHA=$(sha256sum "$file.c4gh" | cut -d' ' -f 1)
    ENC_MD5=$(md5sum "$file.c4gh" | cut -d' ' -f 1)
    s3cmd -q -c /shared/s3cfg put "$file.c4gh" s3://dummy_gdi.eu/"$file.c4gh"

    ## get correlation id from upload message
    CORRID=$(
        curl -s -X POST \
            -H "content-type:application/json" \
            -u test:test http://rabbitmq:15672/api/queues/gdi/inbox/get \
            -d '{"count":1,"encoding":"auto","ackmode":"ack_requeue_false"}' | jq -r .[0].properties.correlation_id
    )

    ## publish message to trigger ingestion
    properties=$(
        jq -c -n \
            --argjson delivery_mode 2 \
            --arg correlation_id "$CORRID" \
            --arg content_encoding UTF-8 \
            --arg content_type application/json \
            '$ARGS.named'
    )

    encrypted_checksums=$(
        jq -c -n \
            --arg sha256 "$ENC_SHA" \
            --arg md5 "$ENC_MD5" \
            '$ARGS.named|to_entries|map(with_entries(select(.key=="key").key="type"))'
    )

    ingest_payload=$(
        jq -r -c -n \
            --arg type ingest \
            --arg user dummy@gdi.eu \
            --arg filepath dummy_gdi.eu/"$file.c4gh" \
            --argjson encrypted_checksums "$encrypted_checksums" \
            '$ARGS.named|@base64'
    )

    ingest_body=$(
        jq -c -n \
            --arg vhost test \
            --arg name sda \
            --argjson properties "$properties" \
            --arg routing_key "ingest" \
            --arg payload_encoding base64 \
            --arg payload "$ingest_payload" \
            '$ARGS.named'
    )

    curl -s -u test:test "http://rabbitmq:15672/api/exchanges/gdi/sda/publish" \
        -H 'Content-Type: application/json;charset=UTF-8' \
        -d "$ingest_body"
done

### wait for ingestion to complete
echo "waiting for ingestion to complete"
RETRY_TIMES=0
until [ "$(curl -s -u test:test http://rabbitmq:15672/api/queues/gdi/verified | jq -r '."messages_ready"')" -eq 2 ]; do
    echo "waiting for ingestion to complete"
    RETRY_TIMES=$((RETRY_TIMES + 1))
    if [ "$RETRY_TIMES" -eq 30 ]; then
        echo "::error::Time out while waiting for ingestion to complete"
        exit 1
    fi
    sleep 2
done

I=0
for file in NA12878.bam NA12878_20k_b37.bam; do
    I=$((I+1))
    decrypted_checksums=$(
        curl -s -u test:test \
            -H "content-type:application/json" \
            -X POST http://rabbitmq:15672/api/queues/gdi/verified/get \
            -d '{"count":1,"encoding":"auto","ackmode":"ack_requeue_false"}' | jq -r '.[0].payload|fromjson|.decrypted_checksums|tostring'
    )

    finalize_payload=$(
        jq -r -c -n \
            --arg type accession \
            --arg user dummy@gdi.eu \
            --arg filepath dummy_gdi.eu/"$file.c4gh" \
            --arg accession_id "EGAF7490000000$I" \
            --argjson decrypted_checksums "$decrypted_checksums" \
            '$ARGS.named|@base64'
    )

    finalize_body=$(
        jq -c -n \
            --arg vhost test \
            --arg name sda \
            --argjson properties "$properties" \
            --arg routing_key "accessionIDs" \
            --arg payload_encoding base64 \
            --arg payload "$finalize_payload" \
            '$ARGS.named'
    )

    curl -s -u test:test "http://rabbitmq:15672/api/exchanges/gdi/sda/publish" \
        -H 'Content-Type: application/json;charset=UTF-8' \
        -d "$finalize_body"
done

### Assign file to dataset
mappings=$(
    jq -c -n \
        '$ARGS.positional' \
        --args "EGAF74900000001" \
        --args "EGAF74900000002"
)

mapping_payload=$(
    jq -r -c -n \
        --arg type mapping \
        --arg dataset_id EGAD74900000101 \
        --argjson accession_ids "$mappings" \
        '$ARGS.named|@base64'
)

mapping_body=$(
    jq -c -n \
        --arg vhost test \
        --arg name sda \
        --argjson properties "$properties" \
        --arg routing_key "mappings" \
        --arg payload_encoding base64 \
        --arg payload "$mapping_payload" \
        '$ARGS.named'
)

curl -s -u test:test "http://rabbitmq:15672/api/exchanges/gdi/sda/publish" \
    -H 'Content-Type: application/json;charset=UTF-8' \
    -d "$mapping_body"

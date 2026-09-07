## A script similar to this can be used to create connectors making sure the endpoints are ready

echo "Waiting for Kafka Connect to start listening on kafka-connect  "
while :; do
    # Check if the connector endpoint is ready
    # If not check again
    curl_status=$(curl -s -o /dev/null -w %{http_code} http://localhost:8083/connectors)
    echo -e $(date) "Kafka Connect listener HTTP state: " $curl_status " (waiting for 200)"
    if [ $curl_status -eq 200 ]; then
        break
    fi
    sleep 5
done

echo "======> Delete all Connectors"
curl -s "http://localhost:8083/connectors"| jq '.[]'| xargs -I{connector_name} curl -s -XDELETE "http://localhost:8083/connectors/"{connector_name}

echo "======> Creating connectors"
# Send a simple POST request to create the connector
# curl -X POST --data-binary @path/to/my-file.txt http://example.com/
for filename in /etc/kafka-connect/configs/*.json; do
    curl -X POST -H "Content-Type: application/json" --data-binary @$filename http://localhost:8083/connectors
    sleep 5
done    


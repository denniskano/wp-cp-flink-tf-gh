#!/bin/ash
cd /opt/

ls -la

echo -e "\n"
echo " CERT PASS ======= $CERT_PASS"
if [ -f "/opt/$KAFKA_KEYSTORE" ]; then
    rm /opt/$KAFKA_KEYSTORE
fi
if [ -f "/opt/$KAFKA_TRUSTSTORE" ]; then
    rm /opt/$KAFKA_TRUSTSTORE
fi

rm -rf /tmp/trustCAs
mkdir /tmp/trustCAs

keytool -importkeystore \
	-deststorepass $CERT_PASS \
	-destkeypass $CERT_PASS \
	-destkeystore $KAFKA_KEYSTORE \
	-deststoretype pkcs12 \
	-srckeystore $PKCS \
	-srcstoretype PKCS12 \
	-srcstorepass $CERT_PASS

echo "Validate Server Certificate from Keytool keystore $KAFKA_KEYSTORE"
keytool -list -v -keystore $KAFKA_KEYSTORE -storepass $CERT_PASS
echo -e "\n"
# create truststore jks
echo "CREATE TRUSTSTORE"
echo -e "\n"
cat $KAFKA_PUBLIC_PEM | awk 'split_after==1{n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > ("/tmp/trustCAs/ca" n ".pem")}'
for file in /tmp/trustCAs/*; do
  fileName="${file##*/}"
  keytool -import \
		-trustcacerts \
		-alias ${fileName} \
		-file ${file} \
		-keystore $KAFKA_TRUSTSTORE \
		-deststorepass $CERT_PASS \
		-deststoretype pkcs12 \
		-noprompt
done
echo "validate CA certs keystore $KAFKA_TRUSTSTORE"
keytool -list -v -keystore $KAFKA_TRUSTSTORE -storepass $CERT_PASS

echo -e "\n"






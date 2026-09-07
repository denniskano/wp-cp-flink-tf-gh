#!/bin/bash


################################################################################
# Overview
################################################################################
#
# Secret Protection functionality using the updated Confluent CLI
#
# Documentation accompanying this tutorial: README.adoc
#
# Usage:
#
#   # Provide all arguments on command line
#   ./demo-secret-protection.sh $workspace
#
# Requirements:
#
#   - Confluent Platform 5.4 or higher (https://www.confluent.io/download/)
#   - Local install of Confluent CLI (v0.200.0 or above)
#
################################################################################

##################################################
# Initialize parameters
##################################################
WORKSPACE=$1
echo -e "\n----- Initialize parameters -----"
PASSPHRASE_FILE=$WORKSPACE/passphrase.txt
LOCAL_SECRETS_FILE=$WORKSPACE/security-secrets.properties
REMOTE_SECRETS_FILE=$WORKSPACE/security-secrets.properties
ORIGINAL_CONFIGURATION_FILE=$WORKSPACE/plaintext-config-file.properties
MODIFIED_CONFIGURATION_FILE=$WORKSPACE/encrypted-config-file.properties
CONFIG=$secretFields
OUTPUT_FILE=$WORKSPACE/output.txt
# cleanup

# echo -e "\n----- LANG  Charset  -----"
# echo $LANG
export LANG="C.UTF-8"
# echo $LANG

# function cleanup {
rm -f $LOCAL_SECRETS_FILE
rm -f $REMOTE_SECRETS_FILE
rm -f $MODIFIED_CONFIGURATION_FILE
rm -f $OUTPUT_FILE
unset CONFLUENT_SECURITY_MASTER_KEY

#  return 0
# }

##################################################
# Configure Pre-Requisites
##################################################
# echo $secretFields
# for secretField in $secretFields; do
# echo "pfx.password=$CERT_PASS" >> $WORKSPACE/encrypted-config-file.properties
# done
# echo $CREDENTIAL_ID > $WORKSPACE/passphrase.txt
# ls -la ${WORKSPACE}/
# pwd
# cat $WORKSPACE/encrypted-config-file.properties
# cat $WORKSPACE/passphrase.txt

##################################################
# Generate the master key based on a passphrase
##################################################
echo -e "\n----- Generate the master key -----"
echo -e "\nGenerate the master key based on a passphrase"
echo -e "confluent secret master-key generate --passphrase @$PASSPHRASE_FILE --local-secrets-file $LOCAL_SECRETS_FILE"
OUTPUT=$(confluent secret master-key generate --passphrase @$PASSPHRASE_FILE --local-secrets-file $LOCAL_SECRETS_FILE)
if [[ $? != 0 ]]; then
  echo "Failed to create master-key. Please troubleshoot and run again"
  exit 1
fi
MASTER_KEY=$(echo "$OUTPUT" | grep '| Master Key' | awk '{print $5;}')
echo "MASTER_KEY: $MASTER_KEY"

# Export the master key
echo -e "\nExport the master key"
# echo -e "export CONFLUENT_SECURITY_MASTER_KEY=$MASTER_KEY"
# echo $MASTER_KEY | base64 >  $WORKSPACE/master-key.txt
echo -n $MASTER_KEY>  $WORKSPACE/master-key.txt
export CONFLUENT_SECURITY_MASTER_KEY=$MASTER_KEY
cat -v $WORKSPACE/master-key.txt
ls -la $WORKSPACE
##################################################
# Encrypt the value of a configuration parameter
# - configuration file is a copy of $CONFLUENT_HOME/etc/schema-registry/connect-avro-distributed.properties
# - configuration parameter is config.storage.topic
##################################################
cp $ORIGINAL_CONFIGURATION_FILE $MODIFIED_CONFIGURATION_FILE

# echo -e "\nShow Passwords file $ORIGINAL_CONFIGURATION_FILE"
# cat $ORIGINAL_CONFIGURATION_FILE
echo -e "\n----- Encrypt configuration parameter -----"
echo -e "\nvalue of $CONFIG in $MODIFIED_CONFIGURATION_FILE"
# grep "^$CONFIG" $MODIFIED_CONFIGURATION_FILE

# Explicitly specify which configuration parameters should be encrypted
echo -e "\nEncrypt the configuration parameter $CONFIG in configuration file $MODIFIED_CONFIGURATION_FILE"
echo -e "confluent secret file encrypt --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $REMOTE_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --config $CONFIG"
confluent secret file encrypt --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $REMOTE_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --config $CONFIG


echo -e "\nvalue of $CONFIG in $MODIFIED_CONFIGURATION_FILE"
cat -v $MODIFIED_CONFIGURATION_FILE

echo -e "\nvalue of $REMOTE_SECRETS_FILE"
cat -v $REMOTE_SECRETS_FILE

echo -e "\nvalue of $LOCAL_SECRETS_FILE"
cat -v $LOCAL_SECRETS_FILE
##################################################
# Update the value of the configuration parameter
##################################################
# Check the secrets

# echo -e "\n----- Update the value of the configuration parameter -----"
# echo -e "\nvalue of $CONFIG in $MODIFIED_CONFIGURATION_FILE"
# grep "^$CONFIG" $MODIFIED_CONFIGURATION_FILE
# echo -e "\nvalue of $CONFIG in $LOCAL_SECRETS_FILE"
# grep $CONFIG $LOCAL_SECRETS_FILE

# Update the parameter value
# echo -e "\nUpdate the configuration parameter $CONFIG to a new value"
# echo -e "confluent secret file update --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $REMOTE_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --config @etc/new-config-value.txt"
# confluent secret file update --local-secrets-file $LOCAL_SECRETS_FILE --remote-secrets-file $REMOTE_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --config @etc/new-config-value.txt

# Check the secrets again
# echo -e "\nvalue of $CONFIG in $MODIFIED_CONFIGURATION_FILE (this has not changed)"
# grep "^$CONFIG" $MODIFIED_CONFIGURATION_FILE
# echo -e "\nvalue of $CONFIG in $LOCAL_SECRETS_FILE (this has changed)"
# grep $CONFIG $LOCAL_SECRETS_FILE

##################################################
# Decrypt the file
##################################################

# Print the decrypted configuration values
# echo -e "\n----- Rotate the data key and decrypt the configuration parameter -----"
# echo -e "\nDecrypt the secret"
# echo -e "confluent secret file decrypt --local-secrets-file $LOCAL_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --output-file $OUTPUT_FILE"
# confluent secret file decrypt --local-secrets-file $LOCAL_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --output-file $OUTPUT_FILE
# echo -e "\ndecrypted value:"
# cat $OUTPUT_FILE

# Rotate datakey
# echo -e "\nRotate the datakey"
# echo -e "confluent secret file rotate --data-key --local-secrets-file $LOCAL_SECRETS_FILE --passphrase @etc/passphrase.txt"
# confluent secret file rotate --data-key --local-secrets-file $LOCAL_SECRETS_FILE --passphrase @etc/passphrase.txt

# Print the decrypted configuration values
# echo -e "\nDecrypt the secret after the datakey has been rotated"
# echo -e "confluent secret file decrypt --local-secrets-file $LOCAL_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --output-file $OUTPUT_FILE"
# confluent secret file decrypt --local-secrets-file $LOCAL_SECRETS_FILE --config-file $MODIFIED_CONFIGURATION_FILE --output-file $OUTPUT_FILE
# echo -e "\ndecrypted value:"
# cat $OUTPUT_FILE

##################################################
# End
##################################################
# echo -e "\n----- View files -----\n"
# echo -e "LOCAL_SECRETS_FILE: $LOCAL_SECRETS_FILE"
# echo -e "ORIGINAL_CONFIGURATION_FILE: $ORIGINAL_CONFIGURATION_FILE"
# echo -e "MODIFIED_CONFIGURATION_FILE: $MODIFIED_CONFIGURATION_FILE"

# echo -e "\n----- diff files -----\n"
# echo "diff -w $ORIGINAL_CONFIGURATION_FILE $MODIFIED_CONFIGURATION_FILE"
# diff -w $ORIGINAL_CONFIGURATION_FILE $MODIFIED_CONFIGURATION_FILE
echo -e "\n------------------------- END SECRET PROTECTION ------------------------------"

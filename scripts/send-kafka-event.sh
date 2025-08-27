#!/bin/bash

# Script to send a message to Kafka topic with delay
# Usage: ./send-kafka-event.sh

# Delay in seconds
DELAY=5
TOPIC="ticketly.seats.locked"

echo "Waiting for $DELAY seconds before sending message to $TOPIC..."
sleep $DELAY

# Extract the session ID to use as the key
KEY="7132888b-271d-4b43-b2df-817247399483"

# JSON payload - formatted as a single line to avoid newline issues
PAYLOAD='{"sessionId":"7132888b-271d-4b43-b2df-817247399483","seatIds":["af4e2ffb-034a-4ad2-a4e9-9871581f4532"]}'

# Create a temporary file with the key and value separated by a colon
echo "Sending message to $TOPIC with key: $KEY"
# Create a temporary file with the correct format
TEMP_FILE=$(mktemp)
echo "${KEY}:${PAYLOAD}" > $TEMP_FILE

# Send the message using the file as input
cat $TEMP_FILE | docker exec -i kafka kafka-console-producer --bootstrap-server kafka:29092 --topic $TOPIC --property parse.key=true --property key.separator=:

# Clean up the temporary file
rm $TEMP_FILE

echo -e "\nMessage sent successfully!"

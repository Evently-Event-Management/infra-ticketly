#!/bin/bash

# Check if loop mode is requested
LOOP_MODE=false
if [[ "$1" == "--loop" ]]; then
    LOOP_MODE=true
fi

monitor_once() {
    clear
    echo "=== EventBridge Scheduler & SQS Monitor ==="
    echo "Date: $(date)"
    echo ""

    # Set LocalStack endpoint
    ENDPOINT="http://localhost:4566"

    echo "📅 SCHEDULED TASKS:"
    echo "==================="
    aws --endpoint-url=$ENDPOINT scheduler list-schedules --query 'Schedules[*].[Name,State,CreationDate]' --output table

    echo ""
    echo "📋 ACTIVE SCHEDULE:"
    echo "=================="
    aws --endpoint-url=$ENDPOINT scheduler get-schedule \
        --name "session-onsale-bd6599e7-4d77-4b11-ad26-c506f5ef8c82" \
        --group-name "event-ticketing-schedules" \
        --query '{Name:Name,Expression:ScheduleExpression,State:State,Input:Target.Input}' \
        --output table

    echo ""
    echo "📨 SQS QUEUE STATUS:"
    echo "==================="
    QUEUE_URL="http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/session-on-sale-queue"
    
    # Get message counts
    echo "Queue: session-on-sale-queue"
    aws --endpoint-url=$ENDPOINT sqs get-queue-attributes \
        --queue-url "$QUEUE_URL" \
        --attribute-names ApproximateNumberOfMessages \
        --output table
    
    # Try to peek at messages
    echo ""
    echo "📬 RECENT MESSAGES:"
    echo "=================="
    MESSAGES=$(aws --endpoint-url=$ENDPOINT sqs receive-message \
        --queue-url "$QUEUE_URL" \
        --max-number-of-messages 5 \
        --visibility-timeout 1 2>/dev/null)
    
    if [[ -n "$MESSAGES" ]]; then
        echo "$MESSAGES" | grep -o '"Body":"[^"]*"' || echo "Messages found but couldn't parse"
    else
        echo "No messages in queue"
    fi

    echo ""
    echo "🕒 TIME INFO:"
    echo "============"
    echo "Local: $(date)"
    echo "UTC:   $(date -u)"
    echo ""
    
    if [[ "$LOOP_MODE" == "true" ]]; then
        echo "Press Ctrl+C to stop monitoring..."
        echo "Next update in 5 seconds..."
    else
        echo "Run './scripts/monitor-sqs-live.sh --loop' for continuous monitoring"
    fi
}

if [[ "$LOOP_MODE" == "true" ]]; then
    echo "Starting continuous monitoring (Press Ctrl+C to stop)..."
    while true; do
        monitor_once
        sleep 5
    done
else
    monitor_once
fi

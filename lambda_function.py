import os
import time
import json
import urllib.request
import urllib.error
from datetime import datetime, timezone
import boto3

# Explicitly bind AWS SDK clients to us-east-1
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
sns = boto3.client('sns', region_name='us-east-1')
s3 = boto3.client('s3', region_name='us-east-1')

# Read and sanitize environment variables
TARGET_URL = (os.environ.get('TARGET_URL') or '').strip()
DYNAMODB_TABLE = (os.environ.get('DYNAMODB_TABLE') or 'website-uptime-history').strip()
SNS_TOPIC_ARN = (os.environ.get('SNS_TOPIC_ARN') or '').strip()
S3_BUCKET_NAME = (os.environ.get('S3_BUCKET_NAME') or 'website-uptime-dashboard-sun-waliur-2026').strip()

def lambda_handler(event, context):
    print(f"Starting uptime check for target: '{TARGET_URL}'")
    print(f"Configured DynamoDB table: '{DYNAMODB_TABLE}'")
    print(f"Configured SNS Topic ARN: '{SNS_TOPIC_ARN}'")
    print(f"Configured S3 Bucket: '{S3_BUCKET_NAME}'")

    timestamp_iso = datetime.now(timezone.utc).isoformat()
    status = "DOWN"
    response_code = 0
    latency_ms = 0.0
    error_message = None

    # Step 1: Execute Synthetic Health Check Probe
    start_time = time.time()
    try:
        req = urllib.request.Request(
            TARGET_URL,
            headers={'User-Agent': 'AWS-Lambda-Uptime-Monitor/1.0'}
        )
        with urllib.request.urlopen(req, timeout=10) as response:
            latency_ms = round((time.time() - start_time) * 1000, 2)
            response_code = response.getcode()
            if response_code == 200:
                status = "UP"
            else:
                status = "DEGRADED"
                error_message = f"Unexpected HTTP status: {response_code}"
    except urllib.error.HTTPError as e:
        latency_ms = round((time.time() - start_time) * 1000, 2)
        response_code = e.code
        error_message = f"HTTP Error {e.code}: {e.reason}"
    except Exception as e:
        latency_ms = round((time.time() - start_time) * 1000, 2)
        error_message = str(e)

    print(f"Probe Result - Status: {status}, Code: {response_code}, Latency: {latency_ms} ms")

    # Step 2: Record Probe into DynamoDB Table
    if DYNAMODB_TABLE:
        try:
            table = dynamodb.Table(DYNAMODB_TABLE)
            table.put_item(
                Item={
                    'site_url': TARGET_URL,
                    'timestamp': timestamp_iso,
                    'status': status,
                    'response_code': response_code,
                    'latency_ms': str(latency_ms),
                    'error': error_message or "None"
                }
            )
            print("Successfully recorded log item to DynamoDB.")
        except Exception as ddb_err:
            print(f"DynamoDB PutItem Failed: {str(ddb_err)}")
            raise ddb_err

    # Step 3: Trigger SNS Outage Alert if Site is NOT UP
    if status != "UP" and SNS_TOPIC_ARN:
        print(f"Attempting to publish downtime alert to SNS Topic: '{SNS_TOPIC_ARN}'")
        alert_body = (
            f"CRITICAL: Website Outage Detected!\n\n"
            f"Target URL: {TARGET_URL}\n"
            f"Status: {status}\n"
            f"HTTP Code: {response_code}\n"
            f"Latency: {latency_ms} ms\n"
            f"Error Details: {error_message}\n"
            f"Timestamp (UTC): {timestamp_iso}\n"
        )
        try:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=f"OUTAGE ALERT: {TARGET_URL} is {status}",
                Message=alert_body
            )
            print("Successfully published outage alert to SNS.")
        except Exception as sns_err:
            print(f"SNS Publish Failed: {str(sns_err)}")
            raise sns_err

    # Step 4: Publish Telemetry Payload to S3 Static Dashboard
    status_payload = {
        "targetUrl": TARGET_URL,
        "status": status,
        "responseCode": response_code,
        "latencyMs": latency_ms,
        "lastChecked": timestamp_iso,
        "errorMessage": error_message
    }

    if S3_BUCKET_NAME:
        try:
            s3.put_object(
                Bucket=S3_BUCKET_NAME,
                Key='status.json',
                Body=json.dumps(status_payload, indent=2),
                ContentType='application/json'
            )
            print(f"Successfully updated status.json in S3 bucket '{S3_BUCKET_NAME}'.")
        except Exception as s3_err:
            print(f"S3 PutObject Failed: {str(s3_err)}")
            raise s3_err

    return {
        "statusCode": 200,
        "body": json.dumps(status_payload)
    }
import os
import json
import boto3
from botocore.exceptions import ClientError

# Reuse boto3 client across invocations (performance best practice)
glue = boto3.client("glue")

def lambda_handler(event, context):
    """
    Lambda to trigger a single Glue crawler when called by Step Function / EventBridge.
    """

    crawler_name = os.environ.get("CRAWLER_NAME")
    if not crawler_name:
        return {
            "statusCode": 400,
            "body": "Missing environment variable: CRAWLER_NAME"
        }

    try:
        # Log the incoming event (optional, helps debugging)
        print("Received event:", json.dumps(event))

        # Start the crawler
        response = glue.start_crawler(Name=crawler_name)

        return {
            "statusCode": 200,
            "body": f"Crawler '{crawler_name}' triggered successfully.",
            "response": response
        }

    except ClientError as e:
        error_message = str(e)
        print(f"Failed to start crawler: {error_message}")

        return {
            "statusCode": 500,
            "body": f"Error starting crawler: {error_message}"
        }

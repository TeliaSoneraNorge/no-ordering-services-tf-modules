import os
import logging
import boto3
from datetime import datetime, timedelta

import dynamodb

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# local testing only
logging.basicConfig(level=logging.INFO)

DYNAMO_DB_TABLE = os.getenv('DYNAMO_DB_TABLE')
FAILING_INTERVAL_IN_MINUTES = int(os.getenv('FAILING_INTERVAL_IN_MINUTES'))
MAX_FAILING_COUNT = int(os.getenv('MAX_FAILING_COUNT'))
DYNAMODB_ITEMS_TTL = int(os.getenv('DYNAMODB_ITEMS_TTL'))
SNS_ARN = os.getenv("SNS_ARN")
NOTIFY_ON_FAILING = os.getenv("NOTIFY_ON_FAILING")
SHUTDOWN_ON_FAILING = os.getenv("SHUTDOWN_ON_FAILING")

ecs_client = boto3.client("ecs")
sns_client = boto3.client('sns')


def lambda_handler(event, context):
    logger.info(f'event: {event}')
     
    try:
        service, execution_stopped_at, ttl, cluster_arn = extract_details_from_event(event)

        events = dynamodb.get_ecs_task_failing_items_by_service_in_failing_interval(DYNAMO_DB_TABLE, service,
                                                                                    MAX_FAILING_COUNT,
                                                                                    FAILING_INTERVAL_IN_MINUTES)
        dynamodb.put_ecs_task_failing_group(DYNAMO_DB_TABLE, service, execution_stopped_at, ttl)

        if evaluate_service_shutdown_prerequisite(events, service, execution_stopped_at):
            if "enabled" == NOTIFY_ON_FAILING:
                sns_notify("ECS Task Failing Notification", f"Service: {service} is constantly failing to start.")
            if "enabled" == SHUTDOWN_ON_FAILING:
                shutdown_service(service.split(':')[1], cluster_arn)

    except Exception as e:
        logger.error(f'ECS service check for container infinite restarts failed: {event}')
        logger.error(e)
        subject = "ECS Task Failing Error"
        message = f"Service: {service} shutdown failed."
        sns_notify(subject, message)


def extract_details_from_event(event):
    service = event['detail']['group']
    execution_stopped_at = event['detail']['executionStoppedAt']
    ttl_datetime = datetime.strptime(execution_stopped_at, "%Y-%m-%dT%H:%M:%S.%fZ") + timedelta(
        hours=DYNAMODB_ITEMS_TTL)
    ttl = ttl_datetime.timestamp()
    cluster_arn = event['detail']['clusterArn']

    return service, execution_stopped_at, ttl, cluster_arn


def evaluate_service_shutdown_prerequisite(items, service, execution_stopped_at):
    items.insert(0,
                 {
                     "Service": service,
                     "ExecutionStoppedAt": execution_stopped_at
                 })

    return len(items) >= MAX_FAILING_COUNT


def shutdown_service(service_name, cluster):
    logger.info(f'Shutting down service: {service_name}')
    ecs_client.update_service(
        cluster=cluster,
        service=service_name,
        desiredCount=0
    )


def sns_notify(subject, message):
    sns_client.publish(
        Subject=subject,
        TopicArn=SNS_ARN,
        Message=message
    )

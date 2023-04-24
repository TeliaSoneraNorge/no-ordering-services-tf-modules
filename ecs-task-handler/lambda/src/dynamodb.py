import boto3
import logging
from datetime import datetime, timedelta
from decimal import Decimal


logger = logging.getLogger()
logger.setLevel(logging.INFO)

# local testing only
logging.basicConfig(level=logging.INFO)

dynamodb = boto3.resource('dynamodb')


def get_ecs_task_failing_items_by_service_in_failing_interval(table, service, item_count, failing_interval_in_minutes):
    logger.info(f'Looking for {service} in table: {table} within last {failing_interval_in_minutes} minutes')

    _date_time = (datetime.now() - timedelta(minutes=failing_interval_in_minutes))
    esa_condition = _date_time.strftime("%Y-%m-%dT%H:%M:%S.%fZ")

    table = dynamodb.Table(table)
    items = table.query(Limit=item_count,
                        ConsistentRead=True,
                        KeyConditionExpression="Service = :service and ExecutionStoppedAt >= :execution_stopped_at",
                        ExpressionAttributeValues={
                            ":service": service,
                            ":execution_stopped_at": esa_condition
                        },
                        ScanIndexForward=False,
                        )
    return items['Items']


def put_ecs_task_failing_group(table, service, execution_stopped_at, ttl):
    logger.info(f'Adding group {service} in table: {table}')

    item = {
        "Service": service,
        "ExecutionStoppedAt": execution_stopped_at,
        "TTL": Decimal(ttl)
    }
    table = dynamodb.Table(table)
    table.put_item(Item=item)

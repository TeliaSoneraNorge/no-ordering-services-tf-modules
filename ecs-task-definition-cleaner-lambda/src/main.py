import boto3
import os
from cleaner import EcsTasksDefCleaner

OLD_REVISION_COUNT = os.environ['OLD_REVISION_COUNT']

ssm = boto3.client('ssm')

def lambda_handler(event, context):
    ecs_cluster_name, ecs_service_name, old_revision_count, dry_run = get_parameters(event)

    cleaner = EcsTasksDefCleaner( old_revision_count=old_revision_count, dry_run=dry_run )
    cleaner.clean_for_service(ecs_cluster_name, ecs_service_name)

    return {
        'statusCode': 200,
        'body': {}
    }


def get_parameters(event):

    ecs_cluster_name = event["ecs_cluster_name"] if "ecs_cluster_name" in event else ""
    ecs_service_name = event["ecs_service_name"] if "ecs_service_name" in event else ""
    old_revision_count = int(event["old_revision_count"]) if "old_revision_count" in event else OLD_REVISION_COUNT
    dry_run = False if "dry_run" in event and event["dry_run"] == "False" else True
    if ecs_cluster_name == "" or ecs_service_name == "":
        raise ValueError("Expected parameters in event: ecs_service_name, ecs_cluster_name")
    return [ecs_cluster_name, ecs_service_name, old_revision_count, dry_run]
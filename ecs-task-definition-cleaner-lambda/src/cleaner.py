import boto3


class EcsTasksDefCleaner:
    """
    The cleaner deletes old revisions of ECS task definition,
    Will not touch the first revision (most likely is in TF state) and the currently deployed
    """

    def __init__(self, old_revision_count=10, dry_run=True):
        self.old_revision_count = int(old_revision_count)
        self.client = boto3.client("ecs")
        self.dry_run = dry_run
        self.deregistered_count = 0
        self.removed_count = 0

    def clean_for_service(self, ecs_cluster_name, ecs_service_name):

        print(f"Starting cleaning procedure for service: {ecs_service_name},"
              f" will keep {self.old_revision_count} revisions")

        deployed_revision = self.__get_deployed_revision_for_the_service(ecs_cluster_name, ecs_service_name)
        print(f"Currently deployed revision {deployed_revision}")
        revisions_to_delete = self.get_task_revisions_for_delete(deployed_revision)
        if len(revisions_to_delete) > 0:
            self.__delete_revisions(revisions_to_delete)

    def clean_for_cluster(self, ecs_cluster_name):

        raise NotImplemented

    def get_task_revisions_for_delete(self, deployed_revision):

        # e.g arn:aws:ecs:eu-west-1:456893923059:task-definition/st1-api-security-hand:3ler4
        family = deployed_revision[deployed_revision.rfind("/") + 1:deployed_revision.rfind(":")]
        all_revisions = self.__get_all_task_revisions(family)
        to_delete = []

        # skip the last element from the list (the oldest revision) because most likely is in TF state
        if len(all_revisions) > 0:
            print(f"Skipping the element due to TF state: {all_revisions[-1]}")
            all_revisions.pop()

        # skip deployed revision
        if deployed_revision in all_revisions:
            print(f"Skipping the element because is currently deployed: {deployed_revision}")
            all_revisions.remove(deployed_revision)

        if len(all_revisions) > self.old_revision_count:
            to_delete = all_revisions[self.old_revision_count:]

        print(f"Number of all eligible revisions = {len(all_revisions)}")
        print(f"Number of revisions to be deleted = {len(to_delete)}")

        return to_delete

    def __get_all_task_revisions(self, family):
        response_active = self.__get_task_revisions_for_service(family, "ACTIVE")
        response_inactive = self.__get_task_revisions_for_service(family, "INACTIVE")
        all_tasks_revisions = response_active["taskDefinitionArns"] + response_inactive["taskDefinitionArns"]
        return all_tasks_revisions

    def __get_deployed_revision_for_the_service(self, ecs_cluster_name, ecs_service_name):

        response = self.client.describe_services(
            cluster=ecs_cluster_name,
            services=[ecs_service_name])
        if len(response["services"]) == 0:
            raise Exception(f"Didn't find service {ecs_cluster_name, ecs_service_name}")
        service = response["services"][0]
        return service["taskDefinition"]

    def __get_task_revisions_for_service(self, family_prefix, status):
        response = self.client.list_task_definitions(
            familyPrefix=family_prefix,
            status=status,
            sort="DESC"
        )
        return response

    def __delete_revisions(self, revisions_to_delete):

        # deregister task definition
        for revision in revisions_to_delete:

            if self.dry_run:
                print(f"DryRun: Cleaning revision: {revision}")
                continue

            self.__delete_revision(revision)

        print(f"Deregistered: {self.deregistered_count}")
        print(f"Removed: {self.removed_count}")

    def __delete_revision(self, revision):

        print(f"Cleaning revision {revision}")
        try:
            self.client.deregister_task_definition(
                taskDefinition=revision
            )
            self.deregistered_count += 1
        except Exception as e:
            print(f"Problem to deregister revision {revision}")
            print(e)
        try:
            self.client.delete_task_definitions(
                taskDefinitions=[revision]
            )
            self.removed_count += 1
        except Exception as e:
            print(f"Problem to delete revision {revision}")
            print(e)

import os, sys
from unittest.mock import MagicMock

test_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(test_dir + "/../src")

# before cleaner, env variables need to be set
import tests.lambda_env as env
import src.cleaner as cleaner
from pytest import fixture

revisions = [
    "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:6",
    "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:5",
    "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:4",
    "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:3",
    "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:2",
    "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:1",
]


@fixture
def task_revisions_for_service_mock(mocker):
    mock = mocker.patch("src.cleaner.EcsTasksDefCleaner._EcsTasksDefCleaner__get_all_task_revisions",
                        return_value=MagicMock(), autospec=True)
    mock.return_value = list(revisions)
    return mock

@fixture
def task_revision_in_terraform_state_none(mocker):
    mock = mocker.patch("src.cleaner.EcsTasksDefCleaner._EcsTasksDefCleaner__get_revision_referenced_in_tf_state",
                        return_value=MagicMock(), autospec=True)
    mock.return_value = None
    return mock

@fixture
def task_revision_in_terraform_state_2(mocker):
    mock = mocker.patch("src.cleaner.EcsTasksDefCleaner._EcsTasksDefCleaner__get_revision_referenced_in_tf_state",
                        return_value=MagicMock(), autospec=True)
    mock.return_value = "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:2"
    return mock

@fixture
def task_deployed_revision_for_service_mock(mocker):
    mock = mocker.patch("src.cleaner.EcsTasksDefCleaner._EcsTasksDefCleaner__get_deployed_revision_for_the_service",
                        return_value=MagicMock(), autospec=True)
    mock.return_value = "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:6"
    return mock


class TestCleaner:

    def test_number_of_cleaned_revisions_should_delete_1_revision(self, task_revisions_for_service_mock,
                                                                  task_revision_in_terraform_state_none):
        deployed_revision = "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:6"
        for_delete = cleaner.EcsTasksDefCleaner(old_revision_count=3, dry_run=True)\
            .get_task_revisions_for_delete(deployed_revision)
        assert len(for_delete) == 1
        if (len(for_delete) == 1):
            assert for_delete[0] == "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:2"

    def test_number_of_cleaned_revisions_should_save_deployed_revision(self, task_revisions_for_service_mock,
                                                                       task_revision_in_terraform_state_none):
        deployed_revision = "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:6"
        for_delete = cleaner.EcsTasksDefCleaner(old_revision_count=0, dry_run=True)\
            .get_task_revisions_for_delete(deployed_revision)
        assert len(for_delete) == 4
        assert deployed_revision not in for_delete

    def test_number_of_cleaned_revisions_should_save_revision_referenced_in_tf(self, task_revisions_for_service_mock,
                                                                       task_revision_in_terraform_state_2):
        deployed_revision = "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:6"
        tf_revision = "arn:aws:ecs:eu-west-1:123456789:task-definition/my-task:2"
        for_delete = cleaner.EcsTasksDefCleaner(old_revision_count=0, dry_run=True)\
            .get_task_revisions_for_delete(deployed_revision)
        assert len(for_delete) == 4
        assert deployed_revision not in for_delete
        assert tf_revision not in for_delete

    def test_dry_run_enabled_should_skip_delete(self, task_revisions_for_service_mock,
                                                task_deployed_revision_for_service_mock,
                                                task_revision_in_terraform_state_none, mocker):
        obj = cleaner.EcsTasksDefCleaner(old_revision_count=0, dry_run=True)
        spy = mocker.spy(obj, "_EcsTasksDefCleaner__delete_revision")
        for_delete = obj.clean_for_service("cluster_name", "service_name")
        assert spy.call_count == 0

import os, sys
from pytest import fixture

test_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(test_dir + "/../src")

# before reporter, env variables need to be set
import tests.lambda_env as env
import src.main as lfunction


@fixture
def lambda_event():

    return {
        "ecs_cluster_name": "my-cluster",
        "ecs_service_name": "my-service",
        "dry_run": "False"
    }

class TestLocalRunner:
    """
    The below method helps to run the lambda during a local development
    See README.md
    """

    def test_run(self, lambda_event):

       lfunction.lambda_handler(lambda_event, None)

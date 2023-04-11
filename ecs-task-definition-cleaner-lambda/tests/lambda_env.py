import os

os.environ['OLD_REVISION_COUNT'] = "3"
os.environ['S3_TF_STATE_OBJECTS'] = "my-state-object1,my-state-object2 "
os.environ['S3_TF_STATE_BUCKET'] = "my-state-bucket"
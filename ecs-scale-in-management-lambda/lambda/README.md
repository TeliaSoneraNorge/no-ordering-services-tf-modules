Before you run the Lambda localy you need to set AWS credentials to the shell.


### Run locally with pure Node

    npm install
    npm test


### How to run locally with SAM ?

    sam build

    sam local invoke --docker-network host -e events/event.json
Before you run the Lambda localy you need to set AWS credentials to the shell.


### Run locally with pure Node

    npm install
    npm test

###Debugging

#### Option #1 Visual Studio Code

1. Open Javascript Debug Terminal
1.      npm test

#### Option #2 Visual Studio Code or others (remote debugging)

1.      node  --inspect-brk=0.0.0:9229 ./node_modules/jest/bin/jest.js --silent=false --config=jest.unit-tests.config.js --runInBand
1. Connect to remotely to the process to port 9229, for Visual Studio you can use the configuraton in file .vscode/launch.json

const ecs = require('./ecs.js');
const rds = require('./rds.js');
const ssm = require('./ssm.js');
const aas = require('./aas.js');

const PARAMETER_STORE_KEY = "/StopStartService/SystemIsStopped";
const PARAMETER_STORE_KEY_SKIP_ACTIONS = "/StopStartService/SkipActions"

exports.handler = async (event) => {
    let error = null;
    let action = null;

    if (event.body) {
        let body = JSON.parse(event.body);
        if (body.action) {
            action = body.action;
        }
    } else {
        action = event.action;
    }

    let response = {
        statusCode: 200,
        body: "200 OK",
    };


    if (await skipActions()) {
        return response;
    }

    try {
        switch (action) {
            case "start":
                await startSystem(response);
                break;
            case "stop":
                await stopSystem();
                break;
            case "status":
                await getSystemStatus(response);
                break;
            case "test":
                await systemTest(response);
                break;
            default:
                response.statusCode = 400;
                response.body = "400 Error - No valid action specified in the request.";
        }
    } catch (err) {
        console.log(err);
        error = err;
    }

    if (error != null) {
        response = {
            statusCode: 500,
            body: error,
        };
    }

    return response;
};

/**
 *
 *  Check if SSM parameter /StopStartService/SkipActions has been defined and set to true
 */
const skipActions = async () => {
    try {

        let paramExists = await ssm.paramExists(PARAMETER_STORE_KEY_SKIP_ACTIONS);
        console.log(PARAMETER_STORE_KEY_SKIP_ACTIONS + " exists " + paramExists);
        if (paramExists) {
            let skipActions =  await ssm.readParam(PARAMETER_STORE_KEY_SKIP_ACTIONS);
            console.log("skipActions = " + skipActions);
            if (skipActions==='true') {
                console.log("Action will be skiped, in case you want to change the behaviour pls change SSM parameter " + PARAMETER_STORE_KEY_SKIP_ACTIONS);
                return true;
            }
        }
    }
    catch (err) {
        console.log(err);
    }
    return false;
}

const startSystem = async response => {
    if (await isSystemStopped()) {
        console.log("Starting system resources.");
        await rds.startRdsInstances();
        await ecs.startClusters();
        await aas.startScalableServices();

        await ssm.deleteParam(PARAMETER_STORE_KEY);
        console.log("System resources successfuly started.");
    }
    else {
        response.body = "200 OK - System already started.";
    }
};

const stopSystem = async () => {

    console.log("Stopping system resources.");
    await ecs.stopClusters();
    await aas.stopScalableServices();
    await rds.stopRdsInstances();

    if (!(await isSystemStopped())) {
        await ssm.writeParam(PARAMETER_STORE_KEY, "true");
    }
    console.log("System resources sucessfuly stoped.");
};

const getSystemStatus = async response => {
    console.log("Checking status of system resources...");
    if (await isSystemStopped()) {
        console.log("System resources stopped.");
        response.body = "200 OK - System stopped.";
    }
    else {
        console.log("System resources started.");
        response.body = "200 OK - System started.";
    }
};

/**
 * Only for testing purpose
 * @param {*} response
 */
const systemTest = async response => {
    //console.log(await ssm.deleteParam("/StopStartService/isSystemStopped"));
    //await ecs.stopClusters();
    //await ecs.startClusters();
    //await rds.stopRdsInstances();
    //await ecs.testMethod();
    //await ecs.testSet();
    //await ecs.testMethod();
    //await aas.startScalableServices();

    response.body = "200 OK - Test";
};

const isSystemStopped = async () => await ssm.paramExists(PARAMETER_STORE_KEY);
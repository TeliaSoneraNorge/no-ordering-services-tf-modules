const ecs = require('./ecs.js');
const rds = require('./rds.js');
const ssm = require('./ssm.js');
const aas = require('./aas.js');

const PARAMETER_STORE_KEY = "/StopStartService/SystemIsStopped";
const PARAMETER_STORE_KEY_SKIP_ACTIONS = "/StopStartService/SkipActions"
const PARAMETER_STORE_KEY_SKIP_SERVICES = "/StopStartService/SkipServices"

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

    //this code skip the action if /StopStartService/SkipActions == true and sets the parameter to false
    if (await skipActions()) {
        return response;
    }

    let servicesToSkip = await fetchServicesToSkip();

    try {
        switch (action) {
            case "start":
                await startSystem(response, servicesToSkip);
                break;
            case "stop":
                await stopSystem(servicesToSkip);
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
 *  Check if SSM parameter /StopStartService/SkipActions has been defined and set to 'true'
 *  If the parameter was 'true' set it to 'false'
 */
const skipActions = async () => {
    try {

        let paramExists = await ssm.paramExists(PARAMETER_STORE_KEY_SKIP_ACTIONS);
        console.log(PARAMETER_STORE_KEY_SKIP_ACTIONS + " exists " + paramExists);
        if (paramExists) {
            let skipActions =  await ssm.readParam(PARAMETER_STORE_KEY_SKIP_ACTIONS);
            console.log("skipActions = " + skipActions);
            if (skipActions==='true') {
                console.log("Action will be skiped, setting SSM parameter " + PARAMETER_STORE_KEY_SKIP_ACTIONS + "to true so next time the action will not be skipped");
                await ssm.writeParam(PARAMETER_STORE_KEY_SKIP_ACTIONS, "false", "Standard", true);
                return true;
            }
        }
    }
    catch (err) {
        console.log(err);
    }
    return false;
}

const startSystem = async (response, servicesToSkip) => {
    if (await isSystemStopped()) {
        console.log("Starting system resources.");
        await rds.startRdsInstances();
        await ecs.startClusters(servicesToSkip);
        await aas.startScalableServices(servicesToSkip);

        await ssm.deleteParam(PARAMETER_STORE_KEY);
        console.log("System resources successfuly started.");
    }
    else {
        response.body = "200 OK - System already started.";
    }
};

const stopSystem = async (servicesToSkip) => {

    console.log("Stopping system resources.");
    await ecs.stopClusters(servicesToSkip);
    await aas.stopScalableServices(servicesToSkip);
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

const fetchServicesToSkip = async () => {
    if (await ssm.paramExists(PARAMETER_STORE_KEY_SKIP_SERVICES)) {
        let skipServices = await ssm.readParam(PARAMETER_STORE_KEY_SKIP_SERVICES);
        return skipServices.split(',');
    }
    return [];
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
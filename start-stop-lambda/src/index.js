const ecs = require('./ecs.js');
const rds = require('./rds.js');
const ssm = require('./ssm.js');
const aas = require('./aas.js');

const PARAMETER_STORE_KEY = "/StopStartService/SystemIsStopped";
const PARAMETER_STORE_KEY_SKIP_ACTIONS = "/StopStartService/SkipActions";
const PARAMETER_STORE_KEY_SKIP_SERVICES = "/StopStartService/SkipECSServices";
const PARAMETER_STORE_KEY_SKIP_RDS = "/StopStartService/SkipRDSInstances";

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

    let ecsServicesToSkip = await fetchServicesToSkip(PARAMETER_STORE_KEY_SKIP_SERVICES);
    let rdsInstancesToSkip = await fetchServicesToSkip(PARAMETER_STORE_KEY_SKIP_RDS);

    try {
        switch (action) {
            case "start":
                await startSystem(response, ecsServicesToSkip, rdsInstancesToSkip);
                break;
            case "stop":
                await stopSystem(ecsServicesToSkip, rdsInstancesToSkip);
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
        if (paramExists) {
            let skipActions = await ssm.readParam(PARAMETER_STORE_KEY_SKIP_ACTIONS);
            console.log(`skipActions = ${skipActions}`);
            if (skipActions === 'true') {
                console.log(`Action will be skiped, setting SSM parameter ${PARAMETER_STORE_KEY_SKIP_ACTIONS} to false so next time the action will not be skipped`);
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

const startSystem = async (response, ecsServicesToSkip, rdsInstancesToSkip) => {
    if (await isSystemStopped()) {
        console.log("Starting system resources.");
        await rds.startRdsInstances(rdsInstancesToSkip);
        await ecs.startClusters(ecsServicesToSkip);
        await aas.startScalableServices(ecsServicesToSkip);

        await ssm.deleteParam(PARAMETER_STORE_KEY);
        console.log("System resources successfuly started.");
    }
    else {
        response.body = "200 OK - System already started.";
    }
};

const stopSystem = async (ecsServicesToSkip, rdsInstancesToSkip) => {

    console.log("Stopping system resources.");
    await ecs.stopClusters(ecsServicesToSkip);
    await aas.stopScalableServices(ecsServicesToSkip);
    await rds.stopRdsInstances(rdsInstancesToSkip);

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
 * Reads list of ECS services/RDS instances from SSM parameter store which should be excluded from start/stop tasks.
 * Expected ECS services format in SSM parameter store: Comma separated list of services: st1-price-master-ui,st1-account-manager
 * Expected RDS instances format in SSM parameter store: Comma separated list of RDS instances: product-dev-common-postgre-db,product-dev-common-oracle-db
 * @returns list of ECS services or RDS instances to skip
 */
const fetchServicesToSkip = async parameterName => {
    if (await ssm.paramExists(parameterName)) {
        let skipServices = await ssm.readParam(parameterName);
        console.log("Services to skip: " + skipServices);
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
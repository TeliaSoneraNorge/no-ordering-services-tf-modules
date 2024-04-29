const { DeploymentStrategyDelegator } = require('./deployment-strategy.js');
const { RMToolClient } = require('./rmtool-client.js');

const STARTED = "STARTED";
const COMPLETED = "COMPLETED";
const SUCCESS = "SUCCESS";
const FAILURE = "FAILURE";

exports.monitorHandler = async (event, context, callback) => {

    let status = "SUCCESS";

    try {
        validateInputPayload(event);

        const deploymentStrategy = DeploymentStrategyDelegator[event.deployment_type](event.service, event.cluster, event.waiter);
        console.info(`Waiting for deploy of deployment type: ${deploymentStrategy.identify()}`);
        console.info(event)

        await RMToolClient.actionUpdate(STARTED, SUCCESS, event.service, event.env_action_update);

        const result = await deploymentStrategy.waitForServiceStability();
        console.info(`Service(${event.service}) is HEALTHY!`);
        console.info(result);

        await RMToolClient.actionUpdate(COMPLETED, SUCCESS, event.service, event.env_action_update);

    } catch (error) {
        console.info(`Failure: Service(${event.service}) has not reached HEALTHY state in time`);
        console.error(error);
        status = "FAILURE"

        await RMToolClient.actionUpdate(COMPLETED, FAILURE, event.service, event.env_action_update);
    }

    const message = `Done! with status: ${status}`;
    console.info(message);
    return message;
}


const validateInputPayload = (event) => {

    if (!(event.deployment_type && event.service && event.cluster && event.waiter)) {
        throw new Error("Missing one or multiple mandatory properties: deployment_type, service, cluster, wait_for_minutes");
    }

    if (!(event.env_action_update)) {
        throw new Error("Missing one or multiple mandatory properties: env_action_update");
    }

    if (!DeploymentStrategyDelegator.hasOwnProperty(event.deployment_type)) {
        throw new Error("Invalid or unspecified deployment_type");
    }
}

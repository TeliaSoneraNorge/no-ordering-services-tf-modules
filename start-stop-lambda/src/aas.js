
const { ApplicationAutoScalingClient, DescribeScalableTargetsCommand, RegisterScalableTargetCommand } = require("@aws-sdk/client-application-auto-scaling");
const ssm = require('./ssm.js');

const SERVICE_NAMESPACE = 'ecs';
const PARAMETER_STORE_KEY = "/StopStartService/stopApplicationAutoScaling/state";

const client = new ApplicationAutoScalingClient();

exports.startScalableServices = async servicesToSkip => {
    if (!(await ssm.paramExists(PARAMETER_STORE_KEY))) {
        console.error("Services are already started. Skipping operation.");
        return;
    }
    const backup = await ssm.readParam(PARAMETER_STORE_KEY);
    const services = JSON.parse(backup);
    const promises = [];
    services.filter(service => notIn(service, servicesToSkip)).forEach(service => {
        promises.push(updateScalableService(SERVICE_NAMESPACE, service.ResourceId, service.ScalableDimension, service.MinCapacity, service.MaxCapacity));
    });
    const results = await Promise.all(promises);
    await ssm.deleteParam(PARAMETER_STORE_KEY);
    return results;
};

const notIn = (service, servicesToSkip) => {
    let serviceName = service.ResourceId.substr(service.ResourceId.lastIndexOf('/') + 1);
    return servicesToSkip.indexOf(serviceName) === -1;
}

exports.stopScalableServices = async servicesToSkip => {
    if (await ssm.paramExists(PARAMETER_STORE_KEY)) {
        console.error("Services are already stopped. Skipping operation.");
        return;
    }
    const services = await listScalableServices(SERVICE_NAMESPACE);
    const promises = [];
    services.filter(service => notIn(service, servicesToSkip)).forEach(service => {
        promises.push(updateScalableService(SERVICE_NAMESPACE, service.ResourceId, service.ScalableDimension, 0, 0));
    });
    const results = await Promise.all(promises);
    const backup = JSON.stringify(services);
    await ssm.writeParam(PARAMETER_STORE_KEY, backup, 'Advanced');
    return results;
};

const listScalableServices = async serviceNamespace => {
    const params = {
        ServiceNamespace: serviceNamespace
    };

    const result = await client.send(new DescribeScalableTargetsCommand(params))
    let services = result.ScalableTargets.map(item => ({
        MaxCapacity: item.MaxCapacity,
        MinCapacity: item.MinCapacity,
        ResourceId: item.ResourceId,
        ScalableDimension: item.ScalableDimension
    }));
    return services;
};

const updateScalableService = async (serviceNamespace, resourceId, scalableDimension, minCapacity, maxCapacity) => {
    const params = {
        MaxCapacity: maxCapacity,
        MinCapacity: minCapacity,
        ResourceId: resourceId,
        ScalableDimension: scalableDimension,
        ServiceNamespace: serviceNamespace
    };

    const result = await client.send(new RegisterScalableTargetCommand(params));
    return result;
};
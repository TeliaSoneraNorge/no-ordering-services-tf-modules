const AWS = require("aws-sdk");
const applicationAutoScaling = new AWS.ApplicationAutoScaling({apiVersion: '2016-02-06'});
const ssm = require('./ssm.js');

const SERVICE_NAMESPACE = 'ecs';
const PARAMETER_STORE_KEY = "/StopStartService/stopApplicationAutoScaling/state";

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
    return new Promise((resolve, reject) => {
        const params = {
            ServiceNamespace: serviceNamespace
        };
        applicationAutoScaling.describeScalableTargets(params, (err, data) => {
            if (err) { // an error occurred
                console.log(err, err.stack);
                reject(err);
            } else { // successful response
                let services = data.ScalableTargets.map(item => ({
                    MaxCapacity: item.MaxCapacity,
                    MinCapacity: item.MinCapacity,
                    ResourceId: item.ResourceId,
                    ScalableDimension: item.ScalableDimension
                }));
                resolve(services);
            }
        });
    });
};

const updateScalableService = async (serviceNamespace, resourceId, scalableDimension, minCapacity, maxCapacity) => {
    return new Promise((resolve, reject) => {
        const params = {
            MaxCapacity: maxCapacity,
            MinCapacity: minCapacity,
            ResourceId: resourceId,
            ScalableDimension: scalableDimension,
            ServiceNamespace: serviceNamespace
        };
        applicationAutoScaling.registerScalableTarget(params, (err, data) => {
            if (err) {  // an error occurred
                console.log(err, err.stack);
                reject(err);
            } else { // successful response
                resolve(data);
            }
        });
    });
};
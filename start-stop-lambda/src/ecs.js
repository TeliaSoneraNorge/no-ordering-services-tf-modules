const { ECSClient, ListClustersCommand, UpdateServiceCommand, DescribeServicesCommand, ListServicesCommand } = require("@aws-sdk/client-ecs");
const ssm = require('./ssm.js');

const client = new ECSClient();

exports.stopClusters = async servicesToSkip => {
    let clusterArns = await getClusterNames();
    let clusterNames = extractNamesFromArns(clusterArns);

    for (let i = 0; i < clusterNames.length; i++) {
        console.log("Stopping tasks in cluster: " + clusterNames[i]);
        await stopTasks(clusterNames[i], servicesToSkip);
    }
};

exports.startClusters = async servicesToSkip => {
    let clusterArns = await getClusterNames();
    let clusterNames = extractNamesFromArns(clusterArns);

    for (let i = 0; i < clusterNames.length; i++) {
        console.log("Starting tasks in cluster: " + clusterNames[i]);
        await startTasks(clusterNames[i], servicesToSkip);
        await ssm.deleteParam("/StopStartService/ECS/" + clusterNames[i] + "/NumberOfRunningTasks");
    }
};

const getClusterNames = async () => {
    const result = await client.send(new ListClustersCommand());
    return result.clusterArns;
}


const stopTasks = async (clusterName, servicesToSkip) => {
    let allServiceARNs = await getNeoEcsServiceList(clusterName);
    let allServiceNames = extractNamesFromArns(allServiceARNs).filter(name => servicesToSkip.indexOf(name) === -1);

    await storeNumberOfTasksToSsm(clusterName, allServiceNames);
    await stopServiceTasks(clusterName, allServiceNames);
};

const startTasks = async (clusterName, servicesToSkip) => {
    let allServiceARNs = await getNeoEcsServiceList(clusterName);
    let allServiceNames = extractNamesFromArns(allServiceARNs).filter(name => servicesToSkip.indexOf(name) === -1);
    let taskNumbers = await getNumberOfTasksFromSsm(clusterName);

    await startServiceTasks(clusterName, allServiceNames, taskNumbers);
};

const startServiceTasks = async (clusterName, serviceNames, taskNumbers) => {
    let resultPromises = [];

    serviceNames.forEach((serviceName) => {
        if (taskNumbers.hasOwnProperty(serviceName)) {
            resultPromises.push(updateServiceTasks(clusterName, serviceName, taskNumbers[serviceName]));
        }
        else {
            resultPromises.push(updateServiceTasks(clusterName, serviceName, 1));
        }
    });

    let results = await Promise.all(resultPromises);
    console.log("ECS Services started.");

    return results;
};


const getNumberOfTasksFromSsm = async (clusterName) => {
    let result = {};

    result = JSON.parse(await ssm.readParam("/StopStartService/ECS/" + clusterName + "/NumberOfRunningTasks"));

    return result;
};


const stopServiceTasks = async (clusterName, serviceNames) => {
    let resultPromises = [];

    serviceNames.forEach((serviceName) => {
        resultPromises.push(updateServiceTasks(clusterName, serviceName, 0));
    });

    let results = await Promise.all(resultPromises);

    console.log("ECS Services stopped.");

    return results;

};

const updateServiceTasks = async (clusterName, serviceName, desiredCount) => {
    let params = {
        desiredCount: desiredCount,
        service: serviceName,
        cluster: clusterName,
    };
    console.log(`Service ${serviceName} desired task count set to: ${desiredCount}`);
    const result = await client.send(new UpdateServiceCommand(params));
    return result;
};

const storeNumberOfTasksToSsm = async (clusterName, serviceNames) => {
    let resultPromises = [];


    serviceNames.forEach((serviceName) => {

        resultPromises.push(getServiceTaskCount(clusterName, serviceName));
    });

    let results = parseJsonArrayToJson(await Promise.all(resultPromises));

    if (!(await ssm.paramExists("/StopStartService/ECS/" + clusterName + "/NumberOfRunningTasks"))) {
        await ssm.writeParam("/StopStartService/ECS/" + clusterName + "/NumberOfRunningTasks", results);
    }

    return results;
};

const parseJsonArrayToJson = (jsonArray) => {

    let result;

    result = JSON.stringify(jsonArray);

    //replace all occurances of { and } using regular expression.
    result = result.replace(/{/g, '');
    result = result.replace(/}/g, '');

    result = result.replace("[", "{");
    result = result.replace("]", "}");

    return result;
}


const getServiceTaskCount = async (clusterName, serviceName) => {
    let params = {
        services: [serviceName],
        cluster: clusterName,
    };

    const result = await client.send(new DescribeServicesCommand(params));
    let taskCountMap = {};;

    let servceObj = {};
    servceObj = result.services[0];

    taskCountMap[servceObj.serviceName] = servceObj.desiredCount;
    return taskCountMap;
};


const getNeoEcsServiceList = async (clusterName) => {
    const params = {
        cluster: clusterName,
        maxResults: 100,
    };

    const result = await client.send(new ListServicesCommand(params));

    return result.serviceArns;
};


const extractNamesFromArns = (arns) => {
    let names = [];

    for (let i = 0; i < arns.length; i++) {
        let arn = arns[i];
        //typical ARN arn:aws:ecs:eu-west-1:456893923059:service/st1aws-accountmanager-app
        let nameStartPos = arn.lastIndexOf('/') + 1;
        let name = arn.substr(nameStartPos);
        names.push(name);
    }

    return names;
};

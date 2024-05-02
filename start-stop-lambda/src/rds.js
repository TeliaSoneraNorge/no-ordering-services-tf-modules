const { RDSClient, DescribeDBInstancesCommand, StartDBInstanceCommand, StopDBInstanceCommand, waitUntilDBInstanceAvailable } = require("@aws-sdk/client-rds");
const client = new RDSClient();

exports.stopRdsInstances = async rdsInstancesToSkip => {
    let rdsInstanceInfos = await getDBInstanceInfo();

    console.log("Stopping RDS instances:");
    rdsInstanceInfos = rdsInstanceInfos.filter(rdsInstanceInfo => notIn(rdsInstanceInfo, rdsInstancesToSkip));
    for (let rdsInstanceInfo of rdsInstanceInfos) {
        if (rdsInstanceInfo.DBInstanceStatus === "available")
            await stopDbInstance(rdsInstanceInfo.DBInstanceIdentifier);
        else
            console.log(rdsInstanceInfo.DBInstanceIdentifier + " already stopped.");
    }
};

exports.startRdsInstances = async rdsInstancesToSkip => {
    let rdsInstanceInfos = await getDBInstanceInfo();

    console.log("Starting RDS instances:");
    rdsInstanceInfos = rdsInstanceInfos.filter(rdsInstanceInfo => notIn(rdsInstanceInfo, rdsInstancesToSkip));
    let promises = [];
    for (let rdsInstanceInfo of rdsInstanceInfos) {
        if (rdsInstanceInfo.DBInstanceStatus === "stopped") {
            promises.push(startDbInstance(rdsInstanceInfo.DBInstanceIdentifier));
            promises.push(waitOnDbInstanceAvailable(rdsInstanceInfo.DBInstanceIdentifier));
        } else
            console.log(rdsInstanceInfo.DBInstanceIdentifier + " already started.");
    }
    await Promise.all(promises);
};

const notIn = (rdsInstanceInfo, rdsInstancesToSkip) => {
    return rdsInstancesToSkip.indexOf(rdsInstanceInfo.DBInstanceIdentifier) === -1;
}

const getDBInstanceInfo = async () => {

    const command = new DescribeDBInstancesCommand({});
    const result = await client.send(command);

    const rdsInstanceInfos = [];
    for (let dbInstance of result.DBInstances) {
        if (dbInstance.Engine !== "docdb") {
            let obj = {};
            obj["DBInstanceIdentifier"] = dbInstance.DBInstanceIdentifier;
            obj["DBInstanceStatus"] = dbInstance.DBInstanceStatus;
            rdsInstanceInfos.push(obj);
        }
    }
    return rdsInstanceInfos;
};

const stopDbInstance = async (name) => {
    let params = {
        DBInstanceIdentifier: name
    };
    console.log(`Stopping DB instance: ${name}`);
    const result = await client.send(new StopDBInstanceCommand(params));
    return result;
};

const startDbInstance = async (name) => {

    let params = {
        DBInstanceIdentifier: name
    };
    console.log(`Starting DB instance: ${name}`);
    const result = await client.send(new StartDBInstanceCommand(params));
    return result;
};

const waitOnDbInstanceAvailable = async (dbIdentifier) => {
    await waitUntilDBInstanceAvailable({ client, maxWaitTime: 60 }, { DBInstanceIdentifier: dbIdentifier });
}

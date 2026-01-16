const { SSM } = require("aws-sdk");
const AWS = require("aws-sdk");
const ssm = require('./ssm.js');
const ec2 = new AWS.EC2({ apiVersion: '2014-10-31' });
const SSM_PARAM_NAME = "/StopStartService/EC2/stopped";

exports.stopEC2Instances = async ec2InstancesToSkip => {
    let ec2InstanceInfos = await getEC2InstanceInfo();
    let instancesToStop = []
    console.log("Stopping EC2 instances:");
    ec2InstanceInfos = ec2InstanceInfos.filter(ec2InstanceInfo => notIn(ec2InstanceInfo, ec2InstancesToSkip));
    for (let ec2InstanceInfo of ec2InstanceInfos) {
        if (ec2InstanceInfo.Status === "running") {
            instancesToStop.push(ec2InstanceInfo.InstanceId);
        }
    }

    if (instancesToStop.length > 0) {
        await stopEC2Instances(instancesToStop);
        await ssm.writeParam(SSM_PARAM_NAME, instancesToStop.join(), "Standard", true);
    }
};

exports.startEC2Instances = async () => {

    let ec2StoppedInstances = await ssm.readParam(SSM_PARAM_NAME);
    if (ec2StoppedInstances) {
        await startEC2Instances(ec2StoppedInstances.split(","));
    }
    ssm.deleteParam(SSM_PARAM_NAME);
};


const notIn = (ec2InstanceInfo, ec2InstancesToSkip) => {
    return ec2InstancesToSkip.indexOf(ec2InstanceInfo.InstanceId) === -1;
}

const getEC2InstanceInfo = async () => {

    return new Promise((resolve, reject) => {
        let params = {};

        ec2.describeInstanceStatus(params, (err, data) => {
            if (err) reject(err); // an error occurred
            else {                 // successful response
                let ec2InstanceInfos = [];
                for (let ec2Instance of data.InstanceStatuses) {
                    let obj = {};
                    obj["InstanceId"] = ec2Instance.InstanceId;
                    obj["Status"] = ec2Instance.InstanceState.Name;
                    ec2InstanceInfos.push(obj);
                    resolve(ec2InstanceInfos);
                }
            }
        });
    });
};

const stopEC2Instances = async (ids) => {
    return new Promise((resolve, reject) => {
        let params = {
            InstanceIds: ids
        };
        console.log("Stopping EC2 instance: " + ids);

        ec2.stopInstances(params, (err, data) => {
            if (err) reject(err); // an error occurred
            else resolve(data);           // successful response
        });
    });
};

const startEC2Instances = async (ids) => {
    return new Promise((resolve, reject) => {
        let params = {
            InstanceIds: ids
        };
        console.log("Starting EC2 instances: " + ids);

        ec2.startInstances(params, (err, data) => {
            if (err) reject(err); // an error occurred
            else resolve(data);           // successful response
        });
    });
};


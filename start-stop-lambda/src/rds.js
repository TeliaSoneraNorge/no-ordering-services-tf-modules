const AWS = require("aws-sdk");
const rds = new AWS.RDS({apiVersion: '2014-10-31'});
const ssm = require('./ssm.js');

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
    for (let rdsInstanceInfo of rdsInstanceInfos) {
        if (rdsInstanceInfo.DBInstanceStatus === "stopped")
            await startDbInstance(rdsInstanceInfo.DBInstanceIdentifier);
        else
            console.log(rdsInstanceInfo.DBInstanceIdentifier + " already started.");
    }
};

const notIn = (rdsInstanceInfo, rdsInstancesToSkip) => {
    return rdsInstancesToSkip.indexOf(rdsInstanceInfo.DBInstanceIdentifier) === -1;
}

const getDBInstanceInfo = async () => {
    
    return new Promise((resolve, reject) => {
        let params = {};

        rds.describeDBInstances(params, (err, data) => {
           if (err) reject(err); // an error occurred
           else{                 // successful response
               let rdsInstanceInfos = [];
               for(let dbInstance of data.DBInstances){
                    if(dbInstance.Engine !== "docdb"){
                        let obj = {};
                        obj["DBInstanceIdentifier"] = dbInstance.DBInstanceIdentifier; 
                        obj["DBInstanceStatus"] = dbInstance.DBInstanceStatus;
                        rdsInstanceInfos.push(obj);
                    }
                }
                resolve(rdsInstanceInfos); 
           }    
        });
    });
};

const stopDbInstance = async (name) => {
    return new Promise((resolve, reject) => {
        let params = {
            DBInstanceIdentifier : name
        };
        console.log("Stopping DB instance: " + name); 
        
        rds.stopDBInstance(params, (err, data) => {
           if (err) reject(err); // an error occurred
           else     resolve(data);           // successful response
        }); 
    });
};

const startDbInstance = async (name) => {
    return new Promise((resolve, reject) => {
        let params = {
            DBInstanceIdentifier : name
        };
        console.log("Starting DB instance: " + name); 

        rds.startDBInstance(params, (err, data) => {
           if (err) reject(err); // an error occurred
           else     resolve(data);           // successful response
        });
    });
};
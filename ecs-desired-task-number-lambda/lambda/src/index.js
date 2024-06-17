const { ECSClient,UpdateServiceCommand } = require("@aws-sdk/client-ecs");
const client = new ECSClient();

exports.handler = async (event, context, callback) => {

 const params = {
  desiredCount: event.desiredCount, 
  service: event.serviceName,
  cluster: event.clusterName
 };
    console.log("Input parameters: %j", params);
    try {
        const result = await client.send(new UpdateServiceCommand(params));
        console.log(`Service ${event.serviceName} desired task count set to: ${event.desiredCount}`);
        console.log(result);
    }
    catch (err) {
        console.error(err);
        throw err;
    }
};


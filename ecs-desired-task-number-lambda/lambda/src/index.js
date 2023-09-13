const AWS = require("aws-sdk");
const ecs = new AWS.ECS({ apiVersion: '2014-11-13' });

exports.handler = (event, context, callback) => {

 var params = {
  desiredCount: event.desiredCount, 
  service: event.serviceName,
  cluster: event.clusterName
 };
 console.log("Input parameters: %j", params); 

 ecs.updateService(params, function(err, data) {
   if (err) console.log(err, err.stack); // an error occurred
   else     console.log(data);           // successful response
   
 });

};

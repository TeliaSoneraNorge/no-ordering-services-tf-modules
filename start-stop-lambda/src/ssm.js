const AWS = require("aws-sdk");
const ssm = new AWS.SSM({apiVersion: '2014-11-06'});


exports.readParam = async (key) => {
    
    return new Promise((resolve, reject) => {
        
        let params = {
          Name: key, /* required */
          WithDecryption: false
        };

       
       ssm.getParameter(params, (err, data) => {
          if (err)  reject(err); 
            else{
                let obj = {};
                obj = data;
                resolve(obj.Parameter.Value);
            }  
        });
    });
    
};


exports.writeParam = async (key, value, tier) => {
    return new Promise((resolve, reject) => {
        let params = {
          Name: key, /* required */
          Type: "String", /* required */
          Value: value, /* required */
          Tier: tier ? tier : 'Standard'
          //Overwrite: true,
        };

       
       ssm.putParameter(params, (err, data) => {
          if (err)  reject(err); 
            else{
                resolve(data);
            }  
        });
    });
};

exports.paramExists = async (key)  => {
    
    return new Promise((resolve, reject) => {
        
        let params = {
            Filters: [
            {
              Key: "Name", /* required */
              Values: [ /* required */
                key,
                /* more items */
              ]
            },
            /* more items */
          ],
        };

       
       ssm.describeParameters(params, (err, data) => {
          if (err)  reject(err); 
            else{
                resolve(data.Parameters.length>0);
            }  
        });
    });
    
};

exports.deleteParam = async (key) => {
    
    return new Promise((resolve, reject) => {
        
        let params = {
          Name: key, /* required */
        };

       
       ssm.deleteParameter(params, (err, data) => {
          if (err)  reject(err); 
            else{
               resolve(data);
            }  
        });
    });
    
};

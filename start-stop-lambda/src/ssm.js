const { SSMClient, GetParameterCommand, PutParameterCommand, DeleteParameterCommand, DescribeParametersCommand } = require("@aws-sdk/client-ssm");
const client = new SSMClient();

exports.readParam = async (key) => {
  const params = {
    Name: key, /* required */
    WithDecryption: false
  };

  const command = new GetParameterCommand(params);

  const result = await client.send(command);
  return result.Parameter.Value;
};


exports.writeParam = async (key, value, tier = 'Standard', overwrite = false) => {
  const params = {
    Name: key, /* required */
    Type: "String", /* required */
    Value: value, /* required */
    Tier: tier,
    Overwrite: overwrite
  };

  const command = new PutParameterCommand(params);
  const result = await client.send(command);
  return result;
};

exports.paramExists = async (key) => {
  const params = {
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

  const command = new DescribeParametersCommand(params);
  const result = await client.send(command);
  return result.Parameters.length > 0;
};

exports.deleteParam = async (key) => {
  const params = {
    Name: key, /* required */
  };

  const command = new DeleteParameterCommand(params);
  const result = await client.send(command);
  return result;
};

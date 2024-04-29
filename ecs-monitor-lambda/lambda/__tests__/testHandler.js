process.env.ENV_CLIENT_SECRET_BASE64_PARAM_PATH = '/rmtool/basicauth';
process.env.ENV_RMTOOL_HOST = 'neo-ife.neo-prod.telia.io';

const handler = require('../src/handlers/ecs-deploy-monitor.js');
const inputClassic = require("../events/event.json");
const inputBlueGreen = require("../events/event-blue-green.json");

test('Test monitor classic', async () => {
  let res = await handler.monitorHandler(inputClassic);
  console.log(res);
}, 60000);

test('Test monitor blue-green', async () => {
  let res = await handler.monitorHandler(inputBlueGreen);
  console.log(res);
}, 60000);

const handler = require('../src/index.js');
const input = require("../events/event.js")

test('Set number of tasks for a service', async () => {

    console.log("Input parameters: %j", input.inputBody());
    await handler.handler(input.inputBody().body);

});

const handler = require('../src/app.js');
const input = require("../events/event.js")

test('Disable scale in', async () => {

    console.log("Input parameters: %j", input.inputBody());
    await handler.lambdaHandler(input.inputBody());

});


const handler = require('../src/index.js');
const input = require("../events/event.js")

test('Switch on envronments', async () => {

  try {
    let res = await handler.handler(input.inputBody());
    console.log(res);
  } catch (err) {
    console.log(err);
  }
});
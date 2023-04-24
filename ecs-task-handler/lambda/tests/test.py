import json
import src.main as main



def test():

    f = open('event.json')
    event = json.load(f)
    main.lambda_handler(event, None)

test()

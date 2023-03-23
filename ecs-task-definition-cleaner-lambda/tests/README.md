### How to run the test ?

Go to the root directory containing src and test directories and run:

```commandline
pytest tests 
```

    
In order to run the lambda function against AWS account:
- set AWS credentials in bash
- put correct values to lambda_env.py and run

  ``` commandline
  pytest tests && pytest tests/run_locally.py -k 'test_run' -rP
  ```  

There is possible to run the test directly from your IDE, just go to the py file and run.

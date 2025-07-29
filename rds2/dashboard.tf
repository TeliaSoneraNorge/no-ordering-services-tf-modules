resource "aws_cloudwatch_dashboard" "main" {
  count          = var.create_dashboard ? 1 : 0
  dashboard_name = "${local.identifier}-db-dashboard"

  dashboard_body = <<EOF
  {
      "widgets": [
          {
              "type": "metric",
              "x": 0,
              "y": 0,
              "width": 6,
              "height": 6,
              "properties": {
                  "view": "timeSeries",
                  "stacked": false,
                  "region": "eu-west-1",
                  "metrics": [
                      [ "AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${local.identifier}-db" ]
                  ]
              }
          },
          {
              "type": "metric",
              "x": 6,
              "y": 0,
              "width": 6,
              "height": 6,
              "properties": {
                  "view": "timeSeries",
                  "stacked": false,
                  "region": "eu-west-1",
                  "metrics": [
                      [ "AWS/RDS", "WriteLatency", "DBInstanceIdentifier", "${local.identifier}-db" ],
                      [ ".", "ReadLatency", ".", "." ]
                  ]
              }
          },
          {
              "type": "metric",
              "x": 12,
              "y": 0,
              "width": 6,
              "height": 6,
              "properties": {
                  "view": "timeSeries",
                  "stacked": false,
                  "region": "eu-west-1",
                  "metrics": [
                      [ "AWS/RDS", "WriteThroughput", "DBInstanceIdentifier", "${local.identifier}-db" ],
                      [ ".", "ReadThroughput", ".", "." ]
                  ]
              }
          },
          {
              "type": "metric",
              "x": 18,
              "y": 0,
              "width": 6,
              "height": 6,
              "properties": {
                  "view": "timeSeries",
                  "stacked": false,
                  "region": "eu-west-1",
                  "metrics": [
                      [ "AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "${local.identifier}-db" ]
                  ]
              }
          },
          {
              "type": "metric",
              "x": 0,
              "y": 6,
              "width": 6,
              "height": 6,
              "properties": {
                  "view": "timeSeries",
                  "stacked": false,
                  "region": "eu-west-1",
                  "metrics": [
                      [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${local.identifier}-db" ]
                  ]
              }
          },
          {
              "type": "metric",
              "x": 6,
              "y": 6,
              "width": 6,
              "height": 6,
              "properties": {
                  "view": "timeSeries",
                  "stacked": false,
                  "region": "eu-west-1",
                  "metrics": [
                      [ "AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", "${local.identifier}-db" ],
                      [ ".", "WriteIOPS", ".", "." ]
                  ]
              }
          },
          {
              "type": "metric",
              "x": 12,
              "y": 6,
              "width": 6,
              "height": 6,
              "properties": {
                  "view": "timeSeries",
                  "stacked": false,
                  "region": "eu-west-1",
                  "metrics": [
                      [ "AWS/RDS", "DiskQueueDepth", "DBInstanceIdentifier", "${local.identifier}-db" ]
                  ]
              }
          },
          {
              "type": "metric",
              "x": 18,
              "y": 6,
              "width": 6,
              "height": 6,
              "properties": {
                  "view": "timeSeries",
                  "stacked": false,
                  "region": "eu-west-1",
                  "metrics": [
                      [ "AWS/RDS", "NetworkReceiveThroughput", "DBInstanceIdentifier", "${local.identifier}-db" ],
                      [ ".", "NetworkTransmitThroughput", ".", "." ]
                  ]
              }
          }
      ]
  }
   EOF
}

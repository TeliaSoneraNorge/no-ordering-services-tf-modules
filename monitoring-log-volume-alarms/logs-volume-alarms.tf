resource "aws_cloudwatch_metric_alarm" "incoming_log_events_anomaly" {

  alarm_name                = "Incoming log events to log group ${var.log_group_name} ${var.env_description}"
  comparison_operator       = "GreaterThanUpperThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold_metric_id       = "ad1"
  alarm_description         = "The alarm is red when the number of incoming log events exceeds the defined band"
  insufficient_data_actions = []
  alarm_actions             = [var.sns_topic_arn]
  ok_actions                = [var.sns_topic_arn]
  treat_missing_data        = "ignore"
  datapoints_to_alarm       = var.datapoints_to_alarm

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1,${var.metric_query_band})"
    label       = "IncomingLogEvents (expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "IncomingLogEvents"
      namespace   = "AWS/Logs"
      period      = var.metric_query_period
      stat        = "Average"

      dimensions = {
        "LogGroupName" = var.log_group_name
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "incoming_bytes_anomaly" {

  alarm_name                = "Incoming bytes to log group ${var.log_group_name}"
  comparison_operator       = "GreaterThanUpperThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold_metric_id       = "ad1"
  alarm_description         = "The alarm is red when the number of incoming bytes exceeds the defined band"
  insufficient_data_actions = []
  alarm_actions             = [var.sns_topic_arn]
  ok_actions                = [var.sns_topic_arn]
  treat_missing_data        = "ignore"
  datapoints_to_alarm       = var.datapoints_to_alarm

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${var.metric_query_band})"
    label       = "IncomingBytes (expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "IncomingBytes"
      namespace   = "AWS/Logs"
      period      = var.metric_query_period
      stat        = "Average"

      dimensions = {
        "LogGroupName" = var.log_group_name
      }
    }
  }

  // standard alarm when needed
  //  alarm_name          = "log_group_${var.log_group_name}_incoming_bytes"
  //  evaluation_periods  = "6"
  //  metric_name         = "IncomingBytes"
  //  namespace           = "AWS/Logs"
  //  period              = "300"
  //  statistic           = "Average"
  //  threshold           = "120000"
  //  comparison_operator = "GreaterThanThreshold"
  //  alarm_description   = "The alarm is red when the number of incoming bytes exceeds the threshold/band in the last 30 min"
  //  alarm_actions       = [var.sns_topic_arn]
  //  ok_actions          = [var.sns_topic_arn]
  //  treat_missing_data  = "breaching"
  //  datapoints_to_alarm = 6

}

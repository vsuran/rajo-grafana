import json
import logging
import os

import boto3
from botocore.exceptions import BotoCoreError, ClientError


logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns = boto3.client("sns")
TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def _build_message(alerts, status):
    header = "ACSNET_ALERT"
    lines = []
    for alert in alerts:
        labels = alert.get("labels") or {}
        annotations = alert.get("annotations") or {}
        summary = annotations.get("summary") or annotations.get("description") or "Alert"
        instance = labels.get("instance") or labels.get("alertname") or "unknown"
        severity = labels.get("severity", "").upper()
        pieces = [piece for piece in [severity, summary, f"({instance})"] if piece]
        lines.append(" ".join(pieces))

    if lines:
        return f"{header} [{status.upper()}] " + " | ".join(lines)

    return f"{header} [{status.upper()}] Alert received"


def handler(event, context):
    """Alertmanager webhook handler that relays a summary via SNS."""
    try:
        raw_body = event.get("body") or "{}"
        body = json.loads(raw_body)
    except (TypeError, ValueError):
        logger.exception("Failed to parse webhook body")
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "invalid_payload"})
        }

    status = body.get("status", "unknown")
    alerts = body.get("alerts") or []

    message_body = _build_message(alerts, status)

    try:
        sns.publish(
            TopicArn=TOPIC_ARN,
            Message=message_body,
            MessageAttributes={
                "AWS.SNS.SMS.SMSType": {"DataType": "String", "StringValue": "Transactional"}
            },
        )
    except (BotoCoreError, ClientError):
        logger.exception("Failed to publish to SNS")
        return {
            "statusCode": 502,
            "body": json.dumps({"error": "sns_publish_failed"})
        }

    logger.info("Published %s alert(s)", len(alerts))
    return {
        "statusCode": 200,
        "body": json.dumps({"sent": True, "alerts": len(alerts)})
    }

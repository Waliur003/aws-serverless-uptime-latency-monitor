# Cloud Engineering Project 12: Automated Website Uptime & Latency Monitor (Serverless Synthetic Probing, DynamoDB Time-Series Telemetry & S3 Status Dashboard)

## Overview

I architected and deployed an automated, serverless Site Reliability Engineering (SRE) monitoring and incident alerting engine on AWS designed to continuously audit website availability, measure network latency, and notify on-call engineers of service degradation or downtime in real time.

Built according to AWS Well-Architected Framework operational excellence and reliability pillars, this project replaces expensive third-party synthetic monitoring tools with a lean, event-driven AWS serverless architecture.

Operating on an automated Amazon EventBridge schedule running every 5 minutes, an event-driven AWS Lambda function (Python 3.12 / Boto3) executes synthetic HTTP/HTTPS health checks against designated endpoint URLs. The worker calculates millisecond-accurate network response latency, validates HTTP status codes, and determines operational health.

The function then:

* Records raw probe metrics and timestamps into an Amazon DynamoDB NoSQL table
* Evaluates operational health (`UP`, `DEGRADED`, or `DOWN`)
* Instantly dispatches critical incident notifications through Amazon Simple Notification Service (SNS) during service degradation or outages

* Generates a lightweight, structured `status.json` telemetry payload
* Writes the state payload directly into an Amazon S3 static website hosting bucket

The complete monitoring infrastructure and public status page operate with zero persistent virtual machines and zero idle compute costs.

---

## The Problem

### 1. Undetected Service Outages & Silent Failures

Web applications and cloud APIs experience transient failures due to DNS misconfigurations, certificate expirations, downstream database connection timeouts, and regional infrastructure incidents. Without active synthetic health checks, engineering teams only become aware of outages after end users report service disruptions.

### 2. High Recurring SaaS Costs for Basic Uptime Checks

Third-party synthetic uptime monitoring solutions charge expensive recurring monthly subscriptions per monitored endpoint and frequency interval. For engineering teams managing multiple internal microservices and testing environments, commercial SaaS tools create unnecessary financial overhead.

### 3. Server Provisioning & Maintenance Overhead

Deploying persistent EC2 instances or maintaining virtual servers solely to run monitoring daemons (e.g., Prometheus, Nagios, or custom cron jobs) introduces:

* Continuous hourly compute costs
* Operating system patching requirements
* Single-point-of-failure (SPOF) risks in single-AZ instances
* Added security surface area

---

## The Solution

### Automated Synthetic Probing Engine

Implemented an event-driven AWS Lambda function using Python 3.12 and native `urllib.request` to execute non-intrusive synthetic probes. The function:

* Measures millisecond round-trip response latency
* Evaluates HTTP response codes (`200 OK` vs. client/server errors)
* Handles network exceptions, timeouts, and DNS lookup failures gracefully without crashing

### Persistent Time-Series Incident Telemetry

Configured an Amazon DynamoDB table running in On-Demand capacity mode (`PAY_PER_REQUEST`). The database stores persistent time-series logs of every probe execution, capturing:

* Target endpoint URL
* ISO-8601 UTC timestamp

* Status classification (`UP`, `DEGRADED`, `DOWN`)
* HTTP response code

* Latency in milliseconds
* Detailed error messages

### High-Priority Outage Escalation Bus

Created an Amazon SNS topic (`uptime-alert-topic`) subscribed to on-call engineer endpoints. When an endpoint fails to return an HTTP 200 status code, Lambda bypasses dashboard polling and immediately dispatches an urgent push notification detailing the HTTP error code, latency, and failure reason.

### Serverless SRE Status Dashboard

Eliminated server maintenance by publishing real-time telemetry into an Amazon S3 bucket (`website-uptime-dashboard-sun-waliur-2026`) configured for Static Website Hosting. A lightweight frontend (`index.html`) asynchronously fetches `status.json`, dynamically rendering live health badges, response codes, and round-trip latency.

---

## Tech Stack

| Layer | Technology |
| --- | --- |
| **Synthetic Probe Worker** | AWS Lambda (`uptime-health-checker`, Python 3.12, Boto3 SDK) |
| **Time-Series Storage** | Amazon DynamoDB (`website-uptime-history`, On-Demand Capacity) |
| **Alerting & Notification Engine** | Amazon SNS (`uptime-alert-topic`, Email Protocol) |
| **Event Automation & Scheduling** | Amazon EventBridge (`uptime-check-schedule`, 5-minute rate) |
| **Static Storage & Status Hosting** | Amazon S3 (`website-uptime-dashboard-sun-waliur-2026`, Static Web Hosting) |
| **Identity & Access Management** | AWS IAM (Least-Privilege Custom Roles & Resource-Scoped Policies) |
| **Frontend Status Dashboard** | Native HTML5, Asynchronous JavaScript (Fetch API), CSS3 Grid/Flexbox |
| **Infrastructure as Code** | HashiCorp Terraform |

---

## Architecture Diagram

```text
       +-------------------------------------------------------+
       |             AWS Cloud (us-east-1)                     |
       |                                                       |
       |  +--------------------+                               |
       |  | Amazon EventBridge |                               |
       |  | (5-Min Rate Rule)  |                               |
       |  +--------------------+                               |
       |            |                                          |
       |            | (1. Automated Trigger)                   |
       |            v                                          |
       |  +--------------------+                               |
       |  |     AWS Lambda     |--------(2. HTTP Synthetic Probe)-----> [Monitored Website Endpoint]
       |  |   (Python 3.12)    |<-------(3. Latency & Status)----------- (HTTP 200 OK / 404 / 500)
       |  +--------------------+                               |
       |       |          |    |                               |
       |       |          |    +---(4. If Outage / Status!=UP)-+
       |       |          |                                    |
       |       |          |                                    v
       |       |          |                          +-------------------+
       |       |          |                          |    Amazon SNS     |---> [On-Call Engineer Inboxes]
       |       |          |                          | (Outage Alerts)   |
       |       |          |                          +-------------------+
       |       |          |                                    
       |       |          +---(5. PutItem Time-Series Log)----+
       |       |                                               |
       |       v                                               v
       |  +-----------------------+               +--------------------------+
       |  |       Amazon S3       |               |     Amazon DynamoDB      |
       |  | (Static Status Page) |               | (website-uptime-history) |
       |  | - index.html          |               +--------------------------+
       |  | - status.json         |
       |  +-----------------------+
       |              |
       +--------------|----------------------------------------+
                      |
                      | (6. Public HTTP Telemetry Fetch)
                      v
          +------------------------+
          |  Browser Status View   |
          | (Live SRE Health Card) |
          +------------------------+

```

---

## Project Procedure

### 1. Database Architecture & Time-Series Logging Fabric

* **DynamoDB Table Provisioning:** Created the Amazon DynamoDB table `website-uptime-history` in `us-east-1`.
* **Key Schema Configuration:**
* **Partition Key:** `site_url` (String) to support monitoring multiple distinct endpoints within a single cluster.
* **Sort Key:** `timestamp` (String / ISO-8601 UTC) to enable precise time-series chronological sorting and historical range queries.
* **Capacity Planning:** Configured **On-demand** capacity mode (`PAY_PER_REQUEST`) to eliminate idle provisioned throughput costs and scale effortlessly with invocation spikes.

### 2. High-Priority Alerting Bus Configuration

* **SNS Topic Creation:** Deployed an Amazon SNS Standard topic named `uptime-alert-topic` (`arn:aws:sns:us-east-1:418272769771:uptime-alert-topic`).
* **Subscription Handshake:** Created an email protocol subscription mapped to engineer distribution lists and completed the tokenized confirmation handshake.

### 3. S3 Public Status Dashboard Hosting

* **Bucket Provisioning:** Provisioned `website-uptime-dashboard-sun-waliur-2026` in `us-east-1`.
* **Public Access Configuration:** Explicitly disabled S3 Block Public Access settings to permit object-level public retrieval for web users.
* **Bucket Policy Enforcement:** Applied a statement granting `s3:GetObject` on `arn:aws:s3:::website-uptime-dashboard-sun-waliur-2026/*` to public principals.
* **Static Hosting Activation:** Enabled Static Website Hosting with `index.html` configured as the root document.
* **Frontend Deployment:** Uploaded a dark-mode status page (`index.html`) that uses the native JavaScript Fetch API to poll `status.json` and dynamically update operational health badges and metrics.

### 4. Least-Privilege IAM Execution Architecture

* **Role Provisioning:** Created the IAM service role `WebsiteUptimeMonitorRole` with trust policies restricted strictly to `lambda.amazonaws.com`.
* **Managed Policy Attachment:** Attached `AWSLambdaBasicExecutionRole` for CloudWatch log stream telemetry.
* **Custom Scoped Policy:** Authored and attached `UptimeMonitorExecutionPolicy`:
* `dynamodb:PutItem`, `dynamodb:Query`, `dynamodb:Scan` scoped to `arn:aws:dynamodb:*:*:table/website-uptime-history`
* `sns:Publish` scoped to `arn:aws:sns:*:*:uptime-alert-topic`
* `s3:PutObject` scoped to `arn:aws:s3:::website-uptime-dashboard-sun-waliur-2026/*`

### 5. Serverless Synthetic Probe Deployment

* **Function Provisioning:** Deployed the Lambda function `uptime-health-checker` using the Python 3.12 runtime.
* **Timeout Configuration:** Increased the execution timeout from 3 seconds to 15 seconds to accommodate network socket handshakes, HTTP retries, and multi-service AWS API writes without timing out.
* **Environment Variable Parameterization:** Configured:
* `TARGET_URL`: Active URL to monitor
* `DYNAMODB_TABLE`: `website-uptime-history`

* `SNS_TOPIC_ARN`: `arn:aws:sns:us-east-1:418272769771:uptime-alert-topic`
* `S3_BUCKET_NAME`: `website-uptime-dashboard-sun-waliur-2026`

* **Handler Logic:**
1. Issues an HTTP probe using Python `urllib.request` with a custom `User-Agent`
2. Calculates round-trip response duration in milliseconds
3. Writes execution metrics to DynamoDB
4. Triggers an SNS alert if the status is not `UP`

5. Serializes and writes `status.json` into the S3 bucket

### 6. Automated EventBridge Scheduling

* **Cron Rule Construction:** Created an Amazon EventBridge rule `uptime-check-schedule` with a recurring rate of `rate(5 minutes)`.
* **Target Mapping:** Attached the rule to target `uptime-health-checker` Lambda.
* **Resource Policy:** Granted `events.amazonaws.com` invocation authority via `aws_lambda_permission`.

---

## Infrastructure as Code (IaC) Architecture

To ensure repeatable and immutable provisioning, the complete SRE monitoring system is deployable via modular Terraform code:

```text
terraform-aws-uptime-monitor/
├── main.tf              # Provider configuration, AWS backend, and global tags
├── variables.tf         # Abstracted parameters (target URL, email, bucket name)
├── dynamodb.tf          # DynamoDB table schema, keys, and billing mode
├── sns.tf               # SNS alert topic and email subscription
├── iam.tf               # IAM execution role, CloudWatch logging, and scoped inline policy
├── lambda.tf            # Lambda archive packaging, function resource, env vars
├── s3.tf                # S3 bucket, website configuration, public access settings, and policy
├── eventbridge.tf       # CloudWatch / EventBridge rule, target binding, and Lambda permissions
└── outputs.tf           # S3 website URL, DynamoDB table name, and SNS topic ARN

```

### Detailed File-by-File Technical Breakdown

* **`main.tf`**: Configures the `hashicorp/aws` (`~> 5.0`) and `hashicorp/archive` (`~> 2.4`) providers targeting `us-east-1` with global project tags.
* **`variables.tf`**: Parameterizes variable inputs including `target_url`, `alert_email`, `s3_bucket_name`, and `aws_region`.
* **`dynamodb.tf`**: Provisions `aws_dynamodb_table` with `PAY_PER_REQUEST` billing mode, `site_url` hash key, `timestamp` range key, and point-in-time recovery enabled.
* **`sns.tf`**: Provisions `aws_sns_topic` and declares `aws_sns_topic_subscription` using the `email` protocol.
* **`iam.tf`**: Implements `aws_iam_role` with Lambda trust policy, attaches `AWSLambdaBasicExecutionRole`, and defines scoped actions for DynamoDB, SNS, and S3.
* **`lambda.tf`**: Packages `lambda_function.py` via `archive_file`, configures `aws_lambda_function` with runtime `python3.12`, `timeout = 15`, `source_code_hash`, and passes environment variables.
* **`s3.tf`**: Provisions `aws_s3_bucket`, configures `aws_s3_bucket_website_configuration`, disables public access blocks, uploads `index.html`, and applies a public read policy with an explicit `depends_on`.
* **`eventbridge.tf`**: Defines `aws_cloudwatch_event_rule` with `schedule_expression = "rate(5 minutes)"`, sets the target to the Lambda ARN, and grants invocation permissions via `aws_lambda_permission`.
* **`outputs.tf`**: Exports `dashboard_url`, `dynamodb_table_name`, and `sns_topic_arn`.

---

## Technical Difficulties Faced & Engineering Resolutions

### Challenge 1: DynamoDB `ResourceNotFoundException` on PutItem Invocations

* **Root Cause Analysis:** Initial Lambda test executions returned `ResourceNotFoundException: Requested resource not found` at line 50 (`table.put_item()`). While the table name matched, the boto3 DynamoDB resource initialized without an explicit region constraint, defaulting to an endpoint where the table was absent.
* **Architectural Resolution:** Hardened the client initialization in Python:
```python
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

```

and verified that `website-uptime-history` was active in the exact `us-east-1` region.

### Challenge 2: Amazon SNS `InvalidParameterException` on TopicArn

* **Root Cause Analysis:** Lambda executions triggered `InvalidParameterException: Invalid parameter: TopicArn` when calling `sns.publish()`. Inspecting the environment variables revealed that copying the ARN had introduced hidden trailing whitespace and carriage return characters.
* **Architectural Resolution:** Implemented sanitization across all runtime environment variable readers:
```python
SNS_TOPIC_ARN = (os.environ.get('SNS_TOPIC_ARN') or '').strip()

```

and explicitly bound the SNS client to `us-east-1`.

### Challenge 3: Lambda Timeout on Network Socket Connects

* **Root Cause Analysis:** The default 3-second Lambda execution timeout caused intermittent execution failures when testing slow endpoints or handling socket connection retries before the function could write records to DynamoDB and S3.
* **Architectural Resolution:** Increased the Lambda timeout configuration to 15 seconds and set an explicit 10-second timeout on the internal `urllib.request.urlopen(req, timeout=10)` call, allowing clean exception handling before function termination.

### Challenge 4: Regional S3 Static Website DNS Resolution Failure

* **Root Cause Analysis:** The status dashboard initially failed to load over HTTP because the original S3 bucket had been provisioned in a secondary region, mismatched with the `us-east-1` Lambda pipeline.
* **Architectural Resolution:** Created a new bucket directly in `us-east-1` (`website-uptime-dashboard-sun-waliur-2026`), updated IAM write policies, re-pointed Lambda's `S3_BUCKET_NAME` variable, and re-uploaded `index.html`.

---

## Verification and Results

### Verified Synthetic Probe & Status Detection

The Lambda function was executed against both active and failing endpoints, proving complete accuracy in operational health classification:

* **Execution Status:** `Status: Succeeded` (HTTP 200)
* **Tested Outage Response Code:** `404 Not Found`

* **Measured Latency:** `324.98 ms`
* **Status Classification:** Correctly evaluated as `DOWN`

* **Telemetry Payload:**
```json
{
  "targetUrl": "http://cloud-cost-dashboard-sun-2026.s3-website-us-east-1.amazonaws.com",
  "status": "DOWN",
  "responseCode": 404,
  "latencyMs": 324.98,
  "lastChecked": "2026-11-05T00:08:23.587866+00:00",
  "errorMessage": "HTTP Error 404: Not Found"
}

```

### Verified DynamoDB Telemetry Logging

Navigated to **Amazon DynamoDB** > **Tables** > `website-uptime-history` > **Explore items** and verified that every probe execution successfully persists records containing:

* `site_url`
* `timestamp`
* `status`
* `response_code`
* `latency_ms`
* `error`

### Confirmed Real-Time SNS Outage Alerting

When the synthetic probe encountered an HTTP 404 or connection failure, Amazon SNS immediately delivered an alert email containing:

* Target URL
* Outage status (`DOWN`)
* Response code (`404`)
* Latency duration
* Timestamp in UTC

### Validated Live S3 Public Dashboard

Accessed the public website endpoint and confirmed dynamic rendering of the SRE operational card:

```text
http://website-uptime-dashboard-sun-waliur-2026.s3-website-us-east-1.amazonaws.com

```

The interface successfully rendered:

* Operational badge (`SYSTEM OPERATIONAL (UP)` / `CRITICAL OUTAGE`)
* Target endpoint name
* Millisecond probe latency
* HTTP status code
* UTC timestamp of the last probe

---

## Verification Screenshots

### 1. Amazon DynamoDB Table Recording Real-Time Synthetic Probe Metrics

Displays the AWS DynamoDB console for `website-uptime-history` under **Explore items**, showing time-series rows capturing probe executions with `site_url`, timestamps, latency metrics, HTTP status codes, and operational health states (`UP` vs. `DOWN`).

### 2. Lambda Function Successful Execution Output Returning HTTP 200 & Telemetry

Shows the execution result banner inside the AWS Lambda console for `uptime-health-checker` returning `Status: Succeeded` with HTTP 200, alongside the structured JSON response payload confirming successful probe execution, DynamoDB persistence, and S3 status synchronization.

### 3. Automated Amazon SNS High-Priority Outage Email Notification

Captures the alert email delivered to the engineer inbox from `AWS Notifications` (`uptime-alert-topic`), displaying the subject line `OUTAGE ALERT: ... is DOWN` and the message body containing failure logs, HTTP error codes, and UTC timestamps.

### 4. Live S3 SRE Health Dashboard Rendering Operational Telemetry

Displays the web browser viewing `website-uptime-dashboard-sun-waliur-2026.s3-website-us-east-1.amazonaws.com`, showing the dark-mode status card with a green operational badge, real-time response latency, and HTTP status verification.

### 5. Amazon EventBridge Schedule Automating 5-Minute Probes

Shows the AWS EventBridge console displaying the active `uptime-check-schedule` rule configured with `rate(5 minutes)` and mapped to the Lambda target, verifying automated continuous synthetic monitoring.

---

## Future Improvements

### Multi-Region Synthetic Probing

Deploy Lambda probe workers across multiple AWS regions (`us-west-2`, `eu-west-1`, `ap-southeast-1`) to calculate geo-distributed latency and eliminate regional false positives.

### Dynamic DynamoDB Historical Latency Sparklines

Update `index.html` with Chart.js to query an Amazon API Gateway REST endpoint backed by DynamoDB, rendering 24-hour historical uptime and latency sparkline graphs.

### CloudFront & Route 53 Custom Domain Security

Front the S3 static status page with an Amazon CloudFront distribution to enforce HTTPS on Port 443 via ACM and attach a custom corporate status domain (e.g., `status.example.com`).

---

## Cost Analysis (FinOps Footprint)

This architecture was engineered to operate within AWS Free Tier limits and incur near-zero operating costs:

| Service Component | Usage Metric / Allocation | Monthly Estimated Cost |
| --- | --- | --- |
| **AWS Lambda** | 8,640 executions/month (every 5 min), 128 MB, ~350ms duration | $0.00 (Free Tier covers 1M invocations) |
| **Amazon DynamoDB** | 8,640 write requests/month, Pay-Per-Request on-demand | $0.00 (Well within 25 GB & 25 WCU Free Tier) |
| **Amazon SNS** | Triggered only during outages / state changes (< 50 emails/month) | $0.00 (First 1,000 email alerts free) |
| **Amazon S3** | < 10 KB storage (`index.html` + `status.json`), ~500 GET requests/month | $0.00 (Negligible storage/transfer) |
| **Amazon EventBridge** | 1 schedule rule running 8,640 events/month | $0.00 (Schedule rules are free) |
| **Amazon CloudWatch Logs** | Ingestion of probe execution logs (< 20 MB/month) | $0.00 (Within 5 GB ingestion Free Tier) |
| **Total Monthly Operating Cost** | **Continuous Automated SRE Synthetic Monitoring** | **$0.00 / month (100% Free Tier Compliant)** |

---

## Monitoring, Alerting & Observability Framework

### 1. Compute & Synthetic Probe Telemetry (Amazon CloudWatch)

* **Log Stream Ingestion:** All probe execution logs, network socket traces, and latency timings stream into the `/aws/lambda/uptime-health-checker` CloudWatch Log Group.
* **Execution Metrics:** Monitored via native CloudWatch metrics:
* `Duration`: Tracks probe runtimes (consistently 200ms–400ms).
* `Errors`: Tracks Lambda runtime exceptions.
* `Invocations`: Confirms triggered executions dispatched every 5 minutes.

### 2. Event-Driven Incident Notification (Amazon SNS)

* **Instant Incident Escalation:** Immediately publishes an alert to `uptime-alert-topic` when the monitored site drops below HTTP 200 or encounters connection timeouts, bypassing manual dashboard checks.
* **Detailed Context:** Alerts include target URL, HTTP code, latency, and exact error strings to accelerate Mean Time to Detect (MTTD) and Mean Time to Resolve (MTTR).

### 3. Client-Side Telemetry & Fail-Safe State (S3 & Web Frontend)

* **Visual Status Flags:** If `status.json` cannot be fetched, `index.html` displays a red alert badge (`No telemetry data found yet`), alerting administrators to check Lambda logs.
* **Direct Inspection:** SREs can inspect the JSON payload directly via the S3 REST endpoint or AWS Console to verify state timestamps.

---

## Technical Skills Demonstrated

* **Site Reliability Engineering (SRE):** Synthetic health check automation, SLA/SLO uptime tracking, latency monitoring, and automated incident alerting.
* **Serverless Engineering:** AWS Lambda, Python 3.12, Boto3 SDK, EventBridge cron scheduling, and event-driven architecture.
* **NoSQL Database Design:** Amazon DynamoDB on-demand capacity planning, time-series schema design, and composite key modeling (`site_url` + `timestamp`).
* **Cloud Storage & Web Delivery:** Amazon S3 static website hosting, JSON object persistence, and asynchronous JavaScript DOM manipulation.
* **Security & IAM:** Least-privilege IAM service role design, resource-scoped execution policies, and cross-service permissions.
* **Infrastructure as Code (IaC):** Modular HashiCorp Terraform architecture, resource dependencies, and parameter abstraction.

---

## Notes

This project demonstrates a production-ready, serverless SRE framework for auditing endpoint reliability and network latency. By combining scheduled Lambda synthetic probes with DynamoDB time-series logging, Amazon SNS push alerts, and an S3 static status page, it provides continuous observability without the cost or operational maintenance of persistent server infrastructure.

---

## Bottom Line

The Automated Website Uptime & Latency Monitor provides robust SRE observability and instantaneous incident alerting. By coupling EventBridge scheduled synthetic probing with DynamoDB time-series storage, Amazon SNS outage notifications, and an S3 static health dashboard, the platform guarantees high availability monitoring, rapid incident detection, and zero idle compute costs.

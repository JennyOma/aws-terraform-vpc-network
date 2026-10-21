
# AWS Cost Analysis

## Region

Europe (Stockholm): eu-north-1

## Resources That May Generate Charges

| Resource | Billing Considerations |
|---|---|
| NAT Gateway | Hourly usage and data processing |
| Elastic IP | Public IPv4 address charges |
| Public EC2 instance | Compute time and EBS storage |
| Private EC2 instance | Compute time and EBS storage |
| Data transfer | Charges may apply depending on traffic |
| CloudWatch | Logs and metrics may generate charges |

## Cost-Control Strategy

- Use two small EC2 instances for temporary testing.
- Deploy only when ready to test connectivity.
- Avoid leaving the NAT Gateway running overnight.
- Use one Availability Zone to limit the number of NAT Gateways.
- Review the Terraform plan before deployment.
- Destroy the lab resources after recording test results.
- Verify Terraform state is empty after cleanup.
- Check AWS Billing for remaining charges.

## Important Notes

AWS Free Tier eligibility varies by account and service.

NAT Gateways and public IPv4 addresses may incur charges even when traffic is low.

Deleting infrastructure prevents most ongoing usage charges, but previously incurred costs can still appear in AWS Billing.

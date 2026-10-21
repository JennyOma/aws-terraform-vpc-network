
# Security Design

## Network Isolation

- Custom VPC: 10.0.0.0/16
- Public subnet: 10.0.1.0/24
- Private subnet: 10.0.2.0/24
- Public subnet has a default route to the Internet Gateway.
- Private subnet routes outbound internet traffic through a NAT Gateway.
- Private EC2 instance has no public IPv4 address.

## Security Groups

### Public EC2
- Inbound: HTTP (TCP port 80) from the internet.
- Outbound: All traffic.
- No inbound SSH access.

### Private EC2
- Inbound: No rules.
- Outbound: HTTPS (TCP port 443) only.

## Instance Security

- Amazon Linux 2023
- IMDSv2 required
- Encrypted EBS root volumes
- AWS Systems Manager access using an IAM instance profile
- No SSH key pairs required

## Limitations

- HTTP is unencrypted and used only for a temporary demonstration.
- The architecture uses a single Availability Zone.
- A single NAT Gateway is not highly available across multiple Availability Zones.
- No VPC Flow Logs are currently configured.
- Security groups are stateful; network ACLs provide an additional optional network control.

## Cleanup

The infrastructure will be destroyed after testing to minimise AWS costs.

Terraform state must remain private and must not be committed to GitHub.

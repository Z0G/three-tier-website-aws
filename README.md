# AWS 3-Tier WordPress Architecture

A production-style, highly available WordPress deployment on AWS using a classic 3-tier architecture — web, application, and database — built manually and automated with terraform.
> **Status:** Console deployment complete | Terraform conversion in progress

---

## Architecture Overview

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────┐
│              Application Load Balancer           │
│         (Internet-facing, ALBSecurityGroup)      │
│    PublicSubnet1 (AZ1)  │  PublicSubnet2 (AZ2)  │
└──────────────┬──────────────────────┬────────────┘
               │                      │
    ┌──────────▼──────────┐ ┌─────────▼──────────┐
    │  ApplicationServer1 │ │ ApplicationServer2  │
    │  PrivateAppSubnet1  │ │  PrivateAppSubnet2  │
    │  ca-central-1a      │ │  ca-central-1b      │
    │  (Apache + PHP +    │ │  (Apache + PHP +    │
    │   WordPress)        │ │   WordPress)        │
    └──────────┬──────────┘ └─────────┬───────────┘
               │                      │
               └──────────┬───────────┘
                           │
              ┌────────────▼────────────┐
              │     Amazon EFS          │
              │  (Shared /var/www/html) │
              │  Mount targets in both  │
              │  PrivateAppSubnets      │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │     Amazon RDS MySQL    │
              │  PrivateDBSubnet1/2     │
              │  (Not publicly          │
              │   accessible)           │
              └─────────────────────────┘
```

**Key design principles:**
- EC2 application servers in private subnets — no direct internet exposure
- Shared EFS volume ensures both servers serve identical WordPress files
- RDS in isolated DB subnets — only reachable from WebServerSecurityGroup
- Dual NAT Gateways for AZ-redundant outbound internet access from private subnets
- ALB distributes traffic across both AZs for high availability

---

## Infrastructure Details

### VPC & Networking

| Resource | Name | CIDR / Details |
|---|---|---|
| VPC | myVPC | 10.0.0.0/16 |
| Public Subnet 1 | PublicSubnet1 | 10.0.0.0/24 — ca-central-1a |
| Public Subnet 2 | PublicSubnet2 | 10.0.1.0/24 — ca-central-1b |
| Private App Subnet 1 | PrivateAppSubnet1 | 10.0.2.0/24 — ca-central-1a |
| Private App Subnet 2 | PrivateAppSubnet2 | 10.0.3.0/24 — ca-central-1b |
| Private DB Subnet 1 | PrivateDBSubnet1 | 10.0.4.0/24 — ca-central-1a |
| Private DB Subnet 2 | PrivateDBSubnet2 | 10.0.5.0/24 — ca-central-1b |
| Internet Gateway | MyIGW | Attached to myVPC |
| NAT Gateway 1 | NATGateway1 | PublicSubnet1 — 1 Elastic IP |
| NAT Gateway 2 | NATGateway2 | PublicSubnet2 — 1 Elastic IP |

**Route Tables:**

| Route Table | Associated Subnets | Target |
|---|---|---|
| PublicRouteTable | PublicSubnet1, PublicSubnet2 | 0.0.0.0/0 → MyIGW |
| PrivateRouteTableAZ1 | PrivateAppSubnet1, PrivateDBSubnet1 | 0.0.0.0/0 → NATGateway1 |
| PrivateRouteTableAZ2 | PrivateAppSubnet2, PrivateDBSubnet2 | 0.0.0.0/0 → NATGateway2 |

### Security Groups

| Security Group | Inbound Rules |
|---|---|
| ALBSecurityGroup | HTTP :80 from 0.0.0.0/0, HTTPS :443 from 0.0.0.0/0 |
| WebServerSecurityGroup | HTTP :80 from ALBSecurityGroup, HTTPS :443 from ALBSecurityGroup, SSH :22 from SSHSecurityGroup |
| DatabaseSecurityGroup | MySQL :3306 from WebServerSecurityGroup |
| EFSSecurityGroup | NFS :2049 from WebServerSecurityGroup, NFS :2049 self-referencing, SSH :22 from SSHSecurityGroup |
| SSHSecurityGroup | SSH :22 from 0.0.0.0/0 *(bastion access — restrict to your IP in production)* |

### Compute

| Resource | Details |
|---|---|
| ApplicationServer1 | t2.micro — Amazon Linux 2023 — ca-central-1a — PrivateAppSubnet1 |
| ApplicationServer2 | t2.micro — Amazon Linux 2023 — ca-central-1b — PrivateAppSubnet2 |
| AMI | Amazon Linux 2023 |
| User data | Installs httpd, PHP, MySQL client; mounts EFS to /var/www/html |

### Load Balancer

| Resource | Details |
|---|---|
| ALB | MyALB — Internet-facing — PublicSubnet1 + PublicSubnet2 |
| Target Group | MyAppServers — HTTP:80 — both instances Healthy |
| Health Check | HTTP / on port 80 |

### Database

| Resource | Details |
|---|---|
| Engine | MySQL 8.0.39 |
| Instance class | db.t3.micro |
| Subnet group | mydbsubnetgroup (PrivateDBSubnet1 + PrivateDBSubnet2) |
| Multi-AZ | No (single AZ — ca-central-1a) |
| Publicly accessible | No |
| Security group | DatabaseSecurityGroup |

### EFS

| Resource | Details |
|---|---|
| File system | MyEFS |
| Performance mode | General Purpose |
| Throughput mode | Elastic |
| Mount targets | PrivateAppSubnet1 (10.0.2.x) and PrivateAppSubnet2 (10.0.3.x) |
| Security group | EFSSecurityGroup |
| Encrypted | Yes |
| Mount point | /var/www/html (shared WordPress files across both EC2s) |

---

## EC2 User Data Script

Both application servers were launched with the following user data to bootstrap WordPress dependencies and mount EFS:

```bash
#!/bin/bash
# Install dependencies
dnf update -y
dnf install -y httpd php php-mysqlnd php-fpm php-json nfs-utils

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Mount EFS
EFS_ID="fs-0d17085071c0b1951"
MOUNT_POINT="/var/www/html"
mkdir -p $MOUNT_POINT
mount -t nfs4 -o nfsvers=4.1 ${EFS_ID}.efs.ca-central-1.amazonaws.com:/ $MOUNT_POINT
echo "${EFS_ID}.efs.ca-central-1.amazonaws.com:/ $MOUNT_POINT nfs4 defaults,_netdev 0 0" >> /etc/fstab

# Download and configure WordPress
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz --strip-components=1
rm latest.tar.gz

# Fix SELinux for Apache network connections
setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_network_connect_db 1
```

---

## Deployment Steps (Console)

1. Create VPC with DNS hostnames enabled
2. Create 6 subnets across 2 AZs (2 public, 2 private app, 2 private DB)
3. Create and attach Internet Gateway
4. Create 2 NAT Gateways with Elastic IPs in the public subnets
5. Create and associate route tables
6. Create 5 security groups with correct chaining rules
7. Create RDS subnet group, then provision RDS MySQL instance
8. Create EFS file system with mount targets in private app subnets
9. Launch 2 EC2 instances with user data in private app subnets
10. SSH to EC2s via bastion host using agent forwarding; complete WordPress setup
11. Create ALB with listener and target group; register both EC2s
12. Verify WordPress accessible via ALB DNS

---

## Screenshots

| Screenshot | Description |
|---|---|
| VPC.png | myVPC — 10.0.0.0/16, DNS hostnames enabled |
| IGW.png | MyIGW attached to myVPC |
| RT-1.png | PrivateRouteTableAZ1 → NATGateway1 |
| RT-2.png | PrivateRouteTableAZ2 → NATGateway2 |
| RT-3.png | PublicRouteTable → MyIGW |
| NATGW.png | Both NAT Gateways available with Elastic IPs |
| SG.png | All 5 security groups |
| ALB-SG.png | ALBSecurityGroup inbound rules |
| WS-SG.png | WebServerSecurityGroup inbound rules |
| DB-SG.png | DatabaseSecurityGroup inbound rules |
| SSH-SG.png | SSHSecurityGroup inbound rules |
| EFS-SG.png | EFSSecurityGroup inbound rules |
| EFS.png | MyEFS general configuration |
| EFS-Network.png | EFS mount targets in both private app subnets |
| RDS.png | RDS connectivity and security details |
| AppServer.png | Both EC2 instances running |
| TargetGroup.png | Both targets healthy in ALB target group |
| ALB.png | MyALB active and internet-facing |
| Website.png | WordPress live via ALB DNS |

---

## Troubleshooting & Lessons Learned

### EC2 instances in private subnets — SSH via bastion
EC2 application servers have no public IP. Access requires a bastion host in a public subnet, and SSH agent forwarding to hop through without copying private keys.

```bash
ssh-add ~/path/to/key.pem
ssh -A ec2-user@<bastion-public-ip>
ssh ec2-user@<private-ip-of-app-server>
```

### SELinux blocking Apache network connections
WordPress returned HTTP 500 errors despite correct `wp-config.php` settings. The root cause was SELinux policies preventing Apache from making outbound network connections to both the database and the filesystem.

**Fix:**
```bash
sudo setsebool -P httpd_can_network_connect 1
sudo setsebool -P httpd_can_network_connect_db 1
```
This must be run on **both** application servers. The `-P` flag makes it persistent across reboots.

### RDS database not created at launch
Leaving the "Initial database name" field blank during RDS setup means no database is created. The WordPress installer then fails with a database connection error.

**Fix:** Connect to MySQL and create it manually:
```bash
mysql -h <rds-endpoint> -u <username> -p
CREATE DATABASE mydatabase;
EXIT;
```

### wp-config.php typo caused 500 error
A typo (`Ddefine` instead of `define`) in `wp-config.php` caused a PHP fatal error and a blank 500 response. Always double-check `wp-config.php` before debugging networking or SELinux.

### Deletion order for AWS cleanup
Deleting resources in the wrong order causes dependency errors. Correct order:

1. RDS (disable deletion protection first via Modify → Apply Immediately)
2. EC2 instances
3. NAT Gateways (wait for deletion to complete)
4. Release Elastic IPs
5. EFS
6. ALB → Target Group
7. Security Groups
8. Subnets
9. Route Tables (custom ones)
10. Internet Gateway (detach first)
11. VPC

---

## Cost Notes

The most expensive resources in this architecture:

| Resource | Approx. Cost |
|---|---|
| 2x NAT Gateways | ~$0.045/hr each + data transfer |
| RDS db.t3.micro | ~$0.017/hr |
| 2x EC2 t2.micro | Free tier eligible |
| EFS | ~$0.08/GB-month (Standard) |
| ALB | ~$0.008/hr + LCU |

**Always delete NAT Gateways and RDS first** when tearing down — they are the primary cost drivers.

---

## Terraform Conversion


- Modular structure: `vpc`, `security_groups`, `ec2`, `alb`, `rds`, `efs` modules
- Remote state in S3 with DynamoDB locking
- Variables for environment-specific config (region, CIDR blocks, instance types)
- Region: `ca-central-1` (standardized across all portfolio projects)


---

## Tech Stack

| Layer | Technology |
|---|---|
| Cloud | AWS (ca-central-1) |
| Compute | EC2 (Amazon Linux 2023, t2.micro) |
| Web/App | Apache HTTP Server, PHP, WordPress |
| Database | Amazon RDS MySQL 8.0 |
| Storage | Amazon EFS |
| Load Balancing | Application Load Balancer |
| Networking | VPC, Subnets, IGW, NAT Gateway, Route Tables |
| Security | Security Groups (5 chained SGs) |
| IaC (planned) | Terraform |

---

## References

- [Tech With Lucy — zerotocloud.co](https://zerotocloud.co)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [Amazon EFS User Guide](https://docs.aws.amazon.com/efs/latest/ug/)
- [WordPress on AWS](https://aws.amazon.com/getting-started/hands-on/wordpress/)

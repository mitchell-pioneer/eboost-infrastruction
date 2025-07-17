# EBoost Infrastructure Deployment Plan

## Overview
This document outlines the comprehensive plan and implementation for deploying the EBoost system using Terraform for infrastructure provisioning and Ansible for configuration management on AWS Ohio datacenter.

## Architecture Overview
- **Cloud Provider**: AWS (us-east-2 - Ohio)
- **Instance Type**: t2.medium (Better performance for multiple services)
- **Services**:
  - Mosquitto MQTT Broker
  - Django Web Application with Admin
  - PostgreSQL Database
  - Docker Container Platform
  - Portainer Docker Management UI
- **Infrastructure as Code**: Terraform
- **Configuration Management**: Ansible

## Project Structure
```
eboost-infrastructure/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── terraform.tfvars.example
├── ansible/
│   ├── playbooks/
│   │   ├── main.yml
│   │   ├── mosquitto.yml
│   │   ├── django.yml
│   │   └── postgresql.yml
│   ├── inventory/
│   │   ├── hosts.ini
│   │   └── group_vars/
│   │       └── all.yml
│   ├── roles/
│   │   ├── mosquitto/
│   │   ├── django/
│   │   ├── postgresql/
│   │   ├── docker/
│   │   └── portainer/
│   └── templates/
│       ├── mosquitto.conf.j2
│       ├── django_settings.py.j2
│       └── postgresql.conf.j2
├── scripts/
│   ├── deploy.sh
│   └── destroy.sh
└── specs/
    ├── spec1.md
    └── spec2.md
```

## Implementation Plan

### Phase 1: Infrastructure Provisioning (Terraform)
1. **AWS Provider Configuration**
   - Configure AWS provider for Ohio region (us-east-2)
   - Set up required versions and backend configuration

2. **Network Setup**
   - Create VPC with public subnet
   - Configure Internet Gateway and Route Tables
   - Set up Security Groups for SSH, HTTP, HTTPS, MQTT (1883, 8883), and PostgreSQL (5432)

3. **EC2 Instance**
   - Launch t2.micro instance with Ubuntu 22.04 LTS
   - Configure key pair for SSH access
   - Apply security groups (including Portainer ports 9000, 9443)
   - Set up Elastic IP for static addressing

4. **Output Configuration**
   - Export instance public IP
   - Export instance ID and security group IDs

### Phase 2: Configuration Management (Ansible)

#### 2.1 Base System Setup
- Update system packages
- Install essential tools (curl, wget, git, python3, pip)
- Configure firewall rules
- Set up user accounts and SSH keys

#### 2.2 PostgreSQL Database Setup
- Install PostgreSQL 14
- Configure database user and permissions
- Create application database
- Secure PostgreSQL installation
- Configure connection settings
- Set up backup scripts

#### 2.3 Mosquitto MQTT Broker Setup
- Install Mosquitto MQTT broker
- Configure authentication and authorization
- Set up SSL/TLS certificates
- Configure persistence and logging
- Create systemd service
- Test MQTT connectivity

#### 2.4 Docker Platform Setup
- Install Docker CE and Docker Compose
- Configure Docker daemon with security settings
- Create Docker networks for service communication
- Set up Docker log rotation
- Configure Docker user permissions

#### 2.5 Portainer Container Management
- Deploy Portainer CE using Docker Compose
- Configure Portainer with persistent storage
- Set up Portainer admin authentication
- Configure firewall rules for Portainer access
- Set up Portainer backup scripts

#### 2.6 Django Application Setup
- Install Python 3.10 and virtual environment
- Install Django and required dependencies
- Configure Django settings for production
- Set up Django Admin interface
- Configure static files serving
- Set up Gunicorn WSGI server
- Configure Nginx reverse proxy
- Set up SSL certificates
- Create systemd services for Django and Gunicorn

### Phase 3: Service Integration
1. **Database Integration**
   - Configure Django to use PostgreSQL
   - Run Django migrations
   - Create Django superuser
   - Set up database connection pooling

2. **MQTT Integration**
   - Configure Django to connect to Mosquitto
   - Set up MQTT message handling
   - Configure authentication between services

3. **Monitoring and Logging**
   - Set up log rotation
   - Configure system monitoring
   - Set up health checks

## Security Considerations
- Use IAM roles instead of access keys where possible
- Enable VPC Flow Logs
- Configure security groups with minimal required access
- Use SSL/TLS for all communications
- Implement proper database security
- Set up fail2ban for SSH protection
- Regular security updates

## Deployment Commands

### Initial Deployment
```bash
# 1. Initialize Terraform
cd terraform
terraform init
terraform plan
terraform apply

# 2. Run Ansible playbooks
cd ../ansible
ansible-playbook -i inventory/hosts.ini playbooks/main.yml

# 3. Verify deployment
ansible-playbook -i inventory/hosts.ini playbooks/verify.yml
```

### Regular Updates
```bash
# Update configuration
ansible-playbook -i inventory/hosts.ini playbooks/main.yml --tags update

# Update Django application
ansible-playbook -i inventory/hosts.ini playbooks/django.yml --tags deploy
```

## Configuration Variables

### Terraform Variables
- `aws_region`: AWS region (default: us-east-2)
- `instance_type`: EC2 instance type (default: t2.micro)
- `key_name`: EC2 key pair name
- `project_name`: Project name for tagging

### Ansible Variables
- `django_secret_key`: Django secret key
- `db_password`: PostgreSQL password
- `mqtt_username`: MQTT broker username
- `mqtt_password`: MQTT broker password
- `domain_name`: Domain name for SSL certificates

## Monitoring and Maintenance
- Set up CloudWatch monitoring
- Configure log aggregation
- Implement automated backups
- Set up alerting for critical services
- Regular security patching schedule

## Cost Optimization
- Use t2.micro instance (free tier eligible)
- Implement auto-shutdown for development environments
- Use EBS GP2 storage for cost efficiency
- Monitor AWS costs using Cost Explorer

## Disaster Recovery
- Automated database backups
- Infrastructure code versioning
- Configuration snapshots
- Recovery procedures documentation

## SSH Key Setup

### AWS EC2 Key Pair Configuration
1. **Generate SSH Key Pair** (if not already done):
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
   ```

2. **Import Public Key to AWS**:
   - AWS Console: EC2 → Key Pairs → Import Key Pair
   - Name: "eboost-key"
   - Content: `cat ~/.ssh/id_rsa.pub`
   
   Or via CLI:
   ```bash
   aws ec2 import-key-pair \
     --key-name "eboost-key" \
     --public-key-material fileb://~/.ssh/id_rsa.pub \
     --region us-east-2
   ```

3. **Update Terraform Configuration**:
   ```hcl
   key_name = "eboost-key"
   public_key_path = "~/.ssh/id_rsa.pub"
   ```

## Next Steps
1. ✅ Create Terraform configuration files
2. ✅ Develop Ansible playbooks and roles
3. ✅ Create dependency installation scripts
4. ✅ Set up SSH key documentation
5. Set up CI/CD pipeline
6. Implement monitoring and alerting
7. Perform security audit
8. Set up automated testing
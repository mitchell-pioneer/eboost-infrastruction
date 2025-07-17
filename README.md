# EBoost Infrastructure

This repository contains Terraform and Ansible configurations for deploying the EBoost system on AWS.

## Architecture

- **Cloud Provider**: AWS (Ohio - us-east-2)
- **Instance Type**: t2.medium (Better performance)
- **Services**:
  - PostgreSQL Database
  - Mosquitto MQTT Broker
  - Django Web Application with Admin Interface
  - Docker Container Platform
  - Portainer Docker Management UI
  - Nginx Reverse Proxy
  - Supervisor Process Manager

## Prerequisites

**Option 1: Automatic Installation (Recommended)**
Run the appropriate dependency installation script for your operating system:

- **Linux/WSL**: `./scripts/install-dependencies.sh`
- **macOS**: `./scripts/install-dependencies-macos.sh`  
- **Windows**: `.\scripts\install-dependencies-windows.ps1`

**Option 2: Manual Installation**
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Ansible >= 2.9
- SSH key pair for EC2 access

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd eboost-infrastructure
   ```

2. **Install dependencies** (choose your platform):
   ```bash
   # Linux/WSL
   ./scripts/install-dependencies.sh
   
   # macOS
   ./scripts/install-dependencies-macos.sh
   
   # Windows PowerShell (as Administrator)
   .\scripts\install-dependencies-windows.ps1
   ```

3. **Configure AWS credentials**:
   ```bash
   aws configure
   ```

4. **Setup SSH Keys for EC2 Access**:
   
   **Option A: AWS Console (Recommended)**
   - Go to [AWS EC2 Console](https://console.aws.amazon.com/ec2/) → Key Pairs
   - Select Ohio region (us-east-2)
   - Click "Import Key Pair"
   - Name it "eboost-key"
   - Copy your public key: `cat ~/.ssh/id_rsa.pub`
   - Paste into "Public key contents" field
   - Click "Import Key Pair"
   
   **Option B: AWS CLI**
   ```bash
   aws ec2 import-key-pair \
     --key-name "eboost-key" \
     --public-key-material fileb://~/.ssh/id_rsa.pub \
     --region us-east-2
   ```

5. **Configure Terraform variables**:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

6. **Deploy the infrastructure**:
   ```bash
   ./scripts/deploy.sh
   ```

7. **Access your applications**:
   - Django Admin: `http://YOUR_IP/admin/`
   - Django App: `http://YOUR_IP/`
   - Portainer: `http://YOUR_IP:9000/`
   - MQTT Broker: `YOUR_IP:1883`

## Manual Deployment

### Step 1: Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 2: Configure Services

```bash
cd ansible
# Update inventory/hosts.ini with your server IP
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/hosts.ini playbooks/main.yml
```

## Configuration

### Default Credentials

⚠️ **Change these in production!**

- Django Admin: `admin` / `changeme123`
- Database: `eboost_user` / `changeme123`
- MQTT: `eboost_mqtt` / `changeme123`
- Portainer: Set password on first login at `http://YOUR_IP:9000`

### Environment Variables

Update `ansible/inventory/group_vars/all.yml` with your configuration:

```yaml
db_name: eboost_db
db_user: eboost_user
db_password: "your_secure_password"
mqtt_username: "your_mqtt_user"
mqtt_password: "your_mqtt_password"
django_secret_key: "your_secret_key"
```

### SSH Key Configuration

The `terraform.tfvars` file should include:

```hcl
aws_region      = "us-east-2"
instance_type   = "t2.micro"
key_name        = "eboost-key"          # Name from AWS Key Pairs
public_key_path = "~/.ssh/id_rsa.pub"   # Path to your public key
project_name    = "eboost"
```

## Security

- All services run behind UFW firewall
- Database is only accessible locally
- MQTT broker requires authentication
- Django uses secure settings for production

## Monitoring

- PostgreSQL logs: `/var/log/postgresql/`
- Mosquitto logs: `/var/log/mosquitto/`
- Django logs: `/var/log/supervisor/`
- Nginx logs: `/var/log/nginx/`

## Backup

- Automatic PostgreSQL backups run daily at 2 AM
- Backups are stored in `/var/backups/postgresql/`
- Retention period: 7 days

## Troubleshooting

### SSH Connection Issues

**Test SSH connection:**
```bash
# Get instance IP
cd terraform
terraform output instance_ip

# Test SSH connection
ssh -i ~/.ssh/id_rsa ubuntu@YOUR_INSTANCE_IP
```

**Common SSH issues:**
```bash
# Check key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Verify key exists in AWS
aws ec2 describe-key-pairs --region us-east-2

# Check if key exists locally
ls -la ~/.ssh/
```

**Key not found error:**
- Ensure the key name in `terraform.tfvars` matches the name in AWS
- Verify you're using the correct region (us-east-2)

### Check service status:
```bash
sudo systemctl status postgresql
sudo systemctl status mosquitto
sudo systemctl status docker
sudo systemctl status portainer
sudo systemctl status nginx
sudo systemctl status supervisor
```

### View logs:
```bash
sudo tail -f /var/log/supervisor/django.log
sudo tail -f /var/log/mosquitto/mosquitto.log
sudo docker logs portainer
sudo docker logs -f portainer
```

### Test MQTT connection:
```bash
mosquitto_pub -h YOUR_IP -t test/topic -m "Hello World" -u eboost_mqtt -P changeme123
mosquitto_sub -h YOUR_IP -t test/topic -u eboost_mqtt -P changeme123
```

## Cleanup

To destroy all resources:

```bash
./scripts/destroy.sh
```

## Additional Documentation

- [SSH Setup Guide](SSH_SETUP.md) - Detailed SSH key configuration
- [Terraform Configuration](terraform/terraform.tfvars.example) - Infrastructure settings
- [Ansible Variables](ansible/inventory/group_vars/all.yml) - Application configuration

## Support

For issues and questions, please refer to the project documentation or create an issue in the repository.
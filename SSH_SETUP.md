# SSH Key Setup Guide for AWS EC2

This guide provides detailed instructions for setting up SSH keys to access your AWS EC2 instances.

## 🔑 SSH Key Overview

SSH keys provide a secure way to access your EC2 instances without passwords. You need:
- **Private key**: Stays on your local machine (never share!)
- **Public key**: Uploaded to AWS and installed on EC2 instances

## 🛠️ Step 1: Generate SSH Key Pair

### Automatic Generation
The dependency installation scripts automatically generate SSH keys:
```bash
# Linux/WSL
./scripts/install-dependencies.sh

# macOS
./scripts/install-dependencies-macos.sh

# Windows PowerShell
.\scripts\install-dependencies-windows.ps1
```

### Manual Generation
```bash
# Generate 4096-bit RSA key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# View your public key
cat ~/.ssh/id_rsa.pub
```

## 🔄 Step 2: Import Public Key to AWS

### Method 1: AWS Console (Recommended)

1. **Navigate to EC2 Key Pairs**:
   - Go to [AWS EC2 Console](https://console.aws.amazon.com/ec2/)
   - **Important**: Select **Ohio (us-east-2)** region
   - Click "Key Pairs" in the left sidebar under "Network & Security"

2. **Import Your Public Key**:
   - Click "Import Key Pair"
   - **Key pair name**: `eboost-key`
   - **Public key contents**: 
     ```bash
     cat ~/.ssh/id_rsa.pub
     ```
   - Copy the entire output and paste it
   - Click "Import Key Pair"

3. **Verify Import**:
   - You should see "eboost-key" in your key pairs list
   - Status should show "Available"

### Method 2: AWS CLI

```bash
# Import your public key
aws ec2 import-key-pair \
  --key-name "eboost-key" \
  --public-key-material fileb://~/.ssh/id_rsa.pub \
  --region us-east-2

# Verify it was imported
aws ec2 describe-key-pairs --region us-east-2
```

### Method 3: Generate Key Directly in AWS

```bash
# Create new key pair in AWS (downloads private key)
aws ec2 create-key-pair \
  --key-name "eboost-key" \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/eboost-key.pem \
  --region us-east-2

# Set proper permissions
chmod 600 ~/.ssh/eboost-key.pem
```

## ⚙️ Step 3: Configure Terraform

Edit `terraform/terraform.tfvars`:

```hcl
aws_region      = "us-east-2"
instance_type   = "t2.micro"
key_name        = "eboost-key"          # Must match AWS key pair name
public_key_path = "~/.ssh/id_rsa.pub"   # Path to your public key file
project_name    = "eboost"
```

## 🧪 Step 4: Test SSH Connection

After deployment, test your SSH connection:

```bash
# Get instance IP from Terraform
cd terraform
terraform output instance_ip

# Test SSH connection
ssh -i ~/.ssh/id_rsa ubuntu@YOUR_INSTANCE_IP

# Alternative: Use the IP directly
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw instance_ip)
```

## 🔍 Troubleshooting

### Common Issues

**"Key not found" during terraform apply:**
```bash
# Check if key exists in AWS
aws ec2 describe-key-pairs --region us-east-2

# Verify key_name in terraform.tfvars matches AWS
grep key_name terraform/terraform.tfvars
```

**"Permission denied" during SSH:**
```bash
# Check key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Verify you're using the correct key
ssh -i ~/.ssh/id_rsa -v ubuntu@YOUR_INSTANCE_IP
```

**"Connection refused" during SSH:**
```bash
# Check if instance is running
aws ec2 describe-instances --region us-east-2 --filters "Name=tag:Name,Values=eboost-instance"

# Check security group allows SSH (port 22)
aws ec2 describe-security-groups --region us-east-2 --group-names "eboost-sg"
```

**Wrong region:**
- Ensure you're using `us-east-2` (Ohio) in all commands
- Check AWS Console shows Ohio region selected
- Verify `terraform.tfvars` has correct region

### Key File Locations

**Linux/macOS:**
- Private key: `~/.ssh/id_rsa`
- Public key: `~/.ssh/id_rsa.pub`

**Windows:**
- Private key: `C:\Users\YourName\.ssh\id_rsa`
- Public key: `C:\Users\YourName\.ssh\id_rsa.pub`

### Manual Key Verification

```bash
# Check key fingerprint locally
ssh-keygen -lf ~/.ssh/id_rsa.pub

# Check key fingerprint in AWS
aws ec2 describe-key-pairs --key-names eboost-key --region us-east-2
```

## 🛡️ Security Best Practices

1. **Never share your private key** (`id_rsa`)
2. **Set correct permissions**: 600 for private key, 644 for public key
3. **Use strong passphrases** for additional security
4. **Rotate keys regularly** in production environments
5. **Use different keys** for different projects/environments

## 📋 Quick Reference

**Generate key:**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

**Import to AWS:**
```bash
aws ec2 import-key-pair --key-name "eboost-key" --public-key-material fileb://~/.ssh/id_rsa.pub --region us-east-2
```

**Test connection:**
```bash
ssh -i ~/.ssh/id_rsa ubuntu@YOUR_INSTANCE_IP
```

**Check AWS keys:**
```bash
aws ec2 describe-key-pairs --region us-east-2
```
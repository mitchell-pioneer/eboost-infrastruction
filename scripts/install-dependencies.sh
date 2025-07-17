#!/bin/bash

# EBoost Infrastructure Dependencies Installation Script
# This script installs all required tools for deploying EBoost infrastructure

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Detect OS and distribution
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
            DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
            DISTRO=$(cat /etc/redhat-release | awk '{print $1}')
        elif [ -f /etc/arch-release ]; then
            OS="arch"
            DISTRO="Arch"
        else
            OS="linux"
            DISTRO="Unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macOS"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        DISTRO="Windows"
    else
        OS="unknown"
        DISTRO="Unknown"
    fi
    
    print_status "Detected OS: $DISTRO ($OS)"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "This script should not be run as root"
        print_warning "Some installations may fail or create permission issues"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Update system packages
update_system() {
    print_header "Updating system packages..."
    
    case $OS in
        "debian")
            sudo apt-get update
            sudo apt-get install -y curl wget unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
            ;;
        "redhat")
            sudo yum update -y
            sudo yum install -y curl wget unzip which
            ;;
        "arch")
            sudo pacman -Sy
            sudo pacman -S --noconfirm curl wget unzip base-devel
            ;;
        "macos")
            if ! command -v brew &> /dev/null; then
                print_status "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew update
            ;;
        *)
            print_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
}

# Install Python and pip
install_python() {
    print_header "Installing Python and pip..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        print_status "Python $PYTHON_VERSION is already installed"
    else
        case $OS in
            "debian")
                sudo apt-get install -y python3 python3-pip python3-venv
                ;;
            "redhat")
                sudo yum install -y python3 python3-pip
                ;;
            "arch")
                sudo pacman -S --noconfirm python python-pip
                ;;
            "macos")
                brew install python3
                ;;
        esac
    fi
    
    # Upgrade pip
    python3 -m pip install --upgrade pip --user
}

# Install Ansible
install_ansible() {
    print_header "Installing Ansible..."
    
    if command -v ansible &> /dev/null; then
        ANSIBLE_VERSION=$(ansible --version | head -n1 | cut -d' ' -f3)
        print_status "Ansible $ANSIBLE_VERSION is already installed"
    else
        case $OS in
            "debian")
                # Add Ansible PPA for latest version
                sudo add-apt-repository --yes --update ppa:ansible/ansible
                sudo apt-get install -y ansible
                ;;
            "redhat")
                sudo yum install -y epel-release
                sudo yum install -y ansible
                ;;
            "arch")
                sudo pacman -S --noconfirm ansible
                ;;
            "macos")
                brew install ansible
                ;;
        esac
    fi
    
    # Install additional Ansible collections
    ansible-galaxy collection install community.docker
    ansible-galaxy collection install ansible.posix
}

# Install Terraform
install_terraform() {
    print_header "Installing Terraform..."
    
    if command -v terraform &> /dev/null; then
        TERRAFORM_VERSION=$(terraform version | head -n1 | cut -d' ' -f2)
        print_status "Terraform $TERRAFORM_VERSION is already installed"
        return
    fi
    
    # Get latest Terraform version
    TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
    
    case $OS in
        "debian"|"redhat"|"arch")
            # Download and install Terraform
            curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
            case $OS in
                "debian")
                    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
                    sudo apt-get update && sudo apt-get install -y terraform
                    ;;
                *)
                    # Generic Linux installation
                    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                    sudo mv terraform /usr/local/bin/
                    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                    ;;
            esac
            ;;
        "macos")
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
            ;;
    esac
}

# Install AWS CLI
install_aws_cli() {
    print_header "Installing AWS CLI..."
    
    if command -v aws &> /dev/null; then
        AWS_VERSION=$(aws --version | cut -d' ' -f1 | cut -d'/' -f2)
        print_status "AWS CLI $AWS_VERSION is already installed"
        return
    fi
    
    case $OS in
        "debian"|"redhat"|"arch")
            # Install AWS CLI v2
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf awscliv2.zip aws/
            ;;
        "macos")
            brew install awscli
            ;;
    esac
}

# Install Docker (optional but recommended)
install_docker() {
    print_header "Installing Docker (recommended for local testing)..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//')
        print_status "Docker $DOCKER_VERSION is already installed"
        return
    fi
    
    case $OS in
        "debian")
            # Add Docker's official GPG key
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Add Docker repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # Add user to docker group
            sudo usermod -aG docker $USER
            ;;
        "redhat")
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            ;;
        "arch")
            sudo pacman -S --noconfirm docker docker-compose
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            ;;
        "macos")
            print_status "Please install Docker Desktop for Mac from https://www.docker.com/products/docker-desktop"
            ;;
    esac
}

# Install additional utilities
install_utilities() {
    print_header "Installing additional utilities..."
    
    case $OS in
        "debian")
            sudo apt-get install -y git vim nano htop tree jq
            ;;
        "redhat")
            sudo yum install -y git vim nano htop tree jq
            ;;
        "arch")
            sudo pacman -S --noconfirm git vim nano htop tree jq
            ;;
        "macos")
            brew install git vim nano htop tree jq
            ;;
    esac
}

# Setup SSH key if not exists
setup_ssh_key() {
    print_header "Setting up SSH key..."
    
    if [ ! -f ~/.ssh/id_rsa ]; then
        print_status "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
        print_status "SSH key generated at ~/.ssh/id_rsa"
        print_warning "Add your public key to AWS EC2 Key Pairs:"
        print_warning "https://console.aws.amazon.com/ec2/v2/home?region=us-east-2#KeyPairs:"
        echo
        echo "Your public key:"
        cat ~/.ssh/id_rsa.pub
        echo
    else
        print_status "SSH key already exists at ~/.ssh/id_rsa"
    fi
}

# Verify installations
verify_installations() {
    print_header "Verifying installations..."
    
    # Check Python
    if command -v python3 &> /dev/null; then
        print_status "✓ Python $(python3 --version | cut -d' ' -f2)"
    else
        print_error "✗ Python not found"
    fi
    
    # Check Ansible
    if command -v ansible &> /dev/null; then
        print_status "✓ Ansible $(ansible --version | head -n1 | cut -d' ' -f3)"
    else
        print_error "✗ Ansible not found"
    fi
    
    # Check Terraform
    if command -v terraform &> /dev/null; then
        print_status "✓ Terraform $(terraform version | head -n1 | cut -d' ' -f2)"
    else
        print_error "✗ Terraform not found"
    fi
    
    # Check AWS CLI
    if command -v aws &> /dev/null; then
        print_status "✓ AWS CLI $(aws --version | cut -d' ' -f1 | cut -d'/' -f2)"
    else
        print_error "✗ AWS CLI not found"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_status "✓ Docker $(docker --version | cut -d' ' -f3 | sed 's/,//')"
    else
        print_warning "○ Docker not installed (optional)"
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        print_status "✓ Git $(git --version | cut -d' ' -f3)"
    else
        print_warning "○ Git not found"
    fi
}

# Main installation function
main() {
    echo "============================================="
    echo "EBoost Infrastructure Dependencies Installer"
    echo "============================================="
    echo
    
    detect_os
    check_root
    
    echo
    print_status "Starting installation process..."
    echo
    
    update_system
    install_python
    install_ansible
    install_terraform
    install_aws_cli
    
    # Ask if user wants Docker
    echo
    read -p "Install Docker for local testing? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_docker
    fi
    
    install_utilities
    setup_ssh_key
    
    echo
    print_header "Installation Summary"
    verify_installations
    
    echo
    print_status "Installation completed successfully!"
    echo
    print_warning "Next steps:"
    echo "1. Configure AWS credentials: aws configure"
    echo "2. Add your SSH public key to AWS EC2 Key Pairs"
    echo "3. Copy terraform/terraform.tfvars.example to terraform/terraform.tfvars"
    echo "4. Update terraform.tfvars with your configuration"
    echo "5. Run ./scripts/deploy.sh to deploy infrastructure"
    echo
    
    if [[ $OS == "debian" ]] || [[ $OS == "redhat" ]] || [[ $OS == "arch" ]]; then
        print_warning "If Docker was installed, you may need to log out and back in for group permissions to take effect."
    fi
}

# Run main function
main "$@"
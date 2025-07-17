#!/bin/bash

# EBoost Infrastructure Dependencies Installation Script for macOS
# This script installs all required tools for deploying EBoost infrastructure on macOS

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

# Install Homebrew
install_homebrew() {
    print_header "Installing Homebrew..."
    
    if command -v brew &> /dev/null; then
        print_status "Homebrew is already installed"
        brew update
    else
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    print_header "Installing Xcode Command Line Tools..."
    
    if xcode-select -p &> /dev/null; then
        print_status "Xcode Command Line Tools are already installed"
    else
        print_status "Installing Xcode Command Line Tools..."
        xcode-select --install
        
        print_warning "Please complete the Xcode Command Line Tools installation and then re-run this script"
        exit 1
    fi
}

# Install Python
install_python() {
    print_header "Installing Python..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        print_status "Python $PYTHON_VERSION is already installed"
    else
        brew install python3
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
        brew install ansible
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
    else
        brew tap hashicorp/tap
        brew install hashicorp/tap/terraform
    fi
}

# Install AWS CLI
install_aws_cli() {
    print_header "Installing AWS CLI..."
    
    if command -v aws &> /dev/null; then
        AWS_VERSION=$(aws --version | cut -d' ' -f1 | cut -d'/' -f2)
        print_status "AWS CLI $AWS_VERSION is already installed"
    else
        brew install awscli
    fi
}

# Install Docker Desktop
install_docker() {
    print_header "Installing Docker Desktop..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//')
        print_status "Docker $DOCKER_VERSION is already installed"
    else
        brew install --cask docker
        print_status "Docker Desktop installed successfully"
        print_warning "Please start Docker Desktop from Applications folder"
    fi
}

# Install additional utilities
install_utilities() {
    print_header "Installing additional utilities..."
    
    local tools=("git" "vim" "nano" "htop" "tree" "jq" "curl" "wget")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_status "$tool is already installed"
        else
            brew install "$tool"
            print_status "$tool installed successfully"
        fi
    done
}

# Setup SSH key
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
    
    # Check Homebrew
    if command -v brew &> /dev/null; then
        print_status "✓ Homebrew $(brew --version | head -n1 | cut -d' ' -f2)"
    else
        print_error "✗ Homebrew not found"
    fi
}

# Main installation function
main() {
    echo "============================================="
    echo "EBoost Infrastructure Dependencies Installer"
    echo "macOS Version"
    echo "============================================="
    echo
    
    check_root
    
    print_status "Starting installation process..."
    echo
    
    install_xcode_tools
    install_homebrew
    install_python
    install_ansible
    install_terraform
    install_aws_cli
    
    # Ask if user wants Docker
    echo
    read -p "Install Docker Desktop for local testing? (y/n): " -n 1 -r
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
    
    print_warning "You may need to restart your terminal for PATH changes to take effect."
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_warning "If Docker was installed, please start Docker Desktop from Applications folder."
    fi
}

# Run main function
main "$@"
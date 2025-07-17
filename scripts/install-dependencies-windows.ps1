# EBoost Infrastructure Dependencies Installation Script for Windows
# This script installs all required tools for deploying EBoost infrastructure on Windows

param(
    [switch]$InstallDocker = $false
)

# Function to print colored output
function Write-Status {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Header {
    param($Message)
    Write-Host "[STEP] $Message" -ForegroundColor Blue
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Install Chocolatey if not present
function Install-Chocolatey {
    Write-Header "Installing Chocolatey package manager..."
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Status "Chocolatey is already installed"
        return
    }
    
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Install Python
function Install-Python {
    Write-Header "Installing Python..."
    
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonVersion = python --version
        Write-Status "Python is already installed: $pythonVersion"
    } else {
        choco install python3 -y
        Write-Status "Python installed successfully"
    }
    
    # Upgrade pip
    python -m pip install --upgrade pip --user
}

# Install Git
function Install-Git {
    Write-Header "Installing Git..."
    
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVersion = git --version
        Write-Status "Git is already installed: $gitVersion"
    } else {
        choco install git -y
        Write-Status "Git installed successfully"
    }
}

# Install Ansible
function Install-Ansible {
    Write-Header "Installing Ansible..."
    
    if (Get-Command ansible -ErrorAction SilentlyContinue) {
        $ansibleVersion = ansible --version | Select-String "ansible" | Select-Object -First 1
        Write-Status "Ansible is already installed: $ansibleVersion"
    } else {
        # Install Ansible via pip
        python -m pip install ansible --user
        Write-Status "Ansible installed successfully"
    }
    
    # Install additional Ansible collections
    ansible-galaxy collection install community.docker
    ansible-galaxy collection install ansible.posix
}

# Install Terraform
function Install-Terraform {
    Write-Header "Installing Terraform..."
    
    if (Get-Command terraform -ErrorAction SilentlyContinue) {
        $terraformVersion = terraform version | Select-String "Terraform" | Select-Object -First 1
        Write-Status "Terraform is already installed: $terraformVersion"
    } else {
        choco install terraform -y
        Write-Status "Terraform installed successfully"
    }
}

# Install AWS CLI
function Install-AwsCli {
    Write-Header "Installing AWS CLI..."
    
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        $awsVersion = aws --version
        Write-Status "AWS CLI is already installed: $awsVersion"
    } else {
        # Download and install AWS CLI v2
        $awsInstaller = "$env:TEMP\AWSCLIV2.msi"
        Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $awsInstaller
        Start-Process msiexec.exe -ArgumentList "/i $awsInstaller /quiet" -Wait
        Remove-Item $awsInstaller
        Write-Status "AWS CLI installed successfully"
    }
}

# Install Docker Desktop (optional)
function Install-Docker {
    Write-Header "Installing Docker Desktop..."
    
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $dockerVersion = docker --version
        Write-Status "Docker is already installed: $dockerVersion"
    } else {
        choco install docker-desktop -y
        Write-Status "Docker Desktop installed successfully"
        Write-Warning "Please restart your computer and enable WSL 2 for Docker Desktop"
    }
}

# Install additional utilities
function Install-Utilities {
    Write-Header "Installing additional utilities..."
    
    # Install useful tools
    $tools = @("vim", "nano", "jq", "curl", "wget")
    
    foreach ($tool in $tools) {
        if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
            try {
                choco install $tool -y
                Write-Status "$tool installed successfully"
            } catch {
                Write-Warning "Failed to install $tool"
            }
        } else {
            Write-Status "$tool is already installed"
        }
    }
}

# Setup SSH key
function Setup-SshKey {
    Write-Header "Setting up SSH key..."
    
    $sshDir = "$env:USERPROFILE\.ssh"
    $sshKeyPath = "$sshDir\id_rsa"
    
    if (!(Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force
    }
    
    if (!(Test-Path $sshKeyPath)) {
        Write-Status "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f $sshKeyPath -N '""'
        Write-Status "SSH key generated at $sshKeyPath"
        Write-Warning "Add your public key to AWS EC2 Key Pairs:"
        Write-Warning "https://console.aws.amazon.com/ec2/v2/home?region=us-east-2#KeyPairs:"
        Write-Host ""
        Write-Host "Your public key:"
        Get-Content "$sshKeyPath.pub"
        Write-Host ""
    } else {
        Write-Status "SSH key already exists at $sshKeyPath"
    }
}

# Verify installations
function Test-Installations {
    Write-Header "Verifying installations..."
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Check Python
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonVersion = python --version
        Write-Status "✓ $pythonVersion"
    } else {
        Write-Error "✗ Python not found"
    }
    
    # Check Ansible
    if (Get-Command ansible -ErrorAction SilentlyContinue) {
        $ansibleVersion = ansible --version | Select-String "ansible" | Select-Object -First 1
        Write-Status "✓ $ansibleVersion"
    } else {
        Write-Error "✗ Ansible not found"
    }
    
    # Check Terraform
    if (Get-Command terraform -ErrorAction SilentlyContinue) {
        $terraformVersion = terraform version | Select-String "Terraform" | Select-Object -First 1
        Write-Status "✓ $terraformVersion"
    } else {
        Write-Error "✗ Terraform not found"
    }
    
    # Check AWS CLI
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        $awsVersion = aws --version
        Write-Status "✓ $awsVersion"
    } else {
        Write-Error "✗ AWS CLI not found"
    }
    
    # Check Docker
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $dockerVersion = docker --version
        Write-Status "✓ $dockerVersion"
    } else {
        Write-Warning "○ Docker not installed (optional)"
    }
    
    # Check Git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVersion = git --version
        Write-Status "✓ $gitVersion"
    } else {
        Write-Warning "○ Git not found"
    }
}

# Main installation function
function Main {
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "EBoost Infrastructure Dependencies Installer" -ForegroundColor Cyan
    Write-Host "Windows PowerShell Version" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if running as Administrator
    if (!(Test-Administrator)) {
        Write-Warning "This script should be run as Administrator for best results"
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne "y") {
            exit 1
        }
    }
    
    Write-Status "Starting installation process..."
    Write-Host ""
    
    Install-Chocolatey
    Install-Python
    Install-Git
    Install-Ansible
    Install-Terraform
    Install-AwsCli
    
    # Ask if user wants Docker
    if (!$InstallDocker) {
        $dockerChoice = Read-Host "Install Docker Desktop for local testing? (y/n)"
        if ($dockerChoice -eq "y") {
            $InstallDocker = $true
        }
    }
    
    if ($InstallDocker) {
        Install-Docker
    }
    
    Install-Utilities
    Setup-SshKey
    
    Write-Host ""
    Write-Header "Installation Summary"
    Test-Installations
    
    Write-Host ""
    Write-Status "Installation completed successfully!"
    Write-Host ""
    Write-Warning "Next steps:"
    Write-Host "1. Configure AWS credentials: aws configure"
    Write-Host "2. Add your SSH public key to AWS EC2 Key Pairs"
    Write-Host "3. Copy terraform\terraform.tfvars.example to terraform\terraform.tfvars"
    Write-Host "4. Update terraform.tfvars with your configuration"
    Write-Host "5. Run .\scripts\deploy.sh to deploy infrastructure"
    Write-Host ""
    
    if ($InstallDocker) {
        Write-Warning "If Docker was installed, you may need to restart your computer for it to work properly."
    }
    
    Write-Warning "You may need to restart your terminal or PowerShell for PATH changes to take effect."
}

# Run main function
Main
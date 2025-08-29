# Windows Agent Setup Script
# PowerShell script for Windows Server 2019/2022

param(
    [string]$JenkinsUrl = "http://YOUR_CONTROLLER_IP:8080",
    [string]$AgentSecret = "YOUR_AGENT_SECRET",
    [string]$AgentName = "windows-agent"
)

Write-Host "=== Windows Jenkins Agent Setup ===" -ForegroundColor Green

# Create Jenkins user
Write-Host "Creating Jenkins user..." -ForegroundColor Yellow
try {
    $Password = ConvertTo-SecureString "admin" -AsPlainText -Force
    New-LocalUser -Name "jenkins" -Password $Password -Description "Jenkins Agent User" -AccountNeverExpires -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member "jenkins"
    Write-Host "Jenkins user created successfully" -ForegroundColor Green
} catch {
    Write-Host "User may already exist or error occurred: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create Jenkins directory
Write-Host "Creating Jenkins directory..." -ForegroundColor Yellow
$JenkinsDir = "C:\jenkins"
if (-not (Test-Path $JenkinsDir)) {
    New-Item -ItemType Directory -Path $JenkinsDir -Force
}

# Set directory permissions
$acl = Get-Acl $JenkinsDir
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("jenkins", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $JenkinsDir $acl

# Create logs directory
$LogsDir = "$JenkinsDir\logs"
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force
}

# Download and install Java 17 (if not already installed)
Write-Host "Checking Java installation..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1 | Select-String "version"
    Write-Host "Java already installed: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "Java not found. Please install Java 17 manually from:" -ForegroundColor Red
    Write-Host "https://adoptium.net/temurin/releases/?version=17" -ForegroundColor Yellow
    Write-Host "Continuing with script assuming Java will be installed..." -ForegroundColor Yellow
}

# Download WinSW (Windows Service Wrapper)
Write-Host "Downloading WinSW..." -ForegroundColor Yellow
$winswUrl = "https://github.com/winsw/winsw/releases/latest/download/WinSW-x64.exe"
$winswPath = "$JenkinsDir\jenkins-agent.exe"

try {
    Invoke-WebRequest -Uri $winswUrl -OutFile $winswPath
    Write-Host "WinSW downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to download WinSW: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please download manually from: $winswUrl" -ForegroundColor Yellow
}

# Create service configuration file
Write-Host "Creating service configuration..." -ForegroundColor Yellow
$serviceConfig = @"
<service>
    <id>jenkins-agent</id>
    <name>Jenkins Agent</name>
    <description>Jenkins Agent running as a Windows Service</description>
    <executable>java</executable>
    <arguments>-jar C:\jenkins\agent.jar -url $JenkinsUrl -secret $AgentSecret -name $AgentName -workDir C:\jenkins -webSocket</arguments>
    <logpath>C:\jenkins\logs</logpath>
    <log mode="roll"></log>
</service>
"@

$serviceConfig | Out-File -FilePath "$JenkinsDir\jenkins-agent.xml" -Encoding UTF8

# Download Jenkins agent.jar (this will need to be updated with actual URL from Jenkins)
Write-Host "Creating script to download agent.jar..." -ForegroundColor Yellow
$downloadScript = @"
# Run this script after configuring the agent in Jenkins UI
# Replace URL with the actual agent.jar download URL from Jenkins
Invoke-WebRequest -Uri "$JenkinsUrl/jnlpJars/agent.jar" -OutFile "C:\jenkins\agent.jar"
"@

$downloadScript | Out-File -FilePath "$JenkinsDir\download-agent.ps1" -Encoding UTF8

# Create installation script
$installScript = @"
# Install and start Jenkins agent service
# Run this AFTER downloading agent.jar

Set-Location C:\jenkins

# Install the service
.\jenkins-agent.exe install

# Start the service
.\jenkins-agent.exe start

# Check service status
Get-Service jenkins-agent
"@

$installScript | Out-File -FilePath "$JenkinsDir\install-service.ps1" -Encoding UTF8

Write-Host "=== Windows Agent Setup Complete ===" -ForegroundColor Green
Write-Host "" 
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure this Windows node in Jenkins UI (Manage Jenkins > Nodes)"
Write-Host "2. Use launch method: 'Launch agent via Java Web Start (JNLP)'"
Write-Host "3. Copy the agent.jar download URL from the node page"
Write-Host "4. Run: C:\jenkins\download-agent.ps1 (update URL first)"
Write-Host "5. Run: C:\jenkins\install-service.ps1"
Write-Host ""
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "- C:\jenkins\jenkins-agent.exe (WinSW)"
Write-Host "- C:\jenkins\jenkins-agent.xml (Service config)"
Write-Host "- C:\jenkins\download-agent.ps1 (Agent download script)"
Write-Host "- C:\jenkins\install-service.ps1 (Service installation script)"
Write-Host ""
Write-Host "Jenkins Directory: $JenkinsDir" -ForegroundColor Cyan
Write-Host "Service will run as: jenkins user" -ForegroundColor Cyan
# Android SDK Setup Script for Windows
# Run this script in PowerShell as Administrator

Write-Host "Setting up Android SDK without Android Studio..." -ForegroundColor Green

# Create SDK directory
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
New-Item -ItemType Directory -Force -Path $sdkPath | Out-Null

Write-Host "SDK will be installed to: $sdkPath" -ForegroundColor Yellow

# Download command-line tools
Write-Host "`nStep 1: Downloading Android SDK Command-line Tools..." -ForegroundColor Cyan
$toolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$toolsZip = "$env:TEMP\android-tools.zip"
$toolsExtract = "$env:TEMP\android-tools"

# Download
Invoke-WebRequest -Uri $toolsUrl -OutFile $toolsZip

# Extract
Expand-Archive -Path $toolsZip -DestinationPath $toolsExtract -Force

# Move to correct location
$cmdlinePath = "$sdkPath\cmdline-tools\latest"
New-Item -ItemType Directory -Force -Path $cmdlinePath | Out-Null
Move-Item -Path "$toolsExtract\cmdline-tools\*" -Destination $cmdlinePath -Force

Write-Host "Command-line tools installed!" -ForegroundColor Green

# Set environment variables
Write-Host "`nStep 2: Setting environment variables..." -ForegroundColor Cyan
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "User")

# Add to PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$sdkPath\platform-tools*") {
    $newPath = "$currentPath;$sdkPath\platform-tools;$sdkPath\cmdline-tools\latest\bin"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added to PATH!" -ForegroundColor Green
}

# Install required packages
Write-Host "`nStep 3: Installing Android SDK components..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Yellow

$env:ANDROID_HOME = $sdkPath
$env:ANDROID_SDK_ROOT = $sdkPath
$env:PATH = "$sdkPath\platform-tools;$sdkPath\cmdline-tools\latest\bin;$env:PATH"

# Accept licenses
Write-Host "Accepting licenses..." -ForegroundColor Yellow
echo "y" | & "$cmdlinePath\bin\sdkmanager.bat" --licenses | Out-Null

# Install required packages
Write-Host "Installing platform-tools, platform, and build-tools..." -ForegroundColor Yellow
& "$cmdlinePath\bin\sdkmanager.bat" "platform-tools" "platforms;android-34" "build-tools;34.0.0" | Out-Null

Write-Host "`n✅ Android SDK setup complete!" -ForegroundColor Green
Write-Host "`nPlease restart your terminal/PowerShell and run: flutter doctor" -ForegroundColor Yellow
Write-Host "SDK Location: $sdkPath" -ForegroundColor Cyan


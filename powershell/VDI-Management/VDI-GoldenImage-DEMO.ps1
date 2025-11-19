<#
.SYNOPSIS
   VDI Golden Image Management Automation - Demo Version
   
.DESCRIPTION
   This is a demonstration excerpt of the full VDI Golden Image management script.
   The complete production script (2,500+ lines) is available upon request.
   
   Full script capabilities include:
   - Automated Windows/Office update management
   - VMware Horizon Agent installation and configuration
   - Dynamic Environment Manager deployment
   - App Volumes agent configuration with HA support
   - FSLogix profile container management
   - Microsoft Teams for VDI deployment
   - OneDrive and Google Drive enterprise installation
   - OSOT (OS Optimization Tool) integration
   - Comprehensive logging and error handling
   
.NOTES
   Version:        2510.0 (Production)
   Author:         Nicholas Buckingham
   Demonstration:  Core framework and key functions
   
   Full Script Stats:
   - Lines of Code: 2,500+
   - Functions: 25+
   - Supported Actions: 14
   - Configuration Parameters: 50+
#>

#----------------[ Script Parameters ]----------------
param (
    [Parameter(Mandatory=$false)]
        [ValidateSet("Update", "Finalize", "VmTools", "Horizon", "DEM", "AppVolumes", "FSLogix", "MsTeams", "OneDrive", "Exit")]
        [string] $Action,
    [Parameter(Mandatory=$false)]
        [string] $ConfigFile
)

#----------------[ Core Configuration ]----------------
$VAR = @{
    ScriptName = "VDI Golden Image Maintenance [v2510]"
    ScriptPath = $PSScriptRoot
    
    # Update Management Settings
    ManageWindowsUpdates = $true
    ManageOfficeUpdates = $true
    ManageMsEdgeUpdate = $true
    
    # OSOT Finalization Settings
    OsotPath = "C:\Program Files\OSOT"
    OsotFinalizeArg = "-v -f 0 1 2 3 4 5 7 9 10 11"
    OsotShutdownAfterFinalize = $true
    
    # Horizon Agent Configuration
    HorizonAgentAddLocal = "ALL"
    HorizonAgentRemove = "SerialPortRedirection,ScannerRedirection,SmartCard,SdoSensor"
    DelPerfTrackerDesktopIcon = $true
    
    # DEM Configuration Share (Example)
    DemConfigPath = "\\domain.local\VDI$\DEMConfig\general"
    
    # App Volumes HA Configuration (Example)
    AppVolManager = @("vdi-avm01.domain.local", "vdi-avm02.domain.local")
    AppVolDisableSpoolerRestart = $true
    AppVolMaxDelayTimeOutS = 30
    
    # Logging Configuration
    LogDir = "Logs"
    LogFileName = "VDI-GI-Maintenance-{0:yyyyMMdd_HHmmss}.txt"
    LogArchiveFiles = 14
}

#----------------[ Example Functions ]----------------

function Write-Log {
    <#
    .SYNOPSIS
        Comprehensive logging function with console and file output
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Warning','Error','Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Console output with color
    switch ($Level) {
        'Info'    { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
    
    # File output
    $logFile = Join-Path $VAR.ScriptPath $VAR.LogDir ($VAR.LogFileName -f (Get-Date))
    $logMessage | Out-File -FilePath $logFile -Append -Encoding UTF8
}

function Get-InstalledSoftwareVersion {
    <#
    .SYNOPSIS
        Retrieves installed software version from registry
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$SoftwareName
    )
    
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $registryPaths) {
        $software = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
                    Where-Object { $_.DisplayName -like "*$SoftwareName*" } |
                    Select-Object -First 1
        
        if ($software) {
            return @{
                Name = $software.DisplayName
                Version = $software.DisplayVersion
                Publisher = $software.Publisher
                InstallDate = $software.InstallDate
            }
        }
    }
    
    return $null
}

function Set-WindowsUpdateRegistry {
    <#
    .SYNOPSIS
        Configures Windows Update registry settings for golden image
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Enable','Disable')]
        [string]$Action
    )
    
    Write-Log "Configuring Windows Update settings: $Action" -Level Info
    
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    
    if (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    if ($Action -eq 'Disable') {
        Set-ItemProperty -Path $regPath -Name "DeferQualityUpdatesPeriodInDays" -Value 30 -Type DWord
        Write-Log "Windows Updates disabled for deployed VMs" -Level Success
    } else {
        Set-ItemProperty -Path $regPath -Name "DeferQualityUpdatesPeriodInDays" -Value 0 -Type DWord
        Write-Log "Windows Updates enabled for golden image maintenance" -Level Success
    }
}

function Install-VDIComponent {
    <#
    .SYNOPSIS
        Generic function for installing/updating VDI components
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComponentName,
        
        [Parameter(Mandatory=$true)]
        [string]$InstallerPath,
        
        [Parameter(Mandatory=$false)]
        [string]$Arguments,
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    Write-Log "Installing/Updating: $ComponentName" -Level Info
    
    if (!(Test-Path $InstallerPath)) {
        Write-Log "Installer not found: $InstallerPath" -Level Error
        return $false
    }
    
    try {
        $process = Start-Process -FilePath $InstallerPath `
                                  -ArgumentList $Arguments `
                                  -Wait `
                                  -PassThru `
                                  -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Log "$ComponentName installed successfully" -Level Success
            return $true
        } else {
            Write-Log "$ComponentName installation failed with exit code: $($process.ExitCode)" -Level Error
            return $false
        }
    }
    catch {
        Write-Log "Exception during $ComponentName installation: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Invoke-OSOTFinalization {
    <#
    .SYNOPSIS
        Executes Windows OS Optimization Tool finalization
    #>
    param(
        [Parameter(Mandatory=$false)]
        [switch]$FastMode
    )
    
    $osotExe = Get-ChildItem -Path $VAR.OsotPath -Filter "VMwareOSOptimizationTool.exe" -Recurse | 
               Sort-Object LastWriteTime -Descending | 
               Select-Object -First 1
    
    if (!$osotExe) {
        Write-Log "OSOT executable not found in: $($VAR.OsotPath)" -Level Error
        return $false
    }
    
    Write-Log "Running OSOT Finalization: $($osotExe.FullName)" -Level Info
    
    $arguments = if ($FastMode) { $VAR.OsotFinalizeArgFast } else { $VAR.OsotFinalizeArg }
    
    try {
        $process = Start-Process -FilePath $osotExe.FullName `
                                  -ArgumentList $arguments `
                                  -Wait `
                                  -PassThru `
                                  -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Log "OSOT Finalization completed successfully" -Level Success
            
            if ($VAR.OsotShutdownAfterFinalize) {
                Write-Log "Shutting down system in 60 seconds..." -Level Warning
                Start-Process "shutdown.exe" -ArgumentList "/s /t 60 /c `"OSOT Finalization Complete - System shutting down for snapshot`"" -NoNewWindow
            }
            
            return $true
        } else {
            Write-Log "OSOT Finalization failed with exit code: $($process.ExitCode)" -Level Error
            return $false
        }
    }
    catch {
        Write-Log "Exception during OSOT Finalization: $($_.Exception.Message)" -Level Error
        return $false
    }
}

#----------------[ Main Script Logic ]----------------

Write-Log "========================================" -Level Info
Write-Log "$($VAR.ScriptName)" -Level Info
Write-Log "========================================" -Level Info

# Load external configuration if specified
if ($ConfigFile) {
    if (Test-Path $ConfigFile) {
        Write-Log "Loading configuration from: $ConfigFile" -Level Info
        . $ConfigFile
    } else {
        Write-Log "Configuration file not found: $ConfigFile" -Level Warning
    }
}

# Action routing
switch ($Action) {
    "Update" {
        Write-Log "Starting Golden Image Update Process" -Level Info
        Set-WindowsUpdateRegistry -Action Enable
        # Full script includes comprehensive update logic
        Write-Log "Update process completed - See full script for implementation" -Level Info
    }
    
    "Finalize" {
        Write-Log "Starting Golden Image Finalization Process" -Level Info
        Set-WindowsUpdateRegistry -Action Disable
        Invoke-OSOTFinalization
        # Full script includes complete finalization workflow
        Write-Log "Finalization process completed - See full script for implementation" -Level Info
    }
    
    default {
        Write-Log "This is a demo version - Full script available upon request" -Level Info
        Write-Log "Supported actions: Update, Finalize, VmTools, Horizon, DEM, AppVolumes, FSLogix, MsTeams, OneDrive" -Level Info
    }
}

Write-Log "Script execution completed" -Level Success

<#
FULL SCRIPT FEATURES NOT SHOWN IN DEMO:
========================================
- Complete update management (Windows/Office/Third-party)
- VMware Tools installation and configuration
- Horizon Agent deployment with feature selection
- Dynamic Environment Manager setup
- App Volumes agent with HA configuration
- FSLogix installation and registry configuration
- Microsoft Teams for VDI (MSIX deployment)
- OneDrive per-machine installation
- Google Drive enterprise deployment
- Horizon Recording Agent configuration
- SDelete disk optimization
- Defragmentation management
- Comprehensive error handling and logging
- Version comparison and upgrade logic
- Interactive menu system
- Configuration file management
- Backup and rollback capabilities

Contact: nbucking@gmail.com for full script access
#>

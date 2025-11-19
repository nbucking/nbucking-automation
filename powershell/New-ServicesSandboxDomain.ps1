<#
.SYNOPSIS
    Creates the complete OU structure for services.sandbox.local domain in Windows Server 2025 Datacenter.

.DESCRIPTION
    This script creates all Organizational Units (OUs) for the services.sandbox.local Active Directory domain.
    It follows the structure defined in the services.sandbox.local file from the automation-stage repository.
    
    The script should be run on a Windows Server 2025 Datacenter Domain Controller with appropriate permissions.

.PARAMETER DomainDN
    The distinguished name of the domain. Default: "DC=services,DC=sandbox,DC=local"

.PARAMETER WhatIf
    Shows what would happen if the script runs without making actual changes.

.EXAMPLE
    .\New-ServicesSandboxDomain.ps1
    
.EXAMPLE
    .\New-ServicesSandboxDomain.ps1 -WhatIf

.NOTES
    Requires: Active Directory PowerShell module
    Compatible with: Windows Server 2025 Datacenter
    Run as: Domain Administrator or equivalent
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$DomainDN = "DC=services,DC=sandbox,DC=local"
)

# Ensure Active Directory module is loaded
Import-Module ActiveDirectory -ErrorAction Stop

# Function to create OU if it doesn't exist
function New-ADOrganizationalUnitIfNotExists {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Description = ""
    )
    
    $ouDN = "OU=$Name,$Path"
    
    try {
        $existingOU = Get-ADOrganizationalUnit -Identity $ouDN -ErrorAction SilentlyContinue
        if ($existingOU) {
            Write-Host "OU already exists: $ouDN" -ForegroundColor Yellow
        }
    }
    catch {
        if ($PSCmdlet.ShouldProcess($ouDN, "Create OU")) {
            try {
                New-ADOrganizationalUnit -Name $Name -Path $Path -Description $Description -ProtectedFromAccidentalDeletion $true
                Write-Host "Created OU: $ouDN" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to create OU: $ouDN - $_"
            }
        }
    }
}

Write-Host "`n=== Creating OU Structure for services.sandbox.local ===" -ForegroundColor Cyan
Write-Host "Domain DN: $DomainDN`n" -ForegroundColor Cyan

# Root Level OUs
$rootOUs = @(
    @{Name="Computers"; Description="Computer objects"},
    @{Name="Desktops"; Description="Desktop computer OUs"},
    @{Name="DHSMail"; Description="DHS Mail related objects"},
    @{Name="Disabled Accounts"; Description="Disabled user and computer accounts"},
    @{Name="Elevated Accounts"; Description="Privileged and elevated access accounts"},
    @{Name="GPO Staging"; Description="Group Policy staging area"},
    @{Name="Groups"; Description="Security and distribution groups"},
    @{Name="Keys"; Description="Key management objects"},
    @{Name="Linux Systems"; Description="Linux server systems"},
    @{Name="Managed Service Accounts"; Description="Group Managed Service Accounts (gMSA)"},
    @{Name="Non-Elevated Accounts"; Description="Standard user accounts"},
    @{Name="Program Data"; Description="Application data objects"},
    @{Name="Windows Systems"; Description="Windows server systems"}
)

Write-Host "Creating root-level OUs..." -ForegroundColor Cyan
foreach ($ou in $rootOUs) {
    New-ADOrganizationalUnitIfNotExists -Name $ou.Name -Path $DomainDN -Description $ou.Description
}

# Desktops Structure
Write-Host "`nCreating Desktops OUs..." -ForegroundColor Cyan
$desktopsPath = "OU=Desktops,$DomainDN"
New-ADOrganizationalUnitIfNotExists -Name "Physical" -Path $desktopsPath -Description "Physical desktop computers"
New-ADOrganizationalUnitIfNotExists -Name "VDI's" -Path $desktopsPath -Description "Virtual Desktop Infrastructure"
New-ADOrganizationalUnitIfNotExists -Name "STAMP" -Path $desktopsPath -Description "STAMP desktop systems"

# VDI's Structure
$vdiPath = "OU=VDI's,$desktopsPath"
New-ADOrganizationalUnitIfNotExists -Name "Gold Images" -Path $vdiPath -Description "VDI gold image templates"
New-ADOrganizationalUnitIfNotExists -Name "SC Exempt" -Path $vdiPath -Description "Smart card exempt VDIs"

# Gold Images
$goldImagesPath = "OU=Gold Images,$vdiPath"
New-ADOrganizationalUnitIfNotExists -Name "Linux" -Path $goldImagesPath -Description "Linux gold images"
New-ADOrganizationalUnitIfNotExists -Name "Windows" -Path $goldImagesPath -Description "Windows gold images"
New-ADOrganizationalUnitIfNotExists -Name "AppVol" -Path $goldImagesPath -Description "App Volumes"

# STAMP Structure (AJ and CS)
$stampPath = "OU=STAMP,$desktopsPath"
New-ADOrganizationalUnitIfNotExists -Name "AJ" -Path $stampPath -Description "AJ STAMP systems"
New-ADOrganizationalUnitIfNotExists -Name "CS" -Path $stampPath -Description "CS STAMP systems"

# STAMP/AJ
$stampAJPath = "OU=AJ,$stampPath"
$stampAJOUs = @(
    "AJ-HZN-LNX-OM-ST", "AJ-HZN-OSC-VCS", "AJ-STAMP-LEAD", 
    "AJ-STR-VRT-ST", "AJ-WNDS-OM-ST"
)
foreach ($ou in $stampAJOUs) {
    New-ADOrganizationalUnitIfNotExists -Name $ou -Path $stampAJPath
}

# STAMP/CS
$stampCSPath = "OU=CS,$stampPath"
$stampCSOUs = @(
    "CPAtest1", "CS-ADD-ENTERPRISE", "CS-CREDSEC-ST", "CS-ESVP-ENTERPRISE",
    "CS-HZN-MA-ST", "CS-HZNSCA-ST", "CS-LNX-OM-RH-ST", "CS-LNX-OM-ST",
    "CS-NTWRK-ST", "CS-SLRWNDS-ST", "CS-STAMP-LEAD", "CS-STR-VRT-ST",
    "CS-TSPPS-ENTERPRISE", "CS-WINDS-OM-P", "CS-WINDS-OM-ST-2", "CSSTSRV-HZNIVS-ST"
)
foreach ($ou in $stampCSOUs) {
    New-ADOrganizationalUnitIfNotExists -Name $ou -Path $stampCSPath
}

# Elevated Accounts Structure
Write-Host "`nCreating Elevated Accounts OUs..." -ForegroundColor Cyan
$elevatedPath = "OU=Elevated Accounts,$DomainDN"
New-ADOrganizationalUnitIfNotExists -Name "PAM Accounts" -Path $elevatedPath -Description "Privileged Access Management accounts"
New-ADOrganizationalUnitIfNotExists -Name "DA" -Path $elevatedPath -Description "Domain Administrator accounts"
New-ADOrganizationalUnitIfNotExists -Name "Service Accounts" -Path $elevatedPath -Description "Elevated service accounts"

# Groups Structure
Write-Host "`nCreating Groups OUs..." -ForegroundColor Cyan
$groupsPath = "OU=Groups,$DomainDN"
New-ADOrganizationalUnitIfNotExists -Name "Distribution Groups" -Path $groupsPath -Description "Distribution groups"
New-ADOrganizationalUnitIfNotExists -Name "Security Groups" -Path $groupsPath -Description "Security groups"
New-ADOrganizationalUnitIfNotExists -Name "Universal Groups" -Path $groupsPath -Description "Universal groups"

# Linux Systems Structure (AJ and CS)
Write-Host "`nCreating Linux Systems OUs..." -ForegroundColor Cyan
$linuxPath = "OU=Linux Systems,$DomainDN"
New-ADOrganizationalUnitIfNotExists -Name "AJ" -Path $linuxPath -Description "AJ Linux systems"
New-ADOrganizationalUnitIfNotExists -Name "CS" -Path $linuxPath -Description "CS Linux systems"

# Linux Systems - AJ
$linuxAJPath = "OU=AJ,$linuxPath"
$linuxServices = @(
    "GitLab", "HDD", "Helix", "OpenShift", "Prisma", 
    "Sonatype", "SSO", "Vault", "VMware"
)
foreach ($service in $linuxServices) {
    New-ADOrganizationalUnitIfNotExists -Name $service -Path $linuxAJPath -Description "$service servers"
}
# OpenShift/HDD sub-OU
New-ADOrganizationalUnitIfNotExists -Name "HDD" -Path "OU=OpenShift,$linuxAJPath" -Description "OpenShift HDD"

# Linux Systems - CS
$linuxCSPath = "OU=CS,$linuxPath"
foreach ($service in $linuxServices) {
    New-ADOrganizationalUnitIfNotExists -Name $service -Path $linuxCSPath -Description "$service servers"
}
# OpenShift/HDD sub-OU
New-ADOrganizationalUnitIfNotExists -Name "HDD" -Path "OU=OpenShift,$linuxCSPath" -Description "OpenShift HDD"

# Non-Elevated Accounts Structure
Write-Host "`nCreating Non-Elevated Accounts OUs..." -ForegroundColor Cyan
$nonElevatedPath = "OU=Non-Elevated Accounts,$DomainDN"
New-ADOrganizationalUnitIfNotExists -Name "Exchange Linked Accounts (DO NOT ENABLE)" -Path $nonElevatedPath -Description "Exchange linked accounts - disabled"
New-ADOrganizationalUnitIfNotExists -Name "PIV Accounts" -Path $nonElevatedPath -Description "PIV card accounts"

# PIV Accounts Structure
$pivPath = "OU=PIV Accounts,$nonElevatedPath"
New-ADOrganizationalUnitIfNotExists -Name "GPO_TEST" -Path $pivPath -Description "GPO testing accounts"
New-ADOrganizationalUnitIfNotExists -Name "Horizon" -Path $pivPath -Description "Horizon related accounts"
New-ADOrganizationalUnitIfNotExists -Name "SCA Team" -Path $pivPath -Description "SCA Team accounts"

# GPO_TEST sub-OUs
$gpoTestPath = "OU=GPO_TEST,$pivPath"
$gpoTestOUs = @("CD", "DP", "JDR", "MS")
foreach ($ou in $gpoTestOUs) {
    New-ADOrganizationalUnitIfNotExists -Name $ou -Path $gpoTestPath
}

# Horizon sub-OU
$horizonPath = "OU=Horizon,$pivPath"
New-ADOrganizationalUnitIfNotExists -Name "Allow Google Chrome pop-ups" -Path $horizonPath -Description "Chrome pop-up policy"

# Windows Systems Structure (AJ and CS)
Write-Host "`nCreating Windows Systems OUs..." -ForegroundColor Cyan
$windowsPath = "OU=Windows Systems,$DomainDN"
New-ADOrganizationalUnitIfNotExists -Name "AJ" -Path $windowsPath -Description "AJ Windows systems"
New-ADOrganizationalUnitIfNotExists -Name "CS" -Path $windowsPath -Description "CS Windows systems"

# Windows Systems - AJ
$windowsAJPath = "OU=AJ,$windowsPath"
$windowsServices = @(
    "DFS", "Exchange", "External DNS", "Flexera", "Horizon", 
    "Mail", "NBU", "Remedy", "SAN", "SCCM", "Security", 
    "SolarWinds Orion", "SQL", "Venafi"
)
foreach ($service in $windowsServices) {
    New-ADOrganizationalUnitIfNotExists -Name $service -Path $windowsAJPath -Description "$service servers"
}

# Windows Systems - CS
$windowsCSPath = "OU=CS,$windowsPath"
$windowsServicesCS = @(
    "DFS", "Exchange", "External DNS", "Flexera", "Horizon", 
    "Jump", "KMS", "Mail", "NBU", "Remedy", "SAN", "SCCM", 
    "Security", "SolarWinds Orion", "SQL", "Venafi"
)
foreach ($service in $windowsServicesCS) {
    New-ADOrganizationalUnitIfNotExists -Name $service -Path $windowsCSPath -Description "$service servers"
}

Write-Host "`n=== OU Structure Creation Complete ===" -ForegroundColor Green
Write-Host "Note: Built-in containers (Builtin, Domain Controllers, ForeignSecurityPrincipals, etc.) already exist and were not created.`n" -ForegroundColor Yellow

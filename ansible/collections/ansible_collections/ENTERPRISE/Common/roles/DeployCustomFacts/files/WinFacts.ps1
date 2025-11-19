##Ansible Facts

$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain ; Write-Host $myFQDN
$local = $myFQDN
$fqdnfull = $local.split("(.)")
$smbios_guid=(Get-WmiObject -Class Win32_ComputerSystemProduct | Select-Object UUID)

$dc = $null
$ev = $null
$tenantname = $null
$domain = $null
$appname = $null
$stampver = "UNKNOWN"
$capsule = 'csstsrvlvsat151.services.stamp.tsa.dhs.gov'


##Evaluate naming standard
if ($fqdnfull[0].length -eq 14)
{
    # Old naming standard
    #C	S	S	S	N	O	N	W	V	B	L	D	5	2
    #0	1	2	3	4	5	6	7	8	9	A	B	C	D
    

    $fqdnfull    = $local.split("(.)")
    $domain      = $fqdnfull[1]
    $location    = $local.substring(0,2) ## Location of host (AJ, CS, D1)
    $tenant      = $local.substring(2,2) ## ST,TV,TM,SG
    $environment = $local.substring(4,3) ## DEV,TST,STG,NON,PRD,etc
    $SystemType  = $local.substring(8,1) ## Virtual or physical
    $application = $local.substring(9,3) ## Application ecosystem
    $tenantenv   = $environment
    $stampver    = "1"

 
    # switch ($location)
    # {
    #     cs { $dc = 'CS'}
    #     aj { $dc = 'AJ'}
    #     d1 { $dc = 'D1'}
    #     CS { $dc = 'CS'}
    #     AJ { $dc = 'AJ'}
    #     D1 { $dc = 'D1'}
    # }


    switch ($tenant)
    {
        ST {$tenantname = 'ENTERPRISE'}
        SS {$tenantname = 'ENTERPRISE'}
        TV {$tenantname = 'VCS'}
        VC {$tenantname = 'VCS'}
        SG {$tenantname = 'SG'}
        TM {$tenantname = 'TIM'}
        VC {$tenantname = 'VCS'}
    }

    switch ($tenant)
    {
        VC {$tenant = 'TV'}
    }

    switch ($application)
    {
        MPO { $appname = 'McAffee'}
        JMP { $appname = 'Jump'}
        NBM { $appname = 'Netbackup'}
        RSS { $appname = 'Remedy'}
        SCN { $appname = 'SQL'}
        SWD { $appname = 'SolarWinds'}
        AWS { $appname = 'SolarWinds'}
        EOC { $appname = 'SolarWinds'}
        APE { $appname = 'SolarWinds'}
        EMX { $appname = 'Exchange'}
        MSG { $appname = 'Exchange-Mailbox'}
        MSC { $appname = 'SCCM'}
        KMS { $appname = 'Key Management Server'}
        VCN { $appname = 'HyperV'}
        ADS { $appname = 'Domain Controller'}
        RDS { $appname = 'RDP Gateway'}
        DHP { $appname = 'DHCP'}
        NSS { $appname = 'Nessus'}
        SCM { $appname = 'SCCM'}
        CRS { $appname = 'NFS Cluster'}
        ORC { $appname = 'Oracle'}
        BLD { $appname = 'Build'}
        LBB { $appname = 'Lab'}
        default {$appname = 'Unknown'}
    }


    

    
    switch ($SystemType)
    {
        P { $System = 'Physical'}
        V { $System = 'Virtual' }
    }

    switch ($location){
        "AJ" {
            switch ($tenant)  {
                "SG" {
                    switch ($environment) {
                        "DEV" { $datacenter="AJNON"}
                        "TST" { $datacenter="AJNON"}
                        "STG" { $datacenter="AJNON"}
                        "PRD" { $datacenter="AJPRD"}
                        default {$datacenter="UNKNOWN"}
                    } # End of env switch
                  } # End of SG
                 "TM" {
                     switch ($environment) {
                        "DEV" { $datacenter="AJNON"}
                        "DIT" { $datacenter="AJNON"}
                        "SIT" { $datacenter="AJNON"}
                        "STG" { $datacenter="AJPRD"}
                        "PRD" { $datacenter="AJPRD"}
                        default {$datacenter="UNKNOWN"}
                      } #End of env switch
                    } # End of TIM
                 "TV" {
                     switch ($environment) {
                        "DEV" { $datacenter="CSNON"}
                        "DTS" { $datacenter="CSNON"}
                        "NON" { $datacenter="CSNON"}
                        "UTS" { $datacenter="CSNON"}
                        "STS" { $datacenter="CSNON"}
                        "TSG" { $datacenter="CSNON"}
                        "TST" { $datacenter="CSNON"}
                        "STG" { $datacenter="AJPRD"}
                        "PRD" { $datacenter="AJPRD"}
                        default {$datacenter="UNKNOWN"}
                      } #End of env switch
                    } # End of TVS
                 "SS" {
                     switch ($environment) {
                        "NON" { $datacenter="AJNON"}
                        "LAB" { $datacenter="AJNON"}
                        "DEV" { $datacenter="AJNON"}
                        "PRD" { $datacenter="AJPRD"}
                        default {$datacenter="UNKNOWN"}
                      } #End of env switch
                    } # End of SS
                 "ST" {
                     switch ($environment) {
                        "NON" { $datacenter="AJNON"}
                        "LAB" { $datacenter="AJNON"}
                        "PRD" { $datacenter="AJPRD"}
                        default {$datacenter="UNKNOWN"}
                      } #End of env switch
                    } # End of ST
                  } # End of tenant switch
        } #End of AJ
        
        "CS" {
            switch ($tenant)  {
                "SG" {
                    switch ($environment) {
                        "DEV" { $datacenter="CSNON"}
                        "TST" { $datacenter="CSNON"}
                        "STG" { $datacenter="CSNON"}
                        "PRD" { $datacenter="CSPRD"}
                        default {$datacenter="UNKNOWN"}
                    } # End of env switch
                  } # End of SG
                 "TM" {
                     switch ($environment) {
                        "DEV" { $datacenter="CSNON"}
                        "DIT" { $datacenter="CSNON"}
                        "SIT" { $datacenter="CSNON"}
                        "STG" { $datacenter="CSPRD"}
                        "PRD" { $datacenter="CSPRD"}
                        default {$datacenter="UNKNOWN"}
                      } #End of env switch
                    } # End of TIM
                 "TV" {
                     switch ($environment) {
                        "DEV" { $datacenter="CSNON"}
                        "DTS" { $datacenter="CSNON"}
                        "NON" { $datacenter="CSNON"}
                        "UTS" { $datacenter="CSNON"}
                        "STS" { $datacenter="CSNON"}
                        "TSG" { $datacenter="CSNON"}
                        "TST" { $datacenter="CSNON"}
                        "STG" { $datacenter="CSPRD"}
                        "PRD" { $datacenter="CSPRD"}
                        default {$datacenter="UNKNOWN"}
                      } #End of env switch
                    } # End of TVS
                 "SS" {
                     switch ($environment) {
                        "NON" { $datacenter="CSNON"}
                        "LAB" { $datacenter="CSNON"}
                        "DEV" { $datacenter="CSNON"}
                        "PRD" { $datacenter="CSPRD"}
                        default {$datacenter="UNKNOWN"}
                      } #End of env switch
                    } # End of SS
                 "ST" {
                     switch ($environment) {
                        "NON" { $datacenter="CSNON"}
                        "LAB" { $datacenter="CSNON"}
                        "PRD" { $datacenter="CSPRD"}
                        default {$datacenter="UNKNOWN"}
                      } #End of env switch
                    } # End of ST
                  } # End of tenant switch
        } #End of CS statement
     } #End of location switch

     switch ($datacenter)
     {
         AJNON {$capsule = 'ajstsrvlvcap152.services.stamp.tsa.dhs.gov'}
         AJPRD {$capsule = 'ajstsrvlvcap151.services.stamp.tsa.dhs.gov'}
         CSNON {$capsule = 'csstsrvlvcap152.services.stamp.tsa.dhs.gov'}
         CSPRD {$capsule = 'csstsrvlvcap151.services.stamp.tsa.dhs.gov'}
     }

}  ## End of old naming standard

elseif ($fqdnfull[0].length -eq 15)
{  ## Start of new naming standard

    #C	S	S	T	S	R	V	W	V	B	L	D	2	5   1
    #0	1	2	3	4	5	6	7	8	9	A	B	C	D   E

    $fqdnfull    = $local.split("(.)")
    $domain      = $fqdnfull[1]
    $location    = $local.substring(0,2)  ## Location of host (AJ, CS, D1)
    $tenant      = $local.substring(2,2)  ## ST,TV,TM,SG
    $tenantenv   = $local.substring(4,3)  ## SRV,MGT
    $SystemType  = $local.substring(8,1)  ## Virtual or physical
    $application = $local.substring(9,3)  ## Application ecosystem
    $environment = $local.substring(12,1) ## PRD or PPD
    $stampver    = "2"

    switch ($environment)
    {
        2 { $environment = 'PPD'}
        1 { $environment = 'PRD'}
    }

    switch ($tenant)
    {
        ST {$tenantname = 'ENTERPRISE'}
        SS {$tenantname = 'ENTERPRISE'}
        TV {$tenantname = 'VCS'}
        VC {$tenantname = 'VCS'}
        SG {$tenantname = 'SG'}
        TM {$tenantname = 'TIM'}
    }

    switch ($application)
    {
        MPO { $appname = 'McAffee'}
        JMP { $appname = 'Jump'}
        NBM { $appname = 'Netbackup'}
        RSS { $appname = 'Remedy'}
        SCN { $appname = 'SQL'}
        SWD { $appname = 'SolarWinds'}
        AWS { $appname = 'SolarWinds'}
        EOC { $appname = 'SolarWinds'}
        APE { $appname = 'SolarWinds'}
        EMX { $appname = 'Exchange'}
        MSG { $appname = 'Exchange-Mailbox'}
        MSC { $appname = 'SCCM'}
        KMS { $appname = 'Key Management Server'}
        VCN { $appname = 'HyperV'}
        ADS { $appname = 'Domain Controller'}
        RDS { $appname = 'RDP Gateway'}
        DHP { $appname = 'DHCP'}
        NSS { $appname = 'Nessus'}
        SCM { $appname = 'SCCM'}
        CRS { $appname = 'NFS Cluster'}
        ORC { $appname = 'Oracle'}
        BLD { $appname = 'Build'}
        LBB { $appname = 'Lab'}
        default {$appname = 'Unknown'}
    }

    switch ($type)
    {
        SRV { $tenantenv = 'Services'}
        MGT { $tenantenv = 'Management'}
    }

    switch ($SystemType)
    {
        P { $System = 'Physical'}
        V { $System = 'Virtual' }
    }

    $datacenter  = $location+$environment
    
    switch ($datacenter)
    {
        CSPPD { $datacenter = 'CSNON'}
        CSNON { $datacenter = 'CSNON'}
        CSPRD { $datacenter = 'CSPRD'}
        AJPPD { $datacenter = 'AJNON'}
        AJNON { $datacenter = 'AJNON'}
        AJPRD { $datacenter = 'AJPRD'}
        D1PRD { $datacenter = 'D1PRD'}
    }

    switch ($datacenter)
    {
        AJNON {$capsule = 'ajstsrvlvcap152.services.stamp.tsa.dhs.gov'}
        AJPRD {$capsule = 'ajstsrvlvcap151.services.stamp.tsa.dhs.gov'}
        CSNON {$capsule = 'csstsrvlvcap152.services.stamp.tsa.dhs.gov'}
        CSPRD {$capsule = 'csstsrvlvcap151.services.stamp.tsa.dhs.gov'}
    } 

} ## End of new naming convention

elseif ($fqdnfull[0].length -eq 13)
{  ## Start of old vdi naming process

    #A	J	S	G	N	O	N	W	V	D	I	6	1
    #0	1	2	3	4	5	6	7	8	9	A	B	C

    $fqdnfull    = $local.split("(.)")
    $domain      = $fqdnfull[1]
    $location    = $local.substring(0,2)  ## Location of host (AJ, CS, D1)
    $tenant      = $local.substring(2,2)  ## ST,TV,TM,SG
    $tenantenv   = $local.substring(4,3)  ## SRV,MGT
    $SystemType  = $local.substring(8,1)  ## Virtual or physical
    $application = $local.substring(8,3)  ## Application ecosystem
    $environment = $local.substring(4,3) ## PRD or PPD
    $stampver    = "1"

    switch ($environment)
    {
        2 { $environment = 'PPD'}
        1 { $environment = 'PRD'}
    }

    switch ($tenant)
    {
        ST {$tenantname = 'ENTERPRISE'}
        SS {$tenantname = 'ENTERPRISE'}
        TV {$tenantname = 'VCS'}
        VC {$tenantname = 'VCS'}
        SG {$tenantname = 'SG'}
        TM {$tenantname = 'TIM'}
    }

    switch ($application)
    {
        MPO { $appname = 'McAffee'}
        JMP { $appname = 'Jump'}
        NBM { $appname = 'Netbackup'}
        RSS { $appname = 'Remedy'}
        SCN { $appname = 'SQL'}
        SWD { $appname = 'SolarWinds'}
        AWS { $appname = 'SolarWinds'}
        EOC { $appname = 'SolarWinds'}
        APE { $appname = 'SolarWinds'}
        EMX { $appname = 'Exchange'}
        MSG { $appname = 'Exchange-Mailbox'}
        MSC { $appname = 'SCCM'}
        KMS { $appname = 'Key Management Server'}
        VCN { $appname = 'HyperV'}
        ADS { $appname = 'Domain Controller'}
        RDS { $appname = 'RDP Gateway'}
        DHP { $appname = 'DHCP'}
        NSS { $appname = 'Nessus'}
        SCM { $appname = 'SCCM'}
        CRS { $appname = 'NFS Cluster'}
        ORC { $appname = 'Oracle'}
        BLD { $appname = 'Build'}
        LBB { $appname = 'Lab'}
        VDI { $appname = 'Virtual Desktop'}
        default {$appname = 'Unknown'}
    }

    switch ($type)
    {
        SRV { $tenantenv = 'Services'}
        MGT { $tenantenv = 'Management'}
    }

    switch ($SystemType)
    {
        P { $System = 'Physical'}
        V { $System = 'Virtual' }
    }

    $datacenter  = $location+$environment
    
    switch ($datacenter)
    {
        CSPPD { $datacenter = 'CSNON'}
        CSNON { $datacenter = 'CSNON'}
        CSPRD { $datacenter = 'CSPRD'}
        AJPPD { $datacenter = 'AJNON'}
        AJNON { $datacenter = 'AJNON'}
        AJPRD { $datacenter = 'AJPRD'}
        D1PRD { $datacenter = 'D1PRD'}
    }

    switch ($datacenter)
    {
        AJNON {$capsule = 'ajstsrvlvcap152.services.stamp.tsa.dhs.gov'}
        AJPRD {$capsule = 'ajstsrvlvcap151.services.stamp.tsa.dhs.gov'}
        CSNON {$capsule = 'csstsrvlvcap152.services.stamp.tsa.dhs.gov'}
        CSPRD {$capsule = 'csstsrvlvcap151.services.stamp.tsa.dhs.gov'}
    } 

} ## End of old vdi naming process


## Check if Chrome is installed and get version
$chrome_exists = Test-Path -Path "C:\Program Files\Google\Chrome\Application\chrome.exe"

if ($chrome_exists) {
     $chrome = (Get-Item "C:\Program Files\Google\Chrome\Application\chrome.exe").VersionInfo
     $chrome = (-split $chrome)[8]
} else {
     $chrome = "NOT INSTALLED"
}

$location    = $location.ToUpper()
$tenantname  = $tenantname.ToUpper()
$domain      = $domain.ToUpper()
$environment = $environment.ToUpper()
$tenantenv   = $tenantenv.ToUpper()
$System      = $System.ToUpper()
$datacenter  = $datacenter.ToUpper()
$appname     = $appname.ToUpper()
$capsule     = $capsule.ToUpper()
$chrome      = $chrome.ToUpper()


@{
    vmInfo = @{
        location = $location
        tenant = $tenantname
        domain = $domain
        environment = $environment
        tenantenvironment = $tenantenv
        systemtype = $System
        datacenter = $datacenter
        application = $appname
        stamp_version = $stampver
        capsule = $capsule
        chrome  = $chrome
        smbios_guid = $smbios_guid
    }
}


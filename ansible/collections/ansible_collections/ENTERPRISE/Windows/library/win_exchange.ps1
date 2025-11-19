#!powershell

# Copyright: (c) 2025, ENTERPRISE Automation Team
# ENTERPRISE Automation Team
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        command = @{ type = "str"; required = $true }
        parameters = @{ type = "dict"; default = @{} }
        output_format = @{ type = "str"; default = "json"; choices = @("json", "table", "list", "raw") }
        timeout = @{ type = "int"; default = 120 }
        load_snapin = @{ type = "bool"; default = $true }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$command = $module.Params.command
$parameters = $module.Params.parameters
$output_format = $module.Params.output_format
$timeout = $module.Params.timeout
$load_snapin = $module.Params.load_snapin

$module.Result.changed = $false
$module.Result.output = ""

# Function to load Exchange Management snap-in
function Load-ExchangeSnapin {
    try {
        # Check if snap-in is already loaded
        $snapin = Get-PSSnapin | Where-Object { $_.Name -eq "Microsoft.Exchange.Management.PowerShell.SnapIn" }
        
        if (-not $snapin) {
            Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop
            $module.Result.snapin_loaded = $true
        } else {
            $module.Result.snapin_loaded = $false
        }
        
        return $true
    }
    catch {
        $module.FailJson("Failed to load Exchange Management snap-in: $($_.Exception.Message)")
        return $false
    }
}

# Function to execute Exchange command
function Invoke-ExchangeCommand {
    param(
        [string]$Command,
        [hashtable]$Parameters,
        [string]$OutputFormat,
        [int]$Timeout
    )
    
    try {
        # Build parameter string for splatting
        $paramString = ""
        $splat = @{}
        
        foreach ($key in $Parameters.Keys) {
            $value = $Parameters[$key]
            $splat[$key] = $value
            
            # Build string representation for logging
            if ($value -is [string]) {
                $paramString += "-$key '$value' "
            } else {
                $paramString += "-$key $value "
            }
        }
        
        $module.Result.command_executed = "$Command $paramString".Trim()
        
        # Execute command with timeout using a job
        # Need to load snap-in in the job since it doesn't inherit parent runspace
        $job = Start-Job -ScriptBlock {
            param($cmd, $params, $loadSnapin)
            
            # Load Exchange snap-in in the job runspace
            if ($loadSnapin) {
                $snapin = Get-PSSnapin | Where-Object { $_.Name -eq "Microsoft.Exchange.Management.PowerShell.SnapIn" }
                if (-not $snapin) {
                    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop
                }
            }
            
            # Execute the command
            if ($params.Count -gt 0) {
                & $cmd @params
            } else {
                & $cmd
            }
        } -ArgumentList $Command, $splat, $load_snapin
        
        # Wait for job with timeout
        $completed = Wait-Job $job -Timeout $Timeout
        
        if (-not $completed) {
            Remove-Job $job -Force
            throw "Command timed out after $Timeout seconds"
        }
        
        # Get results and errors
        $result = Receive-Job $job -ErrorAction SilentlyContinue -ErrorVariable jobErrors
        
        # Check job state
        if ($job.State -eq 'Failed') {
            $errorMsg = "Job failed"
            if ($job.ChildJobs[0].Error.Count -gt 0) {
                $errorMsg = ($job.ChildJobs[0].Error | ForEach-Object { $_.ToString() }) -join "; "
            }
            Remove-Job $job -Force
            throw "Command failed: $errorMsg"
        }
        
        # Check for errors in the error stream
        if ($jobErrors.Count -gt 0) {
            $errorMsg = ($jobErrors | ForEach-Object { $_.ToString() }) -join "; "
            Remove-Job $job -Force
            throw "Command failed: $errorMsg"
        }
        
        Remove-Job $job -Force
        
        return $result
    }
    catch {
        throw "Exchange command execution failed: $($_.Exception.Message)"
    }
}

# Function to format output
function Format-ExchangeOutput {
    param(
        $Result,
        [string]$Format
    )
    
    try {
        switch ($Format.ToLower()) {
            "json" {
                if ($null -eq $Result) {
                    return "null"
                }
                return ($Result | ConvertTo-Json -Depth 5 -Compress)
            }
            "table" {
                if ($null -eq $Result) {
                    return "No results"
                }
                return ($Result | Format-Table -AutoSize | Out-String).Trim()
            }
            "list" {
                if ($null -eq $Result) {
                    return "No results"
                }
                return ($Result | Format-List | Out-String).Trim()
            }
            "raw" {
                if ($null -eq $Result) {
                    return "No results"
                }
                return $Result.ToString()
            }
            default {
                return ($Result | ConvertTo-Json -Depth 10 -Compress)
            }
        }
    }
    catch {
        $module.Warn("Failed to format output as $Format, returning raw: $($_.Exception.Message)")
        return $Result.ToString()
    }
}

# Main execution
try {
    # Check mode - don't execute, just validate
    if ($module.CheckMode) {
        # Load Exchange snap-in if requested (needed for command validation)
        if ($load_snapin) {
            Load-ExchangeSnapin | Out-Null
        }
        
        # Validate command exists
        $cmdlet = Get-Command $command -ErrorAction SilentlyContinue
        if (-not $cmdlet) {
            $module.FailJson("Command '$command' not found. Exchange snap-in may not be loaded.")
        }
        
        $module.Result.msg = "Check mode: Command '$command' would be executed with parameters: $($parameters | ConvertTo-Json -Compress)"
        $module.ExitJson()
    }
    
    # Note: Snap-in is loaded inside the job runspace (see Invoke-ExchangeCommand)
    # We don't need to load it here unless we want to validate the command exists
    # For validation, load it temporarily
    if ($load_snapin) {
        # Load snap-in for command validation
        $snapinLoaded = Get-PSSnapin | Where-Object { $_.Name -eq "Microsoft.Exchange.Management.PowerShell.SnapIn" }
        if (-not $snapinLoaded) {
            try {
                Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop
                $snapinLoadedNow = $true
            } catch {
                $module.FailJson("Failed to load Exchange Management snap-in: $($_.Exception.Message)")
            }
        }
    }
    
    # Validate command exists
    $cmdlet = Get-Command $command -ErrorAction SilentlyContinue
    if (-not $cmdlet) {
        $module.FailJson("Command '$command' not found. Ensure Exchange Management Shell is available.")
    }
    
    # Execute the Exchange command
    $result = Invoke-ExchangeCommand -Command $command -Parameters $parameters -OutputFormat $output_format -Timeout $timeout
    
    # Format output
    $formatted_output = Format-ExchangeOutput -Result $result -Format $output_format
    $module.Result.output = $formatted_output
    
    # Determine if this was a change operation
    $change_commands = @(
        'Move-*', 'Set-*', 'Start-*', 'Stop-*', 'Restart-*', 'Suspend-*', 
        'Resume-*', 'Remove-*', 'Add-*', 'New-*', 'Enable-*', 'Disable-*',
        'Mount-*', 'Dismount-*', 'Redirect-*'
    )
    
    $is_change_command = $false
    foreach ($pattern in $change_commands) {
        if ($command -like $pattern) {
            $is_change_command = $true
            break
        }
    }
    
    $module.Result.changed = $is_change_command
    $module.Result.command_type = if ($is_change_command) { "change" } else { "query" }
    
    # Add execution metadata
    $module.Result.execution_time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $module.Result.server = $env:COMPUTERNAME
    
    # Count results if possible
    if ($result -is [array]) {
        $module.Result.result_count = $result.Count
    } elseif ($null -ne $result) {
        $module.Result.result_count = 1
    } else {
        $module.Result.result_count = 0
    }
    
    $module.ExitJson()
}
catch {
    $module.FailJson("Exchange module execution failed: $($_.Exception.Message)", $_)
}
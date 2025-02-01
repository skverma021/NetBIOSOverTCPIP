### Script to disable NetBIOS over TCP/IP
# Ensure you run this script with administrative privileges.

# Define log file path
$LogFilePath = "C:\Windows\Logs\DisableNetBIOS.log"

# Create the log directory if it doesn't exist
if (!(Test-Path -Path (Split-Path $LogFilePath))) {
    New-Item -ItemType Directory -Path (Split-Path $LogFilePath) -Force | Out-Null }

# Function to log messages
Function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp : $Message" | Out-File -FilePath $LogFilePath -Append
}

# Check domain membership
$Domain = (Get-WmiObject -Class Win32_ComputerSystem).Domain
If ($Domain -eq $null -or $Domain -eq "WORKGROUP") {
    Write-Log "This machine is not domain-joined. Exiting script."
    Exit
}

# Get Windows Server version
$OSVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version
Write-Log "Detected OS Version: $OSVersion"

# Check for Server versions (2012, 2016, 2019)
Switch ($OSVersion) {
    { $_ -like "6.2*" } {
        $ServerVersion = "2012"; break
    }
    { $_ -like "6.3*" } {
        $ServerVersion = "2012 R2"; break
    }
    { $_ -like "10.0.14393*" } {
        $ServerVersion = "2016"; break
    }
    { $_ -like "10.0.17763*" } {
        $ServerVersion = "2019"; break
    }
    { $_ -like "10.0.20348*" } {
        $ServerVersion = "2022"; break
    }
    Default {
        Write-Log "Unsupported OS Version: $OSVersion. Exiting script."
        Exit
    }
}

# Skip disabling on Server 2022
If ($ServerVersion -eq "2022") {
    Write-Log "Skipping NetBIOS disable as the OS is Server 2022."
    Exit
}

Write-Log "Proceeding with NetBIOS disable on Server $ServerVersion."

# ADSI Method to disable NetBIOS
Try {
    $NICs = Get-WmiObject -Namespace "Root\CIMv2" -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    
    If ($NICs.Count -eq 0) {
        Write-Log "No active network adapters found. Exiting script."
        Exit
    }

    foreach ($NIC in $NICs) {
        $AdapterName = $NIC.Description
        Write-Log "Disabling NetBIOS for adapter: $AdapterName"
        $NIC.SetTcpipNetbios(2) | Out-Null
        Write-Log "NetBIOS successfully disabled for adapter: $AdapterName"
    }
} Catch {
    Write-Log "Error occurred while disabling NetBIOS: $_"
}

Write-Log "Script execution completed."

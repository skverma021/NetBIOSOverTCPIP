# get_netbios_shadow_simple.ps1

# Get NetBIOS over TCP/IP
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
$netbiosOptions = $adapters | Select-Object -ExpandProperty TcpipNetbiosOptions -ErrorAction SilentlyContinue

# Determine effective NetBIOS status
$netbiosStatus = if ($netbiosOptions -contains 1) {
    "Enabled"
} elseif ($netbiosOptions -contains 2) {
    "Disabled"
} else {
    "Default or Unknown"
}

# Get Shadow Copy info
$shadowCopies = Get-WmiObject Win32_ShadowCopy -ErrorAction SilentlyContinue
if ($shadowCopies) {
    $volumes = $shadowCopies | Select-Object -ExpandProperty VolumeName | Sort-Object -Unique
    $shadowStatus = "Enabled (Volumes: " + ($volumes -join ", ") + ")"
} else {
    $shadowStatus = "Disabled or No Snapshots"
}

# Output single object
[PSCustomObject]@{
    Host             = $env:COMPUTERNAME
    NetBIOS_Status   = $netbiosStatus
    ShadowCopy_Status = $shadowStatus
    Last_Checked     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
} | ConvertTo-Json -Compress

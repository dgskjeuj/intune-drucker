# Requirement-PingIP.ps1
# Gibt 1 aus, wenn die IP per ICMP erreichbar ist.
# Gibt 0 aus, wenn die IP nicht erreichbar ist.
# Für Intune Requirement Rule: Integer Equals 1
# IP-Adresse entsprechend anpassen.

$IPAddress = "192.168.55.52"

try {
    $PingResult = Test-Connection -ComputerName $IPAddress -Count 2 -Quiet -ErrorAction Stop

    if ($PingResult -eq $true) {
        Write-Output 1
    }
    else {
        Write-Output 0
    }
}
catch {
    Write-Output 0
}

exit 0
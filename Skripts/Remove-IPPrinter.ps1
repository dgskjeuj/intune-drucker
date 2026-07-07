<#
.SYNOPSIS
   Deinstallation von IP-Druckern (4 Warteschlangen)
 
.DESCRIPTION
   Dieses Script dient der Entfernung der vier Druckerwarteschlangen, die ueber das Script
   "Install-IPPrinter.ps1" installiert wurden:
     <PrinterName> - A4 Schwarz-Weiss
     <PrinterName> - A4 Farbe
     <PrinterName> - A3 Schwarz-Weiss
     <PrinterName> - A3 Farbe
   ---
   Deinstallationsbefehl in Intune (Parameter entsprechend befuellen):
   %SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "Skripts\Remove-IPPrinter.ps1" -PortIPAddress "" -PrinterName "" [-A4SW] [-A4Farbe] [-A3SW] [-A3Farbe]
   Hinweis: Ohne Queue-Schalter werden alle vier Warteschlangen entfernt.
 
.EXAMPLE
   Remove-IPPrinter.ps1 -PortIPAddress "192.168.55.52" -PrinterName "Drucker EG"
 
.PARAMETER PortIPAddress
   Die IP-Adresse des Druckers.

.PARAMETER PrinterName
   Der Basisname des Druckers (identisch mit dem Parameter beim Installationsskript).

.PARAMETER A4SW
   Schalter: Warteschlange "<PrinterName> - A4 Schwarz-Weiss" entfernen.

.PARAMETER A4Farbe
   Schalter: Warteschlange "<PrinterName> - A4 Farbe" entfernen.

.PARAMETER A3SW
   Schalter: Warteschlange "<PrinterName> - A3 Schwarz-Weiss" entfernen.

.PARAMETER A3Farbe
   Schalter: Warteschlange "<PrinterName> - A3 Farbe" entfernen.

.NOTES
  Version:        3.0
  Author:         Raphael Baud
  Creation Date:  2023-02-22
  Purpose/Change: Modulare Queue-Auswahl per Schalter; Port-Entfernung nur wenn kein Drucker mehr den Port nutzt
#>

#################
#---Parameter---#
#################
Param(
    [Parameter(Mandatory=$True)]
    [string]$PortIPAddress,

    [Parameter(Mandatory=$True)]
    [string]$PrinterName,

    [switch]$A4SW,
    [switch]$A4Farbe,
    [switch]$A3SW,
    [switch]$A3Farbe
)

#################
#---Execution---#
#################

$PortName = "IP_$PortIPAddress"

#Gewuenschte Warteschlangen bestimmen (ohne Schalter = alle vier)
$removeAll = -not ($A4SW.IsPresent -or $A4Farbe.IsPresent -or $A3SW.IsPresent -or $A3Farbe.IsPresent)

$printerNames = @()
if ($removeAll -or $A4SW)    { $printerNames += "$PrinterName - A4 Schwarz-Weiss" }
if ($removeAll -or $A4Farbe) { $printerNames += "$PrinterName - A4 Farbe" }
if ($removeAll -or $A3SW)    { $printerNames += "$PrinterName - A3 Schwarz-Weiss" }
if ($removeAll -or $A3Farbe) { $printerNames += "$PrinterName - A3 Farbe" }

foreach ($name in $printerNames) {
    if (Get-Printer -Name $name -ErrorAction SilentlyContinue) {
        Remove-Printer -Name $name -ErrorAction SilentlyContinue
    }
}

#Abwarten, bis der Print-Spooler den Port freigibt
Start-Sleep -Seconds 30

#Port nur entfernen wenn kein Drucker mehr diesen Port verwendet
$remainingPrinters = Get-Printer | Where-Object { $_.PortName -eq $PortName }
if (-not $remainingPrinters -and (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue)) {
    Remove-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
}

#nach der Deinstallation etwas abwarten, um das Detection Script zu verzoegern

Start-Sleep -Seconds 180
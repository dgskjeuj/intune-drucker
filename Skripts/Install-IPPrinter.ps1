<#
.SYNOPSIS
   Installation von IP-Druckern
 
.DESCRIPTION
   Dieses Script dient der Installation von IP-Druckern und zugehoeriger Treiber.
   Das Script ist zur Paketierung mittels IntuneWinAppUtil gedacht.
   Innerhalb des Pakets muss ein Unterordner namens "Drivers" existieren, welcher die
   benoetigten Treiber enthaelt (.inf, .cat und .cab).
   Es werden vier Druckerwarteschlangen installiert:
     <PrinterName> - A4 Schwarz-Weiss
     <PrinterName> - A4 Farbe
     <PrinterName> - A3 Schwarz-Weiss
     <PrinterName> - A3 Farbe
   ---
   Installationsbefehl in Intune (Parameter entsprechend befuellen):
   %SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "Skripts\Install-IPPrinter.ps1" -PortIPAddress "" -PrinterName "" -DriverName "" -DriverInfFileName ".inf" [-A4SW] [-A4Farbe] [-A3SW] [-A3Farbe]
   Hinweis: Ohne Queue-Schalter werden alle vier Warteschlangen installiert.
   ---
   Registry-Pfad fuer Detection Rule (Key-Existenz pruefen, je nach installierten Queues anpassen):
   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\<PrinterName> - A3 Farbe

 
.EXAMPLE
   Install-IPPrinter.ps1 -PortIPAddress "192.168.55.52" -PrinterName "Drucker EG" -DriverName "Lexmark Universal v2 PostScript 3 Emulation" -DriverInfFileName "LMUD1n40.inf"
 
.PARAMETER PortIPAddress
   Die IP-Adresse des Druckers.

.PARAMETER PrinterName
   Der Basisname des Druckers. Die vier Warteschlangen erhalten automatisch die Suffixe
   "- A4 Schwarz-Weiss", "- A4 Farbe", "- A3 Schwarz-Weiss" und "- A3 Farbe".

.PARAMETER DriverName
   Der exakte Name des Treibers. Dieser ist aus der .inf-Datei ersichtlich (im Texteditor oeffnen).

.PARAMETER DriverInfFileName
   Der Name der .inf-Datei inklusive Dateiendung, z.B. "LMUD1n40.inf".

.PARAMETER A4SW
   Schalter: Warteschlange "<PrinterName> - A4 Schwarz-Weiss" installieren.

.PARAMETER A4Farbe
   Schalter: Warteschlange "<PrinterName> - A4 Farbe" installieren.

.PARAMETER A3SW
   Schalter: Warteschlange "<PrinterName> - A3 Schwarz-Weiss" installieren.

.PARAMETER A3Farbe
   Schalter: Warteschlange "<PrinterName> - A3 Farbe" installieren.

.NOTES
  Version:        3.0
  Author:         Raphael Baud
  Creation Date:  2023-02-22
  Purpose/Change: Ping-Pruefung (Exit 1618 = Intune-Retry); modulare Queue-Auswahl per Schalter
#>

#################
#---Parameter---#
#################
Param(
    [Parameter(Mandatory=$True)]
    [string]$PortIPAddress,

    [Parameter(Mandatory=$True)]
    [string]$PrinterName,

    [Parameter(Mandatory=$True)]
    [string]$DriverName,

    [Parameter(Mandatory=$True)]
    [string]$DriverInfFileName,

    [switch]$A4SW,
    [switch]$A4Farbe,
    [switch]$A3SW,
    [switch]$A3Farbe
)

#################
#---Execution---#
#################

#Pfad definieren
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

#PortName definieren
$PortName = "IP_$PortIPAddress"

#Erreichbarkeit des Druckers pruefen (Exit 1618 = Intune-Retry)
Write-Host "Pruefe Erreichbarkeit von $PortIPAddress ..."
if (-not (Test-Connection -ComputerName $PortIPAddress -Count 2 -Quiet -ErrorAction SilentlyContinue)) {
    Write-Warning "Drucker unter $PortIPAddress ist nicht erreichbar. Intune wird die Installation erneut versuchen. (Exit 1618)"
    exit 1618
}

#Treiber stagen
$PackageRoot = Split-Path -Parent -Path $PSScriptRoot
$DriverInfPathCandidate1 = Join-Path -Path $PSScriptRoot -ChildPath ("Drivers\" + $DriverInfFileName)
$DriverInfPathCandidate2 = Join-Path -Path $PackageRoot -ChildPath ("Drivers\" + $DriverInfFileName)
$DriverInfPath = @($DriverInfPathCandidate1, $DriverInfPathCandidate2) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $DriverInfPath) {
    Write-Error "Die Treiber-INF-Datei wurde nicht gefunden. Erwartete Pfade: $DriverInfPathCandidate1 oder $DriverInfPathCandidate2"
    exit 1
}

Write-Host "Verwende Treiber-INF: $DriverInfPath"

#Treiber stagen und im Drucksystem registrieren (nur wenn noch nicht vorhanden)
if (-not (Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue)) {
    pnputil /add-driver "$DriverInfPath" /install
    # 0        = Erfolg
    # 183      = ERROR_ALREADY_EXISTS  (Treiber bereits im DriverStore)
    # 259      = ERROR_NO_MORE_ITEMS   (Treiber gestaged, alle Geraete bereits aktuell)
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 183 -and $LASTEXITCODE -ne 259) {
        Write-Error "Fehler beim Hinzufuegen des Treiberpakets. Exit-Code: $LASTEXITCODE"
        exit 1
    }
    Add-PrinterDriver -Name $DriverName
} else {
    Write-Host "Treiber bereits installiert, wird uebersprungen: $DriverName"
}

#Druckerport installieren, wenn noch nicht vorhanden
if(-not (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue)) {

    Add-PrinterPort -Name $PortName -PrinterHostAddress $PortIPAddress

}

#Pruefen ob Treiber erfolgreich installiert wurde
if (-not (Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue)) {
    Write-Warning "Treiber nicht installiert"
    exit 1
}

#Gewuenschte Warteschlangen bestimmen (ohne Schalter = alle vier)
$installAll = -not ($A4SW.IsPresent -or $A4Farbe.IsPresent -or $A3SW.IsPresent -or $A3Farbe.IsPresent)

$printerQueue = @()
if ($installAll -or $A4SW)    { $printerQueue += @{ Name = "$PrinterName - A4 Schwarz-Weiss"; PaperSize = "A4"; Color = $false } }
if ($installAll -or $A4Farbe) { $printerQueue += @{ Name = "$PrinterName - A4 Farbe";          PaperSize = "A4"; Color = $true  } }
if ($installAll -or $A3SW)    { $printerQueue += @{ Name = "$PrinterName - A3 Schwarz-Weiss"; PaperSize = "A3"; Color = $false } }
if ($installAll -or $A3Farbe) { $printerQueue += @{ Name = "$PrinterName - A3 Farbe";          PaperSize = "A3"; Color = $true  } }

#Drucker installieren und Standardeinstellungen konfigurieren
foreach ($queue in $printerQueue) {
    if (-not (Get-Printer -Name $queue.Name -ErrorAction SilentlyContinue)) {
        Add-Printer -Name $queue.Name -PortName $PortName -DriverName $DriverName
    }
    Set-PrintConfiguration -PrinterName $queue.Name -PaperSize $queue.PaperSize -Color $queue.Color
}

#nach der Installation etwas abwarten, um das Detection Script zu verzoegern
Start-Sleep -Seconds 180
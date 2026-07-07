Instalation /deinstalation.

powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "Skripts\Install-IPPrinter.ps1" -PortIPAddress "192.168.55.52" -PrinterName "Barbarossastr" -DriverName "Lexmark Universal v2 PostScript 3 Emulation" -DriverInfFileName "LMUD1n40.inf" -A4SW -A4Farbe -A3SW -A3Farbe

powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "Skripts\Remove-IPPrinter.ps1" -PortIPAddress "192.168.55.52" -PrinterName "Barbarossastr" -A4SW -A4Farbe -A3SW -A3Farbe                                                



Erkennnungs Regeln:
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\Barbarossastr - A3 Farbe
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\Barbarossastr - A3 Schwarz-Weiss
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\Barbarossastr - A4 Farbe
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\Barbarossastr - A4 Schwarz-Weiss

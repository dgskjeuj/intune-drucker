# Drucker-Deployment via Intune (Win32-App)

Dieses Paket installiert Netzwerkdrucker (Lexmark Universal v2 PostScript 3 Emulation) auf Windows-Geräten über Intune als Win32-App. Pro Drucker können bis zu vier Warteschlangen bereitgestellt werden:

| Warteschlange | Papierformat | Farbe |
|---|---|---|
| `<Druckername> - A4 Schwarz-Weiss` | A4 | Schwarzweiß |
| `<Druckername> - A4 Farbe` | A4 | Farbe |
| `<Druckername> - A3 Schwarz-Weiss` | A3 | Schwarzweiß |
| `<Druckername> - A3 Farbe` | A3 | Farbe |

---

## Ordnerstruktur

```
DruckerFGM\
├── Drivers\            ← Lexmark-Treiberdateien (.inf, .cat, ...)
├── Skripts\
│   ├── Install-IPPrinter.ps1
│   └── Remove-IPPrinter.ps1
├── tools\
│   ├── IntuneWinAppUtil.exe
│   └── Package.bat     ← .intunewin-Datei erzeugen
└── Win32-output\
    └── Install-IPPrinter.intunewin   ← fertiges Paket für Intune
```

---

## Schritt 1 – .intunewin-Paket erstellen

`tools\Package.bat` ausführen. Die fertige Datei wird in `Win32-output\` abgelegt.

> **Hinweis:** Das Skript muss als Administrator ausgeführt werden, damit `pnputil` den Treiber in den Windows Driver Store eintragen kann.

---

## Schritt 2 – Win32-App in Intune anlegen

### App-Datei
`Win32-output\Install-IPPrinter.intunewin`

### Pflichtparameter

| Parameter | Bedeutung | Beispiel |
|---|---|---|
| `-PortIPAddress` | IP-Adresse des Druckers | `192.168.55.52` |
| `-PrinterName` | Basisname der Warteschlangen | `Barbarossastr` |
| `-DriverName` | Exakter Treibernahme aus der .inf-Datei | `Lexmark Universal v2 PostScript 3 Emulation` |
| `-DriverInfFileName` | Dateiname der .inf-Datei | `LMUD1n40.inf` |

### Optionale Queue-Schalter

Ohne Schalter werden **alle vier** Warteschlangen installiert. Mit Schaltern werden nur die gewünschten installiert:

| Schalter | Installierte Warteschlange |
|---|---|
| `-A4SW` | `<Druckername> - A4 Schwarz-Weiss` |
| `-A4Farbe` | `<Druckername> - A4 Farbe` |
| `-A3SW` | `<Druckername> - A3 Schwarz-Weiss` |
| `-A3Farbe` | `<Druckername> - A3 Farbe` |

---

## Installationsbefehl (Intune)

```
%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "Skripts\Install-IPPrinter.ps1" -PortIPAddress "192.168.55.52" -PrinterName "Barbarossastr" -DriverName "Lexmark Universal v2 PostScript 3 Emulation" -DriverInfFileName "LMUD1n40.inf" -A4SW -A4Farbe -A3SW -A3Farbe
```

**Nur A4-Queues installieren:**
```
... -A4SW -A4Farbe
```

**Nur eine bestimmte Queue:**
```
... -A3Farbe
```

---

## Deinstallationsbefehl (Intune)

```
%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "Skripts\Remove-IPPrinter.ps1" -PortIPAddress "192.168.55.52" -PrinterName "Barbarossastr" -A4SW -A4Farbe -A3SW -A3Farbe
```

> Der Druckerport (`IP_<IP>`) wird automatisch nur dann entfernt, wenn **keine** Warteschlange mehr diesen Port verwendet.

---

## Detection Rules (Registrierungsschlüssel)

Für jede installierte Warteschlange existiert ein Registry-Schlüssel. Intune prüft auf **Key-Existenz** (kein Wertname, kein Wert nötig):

| Queue | Registry-Pfad |
|---|---|
| A4 Schwarz-Weiss | `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\Barbarossastr - A4 Schwarz-Weiss` |
| A4 Farbe | `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\Barbarossastr - A4 Farbe` |
| A3 Schwarz-Weiss | `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\Barbarossastr - A3 Schwarz-Weiss` |
| A3 Farbe | `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\Barbarossastr - A3 Farbe` |

> **Empfehlung:** Die Detection Rule auf die Warteschlange setzen, die als letzte installiert wird (typischerweise `-A3Farbe`). Wenn nur bestimmte Queues installiert werden, die Detection Rule entsprechend anpassen.

---

## Wiederholungslogik (Retry)

Das Installationsskript pingt die Drucker-IP vor der Installation an. Ist der Drucker **nicht erreichbar** (z. B. Client außerhalb des Netzwerks), gibt das Skript den Exit-Code `1618` zurück. Intune interpretiert diesen Code als „Installation läuft bereits / später erneut versuchen" und wiederholt die Installation automatisch beim nächsten Check-in.

---

## Neuen Drucker hinzufügen

1. Neues Paket `.intunewin` mit `tools\Package.bat` erstellen (Skripte sind druckerunabhängig).
2. Neue Win32-App in Intune anlegen.
3. Installations- und Deinstallationsbefehl mit der neuen IP und dem neuen Druckernamen befüllen.
4. Detection Rule mit dem neuen Druckernamen anpassen.
5. App einer Gruppe zuweisen.

# Resolve Temp Launcher

[简体中文](README.md) · [English](README.en.md)

Ein kleines Hilfsprogramm für Windows, das die temporären Entpackdateien des DaVinci-Resolve-Installationsprogramms auf ein anderes lokales Laufwerk umleitet. Dadurch wird während der Installation weniger Speicherplatz auf dem Systemlaufwerk benötigt.

## Schnellstart

1. Laden Sie das vollständige Windows-Installationspaket von der [offiziellen Blackmagic-Design-Website](https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion) herunter. Entpacken Sie die ursprüngliche ZIP-Datei und lassen Sie EXE, DAT und alle weiteren enthaltenen Dateien im selben Ordner.
2. Laden Sie dieses Projekt als ZIP herunter und entpacken Sie es.
3. Klicken Sie mit der rechten Maustaste auf `Start-ResolveInstaller.cmd` und wählen Sie **Als Administrator ausführen**.
4. Wählen Sie die ursprüngliche Installationsdatei mit der Endung `.exe`. Das Skript bevorzugt D:, sofern dort genügend Platz verfügbar ist. Andernfalls verwendet es das lokale Festplattenlaufwerk außerhalb des Systemlaufwerks mit dem meisten freien Speicherplatz. Der Standardordner heißt `ResolveInstallerTemp`.
5. Führen Sie die Installation im anschließend geöffneten offiziellen Installationsprogramm durch.

Um einen bestimmten beschreibbaren Ordner zu verwenden, führen Sie in einer PowerShell mit Administratorrechten Folgendes aus:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-ResolveInstaller.ps1 -InstallerPath "G:\Downloads\Install Resolve 21.1.1.exe" -TempDirectory "D:\MyTools\ResolveInstallerTemp"
```

Pfade mit Leerzeichen werden unterstützt. Die Beispiele enthalten keine persönlichen Installationspfade.

## Zuerst prüfen, ohne die Installation zu starten

Mit `-CheckOnly` werden die EXE-Signatur, der freie Speicherplatz, die Auflösung des temporären Pfads und der Schreibzugriff geprüft. Das Installationsprogramm wird dabei nicht gestartet. Der gewählte Ordner wird bei Bedarf angelegt; eine kleine Testdatei wird geschrieben und wieder gelöscht. Administratorrechte sind nicht erforderlich, sofern der Ordner beschreibbar ist.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-ResolveInstaller.ps1 -InstallerPath "G:\Downloads\Install Resolve 21.1.1.exe" -TempDirectory "D:\MyTools\ResolveInstallerTemp" -CheckOnly
```

Standardmäßig werden mindestens 15 GB freier Speicherplatz verlangt. Je nach Resolve-Version kann mehr Platz erforderlich sein. Mit `-MinimumFreeSpaceGB 25` lässt sich der Prüfwert erhöhen.

## Funktionsweise und Grenzen

Das Skript setzt `TEMP` und `TMP` ausschließlich im aktuellen PowerShell-Prozess. Das gestartete Installationsprogramm erbt diese Werte. Nach dem Ende oder bei einem Fehler werden die ursprünglichen Werte wiederhergestellt. Dauerhafte Benutzer- oder Systemumgebungsvariablen werden nicht geändert.

Bei der statischen Untersuchung eines Windows-Installationsprogramms für Resolve 21.1.1 wurde ein Aufruf von `GetTempPathW` gefunden. Laut [Microsoft-Dokumentation](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppathw) berücksichtigt diese Funktion TMP und TEMP. Lokale Tests prüfen Pfadauflösung, Schreibzugriff, Vererbung an einen Kindprozess und Wiederherstellung der ursprünglichen Werte. Eine tatsächliche Resolve-Installation wurde **noch nicht vollständig getestet**.

Dieses Hilfsprogramm ändert nicht den Installationsort der Anwendung, ProgramData, Benutzerprojekte, Treiber oder den Windows-Installer-Cache. Eine Installation ohne jegliche Nutzung des Systemlaufwerks wird nicht garantiert. Separat gestartete Systemdienste oder nach einem Neustart fortgesetzte Aufgaben können weiterhin Systemordner für temporäre Dateien verwenden.

Installationsdateien werden nicht verändert, Studio-Lizenzen werden nicht umgangen und vorhandene Daten werden nicht verschoben. Es werden keine Verzeichnisverknüpfungen erstellt und keine Installationsreste automatisch gelöscht. Prüfen Sie den temporären Ordner erst nach Abschluss aller Installationsaufgaben, bevor Sie ihn selbst bereinigen.

## Prüfung des Installationspakets

Vor dem Start verlangt das Skript eine gültige Authenticode-Signatur von Blackmagic Design auf der EXE-Datei. Diese Prüfung bestätigt nicht die Herkunft des gesamten externen DAT-Inhalts und ersetzt keine Prüfung auf Schadsoftware. Auch eine CRC-Prüfung mit 7-Zip erkennt lediglich beschädigte Archivdaten. Verwenden Sie vollständige Installationspakete aus offizieller Quelle.

## Fehlerbehebung

- **Administratorrechte fehlen:** Starten Sie CMD oder PowerShell als Administrator.
- **Schreibzugriff verweigert:** Geben Sie mit `-TempDirectory` einen beschreibbaren Ordner auf einem Laufwerk außerhalb des Systemlaufwerks an.
- **Signatur ungültig:** Brechen Sie ab und laden Sie das Installationsprogramm erneut von der offiziellen Website herunter.
- **Passende DAT-Datei fehlt:** Lassen Sie alle zusammengehörigen Originaldateien im selben Ordner und wählen Sie die richtige EXE.
- **Fehler im offiziellen Installationsprogramm:** Prüfen Sie dessen Protokolle. Dieses Hilfsprogramm behebt keine internen Installationsfehler.

## Tests

Unter Windows PowerShell 5.1 oder neuer beziehungsweise PowerShell 7:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Smoke.Tests.ps1
```

Die Tests starten keine Resolve-Installation. Sie prüfen die Vererbung an Kindprozesse, die Wiederherstellung der Umgebungsvariablen bei Erfolg und Fehlern sowie die Ablehnung relativer Pfade und unsignierter Installationsdateien.

## Mitwirkende und Lizenz

Projektinitiative und Pflege: **Ender-gk**. Unterstützung bei der Entwicklung: **OpenAI Codex**.

Unabhängiges Community-Projekt. Es handelt sich nicht um ein offizielles Produkt von Blackmagic Design oder OpenAI; eine Unterstützung oder Empfehlung durch diese Unternehmen wird nicht behauptet.

MIT-Lizenz; siehe [LICENSE](LICENSE). Resolve-Installationsdateien, kommerzielle Komponenten, Zugangsdaten und persönliche Daten werden nicht mit diesem Projekt verteilt.

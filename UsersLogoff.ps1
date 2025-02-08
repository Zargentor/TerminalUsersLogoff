if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Если нет, перезапускаем скрипт с правами администратора
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "powershell";
    $newProcess.Arguments = "& '" + $myInvocation.MyCommand.Definition + "'";
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);
    exit;
}
# Устанавливаем кодировку вывода в UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Получаем список всех сессий на локальном сервере
$sessions = query session | ForEach-Object {
    $fields = $_ -split '\s+'
    if ($fields[3] -eq "Disc" -and $fields[2] -ne "0") {
        [PSCustomObject]@{
            SessionName = $fields[0]
            UserName    = $fields[1]
            SessionId   = $fields[2]
            State       = $fields[3]
        }
    }
}


# Выполняем выход всех пользователей одновременно, каждый в отдельном процессе
foreach ($session in $sessions) {
    Write-Output "Отключаем: $($session.UserName) с ID: $($session.SessionId)"
    Start-Process -FilePath "logoff" -ArgumentList $session.SessionId -NoNewWindow
}

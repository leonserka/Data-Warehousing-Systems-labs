$ErrorActionPreference='Stop'
$runner=Join-Path $PSScriptRoot 'Run-Lab01.ps1'
$powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$user=[Security.Principal.WindowsIdentity]::GetCurrent().Name
$jobs=@(@{Name='Lab01 ETL JSON';Time='18:10';File='18_automation_json.sql'},@{Name='Lab01 ETL CSV';Time='18:15';File='19_automation_csv.sql'})
foreach($j in $jobs){if(Get-ScheduledTask -TaskName $j.Name -ErrorAction SilentlyContinue){throw "Zadatak vec postoji: $($j.Name)"}}
foreach($j in $jobs){
    $action=New-ScheduledTaskAction -Execute $powershell -Argument ('-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$runner+'" -Job '+$j.File) -WorkingDirectory $PSScriptRoot
    $trigger=New-ScheduledTaskTrigger -Daily -At $j.Time
    $principal=New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
    $settings=New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
    Register-ScheduledTask -TaskName $j.Name -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Lab01 iz files_01; detaljni logovi u istoj mapi; korisnik mora biti prijavljen.' | Out-Null
}
Get-ScheduledTask -TaskName 'Lab01 ETL JSON','Lab01 ETL CSV' | Select-Object TaskName,State

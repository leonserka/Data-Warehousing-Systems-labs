param([Parameter(Mandatory=$true)][ValidateSet('18_automation_json.sql','19_automation_csv.sql')][string]$Job)
$ErrorActionPreference='Stop'
$psql='C:\Program Files\PostgreSQL\17\bin\psql.exe'
$oldPassword=$env:PGPASSWORD
$oldEncoding=$env:PGCLIENTENCODING
$env:PGCLIENTENCODING='UTF8'
$OutputEncoding=[Text.UTF8Encoding]::new($false)
try {
    $entry=Get-Content (Join-Path $env:APPDATA 'postgresql\pgpass.conf') | Where-Object {$_ -match '^localhost:5432:lab1:postgres:'} | Select-Object -First 1
    if(-not $entry){throw 'Nema spremljene prijave za lokalni PostgreSQL.'}
    $env:PGPASSWORD=[regex]::Replace(($entry -split ':',5)[4],'\\([:\\])','$1')
    & $psql -X -w -h localhost -p 5432 -U postgres -d lab01 -v ON_ERROR_STOP=1 -P pager=off -f (Join-Path $PSScriptRoot $Job)
    if($LASTEXITCODE -ne 0){throw 'SQL obrada nije uspjela.'}
    $failed=& $psql -X -w -h localhost -U postgres -d lab01 -Atc "SELECT count(*) FROM dbo.ImportLog WHERE Status IN ('FAILED','RUNNING')"
    if($LASTEXITCODE -ne 0 -or $failed -ne '0'){throw 'ETL log sadrzi neuspjesnu ili nedovrsenu obradu.'}
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
} finally {
    $env:PGPASSWORD=$oldPassword
    $env:PGCLIENTENCODING=$oldEncoding
}

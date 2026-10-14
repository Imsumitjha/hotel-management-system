param(
    [string]$TomcatHome = 'C:\Program Files\Apache Software Foundation\Tomcat 9.0',
    [string]$DatabaseUrl = 'jdbc:mysql://localhost:3306/grand_horizon?useSSL=false&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8'
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$tomcatBase = Join-Path $projectRoot '.local-tomcat'
$warSource = Join-Path $projectRoot 'target\hotel.war'

if (-not (Test-Path (Join-Path $TomcatHome 'bin\catalina.bat'))) {
    throw "Tomcat 9 was not found at '$TomcatHome'. Pass its installation folder with -TomcatHome."
}

if ([string]::IsNullOrWhiteSpace($env:HOTEL_DB_USER)) {
    $env:HOTEL_DB_USER = Read-Host 'MySQL username'
}
if ([string]::IsNullOrWhiteSpace($env:HOTEL_DB_PASSWORD)) {
    $securePassword = Read-Host 'MySQL password' -AsSecureString
    $env:HOTEL_DB_PASSWORD = [System.Net.NetworkCredential]::new('', $securePassword).Password
}
$env:HOTEL_DB_URL = $DatabaseUrl

Write-Host 'Building the hotel web application...'
Push-Location $projectRoot
try {
    & mvn -DskipTests package
    if ($LASTEXITCODE -ne 0) { throw 'Maven packaging failed; see the build output above.' }
} finally {
    Pop-Location
}

if (-not (Test-Path (Join-Path $tomcatBase 'conf\server.xml'))) {
    New-Item -ItemType Directory -Force -Path $tomcatBase | Out-Null
    Copy-Item -Path (Join-Path $TomcatHome 'conf') -Destination $tomcatBase -Recurse
}
foreach ($folder in @('webapps', 'logs', 'temp', 'work')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $tomcatBase $folder) | Out-Null
}
Copy-Item -LiteralPath $warSource -Destination (Join-Path $tomcatBase 'webapps\hotel.war') -Force

$env:CATALINA_HOME = $TomcatHome
$env:CATALINA_BASE = $tomcatBase
$env:JAVA_HOME = if ($env:JAVA_HOME) { $env:JAVA_HOME } else { Split-Path (Split-Path (Get-Command java.exe).Source) }

$tomcatCommand = 'call "{0}" run' -f (Join-Path $TomcatHome 'bin\catalina.bat')
Start-Process -FilePath $env:ComSpec -ArgumentList @('/k', $tomcatCommand) -WorkingDirectory $TomcatHome -WindowStyle Normal | Out-Null
Start-Sleep -Seconds 5
Start-Process 'http://localhost:8080/hotel/' | Out-Null

Write-Host 'Tomcat is starting in its own console window.'
Write-Host 'Open http://localhost:8080/hotel/ if the browser did not open.'
Write-Host 'Stop the local server with Ctrl+C in the Tomcat console.'

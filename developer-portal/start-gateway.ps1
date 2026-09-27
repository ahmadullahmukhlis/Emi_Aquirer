$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
& "$projectRoot\authService\mvnw.cmd" -q -f "$projectRoot\gateway-service\pom.xml" clean package
exit $LASTEXITCODE

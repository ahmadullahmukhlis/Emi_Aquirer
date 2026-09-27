$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$data = Join-Path $root '.local-data'
$logs = Join-Path $root '.local-logs'
New-Item -ItemType Directory -Force -Path $data, $logs | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $root 'authService\.local-data'), (Join-Path $root 'gateway-service\.local-data') | Out-Null

function Start-LocalProcess([string]$name, [string]$file, [string[]]$arguments, [string]$workingDirectory) {
  $out = Join-Path $logs "$name.out.log"
  $err = Join-Path $logs "$name.err.log"
  $quotedArgs = ($arguments | ForEach-Object { if ($_ -match '[\\s"]') { '"' + ($_ -replace '"','\\"') + '"' } else { $_ } }) -join ' '
  $command = "call `"$file`" $quotedArgs 1> `"$out`" 2> `"$err`""
  Start-Process -FilePath 'cmd.exe' -ArgumentList @('/d','/s','/c',$command) -WorkingDirectory $workingDirectory -WindowStyle Hidden
  Write-Host "Started $name"
}

Start-LocalProcess 'auth-service' (Join-Path $root 'authService\mvnw.cmd') @('-q','-Dspring-boot.run.profiles=windows','spring-boot:run') (Join-Path $root 'authService')
Start-LocalProcess 'gateway-service' (Join-Path $root 'authService\mvnw.cmd') @('-q','-f',(Join-Path $root 'gateway-service\pom.xml'),'-Dspring-boot.run.profiles=windows','-Dspring-boot.run.main-class=com.example.gateway.GatewayApplicationKt','spring-boot:run') $root
Start-LocalProcess 'developer-portal' 'python' @('-m','http.server','8082','--directory',(Join-Path $root 'developer-portal')) $root
$npm = (Get-Command npm.cmd -ErrorAction Stop).Source
Start-LocalProcess 'admin-portal' $npm @('start','--','--host','127.0.0.1','--port','8083') (Join-Path $root 'AUTH-FRONTEND')

Write-Host ''
Write-Host 'Local Windows services:' -ForegroundColor Cyan
Write-Host '  Auth API:       http://localhost:8080/api/auth-service'
Write-Host '  Gateway API:    http://localhost:8081/api/gateway'
Write-Host '  Developer UI:   http://localhost:8082'
Write-Host '  Admin UI:       http://localhost:8083'
Write-Host '  Admin login:    admin / Admin@123'
Write-Host "Logs: $logs"

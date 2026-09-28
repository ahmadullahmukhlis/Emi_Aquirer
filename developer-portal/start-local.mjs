import { randomBytes } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync, openSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn, spawnSync } from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
if(existsSync(resolve(root,'.env')))process.loadEnvFile(resolve(root,'.env'));
mkdirSync(resolve(root,'.local-data'),{recursive:true});mkdirSync(resolve(root,'.local-logs'),{recursive:true});
const keyFile=resolve(root,'.local-data','portal-service-key');
if(!existsSync(keyFile))writeFileSync(keyFile,randomBytes(32).toString('hex'),{mode:0o600,flag:'wx'});
const env={...process.env,PORTAL_GATEWAY_KEY:readFileSync(keyFile,'utf8').trim()};
// The key is runtime data: never print it or commit it.
function start(name,command,args,cwd=root){const output=openSync(resolve(root,'.local-logs',name+'.out.log'),'a');const error=openSync(resolve(root,'.local-logs',name+'.err.log'),'a');const child=spawn(command,args,{cwd,env,detached:true,windowsHide:true,stdio:['ignore',output,error]});child.unref();writeFileSync(resolve(root,'.local-data',name+'.pid'),String(child.pid));console.log(`Started ${name} (PID ${child.pid})`);}
try{const response=await fetch('http://localhost:8082/api/health',{signal:AbortSignal.timeout(1000)});if(response.ok)console.log('Portal is already running.');else throw Error();}catch{start('developer-portal',process.execPath,[resolve(root,'developer-portal/server.mjs')]);}
try{await fetch('http://localhost:8081/api/gateway/internal/portal/purchases/health-check',{headers:{'X-Portal-Service-Key':env.PORTAL_GATEWAY_KEY},signal:AbortSignal.timeout(1000)});console.log('Gateway is already running.');}catch{
 console.log('Building Gateway...');
 const build=process.platform==='win32'
  ? spawnSync('powershell.exe',['-NoProfile','-ExecutionPolicy','Bypass','-File',resolve(root,'developer-portal/start-gateway.ps1')],{cwd:root,env,windowsHide:true,stdio:'inherit'})
  : spawnSync('mvn',['-q','clean','package','-DskipTests'],{cwd:resolve(root,'gateway-service'),env,stdio:'inherit'});
 if(build.status!==0)throw Error('Gateway build failed; see the Maven error above.');
 start('gateway-service','java',['-jar',resolve(root,'gateway-service/target/gateway-service-0.0.1-SNAPSHOT.jar'),'--spring.profiles.active=windows'],root);
}
console.log('Developer Portal: http://localhost:8082');

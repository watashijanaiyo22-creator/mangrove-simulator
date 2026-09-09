import http from 'node:http';
import {readFile,stat} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
const root=resolve(import.meta.dirname,'..');
const types={'.html':'text/html','.js':'text/javascript','.mjs':'text/javascript','.css':'text/css','.wgsl':'text/plain','.json':'application/json','.bin':'application/octet-stream','.png':'image/png','.jpg':'image/jpeg','.md':'text/plain'};
http.createServer(async(req,res)=>{try{const name=decodeURIComponent(new URL(req.url,'http://localhost').pathname);const path=resolve(root,'.'+(name==='/'?'/index.html':name));if(!path.startsWith(root+sep)||name.endsWith('.zip')){res.writeHead(403);res.end();return;}const body=await readFile(path);res.writeHead(200,{'Content-Type':types[extname(path)]||'application/octet-stream','Cache-Control':'no-cache'});res.end(body);}catch{res.writeHead(404);res.end('Not found');}}).listen(Number(process.env.PORT||4173),'127.0.0.1',()=>console.log('Mangrove Coastal Lab: http://127.0.0.1:'+(process.env.PORT||4173)));

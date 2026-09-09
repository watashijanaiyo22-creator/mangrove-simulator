import {createRequire} from 'node:module';
import {writeFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const require=createRequire('/Users/taku/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json');
const {chromium}=require('playwright');
const browser=await chromium.launch({headless:true,args:['--enable-unsafe-webgpu','--use-angle=metal']});
const page=await browser.newPage();
await page.goto('http://127.0.0.1:4173');
await page.waitForFunction(()=>typeof window.lab?.pause==='function');
const result=await page.evaluate(async()=>{
 const {sim,device}=window.lab;window.lab.pause();window.lab.reset();
 async function field(){const target=sim.visual.fields[0][sim.phase];const b=device.createBuffer({size:target.size,usage:GPUBufferUsage.COPY_DST|GPUBufferUsage.MAP_READ});const e=device.createCommandEncoder();e.copyBufferToBuffer(target,0,b,0,b.size);device.queue.submit([e.finish()]);await b.mapAsync(GPUMapMode.READ);const data=new Float32Array(b.getMappedRange().slice(0));b.unmap();b.destroy();return data;}
 sim.step(100,{wave:0,boundary:false,sediment:false});const f=await field();let stillFoam=0,stillRms=0;for(let i=0;i<f.length;i+=4){stillFoam=Math.max(stillFoam,f[i]);stillRms=Math.max(stillRms,f[i+2]);}
 window.lab.reset();const reset=await field();let resetMax=0;for(const v of reset)resetMax=Math.max(resetMax,Math.abs(v));
 await window.lab.advance(200);const observed=await sim.read(0);const visual=sim.visual;sim.visual=null;window.lab.reset();await window.lab.advance(200);const unobserved=await sim.read(0);sim.visual=visual;let feedbackError=0;for(let i=0;i<observed.length;i++)feedbackError=Math.max(feedbackError,Math.abs(observed[i]-unobserved[i]));
 return {stillFoam,stillRms,resetMax,feedbackError};
});
assert.ok(result.stillFoam<1e-8&&result.stillRms<1e-8);assert.equal(result.resetMax,0);assert.equal(result.feedbackError,0);
await writeFile('evidence/surface-qa.json',JSON.stringify(result,null,2));console.log(result);await browser.close();

import {createRequire} from 'node:module';
import {writeFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const require=createRequire('/Users/taku/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json');
const {chromium}=require('playwright');
const browser=await chromium.launch({headless:true,args:['--enable-unsafe-webgpu','--use-angle=metal']});
const page=await browser.newPage();
await page.goto('http://127.0.0.1:4173');
await page.waitForFunction(()=>typeof window.lab?.pause==='function');
const errors=[];page.on('pageerror',e=>errors.push(e.message));
const result=await page.evaluate(async()=>{
 window.lab.pause();const areas=[];
 for(const d of [1,1.5,2]){await window.lab.changeForest('staggered',d);areas.push(window.lab.sim.roots.reduce((a,b)=>a+b,0));}
 return {areas,ratios:areas.map(a=>a/areas[0])};
});
assert.ok(Math.abs(result.ratios[1]-1.5)<1e-5&&Math.abs(result.ratios[2]-2)<1e-5);
await page.locator('[data-mode="4"]').click();await page.waitForTimeout(300);
await page.screenshot({path:'evidence/root-diameter-overlay.png'});
assert.deepEqual(errors,[]);
await writeFile('evidence/root-diameter-qa.json',JSON.stringify({...result,errors},null,2));console.log(result);await browser.close();

import {createRequire} from 'node:module';
import {writeFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const require=createRequire('/Users/taku/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json');
const {chromium}=require('playwright');
const browser=await chromium.launch({headless:true,args:['--enable-unsafe-webgpu','--use-angle=metal']});
const page=await browser.newPage();
await page.goto('http://127.0.0.1:4173');
await page.waitForFunction(()=>typeof window.lab?.pause==='function');
await page.evaluate(()=>window.lab.pause());
const records=[];
for(let block=0;block<12;block++){
 await page.evaluate(()=>window.lab.advance(5000));
 if(block%3===2){await page.waitForTimeout(1900);records.push(await page.evaluate(()=>window.lab.lastDiagnostics));}
}
await page.locator('#shoreView').click();
await page.locator('#showNumbers').uncheck();
await page.waitForTimeout(300);
await page.screenshot({path:'evidence/long-natural.png'});
assert.ok(records.every(r=>r.latest.every(x=>x.budget.finite&&x.budget.correction===0)));
await writeFile('evidence/long-observation.json',JSON.stringify(records,null,2));
console.log(JSON.stringify(records.map(r=>({time:r.time,erosion:r.latest.map(x=>x.eroded),retreat:r.latest.map(x=>x.retreat),residuals:r.residuals}))));
await browser.close();

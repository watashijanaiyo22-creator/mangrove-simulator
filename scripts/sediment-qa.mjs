import {createRequire} from 'node:module';
import {writeFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const require=createRequire('/Users/taku/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json');
const {chromium}=require('playwright');
const browser=await chromium.launch({headless:true,args:['--enable-unsafe-webgpu','--use-angle=metal']});
const page=await browser.newPage({viewport:{width:1600,height:1000},deviceScaleFactor:1});
const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
await page.goto(process.env.LAB_URL||'http://127.0.0.1:4173');await page.waitForFunction(()=>typeof window.lab?.pause==='function');await page.evaluate(()=>{lab.pause();lab.reset();});
const records=[];
for(let block=0;block<80;block++){
 const record=await page.evaluate(async()=>{const states=await lab.advance(125);const {totals}=await import('./src/physics.js');const initial=totals(lab.sim.initial);return {time:lab.sim.time,metrics:states.map(s=>{const {vel,...m}=lab.metrics(s);const b=totals(s);return {...m,budget:b,residual:{water:b.water-initial.water-b.boundaryWater,sediment:b.sediment-initial.sediment-b.boundarySediment}};})};});records.push(record);if(block%4===3)console.log(JSON.stringify({time:record.time,velocity:record.metrics.map(m=>m.forest.downstream.speed),erosion:record.metrics.map(m=>m.forest.inside.erosion)}));
 if(block===39||block===79){await page.evaluate(()=>{lab.renderer.crown=false;lab.renderer.angle=-2.8;lab.renderer.elevation=.65;lab.renderer.distance=45;lab.renderer.target=[45,0,24];});await page.waitForTimeout(250);await page.screenshot({path:`evidence/sediment-natural-${block+1}.png`});}
}
const late=records.filter(r=>r.time>90.001);const velocity=[0,1].map(a=>late.reduce((sum,r)=>sum+r.metrics[a].forest.downstream.speed,0)/late.length);const reduction=100*(1-velocity[0]/velocity[1]);
await page.evaluate(()=>{lab.renderer.distance=10;lab.renderer.target=[48,0,22];lab.renderer.elevation=.42;});await page.waitForTimeout(200);await page.screenshot({path:'evidence/sediment-roots.png'});
await writeFile('evidence/sediment-qa.json',JSON.stringify({velocity,reduction,records,errors},null,2));console.log('RESULT',JSON.stringify({velocity,reduction,errors}));assert.deepEqual(errors,[]);assert.ok(reduction>=50);assert.ok(records.every(r=>r.metrics.every(m=>Math.abs(m.residual.water)<.01&&Math.abs(m.residual.sediment)<.05&&m.budget.sedimentCorrection===0)));assert.ok(records.every(r=>r.metrics.every(m=>m.budget.finite&&m.budget.correction===0)));await browser.close();

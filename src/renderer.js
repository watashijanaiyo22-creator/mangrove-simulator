import {bedAt} from './scenario.js';
import {cameraMatrix,lightMatrix} from './math.js';

const meshBuffers=[
 {arrayStride:48,attributes:[{shaderLocation:0,offset:0,format:'float32x3'},{shaderLocation:1,offset:12,format:'float32x3'},{shaderLocation:2,offset:24,format:'float32x2'},{shaderLocation:3,offset:32,format:'float32x4'}]},
 {arrayStride:32,stepMode:'instance',attributes:[{shaderLocation:4,offset:0,format:'float32x4'},{shaderLocation:5,offset:16,format:'float32x4'}]}
];
export class Renderer {
 static async create(device,canvas,sim,forest){
  const r=new Renderer();Object.assign(r,{device,canvas,sim,forest,textures:[],buffers:[],crown:false});r.home();
  r.context=canvas.getContext('webgpu');r.format=navigator.gpu.getPreferredCanvasFormat();r.context.configure({device,format:r.format,alphaMode:'opaque',usage:GPUTextureUsage.RENDER_ATTACHMENT|GPUTextureUsage.COPY_DST});
  r.uniforms=[0,1].map(()=>r.makeBuffer(256,GPUBufferUsage.UNIFORM|GPUBufferUsage.COPY_DST));
  const shader=await(await fetch('./shaders/render.wgsl')).text(),module=device.createShaderModule({code:shader});
  const errors=(await module.getCompilationInfo()).messages.filter(m=>m.type==='error');if(errors.length)throw Error(errors.map(m=>`${m.lineNum}: ${m.message}`).join('\n'));
  const vf=GPUShaderStage.VERTEX|GPUShaderStage.FRAGMENT,f=GPUShaderStage.FRAGMENT;
  r.layout=device.createBindGroupLayout({entries:[{binding:0,visibility:vf,buffer:{type:'uniform'}},{binding:1,visibility:vf,buffer:{type:'read-only-storage'}},{binding:2,visibility:vf,buffer:{type:'read-only-storage'}},{binding:3,visibility:vf,buffer:{type:'read-only-storage'}}]});
  const matLayout=device.createBindGroupLayout({entries:[0,1,2].map(binding=>({binding,visibility:f,texture:{}})).concat({binding:3,visibility:f,sampler:{type:'filtering'}})});
  const groundLayout=device.createBindGroupLayout({entries:[0,1,2,3,4,5].map(binding=>({binding,visibility:f,texture:{}})).concat([{binding:6,visibility:f,sampler:{}},{binding:7,visibility:f,texture:{sampleType:'depth'}},{binding:8,visibility:f,sampler:{type:'comparison'}}])});
  r.opticalLayout=device.createBindGroupLayout({entries:[{binding:0,visibility:f,texture:{}},{binding:1,visibility:f,texture:{sampleType:'depth'}},{binding:2,visibility:f,texture:{}},{binding:3,visibility:f,sampler:{}}]});
  const layout=device.createPipelineLayout({bindGroupLayouts:[r.layout,matLayout,groundLayout]});const waterLayout=device.createPipelineLayout({bindGroupLayouts:[r.layout,matLayout,groundLayout,r.opticalLayout]});
  const pipeline=(vertex,fragment,{buffers=[],water=false}={})=>device.createRenderPipelineAsync({layout:water?waterLayout:layout,vertex:{module,entryPoint:vertex,buffers},fragment:{module,entryPoint:fragment,targets:[{format:r.format,...(water?{blend:{color:{srcFactor:'src-alpha',dstFactor:'one-minus-src-alpha',operation:'add'},alpha:{srcFactor:'one',dstFactor:'one-minus-src-alpha',operation:'add'}}}:{})}]},primitive:{topology:'triangle-list',cullMode:'none'},depthStencil:{format:'depth24plus',depthWriteEnabled:!water,depthCompare:'less-equal'}});
  [r.bed,r.water,r.mesh,r.skyPipeline,r.reflectionSky,r.bedEdge,r.waterEdge]=await Promise.all([pipeline('bedVertex','bedFragment'),pipeline('waterVertex','waterFragment',{water:true}),pipeline('meshVertex','meshFragment',{buffers:meshBuffers}),pipeline('skyVertex','skyFragment'),pipeline('skyVertex','reflectionSky'),pipeline('bedEdgeVertex','edgeFragment'),pipeline('waterEdgeVertex','edgeFragment')]);
  r.shadowPipeline=await device.createRenderPipelineAsync({layout:device.createPipelineLayout({bindGroupLayouts:[r.layout,matLayout]}),vertex:{module,entryPoint:'shadowVertex',buffers:meshBuffers},fragment:{module,entryPoint:'shadowFragment',targets:[]},primitive:{topology:'triangle-list',cullMode:'none'},depthStencil:{format:'depth24plus',depthWriteEnabled:true,depthCompare:'less',depthBias:2,depthBiasSlopeScale:2}});
  r.groups=r.uniforms.map(buffer=>sim.states.map((pair,a)=>pair.map((state,phase)=>device.createBindGroup({layout:r.layout,entries:[{binding:0,resource:{buffer}},{binding:1,resource:{buffer:state}},{binding:2,resource:{buffer:sim.rootBuffer}},{binding:3,resource:{buffer:sim.visual.fields[a][phase]}}]}))));
  r.sampler=device.createSampler({addressModeU:'repeat',addressModeV:'repeat',magFilter:'linear',minFilter:'linear',mipmapFilter:'linear',maxAnisotropy:8});r.screenSampler=device.createSampler({magFilter:'linear',minFilter:'linear'});
  r.shadow=device.createTexture({size:[2048,2048],format:'depth24plus',usage:GPUTextureUsage.RENDER_ATTACHMENT|GPUTextureUsage.TEXTURE_BINDING});
  const maps=await Promise.all(['mud-color','mud-normal','mud-arm','sand-color','sand-normal','sand-arm'].map(name=>r.loadTexture(`./public/materials/${name}.jpg`,name.endsWith('color'))));
  r.groundGroup=device.createBindGroup({layout:groundLayout,entries:maps.map((tex,binding)=>({binding,resource:tex.createView()})).concat([{binding:6,resource:r.sampler},{binding:7,resource:r.shadow.createView()},{binding:8,resource:device.createSampler({compare:'less-equal',magFilter:'linear',minFilter:'linear'})}])});
  const metadata=await(await fetch('./public/tree/model.json')).json();r.parts=[];
  const neutral=r.solidTexture([255,170,0,255]);
  for(const part of metadata.parts){
   const data=await(await fetch(`./public/tree/${part.name}.bin`)).arrayBuffer();const buffer=r.makeBuffer(data.byteLength,GPUBufferUsage.VERTEX|GPUBufferUsage.COPY_DST,data);
   const textures=await Promise.all([r.loadTexture(`./public/tree/${part.color}`,true),r.loadTexture(`./public/tree/${part.normal}`),part.arm?r.loadTexture(`./public/tree/${part.arm}`):neutral]);
   const group=device.createBindGroup({layout:matLayout,entries:textures.map((tex,binding)=>({binding,resource:tex.createView()})).concat({binding:3,resource:r.sampler})});r.parts.push({...part,buffer,group});
  }
  const instances=new Float32Array(forest.trees.flatMap(t=>[t.x,t.y,t.z,t.scale,t.angle,forest.diameter??1,0,0]));r.instances=r.makeBuffer(256*32,GPUBufferUsage.VERTEX|GPUBufferUsage.COPY_DST,instances);
  r.controls();r.resize();return r;
 }
 makeBuffer(size,usage,data){const b=this.device.createBuffer({size,usage});this.buffers.push(b);if(data)this.device.queue.writeBuffer(b,0,data);return b;}
 solidTexture(rgba){const t=this.device.createTexture({size:[1,1],format:'rgba8unorm',usage:GPUTextureUsage.COPY_DST|GPUTextureUsage.TEXTURE_BINDING});this.device.queue.writeTexture({texture:t},new Uint8Array(rgba),{bytesPerRow:4},[1,1]);this.textures.push(t);return t;}
 async loadTexture(url,srgb=false){
  const response=await fetch(url);if(!response.ok)throw Error(`Material unavailable: ${url}`);const blob=await response.blob();let bitmap=await createImageBitmap(blob,{colorSpaceConversion:'none'});const w=bitmap.width,h=bitmap.height;
  const levels=1+Math.floor(Math.log2(Math.max(w,h))),t=this.device.createTexture({size:[w,h],mipLevelCount:levels,format:srgb?'rgba8unorm-srgb':'rgba8unorm',usage:GPUTextureUsage.COPY_DST|GPUTextureUsage.TEXTURE_BINDING|GPUTextureUsage.RENDER_ATTACHMENT});
  for(let level=0;level<levels;level++){const mw=Math.max(1,w>>level),mh=Math.max(1,h>>level);let mip=level?await createImageBitmap(bitmap,{resizeWidth:mw,resizeHeight:mh,resizeQuality:'high',colorSpaceConversion:'none'}):bitmap;this.device.queue.copyExternalImageToTexture({source:mip},{texture:t,mipLevel:level},[mw,mh]);if(level)mip.close();}bitmap.close();this.textures.push(t);return t;
 }
 resize(){
  const rect=this.canvas.getBoundingClientRect(),ratio=Math.min(devicePixelRatio,1.5),w=Math.max(1,Math.round(rect.width*ratio)),h=Math.max(1,Math.round(rect.height*ratio));if(this.canvas.width===w&&this.canvas.height===h&&this.depth)return;
  this.canvas.width=w;this.canvas.height=h;for(const key of ['depth','scene','sceneDepth','reflection','reflectionDepth'])this[key]?.destroy();const d=this.device;
  const target=(width,height,format)=>d.createTexture({size:[width,height],format,usage:GPUTextureUsage.RENDER_ATTACHMENT|GPUTextureUsage.TEXTURE_BINDING|GPUTextureUsage.COPY_SRC|GPUTextureUsage.COPY_DST});
  this.depth=target(w,h,'depth24plus');this.scene=target(w,h,this.format);this.sceneDepth=target(w,h,'depth24plus');this.reflection=target(Math.ceil(w/2),Math.ceil(h/2),this.format);this.reflectionDepth=target(Math.ceil(w/2),Math.ceil(h/2),'depth24plus');
  if(this.tracerGroups)this.tracerBindings=this.tracerGroups();
  if(this.sedimentGroups)this.sedimentBindings=this.sedimentGroups();
  this.opticalGroup=d.createBindGroup({layout:this.opticalLayout,entries:[{binding:0,resource:this.scene.createView()},{binding:1,resource:this.sceneDepth.createView()},{binding:2,resource:this.reflection.createView()},{binding:3,resource:this.screenSampler}]});
 }
 controls(){
  let last=null;this.canvas.addEventListener('pointerdown',e=>{last=[e.clientX,e.clientY];this.canvas.setPointerCapture(e.pointerId);});
  this.canvas.addEventListener('pointermove',e=>{if(!last)return;const dx=e.clientX-last[0],dy=e.clientY-last[1];if(e.shiftKey||e.buttons===2){this.pan(dx,dy);}else{this.angle+=dx*.005;this.elevation=Math.max(.12,Math.min(1.4,this.elevation+dy*.004));}last=[e.clientX,e.clientY];});
  const finish=()=>last=null;this.canvas.addEventListener('pointerup',finish);this.canvas.addEventListener('pointercancel',finish);this.canvas.addEventListener('lostpointercapture',finish);this.canvas.addEventListener('contextmenu',e=>e.preventDefault());
  this.canvas.addEventListener('wheel',e=>{e.preventDefault();this.distance=Math.max(1.2,Math.min(190,this.distance*Math.exp(e.deltaY*.001)));},{passive:false});
  this.canvas.addEventListener('keydown',e=>{const keys=['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','+','=','-'];if(!keys.includes(e.key))return;e.preventDefault();if(e.shiftKey){this.pan(e.key==='ArrowLeft'?-20:e.key==='ArrowRight'?20:0,e.key==='ArrowUp'?-20:e.key==='ArrowDown'?20:0);return;}if(e.key==='ArrowLeft')this.angle-=.1;if(e.key==='ArrowRight')this.angle+=.1;if(e.key==='ArrowUp')this.elevation=Math.min(1.4,this.elevation+.07);if(e.key==='ArrowDown')this.elevation=Math.max(.12,this.elevation-.07);if(e.key==='+'||e.key==='=')this.distance=Math.max(1.2,this.distance*.9);if(e.key==='-')this.distance=Math.min(190,this.distance*1.1);});
 }
 pan(dx,dy){const scale=2*this.distance*Math.tan(.56/2)/Math.max(this.canvas.clientHeight,1);const right=[Math.sin(this.angle),0,-Math.cos(this.angle)];const up=[-Math.cos(this.angle)*Math.sin(this.elevation),Math.cos(this.elevation),-Math.sin(this.angle)*Math.sin(this.elevation)];for(let i=0;i<3;i++)this.target[i]+=(-right[i]*dx+up[i]*dy)*scale;}
 setForest(forest){this.forest=forest;this.device.queue.writeBuffer(this.instances,0,new Float32Array(forest.trees.flatMap(t=>[t.x,t.y,t.z,t.scale,t.angle,forest.diameter??1,0,0])));}
 home(){this.angle=-2.8;this.elevation=.65;this.distance=45;this.target=[45,0,24];}
 basinView(){this.angle=-2.45;this.elevation=.55;this.distance=125;this.target=[37,0,24];}
 shorelineView(){let lo=40,hi=70;for(let i=0;i<30;i++){const x=(lo+hi)/2;if(bedAt(x,22)<0)lo=x;else hi=x;}this.target=[(lo+hi)/2,0,22];this.distance=3;this.angle=-3.14;this.elevation=.7;this.crown=false;}
 rootsView(){this.angle=-2.75;this.elevation=.24;this.distance=24;this.target=[48,.75,22];this.crown=false;}
 drawMeshes(pass,caseID,shadow=false){if(caseID!==0)return;pass.setPipeline(shadow?this.shadowPipeline:this.mesh);pass.setVertexBuffer(1,this.instances);for(const part of this.parts){pass.setVertexBuffer(0,part.buffer);pass.setBindGroup(1,part.group);pass.draw(part.vertices,this.forest.trees.length);}}
 draw(caseID,mode=0,shore=true){
  this.resize();const d=this.device,c=this.sim.c;const eye=[this.target[0]+this.distance*Math.cos(this.angle)*Math.cos(this.elevation),this.target[1]+this.distance*Math.sin(this.elevation),this.target[2]+this.distance*Math.sin(this.angle)*Math.cos(this.elevation)];
  const waterLevel=this.sim.initial[0]+this.sim.initial[4],refEye=[eye[0],2*waterLevel-eye[1],eye[2]],refTarget=[this.target[0],2*waterLevel-this.target[1],this.target[2]];
  const aspect=this.canvas.width/this.canvas.height,mainVP=cameraMatrix(eye,this.target,aspect),refVP=cameraMatrix(refEye,refTarget,aspect),light=lightMatrix();
  for(let i=0;i<2;i++){const values=new Float32Array(64);values.set(i?refVP:mainVP,0);values.set(light,16);values.set(refVP,32);values.set([...(i?refEye:eye),i?-1:1,c.nx,c.ny,c.dx,this.sim.time,mode,shore?1:0,caseID===0?1:0,this.crown?0:1,this.canvas.width,this.canvas.height,waterLevel,this.terrainMultiplier??50],48);d.queue.writeBuffer(this.uniforms[i],0,values);}
  const enc=d.createCommandEncoder();
  const shadow=enc.beginRenderPass({colorAttachments:[],depthStencilAttachment:{view:this.shadow.createView(),depthClearValue:1,depthLoadOp:'clear',depthStoreOp:'store'}});shadow.setBindGroup(0,this.groups[0][caseID][this.sim.phase]);this.drawMeshes(shadow,caseID,true);shadow.end();
  const count=(c.nx-1)*(c.ny-1)*6;
  const drawScene=(color,depth,index,reflection)=>{const pass=enc.beginRenderPass({colorAttachments:[{view:color.createView(),clearValue:{r:.27,g:.36,b:.42,a:1},loadOp:'clear',storeOp:'store'}],depthStencilAttachment:{view:depth.createView(),depthClearValue:1,depthLoadOp:'clear',depthStoreOp:'store'}});pass.setBindGroup(0,this.groups[index][caseID][this.sim.phase]);pass.setBindGroup(1,this.parts[0].group);pass.setBindGroup(2,this.groundGroup);pass.setPipeline(reflection?this.reflectionSky:this.skyPipeline);pass.draw(3);pass.setPipeline(this.bed);pass.draw(count);if(!reflection){pass.setPipeline(this.bedEdge);pass.draw((2*(c.nx-1)+2*(c.ny-1))*6);pass.setPipeline(this.waterEdge);pass.draw((2*(c.nx-1)+2*(c.ny-1))*6);}this.drawMeshes(pass,caseID);pass.end();};
  drawScene(this.reflection,this.reflectionDepth,1,true);drawScene(this.scene,this.sceneDepth,0,false);
  const output=this.context.getCurrentTexture();enc.copyTextureToTexture({texture:this.scene},{texture:output},[this.canvas.width,this.canvas.height]);
  const water=enc.beginRenderPass({colorAttachments:[{view:output.createView(),loadOp:'load',storeOp:'store'}],depthStencilAttachment:{view:this.depth.createView(),depthClearValue:1,depthLoadOp:'clear',depthStoreOp:'store'}});
  water.setBindGroup(0,this.groups[0][caseID][this.sim.phase]);water.setBindGroup(1,this.parts[0].group);water.setBindGroup(2,this.groundGroup);water.setBindGroup(3,this.opticalGroup);water.setPipeline(this.water);water.draw(count);water.end();if(this.tracersEnabled&&this.tracerPipeline&&mode!==2&&mode!==4){const tp=enc.beginRenderPass({colorAttachments:[{view:output.createView(),loadOp:'load',storeOp:'store'}]});tp.setPipeline(this.tracerPipeline);tp.setBindGroup(0,this.tracerBindings[caseID][this.sim.phase]);tp.draw(6,this.tracers.count);tp.end();}if(this.sedimentPipeline&&(mode===0||mode===5)){const sp=enc.beginRenderPass({colorAttachments:[{view:output.createView(),loadOp:"load",storeOp:"store"}]});sp.setPipeline(this.sedimentPipeline);sp.setBindGroup(0,this.sedimentBindings[caseID][this.sim.phase]);sp.draw(6,this.sedimentParticles.count);sp.end();}d.queue.submit([enc.finish()]);
 }
 dispose(){for(const t of this.textures)t.destroy();for(const b of this.buffers)b.destroy();for(const key of ['depth','scene','sceneDepth','reflection','reflectionDepth','shadow'])this[key]?.destroy();this.context.unconfigure();}
}

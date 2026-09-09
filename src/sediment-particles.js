// A reusable GPU observation pool. Neither compute nor rendering writes Cell state.
export class SedimentParticles {
 static async create(sim){
  const self=new SedimentParticles(),d=sim.device;Object.assign(self,{sim,device:d,count:12288});
  self.buffers=[0,1].map(()=>d.createBuffer({size:self.count*32,usage:GPUBufferUsage.STORAGE|GPUBufferUsage.COPY_DST|GPUBufferUsage.COPY_SRC}));
  self.params=d.createBuffer({size:48,usage:GPUBufferUsage.UNIFORM|GPUBufferUsage.COPY_DST});
  const module=d.createShaderModule({code:await(await fetch('./shaders/sediment-particles.wgsl')).text()});
  self.pipeline=await d.createComputePipelineAsync({layout:'auto',compute:{module,entryPoint:'main'}});
  self.groups=sim.states.map((pair,a)=>pair.map((state,phase)=>d.createBindGroup({layout:self.pipeline.getBindGroupLayout(0),entries:[{binding:0,resource:{buffer:self.buffers[a]}},{binding:1,resource:{buffer:state}},{binding:2,resource:{buffer:pair[1-phase]}},{binding:3,resource:{buffer:self.params}}]})));
  self.reset();return self;
 }
 dispose(){for(const b of this.buffers)b.destroy();this.params.destroy();}
 reset(){for(const buffer of this.buffers)this.device.queue.writeBuffer(buffer,0,new Float32Array(this.count*8));}
 step(encoder,phase,dt,time){const c=this.sim.c;this.device.queue.writeBuffer(this.params,0,new Float32Array([c.nx,c.ny,c.dx,dt,time,c.settling,c.friction,c.tauD,0,0,0,0]));const p=encoder.beginComputePass();p.setPipeline(this.pipeline);for(let a=0;a<2;a++){p.setBindGroup(0,this.groups[a][phase]);p.dispatchWorkgroups(this.count/64);}p.end();}
 async attach(renderer){const d=this.device,module=d.createShaderModule({code:await(await fetch('./shaders/sediment-render.wgsl')).text()});renderer.sedimentPipeline=await d.createRenderPipelineAsync({layout:'auto',vertex:{module,entryPoint:'vertex'},fragment:{module,entryPoint:'fragment',targets:[{format:renderer.format,blend:{color:{srcFactor:'src-alpha',dstFactor:'one-minus-src-alpha',operation:'add'},alpha:{srcFactor:'one',dstFactor:'one-minus-src-alpha',operation:'add'}}}]},primitive:{topology:'triangle-list'}});renderer.sedimentGroups=()=>this.sim.states.map((pair,a)=>pair.map(state=>d.createBindGroup({layout:renderer.sedimentPipeline.getBindGroupLayout(0),entries:[{binding:0,resource:{buffer:renderer.uniforms[0]}},{binding:1,resource:{buffer:this.buffers[a]}},{binding:2,resource:{buffer:state}},{binding:3,resource:renderer.sceneDepth.createView()}]})));renderer.sedimentParticles=this;renderer.sedimentBindings=renderer.sedimentGroups();}
}

struct Cell{hydro:vec4f,bed:vec4f,ledger:vec4f}
struct Particle{position:vec4f,info:vec4f} // xyz metres, age seconds; active, class, lifetime, seed
struct Params{size:vec4f,material:vec4f,extra:vec4f}
@group(0) @binding(0) var<storage,read_write> particles:array<Particle>;
@group(0) @binding(1) var<storage,read> state:array<Cell>;
@group(0) @binding(2) var<storage,read> previous:array<Cell>;
@group(0) @binding(3) var<uniform> p:Params;
fn hash(n:u32)->f32{var x=n*747796405u+2891336453u;x=((x>>((x>>28u)+4u))^x)*277803737u;return f32((x>>22u)^x)/4294967295.;}
fn index(pos:vec2f)->u32{let c=vec2u(clamp(pos/p.size.z,vec2f(0.),p.size.xy-1.));return c.y*u32(p.size.x)+c.x;}
fn at(c:vec2i)->vec4f{let i=vec2u(clamp(c,vec2i(0),vec2i(p.size.xy)-1));return state[i.y*u32(p.size.x)+i.x].hydro;}
fn flow(pos:vec2f)->vec2f{let q=pos/p.size.z-.5;let c=vec2i(floor(q));let t=fract(q);let a=mix(mix(at(c),at(c+vec2i(1,0)),t.x),mix(at(c+vec2i(0,1)),at(c+vec2i(1,1)),t.x),t.y);return select(vec2f(0.),a.yz/max(a.x,.002),a.x>.002);}
@compute @workgroup_size(64) fn main(@builtin(global_invocation_id) id:vec3u){
 if(id.x>=arrayLength(&particles)){return;}var particle=particles[id.x];let dt=p.size.w;let tick=u32(p.material.x/dt);let seed=id.x*193u+tick*17u;
 if(particle.info.x<.5){
  let pos=vec2f(6.+hash(seed+3u)*56.,.6+hash(seed+19u)*46.8);let i=index(pos);let c=state[i];
  // Exact new erosion mass, not vegetation identity or pre-existing concentration.
  let erosion=max(0.,c.bed.z-previous[i].bed.z)/dt;
  if(c.hydro.x>.025&&hash(seed+71u)<(1.-exp(-erosion*100.*dt))){
   let sand=select(0.,1.,hash(seed+41u)>.7);
   particle=Particle(vec4f(pos.x,c.bed.x+min(c.hydro.x*.65,.025+length(flow(pos))*.4),pos.y,0.),vec4f(1.,sand,mix(85.,25.,sand),hash(seed+91u)));
  }
 }else{
  let pos=particle.position.xz;let velocity=flow(pos+flow(pos)*dt*.5);let c=state[index(pos)];let speed=length(velocity);let tau=1000.*p.material.z*speed*speed;
  // One physical sediment class; sand/fine are illustrative sizes, not extra mass.
  let settling=p.material.y*mix(1.,4.,particle.info.y)*max(0.,1.-tau/p.material.w);
  let diffusion=vec2f(hash(seed+11u)-.5,hash(seed+29u)-.5)*min(speed*.08,.008);
  particle.position.x+=dt*(velocity.x+diffusion.x);particle.position.z+=dt*(velocity.y+diffusion.y);
  // Shear-driven visual suspension lifts newly eroded grains off the bed.
  // Depth-averaged physics has no vertical velocity; this bounded mixing is observational.
  let excess=max(0.,tau/p.material.w-1.);
  let suspension=excess/(1.+excess)*min(speed*.3,.08)*clamp((c.bed.x+c.hydro.x*.65-particle.position.y)/max(.3*c.hydro.x,.01),0.,1.);
  particle.position.y+=dt*(suspension-settling);particle.position.w+=dt;
  let destination=state[index(particle.position.xz)];particle.position.y=min(particle.position.y,destination.bed.x+destination.hydro.x-.006);
  if(destination.hydro.x<.015||particle.position.y<=destination.bed.x+.002||particle.position.w>particle.info.z||particle.position.x<6.||particle.position.x>71.||particle.position.z<.3||particle.position.z>47.7){particle.info.x=0.;}
 }
 particles[id.x]=particle;
}

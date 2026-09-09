// Observation fields only. Never feed back into hydro or sediment mass.
struct Cell{hydro:vec4f,bed:vec4f,ledger:vec4f}
struct Params{size:vec4f,clock:vec4f}
@group(0) @binding(0) var<storage,read> state:array<Cell>;
@group(0) @binding(1) var<storage,read> old:array<vec4f>;
@group(0) @binding(2) var<storage,read_write> next:array<vec4f>;
@group(0) @binding(3) var<uniform> p:Params;
fn index(x:i32,z:i32)->u32{return u32(clamp(z,0,i32(p.size.y)-1)*i32(p.size.x)+clamp(x,0,i32(p.size.x)-1));}
fn memory(pos:vec2f)->vec4f{let a=vec2i(floor(pos));let t=fract(pos);return mix(mix(old[index(a.x,a.y)],old[index(a.x+1,a.y)],t.x),mix(old[index(a.x,a.y+1)],old[index(a.x+1,a.y+1)],t.x),t.y);}
fn velocity(i:u32)->vec2f{let h=state[i].hydro.x;return select(vec2f(0),state[i].hydro.yz/max(h,.002),h>.002);}
@compute @workgroup_size(8,8) fn main(@builtin(global_invocation_id) id:vec3u){if(id.x>=u32(p.size.x)||id.y>=u32(p.size.y)){return;}let i=id.y*u32(p.size.x)+id.x;let a=state[i];let v=velocity(i);let h=a.hydro.x;let dt=p.size.w;let previous=memory(vec2f(id.xy)-v*dt/p.size.z);let reset=p.clock.x<dt*.5;let x=i32(id.x);let z=i32(id.y);let east=state[index(x+1,z)];let west=state[index(x-1,z)];let north=state[index(x,z+1)];let south=state[index(x,z-1)];let gradient=vec2f(east.bed.x+east.hydro.x-west.bed.x-west.hydro.x,north.bed.x+north.hydro.x-south.bed.x-south.hydro.x)/(2.*p.size.z);let divergence=(velocity(index(x+1,z)).x-velocity(index(x-1,z)).x+velocity(index(x,z+1)).y-velocity(index(x,z-1)).y)/(2.*p.size.z);let froude=length(v)/sqrt(9.81*max(h,.01));
let hydraulic=smoothstep(.25,.85,froude)*smoothstep(.008,.05,length(gradient));let compression=clamp(-divergence*2.,0.,1.)*smoothstep(.015,.055,length(gradient));let production=(hydraulic+compression)*select(0.,1.,h>.006);let oldFoam=select(previous.x,0.,reset);let foam=clamp(oldFoam*exp(-dt/3.5)+production*dt,0.,1.);let wetness=select(select(old[i].y,0.,reset)*exp(-dt/65.),1.,h>.006);let speed2=dot(v,v);let previousMean=select(old[i].z,0.,reset);let mean=mix(previousMean,speed2,1.-exp(-dt/12.));next[i]=vec4f(foam,wetness,mean,0.);
}

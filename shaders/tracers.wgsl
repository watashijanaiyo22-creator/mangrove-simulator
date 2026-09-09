struct Cell { hydro:vec4f,bed:vec4f,ledger:vec4f }
struct Step { size:vec4f,clock:vec4f }
@group(0) @binding(0) var<storage,read_write> particles:array<vec4f>;
@group(0) @binding(1) var<storage,read> state:array<Cell>;
@group(0) @binding(2) var<uniform> step:Step;
fn hash(n:u32)->f32 {var x=n*747796405u+2891336453u;x=((x>>((x>>28u)+4u))^x)*277803737u;return f32((x>>22u)^x)/4294967295.;}
fn flow(p:vec2f)->vec3f {let nx=u32(step.size.x);let c=vec2u(clamp(p/step.size.z,vec2f(0.),step.size.xy-1.));let a=state[c.y*nx+c.x];return vec3f(select(vec2f(0.),a.hydro.yz/max(a.hydro.x,.002),a.hydro.x>.002),a.hydro.x);}
@compute @workgroup_size(64) fn main(@builtin(global_invocation_id) id:vec3u){if(id.x>=arrayLength(&particles)){return;}var p=particles[id.x];if(step.clock.x<step.size.w*.5||p.w<0.){p=vec4f(35.+hash(id.x+3u)*25.,2.+hash(id.x+91u)*44.,hash(id.x+234u),0.);}
 let v=flow(p.xy);let middle=flow(p.xy+v.xy*step.size.w*.5);p.x+=middle.x*step.size.w;p.y+=middle.y*step.size.w;p.w+=step.size.w;
 if(p.x<8.||p.x>70.||p.y<.5||p.y>47.5||p.w>180.){p=vec4f(35.+hash(id.x+u32(p.w)+31u)*10.,2.+hash(id.x+u32(p.w)+77u)*44.,p.z,0.);}
 particles[id.x]=p;
}

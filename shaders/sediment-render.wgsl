struct Cell{hydro:vec4f,bed:vec4f,ledger:vec4f}
struct Particle{position:vec4f,info:vec4f}
struct View{vp:mat4x4f,light:mat4x4f,reflection:mat4x4f,eye:vec4f,grid:vec4f,options:vec4f,screen:vec4f}
@group(0) @binding(0) var<uniform> view:View;
@group(0) @binding(1) var<storage,read> particles:array<Particle>;
@group(0) @binding(2) var<storage,read> state:array<Cell>;
@group(0) @binding(3) var depth:texture_depth_2d;
struct Out{@builtin(position) pos:vec4f,@location(0) uv:vec2f,@location(1) alpha:f32,@location(2) sand:f32}
@vertex fn vertex(@builtin(vertex_index) vi:u32,@builtin(instance_index) i:u32)->Out{
 let particle=particles[i];let coord=vec2u(clamp(particle.position.xz/view.grid.z,vec2f(0.),view.grid.xy-1.));let c=state[coord.y*u32(view.grid.x)+coord.x];
 let visualBed=c.bed.w+(c.bed.x-c.bed.w)*view.screen.w;var world=particle.position.xyz;world.y=min(c.bed.x+c.hydro.x-.004,visualBed+max(.002,particle.position.y-c.bed.x));
 let corners=array<vec2f,6>(vec2f(-1,-1),vec2f(1,-1),vec2f(1,1),vec2f(-1,-1),vec2f(1,1),vec2f(-1,1));let uv=corners[vi];var clip=view.vp*vec4f(world,1.);
 // Enlarged observation grains, constant world size with a subpixel visibility floor.
 let radius=mix(.024,.042,particle.info.y);let pixels=clamp(radius*view.screen.y/max(clip.w,.1),1.25,4.);
 clip.x+=uv.x*pixels*2./view.screen.x*clip.w;clip.y+=uv.y*pixels*2./view.screen.y*clip.w;
 let concentration=c.hydro.w/max(c.hydro.x,.002);let burial=smoothstep(0.,.018,particle.position.y-c.bed.x);let fade=smoothstep(0.,.6,particle.position.w)*smoothstep(0.,4.,particle.info.z-particle.position.w);
 var o:Out;o.pos=clip;o.uv=uv;o.sand=particle.info.y;o.alpha=particle.info.x*fade*burial*exp(-max(0.,c.bed.x+c.hydro.x-world.y)*(.8+concentration*1.2))*.9;return o;
}
@fragment fn fragment(o:Out)->@location(0) vec4f{let d=textureLoad(depth,clamp(vec2i(o.pos.xy),vec2i(0),vec2i(textureDimensions(depth))-1),0);if(d<o.pos.z-.000002||o.alpha<.005){discard;}return vec4f(mix(vec3f(.58,.40,.21),vec3f(.80,.65,.39),o.sand),o.alpha*(1.-smoothstep(.3,1.,length(o.uv))));}

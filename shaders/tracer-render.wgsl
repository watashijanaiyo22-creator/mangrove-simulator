struct Cell{hydro:vec4f,bed:vec4f,ledger:vec4f}
struct View { vp:mat4x4f,light:mat4x4f,reflection:mat4x4f,eye:vec4f,grid:vec4f,options:vec4f,screen:vec4f }
@group(0) @binding(0) var<uniform> view:View;
@group(0) @binding(1) var<storage,read> particles:array<vec4f>;
@group(0) @binding(2) var<storage,read> state:array<Cell>;
@group(0) @binding(3) var depth:texture_depth_2d;
struct Out{@builtin(position) pos:vec4f,@location(0) uv:vec2f,@location(1) wet:f32}
@vertex fn vertex(@builtin(vertex_index) vi:u32,@builtin(instance_index) i:u32)->Out {
 let particle=particles[i];let pos=particle.xy;let coord=vec2u(clamp(pos/view.grid.z,vec2f(0.),view.grid.xy-1.));let c=state[coord.y*u32(view.grid.x)+coord.x];let v=c.hydro.yz/max(c.hydro.x,.002);let dir=normalize(v+vec2f(.00001,0.));let right=vec2f(-dir.y,dir.x);let corners=array<vec2f,6>(vec2f(-1,-1),vec2f(1,-1),vec2f(1,1),vec2f(-1,-1),vec2f(1,1),vec2f(-1,1));let uv=corners[vi];let xz=pos+right*uv.x*.025+dir*uv.y*(.04+min(length(v),1.)*.35);let world=vec3f(xz.x,c.bed.x+c.hydro.x+.012,xz.y);var o:Out;o.pos=view.vp*vec4f(world,1.);o.uv=uv;o.wet=c.hydro.x;return o;
}
@fragment fn fragment(o:Out)->@location(0) vec4f {if(o.wet<.025){discard;}let dims=vec2i(textureDimensions(depth));let d=textureLoad(depth,clamp(vec2i(o.pos.xy),vec2i(0),dims-1),0);if(d<o.pos.z-.000002){discard;}let edge=1.-smoothstep(.55,1.,length(o.uv));return vec4f(.96,.87,.56,edge*.86);}

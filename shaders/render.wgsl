// Water optics adapted from Inkwell WebGPU Water, MIT, James Addison (2026).
// The FFT/spectral displacement is NOT used: all displaced vertices sample hydro.
struct Cell { hydro:vec4f, bed:vec4f, ledger:vec4f }
struct View { vp:mat4x4f, light:mat4x4f, reflection:mat4x4f, eye:vec4f, grid:vec4f, options:vec4f, screen:vec4f }
@group(0) @binding(0) var<uniform> view:View;
@group(0) @binding(1) var<storage,read> state:array<Cell>;
@group(0) @binding(2) var<storage,read> rootArea:array<vec4f>;
@group(0) @binding(3) var<storage,read> surfaceMemory:array<vec4f>;
fn surface(p:vec2f)->vec4f{let i=vec2u(clamp(p/view.grid.z,vec2f(0.),view.grid.xy-1.));return surfaceMemory[i.y*u32(view.grid.x)+i.x];}
@group(1) @binding(0) var matColor:texture_2d<f32>;
@group(1) @binding(1) var matNormal:texture_2d<f32>;
@group(1) @binding(2) var matArm:texture_2d<f32>;
@group(1) @binding(3) var matSampler:sampler;
@group(2) @binding(0) var mudColor:texture_2d<f32>;
@group(2) @binding(1) var mudNormal:texture_2d<f32>;
@group(2) @binding(2) var mudArm:texture_2d<f32>;
@group(2) @binding(3) var sandColor:texture_2d<f32>;
@group(2) @binding(4) var sandNormal:texture_2d<f32>;
@group(2) @binding(5) var sandArm:texture_2d<f32>;
@group(2) @binding(6) var groundSampler:sampler;
@group(2) @binding(7) var shadowMap:texture_depth_2d;
@group(2) @binding(8) var shadowSampler:sampler_comparison;
@group(3) @binding(0) var sceneColor:texture_2d<f32>;
@group(3) @binding(1) var sceneDepth:texture_depth_2d;
@group(3) @binding(2) var reflectedScene:texture_2d<f32>;
@group(3) @binding(3) var screenSampler:sampler;
struct Out { @builtin(position) clip:vec4f, @location(0) world:vec3f, @location(1) normal:vec3f, @location(2) uv:vec2f, @location(3) data:vec4f, @location(4) tangent:vec4f }
fn at(x:i32,z:i32)->Cell {return state[u32(clamp(z,0,i32(view.grid.y)-1)*i32(view.grid.x)+clamp(x,0,i32(view.grid.x)-1))];}
fn sampleCell(p:vec2f)->Cell {let p0=p/view.grid.z-vec2f(.5);let i=vec2i(floor(p0));let f=fract(p0);let a=at(i.x,i.y);let b=at(i.x+1,i.y);let c=at(i.x,i.y+1);let d=at(i.x+1,i.y+1);return Cell(mix(mix(a.hydro,b.hydro,f.x),mix(c.hydro,d.hydro,f.x),f.y),mix(mix(a.bed,b.bed,f.x),mix(c.bed,d.bed,f.x),f.y),vec4f(0.));}
fn visualBed(a:Cell)->f32 {return a.bed.w+(a.bed.x-a.bed.w)*view.screen.w;}
fn elevation(x:i32,z:i32,water:bool)->f32 {let a=at(x,z);return select(visualBed(a),a.bed.x+a.hydro.x,water);}
fn terrainVertex(vertex:u32,water:bool)->Out {
 let corners=array<vec2u,6>(vec2u(0,0),vec2u(0,1),vec2u(1,1),vec2u(0,0),vec2u(1,1),vec2u(1,0));let i=vertex/6u;let nx=u32(view.grid.x)-1u;let coord=vec2u(i%nx,i/nx)+corners[vertex%6u];let x=i32(coord.x);let z=i32(coord.y);let a=at(x,z);let y=elevation(x,z,water);let pos=vec3f((f32(x)+.5)*view.grid.z,y,(f32(z)+.5)*view.grid.z);
 let n=normalize(vec3f(elevation(x-1,z,water)-elevation(x+1,z,water),2.*view.grid.z,elevation(x,z-1,water)-elevation(x,z+1,water)));
 let h=a.hydro.x;let speed=select(0.,length(a.hydro.yz)/max(h,.002),h>.002);var o:Out;o.clip=view.vp*vec4f(pos,1.);o.world=pos;o.normal=n;o.uv=pos.xz;o.tangent=vec4f(1.,0.,0.,1.);o.data=vec4f(h,speed,a.bed.x-a.bed.w,dot(rootArea[u32(z)*u32(view.grid.x)+u32(x)],vec4f(1.)));return o;
}
@vertex fn bedVertex(@builtin(vertex_index) id:u32)->Out{return terrainVertex(id,false);}
@vertex fn waterVertex(@builtin(vertex_index) id:u32)->Out{return terrainVertex(id,true);}
fn hash(p:vec2f)->f32{return fract(sin(dot(p,vec2f(127.1,311.7)))*43758.5453);}
fn noise(p:vec2f)->f32 {let i=floor(p);let t=fract(p);let f=t*t*(3.-2.*t);return mix(mix(hash(i),hash(i+vec2f(1,0)),f.x),mix(hash(i+vec2f(0,1)),hash(i+vec2f(1,1)),f.x),f.y);}
fn heat(v:f32)->vec3f{return mix(vec3f(.06,.31,.43),vec3f(.94,.57,.18),clamp(v,0.,1.));}
fn changeColor(change:f32)->vec3f {let neutral=vec3f(.52,.57,.51);return mix(neutral,select(vec3f(.82,.24,.08),vec3f(.04,.41,.62),change>0.),clamp(log(1.+abs(change)/.00001)/log(701.),0.,1.));}
fn srgb(c:vec3f)->vec3f{return pow(max(c,vec3f(0.)),vec3f(1./2.2));}
fn sun()->vec3f {return normalize(vec3f(.59,.70,.46));}
fn shadow(world:vec3f)->f32 {
 let p=view.light*vec4f(world,1.);let uv=p.xy*.5*vec2f(1.,-1.)+.5;
 var v=0.;for(var y=-1;y<=1;y++){for(var x=-1;x<=1;x++){v+=textureSampleCompareLevel(shadowMap,shadowSampler,uv+vec2f(f32(x),f32(y))/2048.,p.z-.00065);}}
 return .26+.74*v/9.;
}
fn diffuse(color:vec3f,n:vec3f,world:vec3f,ao:f32)->vec3f {let sky=vec3f(.55,.65,.72)*(.40+.14*max(n.y,0.));let direct=vec3f(1.,.94,.80)*max(dot(n,sun()),0.)*.95*shadow(world);return color*(sky+direct)*mix(.45,1.,ao);}
fn bedColor(o:Out)->vec3f {
 let wet=max(surface(o.world.xz).y,.35*(1.-smoothstep(.0,.18,o.world.y-view.screen.z)));let mudWeight=clamp(.55+.25*smoothstep(32.,54.,o.world.x)+.2*tanh(o.data.z/.001),0.,1.);
 let uv=o.world.xz/1.3;let suv=o.world.xz/30.;
 let mud=mix(textureSample(mudColor,groundSampler,uv).rgb,textureSample(mudColor,groundSampler,vec2f(-uv.y,uv.x)*.71+vec2f(.31,.72)).rgb,.45);let sand=textureSample(sandColor,groundSampler,suv).rgb;
 let ma=textureSample(mudArm,groundSampler,uv).rgb;let sa=textureSample(sandArm,groundSampler,suv).rgb;
 let mn=textureSample(mudNormal,groundSampler,uv).xyz*2.-1.;let sn=textureSample(sandNormal,groundSampler,suv).xyz*2.-1.;let micro=mix(sn,mn,mudWeight);
 let n=normalize(o.normal+vec3f(micro.x,0.,-micro.y)*.38);
 var base=mix(sand,mud,mudWeight)*mix(1.16,.56,wet);base*=.9+.2*noise(o.world.xz*.15);
 if(view.options.x==2.){return changeColor(o.data.z);}
 if(view.options.x==1.){return heat(o.data.y/.32);}
 if(view.options.x==3.){return mix(vec3f(.22,.29,.27),vec3f(.18,.65,.46),select(0.,clamp(1.-o.data.y/.12,0.,1.),o.data.x>.04));}
 if(view.options.x==4.){return mix(vec3f(.17,.22,.19),vec3f(.92,.55,.12),clamp(o.data.w*1.4,0.,1.)*view.options.z);}
 var color=diffuse(base,n,o.world,mix(sa.r,ma.r,mudWeight));let rough=mix(sa.g,ma.g,mudWeight);let v=normalize(view.eye.xyz-o.world);let glint=pow(max(dot(n,normalize(v+sun())),0.),mix(90.,22.,rough));color+=glint*wet*.04*shadow(o.world);
 return color;
}
@fragment fn bedFragment(o:Out)->@location(0) vec4f {
 if(view.eye.w<0.&&o.world.y<view.screen.z-.02){discard;}
 var color=bedColor(o);
 let physical=sampleCell(o.world.xz);let initialHeight=physical.bed.w-view.screen.z;let initialWidth=max(fwidth(initialHeight),.00003);let currentWidth=max(fwidth(o.world.y),.00003);
 if(view.options.y>.5){let initial=(1.-smoothstep(initialWidth*.3,initialWidth*1.3,abs(initialHeight)))*step(.45,fract(o.world.z*.7));let current=1.-smoothstep(currentWidth*.3,currentWidth*1.3,abs(physical.bed.x-view.screen.z));color=mix(color,vec3f(.82,.87,.85),initial);color=mix(color,vec3f(.82,.65,.28),current);}
 return vec4f(srgb(color),1.);
}
// Inkwell dielectric Fresnel (retained with MIT notice).
fn dielectricFresnel(cosine:f32)->f32 {
 let eta=1./1.333;let sinTransmittedSquared=eta*eta*max(0.,1.-cosine*cosine);
 if(sinTransmittedSquared>=1.){return 1.;}
 let transmittedCosine=sqrt(max(0.,1.-sinTransmittedSquared));
 let parallel=(cosine-1.333*transmittedCosine)/max(cosine+1.333*transmittedCosine,.0001);
 let perpendicular=(transmittedCosine-1.333*cosine)/max(transmittedCosine+1.333*cosine,.0001);
 return .5*(parallel*parallel+perpendicular*perpendicular);
}
fn smithVisibility(cosine:f32,variance:f32)->f32 {let t=max(0.,1.-cosine*cosine)/max(cosine*cosine,.0001);return 2./(1.+sqrt(1.+variance*t));}
fn glitter(n:vec3f,v:vec3f,rough:f32)->f32 {
 let l=sun();let h=normalize(v+l);let nv=max(dot(n,v),.001);let nl=max(dot(n,l),.001);let nh=max(dot(n,h),.001);
 let variance=rough*rough;let distribution=exp((nh*nh-1.)/max(variance*nh*nh,.00001))/(3.14159*variance*pow(nh,4.));
 return dielectricFresnel(max(dot(v,h),0.))*distribution*smithVisibility(nv,variance)*smithVisibility(nl,variance)/max(4.*nv,.001);
}
fn sky(direction:vec3f)->vec3f {
 let y=clamp(direction.y,0.,1.);let horizon=vec3f(.59,.70,.76);let zenith=vec3f(.16,.35,.53);var color=mix(horizon,zenith,sqrt(y));
 let cloud=noise(direction.xz/max(direction.y+.12,.12)*2.);color=mix(color,vec3f(.87,.88,.83),smoothstep(.62,.85,cloud)*.3);
 return color;
}
@fragment fn waterFragment(o:Out)->@location(0) vec4f {
 let foreground=textureLoad(sceneDepth,vec2i(o.clip.xy),0);if(foreground<o.clip.z-.000001){discard;}
 let a=sampleCell(o.world.xz);let depth=a.hydro.x;if(depth<.003){discard;}
 let concentration=a.hydro.w/max(depth,.002);let velocity=a.hydro.yz/max(depth,.002);let speed=length(velocity);
 let waveSlope=length(o.normal.xz);let activity=clamp(speed*2.4+waveSlope*6.,0.,1.);
 // Surface normals follow the solved free surface; no independently travelling wave layer.
 let n=normalize(o.normal);let v=normalize(view.eye.xyz-o.world);let ndv=max(dot(n,v),.02);
 let screenUV=o.clip.xy/view.screen.xy;let refrUV=clamp(screenUV+vec2f(n.x,-n.z)*(.006+min(depth,3.)*.003),vec2f(.001),vec2f(.999));
 let dims=vec2f(textureDimensions(sceneDepth));let sampledDepth=textureLoad(sceneDepth,vec2i(refrUV*dims),0);let safeUV=select(screenUV,refrUV,sampledDepth>o.clip.z+.000005);
 let floorColor=pow(textureSample(sceneColor,screenSampler,safeUV).rgb,vec3f(2.2));
 // Beer-Lambert path length and suspended sediment extinction, adapted from Inkwell.
 let ray=refract(-v,n,1./1.333);let path=min(depth/max(-ray.y,.28),12.);var throughput=vec3f(1.);var inScatter=vec3f(0.);
 // Integrate the model's depth-averaged concentration along the underwater
 // viewing ray. No invented cloud/noise field is added to the concentration.
 for(var step=0;step<8;step++){
  let distance=(f32(step)+.5)*path/8.;let p=o.world+ray*distance;let column=sampleCell(p.xz);
  let c=select(0.,column.hydro.w/max(column.hydro.x,.002),column.hydro.x>.002);
  let extinction=vec3f(.57,.18,.09)+c*vec3f(2.5,3.5,5.);let segment=exp(-extinction*path/8.);
  let scatter=mix(vec3f(.014,.12,.105),vec3f(.22,.13,.052),1.-exp(-c*4.));
  inScatter+=throughput*scatter*(vec3f(1.)-segment);throughput*=segment;
 }
 let refracted=floorColor*throughput+inScatter;
 let reflectionClip=view.reflection*vec4f(o.world.x,view.screen.z,o.world.z,1.);let reflectionUV=clamp(reflectionClip.xy/reflectionClip.w*vec2f(.5,-.5)+.5+vec2f(n.x,n.z)*.045,vec2f(.001),vec2f(.999));
 let reflection=pow(textureSample(reflectedScene,screenSampler,reflectionUV).rgb,vec3f(2.2));
 let fresnel=dielectricFresnel(ndv);var color=mix(refracted,reflection,fresnel);color+=vec3f(1.,.93,.76)*min(glitter(n,v,.20+activity*.08),2.)*shadow(o.world);
 let froude=speed/sqrt(9.81*max(depth,.015));let breaking=smoothstep(.35,.85,froude)*smoothstep(.008,.035,waveSlope);
 let shoreFoam=max(surface(o.world.xz).x,breaking*.3)*(1.-smoothstep(.4,1.5,depth));let foam=clamp(shoreFoam,0.,1.);
 color=mix(color,vec3f(.84,.89,.83),foam*.55);
 if(view.options.x==1.){let dir=normalize(velocity+vec2f(.00001));let stripe=step(.95,fract(dot(o.world.xz,vec2f(-dir.y,dir.x))*1.8))*step(.4,fract(dot(o.world.xz,dir)*1.1-view.grid.w*speed));color=mix(heat(speed/.32),vec3f(.9),stripe*clamp(speed*8.,0.,1.));}
 if(view.options.x==5.){color=mix(color,vec3f(.52,.26,.07),clamp(concentration/1.2,0.,.85));}
 if(view.options.x==2.){color=changeColor(a.bed.x-a.bed.w);}
 if(view.options.x==3.){color=mix(vec3f(.22,.29,.27),vec3f(.18,.65,.46),clamp(1.-sqrt(surface(o.world.xz).z)/.12,0.,1.));}
 if(view.options.x==4.){color=mix(floorColor,color,.12);}
 return vec4f(srgb(color),smoothstep(.003,.018,depth));
}
struct MeshIn { @location(0) pos:vec3f,@location(1) normal:vec3f,@location(2) uv:vec2f,@location(3) tangent:vec4f,@location(4) location:vec4f,@location(5) rotation:vec4f }
fn bedOriginal(p:vec2f)->f32{return -1.65+2.05*p.x/72.+.045*sin(p.y*.16)*sin(p.x*.085)+.025*sin(p.y*.49+p.x*.13);}
fn meshOut(v:MeshIn)->Out {let co=cos(v.rotation.x);let si=sin(v.rotation.x);let stretch=vec3f(v.rotation.y,1.,v.rotation.y);let p=v.pos*v.location.w*stretch;var world=vec3f(p.x*co-p.z*si,p.y,p.x*si+p.z*co)+v.location.xyz;world.y+=(bedOriginal(world.xz)-v.location.y)*(1.-clamp(p.y/2.,0.,1.));let nn=normalize(v.normal/stretch);let normal=vec3f(nn.x*co-nn.z*si,nn.y,nn.x*si+nn.z*co);var o:Out;o.world=world;o.clip=view.vp*vec4f(world,1.);o.normal=normal;o.uv=v.uv;let tt=normalize(v.tangent.xyz*stretch);o.tangent=vec4f(tt.x*co-tt.z*si,tt.y,tt.x*si+tt.z*co,v.tangent.w);o.data=vec4f(v.rotation.y,p.y,0.,0.);return o;}
@vertex fn meshVertex(v:MeshIn)->Out{return meshOut(v);}
@vertex fn shadowVertex(v:MeshIn)->Out{var o=meshOut(v);o.clip=view.light*vec4f(o.world,1.);return o;}
@fragment fn shadowFragment(o:Out){if(textureSample(matColor,matSampler,o.uv).a<.4){discard;}if(view.options.w>.5&&o.data.y>1.8){discard;}}
@fragment fn meshFragment(o:Out,@builtin(front_facing) front:bool)->@location(0) vec4f {
 if(view.eye.w<0.&&o.world.y<view.screen.z-.01){discard;}
 if(view.options.w>.5&&o.data.y>1.8){discard;}
 let base=textureSample(matColor,matSampler,o.uv);if(base.a<.4){discard;}
 let sampledNormal=textureSample(matNormal,matSampler,o.uv).xyz*2.-1.;let geometric=normalize(select(-o.normal,o.normal,front));let t=normalize(o.tangent.xyz);let bt=normalize(cross(geometric,t))*o.tangent.w;let n=normalize(t*sampledNormal.x+bt*sampledNormal.y+geometric*sampledNormal.z);
 let arm=textureSample(matArm,matSampler,o.uv).rgb;let v=normalize(view.eye.xyz-o.world);var color=diffuse(base.rgb,n,o.world,1.);
 let leaf=clamp((base.g-base.r)*8.,0.,1.);color+=base.rgb*leaf*.35*pow(max(dot(-sun(),v),0.),2.);
 let rough=clamp(arm.g,.35,1.);color+=vec3f(.02)*pow(max(dot(n,normalize(sun()+v)),0.),mix(110.,10.,rough))*shadow(o.world);
 if(view.options.x==4.&&o.data.y<1.8){color=mix(color,vec3f(.95,.48,.07),.7);}
 return vec4f(srgb(color),1.);
}
@vertex fn skyVertex(@builtin(vertex_index) id:u32)->@builtin(position) vec4f {let p=array<vec2f,3>(vec2f(-1,-1),vec2f(3,-1),vec2f(-1,3));return vec4f(p[id],.999999,1.);}
@fragment fn skyFragment(@builtin(position) p:vec4f)->@location(0) vec4f {let uv=p.xy/view.screen.xy;let color=mix(vec3f(.14,.20,.23),vec3f(.26,.33,.35),1.-uv.y);return vec4f(srgb(color),1.);}
@fragment fn reflectionSky(@builtin(position) p:vec4f)->@location(0) vec4f {let uv=p.xy/(view.screen.xy*.5);return vec4f(srgb(sky(normalize(vec3f((uv.x-.5)*2.,.35+uv.y*.65,1.)))),1.);}

fn edgeVertex(id:u32,water:bool)->Out {
 let nx=u32(view.grid.x)-1u;let nz=u32(view.grid.y)-1u;let segment=id/6u;let corner=array<vec2u,6>(vec2u(0,0),vec2u(1,0),vec2u(1,1),vec2u(0,0),vec2u(1,1),vec2u(0,1))[id%6u];
 var coord=vec2u(0);var normal=vec3f(0.,0.,-1.);
 if(segment<nx){coord=vec2u(segment+corner.x,0u);}else if(segment<nx+nz){coord=vec2u(nx,segment-nx+corner.x);normal=vec3f(1.,0.,0.);}else if(segment<2u*nx+nz){coord=vec2u(segment-nx-nz+corner.x,nz);normal=vec3f(0.,0.,1.);}else{coord=vec2u(0u,segment-2u*nx-nz+corner.x);normal=vec3f(-1.,0.,0.);}
 let a=at(i32(coord.x),i32(coord.y));let bottom=select(-2.4,visualBed(a),water);let top=select(visualBed(a),a.bed.x+a.hydro.x,water);let y=mix(bottom,top,f32(corner.y));let world=vec3f((f32(coord.x)+.5)*view.grid.z,y,(f32(coord.y)+.5)*view.grid.z);var o:Out;o.clip=view.vp*vec4f(world,1.);o.world=world;o.normal=normal;o.uv=world.xz;o.data=vec4f(a.hydro.x,y-bottom,select(0.,1.,water),0.);o.tangent=vec4f(1.,0.,0.,1.);return o;
}
@vertex fn bedEdgeVertex(@builtin(vertex_index) id:u32)->Out{return edgeVertex(id,false);}
@vertex fn waterEdgeVertex(@builtin(vertex_index) id:u32)->Out{return edgeVertex(id,true);}
@fragment fn edgeFragment(o:Out)->@location(0) vec4f {
 let grain=noise(o.world.xz*7.+o.world.y*3.);var color=vec3f(.085,.077,.058)*(.8+grain*.4);if(o.data.z>.5){if(o.data.x<.003){discard;}color=mix(vec3f(.045,.15,.15),vec3f(.12,.32,.29),clamp(o.data.y/max(o.data.x,.01),0.,1.));}
 return vec4f(srgb(color),1.);
}

struct Cell { hydro:vec4f, bed:vec4f, ledger:vec4f }
struct Params { size:vec4f, forcing:vec4f, switches:vec4f, material:vec4f, sediment:vec4f }
@group(0) @binding(0) var<storage,read> prev:array<Cell>;
@group(0) @binding(1) var<storage,read_write> next:array<Cell>;
@group(0) @binding(2) var<storage,read> roots:array<vec4f>;
@group(0) @binding(3) var<uniform> p:Params;
const G=9.81; const DRY=0.002;
fn cell(x:i32,z:i32)->Cell { let nx=i32(p.size.x);let nz=i32(p.size.y);var a=prev[u32(clamp(z,0,nz-1)*nx+clamp(x,0,nx-1))];if(x<0||x>=nx){a.hydro.y=-a.hydro.y;}if(z<0||z>=nz){a.hydro.z=-a.hydro.z;}return a; }
struct Face { flux:vec4f, ha:f32, hb:f32 }
fn face(a:Cell,b:Cell,axis:u32)->Face {
 let top=max(a.bed.x,b.bed.x);let ha=max(0.,a.bed.x+a.hydro.x-top);let hb=max(0.,b.bed.x+b.hydro.x-top);
 let qa=select(vec2f(0.),a.hydro.yz*ha/max(a.hydro.x,DRY),a.hydro.x>DRY);
 let qb=select(vec2f(0.),b.hydro.yz*hb/max(b.hydro.x,DRY),b.hydro.x>DRY);
 let ua=select(0.,qa[axis]/max(ha,DRY),ha>DRY);let ub=select(0.,qb[axis]/max(hb,DRY),hb>DRY);
 let speed=max(abs(ua)+sqrt(G*ha),abs(ub)+sqrt(G*hb));
 var flux=vec4f(.5*(qa[axis]+qb[axis])-.5*speed*(hb-ha),.5*(qa*ua+qb*ub)-.5*speed*(qb-qa),0.);
 flux[axis+1u]+=.25*G*(ha*ha+hb*hb);
 let donor=select(b.hydro,a.hydro,flux.x>=0.);flux.w=flux.x*select(0.,donor.w/max(donor.x,DRY),donor.x>DRY);
 return Face(flux,ha,hb);
}
@compute @workgroup_size(8,8)
fn main(@builtin(global_invocation_id) id:vec3u) {
 if(id.x>=u32(p.size.x)||id.y>=u32(p.size.y)){return;}
 let x=i32(id.x);let z=i32(id.y);let index=u32(z*i32(p.size.x)+x);let a=cell(x,z);
 let e=face(a,cell(x+1,z),0u);let w=face(cell(x-1,z),a,0u);let n=face(a,cell(x,z+1),1u);let s=face(cell(x,z-1),a,1u);
 let dt=p.size.w;let k=dt/p.size.z;
 var u=a.hydro-k*(e.flux-w.flux+n.flux-s.flux);
 u.y-=k*.5*G*(w.hb*w.hb-e.ha*e.ha);u.z-=k*.5*G*(s.hb*s.hb-n.ha*n.ha);
 var b=a.bed;var ledger=a.ledger;ledger.z+=max(0.,-u.x);ledger.w+=max(0.,-u.w);u.x=max(0.,u.x);u.w=max(0.,u.w);
 if(u.x>DRY){
  let speed=length(u.yz)/u.x;u=vec4f(u.x,u.yz/(1.+dt*p.material.x*speed/u.x),u.w);
  let low=a.bed.w+vec4f(0.,.3,.6,1.2);let high=a.bed.w+vec4f(.3,.6,1.2,3.6);
  let wet=clamp((min(vec4f(a.bed.x+u.x),high)-max(vec4f(a.bed.x),low))/(high-low),vec4f(0.),vec4f(1.));
  let area=dot(roots[index],wet)*p.switches.x;
  let drag=1.+dt*.5*p.material.y*area/u.x*length(u.yz)/u.x;
  u=vec4f(u.x,u.yz/drag,u.w);
 }else{u.y=0.;u.z=0.;}
 if(p.switches.y>.5&&x<8){
  let blend=1.-exp(-dt*2.*pow((8.-f32(x))/8.,2.));let ramp=min(1.,p.forcing.x/12.);
  let wave=p.forcing.y*ramp*sin(6.2831853*p.forcing.x/p.forcing.w);let h=max(0.,p.forcing.z+wave-a.bed.x);
  let q=wave*sqrt(G*max(p.forcing.z-a.bed.x,.1));let newH=mix(u.x,h,blend);let newMs=mix(u.w,h*p.sediment.w,blend);
  ledger.x+=newH-u.x;ledger.y+=newMs-u.w;u=vec4f(newH,mix(u.y,q,blend),u.z*(1.-blend),newMs);
 }
 if(p.switches.z>.5&&x>=10){
  let tau=select(0.,1000.*p.material.x*dot(u.yz,u.yz)/max(u.x*u.x,DRY*DRY),u.x>DRY);
  let available=max(0.,(a.bed.x-a.bed.w+.45)*p.material.z);
  let erosion=min(available,p.sediment.x*max(tau/p.material.w-1.,0.)*dt);
  let rate=p.sediment.y*max(1.-tau/p.sediment.z,0.)/max(u.x,DRY);
  let deposition=(u.w+erosion)*(1.-exp(-rate*dt));
  u.w+=erosion-deposition;b.y+=deposition;b.z+=erosion;
  b.x=b.w+(b.y-b.z)/p.material.z;
 }
 next[index]=Cell(u,b,ledger);
}

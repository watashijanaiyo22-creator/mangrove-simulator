export const sub=(a,b)=>a.map((v,i)=>v-b[i]);
export const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
export const norm=a=>{const l=Math.hypot(...a)||1;return a.map(v=>v/l);};
export const dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0);
export function multiply(a,b){const r=new Float32Array(16);for(let col=0;col<4;col++)for(let row=0;row<4;row++)for(let k=0;k<4;k++)r[col*4+row]+=a[k*4+row]*b[col*4+k];return r;}
export function cameraMatrix(eye,target,aspect){const z=norm(sub(eye,target)),x=norm(cross([0,1,0],z)),y=cross(z,x);const view=new Float32Array([x[0],y[0],z[0],0,x[1],y[1],z[1],0,x[2],y[2],z[2],0,-dot(x,eye),-dot(y,eye),-dot(z,eye),1]);const f=1/Math.tan(.56/2),near=.1,far=350;const projection=new Float32Array([f/aspect,0,0,0,0,f,0,0,0,0,far/(near-far),-1,0,0,far*near/(near-far),0]);return multiply(projection,view);}
export function cylinder(out,a,b,r,color,r2=r*.82,sides=7){const axis=norm(sub(b,a)),u=norm(cross(axis,Math.abs(axis[1])>.9?[1,0,0]:[0,1,0])),v=cross(axis,u);const point=(t,angle)=>{const dir=u.map((x,i)=>x*Math.cos(angle)+v[i]*Math.sin(angle));return [...a.map((x,i)=>x+(b[i]-x)*t+dir[i]*(t?r2:r)),...dir,...color];};for(let i=0;i<sides;i++){const a0=i/sides*Math.PI*2,a1=(i+1)/sides*Math.PI*2;out.push(...point(0,a0),...point(1,a0),...point(1,a1),...point(0,a0),...point(1,a1),...point(0,a1));}}

export function lightMatrix(){
 const eye=[95,70,70],target=[36,0,24],z=norm(sub(eye,target)),x=norm(cross([0,1,0],z)),y=cross(z,x);
 const v=new Float32Array([x[0],y[0],z[0],0,x[1],y[1],z[1],0,x[2],y[2],z[2],0,-dot(x,eye),-dot(y,eye),-dot(z,eye),1]);
 const r=55,near=1,far=180;const p=new Float32Array([1/r,0,0,0,0,1/r,0,0,0,0,1/(near-far),0,0,0,near/(near-far),1]);return multiply(p,v);
}

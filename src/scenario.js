// vegetationDragMultiplier: illustrative subgrid wake/interference correction to Cd;
// it affects momentum drag only, never water or sediment mass. Not field-calibrated.
export const CONFIG={nx:120,ny:80,dx:0.6,dt:0.018,g:9.81,dry:0.002,friction:0.008,cd:2.0,vegetationDragMultiplier:8,settling:0.004,erosion:0.003,tauE:0.16,tauD:0.12,rhoBulk:900,period:9,concentration:0.12};
export function bedAt(x,z){return -1.65+2.05*x/72+0.045*Math.sin(z*.16)*Math.sin(x*.085)+0.025*Math.sin(z*.49+x*.13);}
export function rng(seed=831){return ()=>{seed=(Math.imul(1664525,seed)+1013904223)>>>0;return seed/4294967296;};}
export function makeForest(layout="standard"){const rand=rng(),trees=[],segments=[],dense=layout!=="standard",rows=layout==="restoration"?12:dense?6:4,columns=dense?16:12;for(let row=0;row<rows;row++)for(let col=0;col<columns;col++){const x=(layout==="restoration"?30:layout==="wide"?37:45)+row*(layout==="restoration"?1.8:layout==="wide"?3.9:dense?2.3:3.6)+(rand()-.5)*(dense?.5:1.5),z=(dense?2:3)+col*(dense?2.8:3.8)+((layout==="restoration"||layout==="staggered"||layout==="wide")?(row%2)*1.4:0)+(rand()-.5)*(dense?.4:1.4),y=bedAt(x,z),scale=.8+rand()*.4,angle=rand()*Math.PI*2;const tree={x,y,z,scale,angle,id:trees.length};trees.push(tree);const add=(a,b,r)=>segments.push({a,b,r,tree:tree.id});add([x,y+.65,z],[x+.1,y+3.9*scale,z+.06],.12*scale);for(let root=0;root<8;root++){const ang=angle+root*Math.PI/4+(rand()-.5)*.22,length=(1.0+rand()*.85)*scale,dx=Math.cos(ang)*length,dz=Math.sin(ang)*length;const a=[x,y+(1+rand()*.45)*scale,z],b=[x+dx*.52,y+.54*scale,z+dz*.52],c=[x+dx,bedAt(x+dx,z+dz)-.09,z+dz];add(a,b,.045*scale);add(b,c,.035*scale);}}
return {trees,segments};}
// Four vertical bands in world height relative to the initial local bed. Store
// frontal area per unit plan area; dividing by depth is done only in drag.
export const BANDS=[0,.3,.6,1.2,3.6];
export function rasterRoots(segments,c=CONFIG){const field=new Float32Array(c.nx*c.ny*4);for(const {a,b,r} of segments){const len=Math.hypot(...a.map((v,k)=>b[k]-v));const steps=Math.max(4,Math.ceil(len/(c.dx*.12)));for(let k=0;k<steps;k++){const t=(k+.5)/steps,p=a.map((v,i)=>v+(b[i]-v)*t),ix=Math.floor(p[0]/c.dx),iz=Math.floor(p[2]/c.dx);if(ix<0||iz<0||ix>=c.nx||iz>=c.ny)continue;const height=p[1]-bedAt((ix+.5)*c.dx,(iz+.5)*c.dx);for(let band=0;band<4;band++)if(height>=BANDS[band]&&height<BANDS[band+1])field[(iz*c.nx+ix)*4+band]+=2*r*len/steps/(c.dx*c.dx);}}
return field;}
export function initialState(c=CONFIG,tide=0){const out=new Float32Array(c.nx*c.ny*12);for(let z=0;z<c.ny;z++)for(let x=0;x<c.nx;x++){const i=(z*c.nx+x)*12,b=bedAt((x+.5)*c.dx,(z+.5)*c.dx),h=Math.max(0,tide-b);out[i]=h;out[i+3]=h*c.concentration;out[i+4]=b;out[i+7]=b;}
return out;}

// Root resistance derived from the supplied GLB's actual lower bark surfaces.
// The azimuth-averaged projected area is a subgrid closure, not resolved CFD.
export async function modelRootField(trees,c=CONFIG,diameterScale=1){
 if(![1,1.5,2].includes(diameterScale))throw Error("Unsupported effective root diameter");
 const response=await fetch('./public/tree/root-surface.bin');if(!response.ok)throw Error('Root geometry could not be loaded');
 const samples=new Float32Array(await response.arrayBuffer()),field=new Float32Array(c.nx*c.ny*4);
 for(const t of trees){const co=Math.cos(t.angle),si=Math.sin(t.angle);for(let i=0;i<samples.length;i+=4){const lx=samples[i]*t.scale*diameterScale,lz=samples[i+2]*t.scale*diameterScale,ly=samples[i+1]*t.scale;const x=t.x+lx*co-lz*si,z=t.z+lx*si+lz*co,ix=Math.floor(x/c.dx),iz=Math.floor(z/c.dx);if(ix<0||iz<0||ix>=c.nx||iz>=c.ny)continue;const blend=1-Math.min(1,Math.max(0,ly/2));const y=t.y+ly+(bedAt(x,z)-t.y)*blend;const h=y-bedAt((ix+.5)*c.dx,(iz+.5)*c.dx);for(let band=0;band<4;band++)if(h>=BANDS[band]&&h<BANDS[band+1])field[(iz*c.nx+ix)*4+band]+=samples[i+3]*t.scale*t.scale*diameterScale/(c.dx*c.dx);}}
 return field;
}

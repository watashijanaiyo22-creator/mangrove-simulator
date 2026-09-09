"""Create a derived upper-tree vertex-colour mesh. Original GLB remains intact.
Nice2meetU2 / Mangrove Tree / CC BY 4.0. Root geometry is replaced in runtime.
"""
import struct,json,io
from pathlib import Path
import numpy as np
from PIL import Image
base=Path(__file__).resolve().parent.parent
b=(base/'mangrove_tree.glb').read_bytes();length=struct.unpack_from('<I',b,12)[0];j=json.loads(b[20:20+length]);binary=b[28+length:]
def accessor(i):
 a=j['accessors'][i];v=j['bufferViews'][a['bufferView']];dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[a['componentType']];size={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']];return np.ndarray((a['count'],size),dtype=dtype,buffer=binary,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dtype).itemsize*size),np.dtype(dtype).itemsize)).copy()
out=[]
for mi in [0,1]:
 p=j['meshes'][mi]['primitives'][0];pos=accessor(p['attributes']['POSITION']);normal=accessor(p['attributes']['NORMAL']);uv=accessor(p['attributes']['TEXCOORD_0']);inds=accessor(p['indices']).reshape(-1,3);mat=j['materials'][p['material']];tex=j['textures'][mat['pbrMetallicRoughness']['baseColorTexture']['index']];view=j['bufferViews'][j['images'][tex['source']]['bufferView']];img=np.asarray(Image.open(io.BytesIO(binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']])).convert('RGB'))/255
 for tri in inds:
  if pos[tri,1].min()<500:continue
  for v in tri:
   point=pos[v]*.0045;point[0]-=.45
   u=uv[v];color=img[int(u[1]%1*img.shape[0])%img.shape[0],int(u[0]%1*img.shape[1])%img.shape[1]]
   if mi==1:color=color*np.array([.72,.86,.65])
   out.append([*point,*normal[v],*color])
a=np.asarray(out,dtype='<f4');(base/'public/canopy.bin').write_bytes(a.tobytes());(base/'public/canopy.json').write_text(json.dumps({'vertices':len(a),'stride':36,'source':'Nice2meetU2 — Mangrove Tree','license':'CC-BY-4.0','changes':'Upper geometry selected, scale adjusted, colour textures baked to vertices; lower trunk and roots replaced by shared procedural geometry.'},indent=2)+'\n');print(len(a),'canopy vertices')

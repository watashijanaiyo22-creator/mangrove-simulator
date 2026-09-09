"""Extract the supplied GLB's complete bark/root and leaf meshes and original maps.
No geometry is deleted or simplified except the unrelated ground plane.
Normals/UVs/tangents preserved. Output units use a declared uniform 0.0045 scale.
"""
import struct,json,math,zipfile,io
from PIL import Image
from pathlib import Path
import numpy as np
base=Path(__file__).resolve().parent.parent
raw=(base/'mangrove_tree.glb').read_bytes();length=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+length]);binary=raw[28+length:];dest=base/'public/tree';dest.mkdir(exist_ok=True)
def accessor(i):
 a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[a['componentType']];size={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']];return np.ndarray((a['count'],size),dtype=dtype,buffer=binary,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dtype).itemsize*size),np.dtype(dtype).itemsize)).copy()
for i,img in enumerate(g['images']):
 v=g['bufferViews'][img['bufferView']];(dest/f'image-{i}.png').write_bytes(binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']])
with zipfile.ZipFile(base/'mangrove-tree.zip') as archive:
 originalLeaf=Image.open(io.BytesIO(archive.read('textures/SM_MangroveTree_Color.png'))).convert('RGBA').transpose(Image.Transpose.FLIP_TOP_BOTTOM)
alpha=np.asarray(originalLeaf.getchannel('A'))/255
parts=[];samples=[]
for mi,label in [(0,'bark'),(1,'leaves')]:
 p=g['meshes'][mi]['primitives'][0];attrs=p['attributes'];pos=accessor(attrs['POSITION'])*.0045;pos[:,1]-=.0982324
 normal=accessor(attrs['NORMAL']);uv=accessor(attrs['TEXCOORD_0']);tangent=accessor(attrs['TANGENT']);idx=accessor(p['indices']).reshape(-1,3)
 data=np.concatenate([pos,normal,uv,tangent],axis=1)[idx.reshape(-1)].astype('<f4');(dest/f'{label}.bin').write_bytes(data.tobytes());mat=g['materials'][p['material']];pbr=mat['pbrMetallicRoughness'];tex=lambda t:'image-'+str(g['textures'][t['index']]['source'])+'.png';parts.append({'name':label,'vertices':len(data),'stride':48,'color':tex(pbr['baseColorTexture']),'normal':tex(mat['normalTexture']),'arm':tex(pbr['metallicRoughnessTexture']) if 'metallicRoughnessTexture' in pbr else None,'roughness':pbr.get('roughnessFactor',1),'alphaMode':mat.get('alphaMode','OPAQUE')})
 if mi in (0,1):
  for tri in idx:
   a,b,c=pos[tri];edge=np.cross(b-a,c-a);area=np.linalg.norm(edge)*.5
   if area<1e-9 or min(a[1],b[1],c[1])>3.6:continue
   # Direction-averaged horizontal projected surface area for a closed root:
   # integral |n dot horizontalDirection|/2 averaged over azimuth = |n_xz|/pi.
   projection=area*np.linalg.norm(edge[[0,2]])/np.linalg.norm(edge)/math.pi
   count=max(1,math.ceil(max(np.linalg.norm(b-a),np.linalg.norm(c-a),np.linalg.norm(b-c))/.09))
   for u in range(count):
    for v in range(count-u):
     s=(u+1/3)/count;t=(v+1/3)/count;point=a+(b-a)*s+(c-a)*t;texuv=uv[tri[0]]+(uv[tri[1]]-uv[tri[0]])*s+(uv[tri[2]]-uv[tri[0]])*t;coverage=1 if mi==0 else alpha[int(texuv[1]%1*alpha.shape[0]),int(texuv[0]%1*alpha.shape[1])];samples.append([*point,projection*coverage/(count*count)])
     if v<count-u-1:
      s=(u+2/3)/count;t=(v+2/3)/count;point=a+(b-a)*s+(c-a)*t;texuv=uv[tri[0]]+(uv[tri[1]]-uv[tri[0]])*s+(uv[tri[2]]-uv[tri[0]])*t;coverage=1 if mi==0 else alpha[int(texuv[1]%1*alpha.shape[0]),int(texuv[0]%1*alpha.shape[1])];samples.append([*point,projection*coverage/(count*count)])
np.asarray(samples,dtype='<f4').tofile(dest/'root-surface.bin');(dest/'model.json').write_text(json.dumps({'source':g['asset']['extras'],'parts':parts,'scale':.0045,'verticalOffset':-.0982324,'rootSurfaceSamples':len(samples),'changes':'Uniform scale and ground alignment only; original complete roots/bark/leaves and original texture bytes preserved. Ground plane excluded.'},indent=2)+'\n');print(parts);print(len(samples),'root surface samples')

# The downloaded GLB lost the original leaf/card alpha. Restore it from the
# supplied source PNG, vertically flipped to match the exported glTF UV layout.
from PIL import Image
if True:
 original=originalLeaf
 exported=original.resize((2048,2048),Image.Resampling.LANCZOS)
 exported.save(dest/'leaves-restored.png')
 meta=json.loads((dest/'model.json').read_text());meta['parts'][1]['color']='leaves-restored.png';meta['parts'][1]['alphaMode']='MASK';meta['changes']+=' Leaf/card alpha restored from supplied original PNG (UV-aligned vertical flip).';(dest/'model.json').write_text(json.dumps(meta,indent=2)+'\n')
 print('Restored original leaf alpha')

# Also provide a corrected GLB with the complete original scene, including its
# ground plane. Geometry/accessors are unchanged; only leaf texture+alpha repaired.
if (dest/'leaves-restored.png').exists():
 png=(dest/'leaves-restored.png').read_bytes();payload=bytearray(binary)
 while len(payload)%4:payload.append(0)
 start=len(payload);payload.extend(png)
 while len(payload)%4:payload.append(0)
 g['bufferViews'].append({'buffer':0,'byteOffset':start,'byteLength':len(png)})
 g['images'][3]['bufferView']=len(g['bufferViews'])-1
 g['materials'][1]['alphaMode']='MASK';g['materials'][1]['alphaCutoff']=.4
 g['buffers'][0]['byteLength']=len(payload)
 js=json.dumps(g,separators=(',',':')).encode()
 while len(js)%4:js+=b' '
 total=12+8+len(js)+8+len(payload)
 (dest/'mangrove-restored.glb').write_bytes(struct.pack('<III',0x46546c67,2,total)+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(payload),0x004e4942)+payload)
 print('Saved complete corrected GLB, original meshes and scene retained')

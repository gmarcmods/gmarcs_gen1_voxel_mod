local root=debug.getinfo(1,'S').source:sub(2):match('(.+)/tests/') or '.'
local ok,ffi=pcall(require,'ffi');if not ok then print('indexed terrain upload: SKIP (FFI unavailable)');return end
local oldLove=love
love={data={newByteData=function(bytes)
 local d={buf=ffi.new('uint8_t[?]',bytes),bytes=bytes}
 function d:getFFIPointer()return self.buf end
 function d:release()end
 return d
end},graphics={newMesh=function(_,n)
 local m={n=n,vertices=ffi.new('float[?]',n*6),uploads=0}
 function m:setVertices(data,start)
  self.uploads=self.uploads+1;ffi.copy(self.vertices+(start-1)*6,data.buf,data.bytes)
 end
 function m:setDrawRange()end
 function m:setVertexMap(data,kind)
  assert(kind=='uint32');self.indices=ffi.new('uint32_t[?]',data.bytes/4)
  ffi.copy(self.indices,data.buf,data.bytes);self.indexCount=data.bytes/4
 end
 return m
end}}
local scene={shapeAt={},tileAt={},skip={},ground={},runs={},objectQuads={},stamps={},outdoor=true}
for y=0,3 do for x=0,3 do local k=(y+64)*4096+x+64;scene.shapeAt[k]={class='ground',flat=true,h=0};scene.tileAt[k]=1 end end
local modules={Structures={forMap=function()return scene end},TileShape={forMap=function()return {}end,baseClass=function(s)return s.class end},
 BuildBudget={tick=function()end,check=function()end},Voxel3D={FACE_SHADE={1,1,1,1,1,1},FORMAT={},pushQuad=function(out,n)
  for _,i in ipairs({1,2,3,1,3,4})do out[#out+1]=n*4+i end
 end}}
local fn=assert(loadfile(root..'/lib/ChunkMesher.lua'))
setfenv(fn,setmetatable({require=function(name)if name=='src.render.Assets' then return {register=function()end}end;return require(name)end},{__index=_G}))
modules.MeshVisibility=assert(loadfile(root..'/lib/MeshVisibility.lua'))()
local C=fn({require=function(name)return assert(modules[name],name)end})
local map={def={width=1,height=1},tileset={id='TEST',tilesPerRow=16,imageWidth=128,imageHeight=48}}
local function verify()
 local vertices,indices,quads=C.geometry(map,true)
 local mesh=C.build(map,true)
 assert(mesh.n==quads*4,'terrain must upload four unique corners per quad, not six duplicated vertices')
 assert(mesh.indexCount==#indices,'indexed upload must retain every triangle')
 for i,index in ipairs(indices)do
  assert(mesh.indices[i-1]==index-1,'FFI indices must be zero-based with unchanged winding')
  for c=1,6 do assert(math.abs(mesh.vertices[(index-1)*6+c-1]-vertices[index][c])<1e-6,'position, UV or shade changed')end
 end
 return mesh
end
verify()
local q={{0,1,0},{1,1,0},{1,1,1},{0,1,1},u=.1,v=.2,shade=.7,own=true}
for i=1,17000 do scene.objectQuads[i]=q end
assert(verify().uploads>1,'large upload must remain budgeted in slices')
-- Interleave distant quads: index grouping must retain every triangle exactly
-- once with unchanged per-quad winding and real, potentially crossing bounds.
for i=1,17000 do
 local x=(i%2==0) and -200 or 200
 scene.objectQuads[i]={{x,1,0},{x+100,1,0},{x+100,1,1},{x,1,1},u=.1,v=.2,shade=.7,own=true}
end
local mesh=C.build(map,true)
local groups=assert(modules.MeshVisibility.groups(mesh),'large mesh needs spatial ranges')
assert(#groups>=3,'separate distant regions')
local seen={};local total=0
for _,g in ipairs(groups)do
 for offset=g.first-1,g.first+g.count-2,6 do
  local q=tonumber(mesh.indices[offset])/4
  assert(q==math.floor(q) and not seen[q],'each quad once')
  seen[q]=true
  for k,index in ipairs({0,1,2,0,2,3})do assert(mesh.indices[offset+k-1]==q*4+index,'winding unchanged')end
  for corner=0,3 do for axis=1,3 do
   local value=mesh.vertices[(q*4+corner)*6+axis-1]
   assert(value>=g.bounds[axis] and value<=g.bounds[axis+3],'actual corner inside spatial bounds')
  end end
  total=total+6
 end
end
assert(total==mesh.indexCount,'all triangles preserved')
love=oldLove
print('indexed terrain upload: exact triangles/UV/shades, zero-based indices and sliced uploads pass')

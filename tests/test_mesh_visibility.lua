local root=debug.getinfo(1,'S').source:sub(2):match('(.+)/tests/') or '.'
local M=assert(loadfile(root..'/lib/MeshVisibility.lua'))()
local I={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
local function bounds(x,y,z,r)return {x-r,y-r,z-r,x+r,y+r,z+r}end
assert(M.visible(bounds(0,0,0,.5),I),'inside geometry')
assert(not M.visible(bounds(3,0,0,.5),I),'offscreen geometry')
assert(M.visible(bounds(1,0,0,.5),I),'edge crossing geometry')
assert(M.visible(bounds(0,0,0,3),I),'camera inside a large bound')
local move={1,0,0,-3,0,1,0,0,0,0,1,0,0,0,0,1}
assert(M.visible(bounds(3,0,0,.5),move),'neighbor translation')
assert(not M.visible(bounds(0,0,0,.5),move),'translated offscreen bound')
-- World curve drops y by k*(dx^2+dz^2). Keep a high object bent into view.
assert(M.visible({2,4,0,2,5,0},{.1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},1,0,0),'curved geometry')
assert(not M.visible({2,4,0,2,5,0},{.1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}),'flat high geometry')
local mesh={ranges={}}
function mesh:setDrawRange(a,n)self.ranges[#self.ranges+1]={a,n}end
local draws=0
love={graphics={draw=function(m)assert(m==mesh);draws=draws+1 end}}
M.register(mesh,{{first=1,count=6,bounds=bounds(0,0,0,.5)},{first=7,count=6,bounds=bounds(5,0,0,.5)}})
assert(M.draw(mesh,I)==6 and draws==1,'only visible indexed triangles must be submitted')
assert(mesh.ranges[#mesh.ranges][1]==nil,'restore draw range for shadow/water/other consumers')
M.enabled=false;assert(M.draw(mesh,I)==12 and draws==2,'unculled comparison must draw all triangles')
print('mesh visibility: frustum edges, camera inside, translated neighbors, curved world and range restoration PASS')

local vertices,indices={},{}
for _,x in ipairs({0,200,0,-200})do
 for _,c in ipairs({{0,0},{100,0},{100,1},{0,1}})do vertices[#vertices+1]={x+c[1],1,c[2],.1,.2,.7} end
end
local groups=M.index(vertices,4,indices,function()end)
assert(#groups==3 and #indices==24,'portable grouping retains all triangles')
assert(groups[1].count==12 and groups[1].bounds[4]==100,'portable bounds include crossing quads')
local seen={}
for i=1,#indices,6 do
 local q=(indices[i]-1)/4;assert(not seen[q]);seen[q]=true
 for j,k in ipairs({1,2,3,1,3,4})do assert(indices[i+j-1]==q*4+k)end
end
print('portable mesh indexing: exact triangles, grouping and crossing bounds PASS')

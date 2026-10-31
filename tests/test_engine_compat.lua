local root=debug.getinfo(1,'S').source:sub(2):match('(.+)/tests/') or '.'
local tries=0
local fn=assert(loadfile(root..'/lib/EngineCompat.lua'))
setfenv(fn,setmetatable({require=function(name)tries=tries+1;error('removed '..name)end},{__index=_G}))
local compat=fn()
compat.clearGbcFx();compat.clearGbcFx()
assert(tries==1,'removed optional effect should be probed once, without crashing current engines')
assert(compat.setGbcFx and compat.setGbcFx(3)==false,'restoring a removed effect must remain safe')
local levels={}
local chunk=assert(loadfile(root..'/lib/EngineCompat.lua'))
setfenv(chunk,setmetatable({require=function()return {setLevel=function(n)levels[#levels+1]=n end}end},{__index=_G}))
local old=chunk();old.clearGbcFx();assert(old.setGbcFx(3)and levels[1]==0 and levels[2]==3,'legacy clear/restore must retain its original level')
print('Gen 1 renderer: removed legacy GBCFX is optional and lookup is cached PASS')

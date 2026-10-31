-- Current engines use shader presets; older releases still expose GBCFX.
local C={}
local checked,legacy=false,nil
function C.setGbcFx(level)
 if not checked then
  checked=true
  local ok,value=pcall(require,'src.render.GBCFX')
  if ok then legacy=value end
 end
 if legacy and type(legacy.setLevel)=='function' then legacy.setLevel(level);return true end
 return false
end
function C.clearGbcFx()return C.setGbcFx(0)end
return C

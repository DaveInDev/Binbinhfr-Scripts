-- @description Adaptative Horizontal Zoom with Mousewheel
-- @author binbinhfr
-- @version 1.0
-- @links
--   https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + This script can be link to the mousewheel (wit shift for example), to trigger the horizontal zoom,
--     but with an adaptative beheviour, that zooms slowly when the view is large, and quickly if the view is tight.
--   + The strenght of the effect can be modified at the beginning of the script

----------------------------------------------------------------------------------------------------------
speed = 1.0   -- strenght of the effect, set to negative to reverse the effect of the mousewheel

do_debug = false

----------------------------------------------------------------------------------------------------------
if do_debug then
  function print(s)
    gfx.x = 10
    gfx.y = gfx.y + 10
    gfx.printf("%s", s)  
  end 
  
  function msg(param, clr) 
    if clr then reaper.ClearConsole() end 
    reaper.ShowConsoleMsg(tostring(param).."\n") 
  end
else
  function print(s)
  end 
  
  function msg(param, clr) 
  end
end

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

function main()
  local is_new,name,sec,cmd,rel,res,val_wheel = reaper.get_action_context()
  local value
  
  if(val_wheel > 0) then
    value = speed
  else
    value = -speed
  end
  
  pixels_per_second = reaper.GetHZoomLevel()
  value = 0.5*(1+(pixels_per_second-10)/15)*value
  if(value > 0.5) then 
    value = 0.5
  elseif(value < -0.5) then
    value = -0.5
  end
  
  msg("wheel=" .. val_wheel .. " value=" .. value )
  msg("zoom1=" .. pixels_per_second )

  pixels_per_second = pixels_per_second * (1+value)

  reaper.adjustZoom(pixels_per_second,1,true,3)
  msg("zoom2=" .. pixels_per_second )
end

main()



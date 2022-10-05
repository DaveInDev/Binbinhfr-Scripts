-- @description Scale notes velocities
-- @author binbinhfr
-- @version 1.0
-- @links
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + This script scales notes velocities between min and max values (that can be outside the 0..127 range)
--   + Can be used on selected items in the arrange view, or selected notes in the MIDI editor

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
function test(cond,val1,val2)
  if cond then return val1 else return val2 end
end

----------------------------------------------------------------------------------------------------------
function scale_velocities_take(take, all_notes)
  if take and reaper.TakeIsMIDI(take) then
    local _, nb_notes = reaper.MIDI_CountEvts(take)
  
    for n = 0, nb_notes-1 do
      local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, n)
  
      if sel or all_notes then
        vel = math.ceil(0.5 + velo_min + (velo_max-velo_min) * vel / 127)
        if vel > 127 then vel = 127 elseif vel < 0 then vel = 0 end
        reaper.MIDI_SetNote(take, n, sel, muted, startppq, endppq, chan, pitch, vel)      
      end
    end
  end
end

----------------------------------------------------------------------------------------------------------

-- test window before user input...
arrangeview = reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000)
midiview = reaper.JS_Window_FindChild(reaper.MIDIEditor_GetActive(), "midiview", true)
focused = reaper.JS_Window_GetFocus()
    
local retval, retvals_csv = reaper.GetUserInputs("Scale notes velocities", 2, "Min velocity,Max velocity,separator=\n", "0\n127")

if retval then
  velo_min, velo_max = retvals_csv:match("([^\n]+)\n([^\n]+)")
  
  velo_min = tonumber(velo_min)
  velo_max = tonumber(velo_max)
  
  if velo_min and velo_max then
    reaper.PreventUIRefresh(1)
        
    if focused == midiview then 
      msg("mid") 
      local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
      scale_velocities_take(take,false)
    end
    
    if focused == arrangeview then 
      msg("arr") 
      local nb_items = reaper.CountSelectedMediaItems(0)
      
      for i = 0, nb_items-1 do
        local item =  reaper.GetSelectedMediaItem(0, i)
        local nb_takes = reaper.CountTakes(item)
        
        for t = 0, nb_takes-1 do
          local take = reaper.GetTake(item, t)
          scale_velocities_take(take,true)
        end
      end
    end
    
    reaper.Undo_OnStateChange("Scale notes velocities")
        
    reaper.PreventUIRefresh(-1)
        
    reaper.UpdateArrange()
  end
end


  



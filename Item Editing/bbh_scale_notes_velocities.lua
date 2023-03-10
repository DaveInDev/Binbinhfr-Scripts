-- @description Scale notes velocities (selected items or notes)
-- @author binbinhfr
-- @version 1.5
-- @links
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
--    + v1.1 can be used on selected notes in midi editor
--    + v1.3 check JS_Reascript installation
--    + v1.4 better detection of arrangeview
--    + v1.5 add a possible random varition
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + This script scales notes velocities between min and max values (that can be outside the 0..127 range)
--   + and possibly add a random variation to humanize the selection.
--   + Can be used on selected items in the arrange view, or selected notes in the MIDI editor

do_debug = false

----------------------------------------------------------------------------------------------------------
if do_debug then
  function msg(param, clr) 
    if clr then reaper.ClearConsole() end 
    reaper.ShowConsoleMsg(tostring(param).."\n") 
  end
else
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
        vel = math.floor(0.5 + velo_min + (velo_max-velo_min) * vel / 127 + math.random(-velo_rand,velo_rand))
        if vel > 127 then vel = 127 elseif vel < 0 then vel = 0 end
        reaper.MIDI_SetNote(take, n, sel, muted, startppq, endppq, chan, pitch, vel)      
      end
    end
  end
end

----------------------------------------------------------------------------------------------------------

if( reaper.JS_Window_FindChildByID == nil ) then
  reaper.ShowMessageBox("Please install JS_Reascript (using Reapack).", "Error", 0)
  return
end

-- test window before user input...
arrangeview = reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000)
-- midiview = reaper.JS_Window_FindChild(reaper.MIDIEditor_GetActive(), "midiview", true)
focused = reaper.JS_Window_GetFocus()
    
local retval, retvals_csv = reaper.GetUserInputs("Scale notes velocities", 3, "Min velocity,Max velocity,Random variation,separator=\n", "0\n127\n0")

if retval then
  velo_min, velo_max, velo_rand = retvals_csv:match("([^\n]+)\n([^\n]+)\n([^\n]+)")
  
  velo_min = tonumber(velo_min)
  velo_max = tonumber(velo_max)
  velo_rand = tonumber(velo_rand)
  
  msg(string.format("velo %d %d %d",velo_min,velo_max,velo_rand )) 
  
  if velo_min and velo_max then
    reaper.PreventUIRefresh(1)
        
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
      
      reaper.Undo_OnStateChange("Scale notes velocities in selected items")
    else
      msg("mid") 
      local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
      scale_velocities_take(take,false)
      
      reaper.Undo_OnStateChange("Scale selected notes velocities")
    end
 
    reaper.PreventUIRefresh(-1)
        
    reaper.UpdateArrange()
  end
end


  



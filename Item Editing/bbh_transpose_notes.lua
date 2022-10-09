-- @description Transpose selected midi notes by semitones (selected items or notes)
-- @author binbinhfr
-- @version 1.1
-- @links
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
--    + v1.1 can be used on selected notes in midi editor
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + This script transposes selected items by a number of semitones
--   + Can be used on selected items in the arrange view, or selected notes in the MIDI editor

----------------------------------------------------------------------------------------------------------
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

-----------------------------------------------------------------------------------------
function test(cond, val1, val2)
  if cond then return val1 else return val2 end
end

----------------------------------------------------------------------------------------------------------
function transpose_take(take, transpose, all_notes)
  if take then
    if reaper.TakeIsMIDI(take) then
      local _, nb_notes = reaper.MIDI_CountEvts(take)
      for n = 0, nb_notes-1 do
        local retval, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, n)
        if( retval and (all_notes or selected)) then
          pitch = pitch + transpose
          if(pitch > 127) then pitch = 127 elseif( pitch <0) then pitch = 0 end
          reaper.MIDI_SetNote(take, n, selected, muted, startppq, endppq, chan, pitch, vel)
        end
      end
    else
      local t_pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH', t_pitch + transpose)
    end
  end
end

----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- test window before user input...
arrangeview = reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000)
midiview = reaper.JS_Window_FindChild(reaper.MIDIEditor_GetActive(), "midiview", true)
focused = reaper.JS_Window_GetFocus()

local retval, transpose = reaper.GetUserInputs("Transpose notes", 1, "Transpose value (semitones):", "0")
if retval ~= true then return end

msg("", true)

reaper.PreventUIRefresh(1)
    
if focused == midiview then 
  msg("mid") 
  local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  transpose_take(take,transpose,false)
  
  reaper.Undo_OnStateChange("Transpose selected notes")
elseif focused == arrangeview then 
  msg("arr") 
  local nb_items = reaper.CountSelectedMediaItems(0)
  
  for i = 0, nb_items-1 do
    local item =  reaper.GetSelectedMediaItem(0, i)
    local nb_takes = reaper.CountTakes(item)
    
    for t = 0, nb_takes-1 do
      local take = reaper.GetTake(item, t)
      transpose_take(take,transpose,true)
    end
  end
  
  reaper.Undo_OnStateChange("Transpose notes in selected items")
end
    
reaper.PreventUIRefresh(-1)
    
reaper.UpdateArrange()



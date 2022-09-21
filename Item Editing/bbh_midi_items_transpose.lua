-- @description Midi items transpose
-- @author binbinhfr
-- @version 1.0
-- @links
--   Forum Thread https: 
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + This script transposes selected items by a number of semitones

local nb_items = reaper.CountSelectedMediaItems(0)
if nb_items == 0 then return end

local retval, transpose = reaper.GetUserInputs("Transpose", 1, "Transpose, semitones:", "0")
if retval ~= true then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

for i = 0, nb_items-1 do
  local it =  reaper.GetSelectedMediaItem(0, i)
  local takes = reaper.CountTakes(it)
  
  for t = 0, takes-1 do
    local take = reaper.GetTake(it, t)
    if not take then break end
    if reaper.TakeIsMIDI(take) == true then
      local _, notes = reaper.MIDI_CountEvts(take)
      for n = 0, notes-1 do
        local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, n)
        pitch = pitch + transpose
        if(pitch > 127) then pitch = 127 elseif( pitch <0) then pitch = 0 end
        reaper.MIDI_SetNote(take, n, sel, muted, startppq, endppq, chan, pitch, vel)
      end
    else
      local t_pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH', t_pitch + transpose)
    end
  end
  reaper.UpdateItemInProject(it)
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("transpose selected track audio items or midi items notes", -1)



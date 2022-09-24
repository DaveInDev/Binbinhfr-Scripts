-- @description Legato notes of selected items to avoid overlapping notes (but keeping chords)
-- @author binbinhfr
-- @version 1.0
-- @links
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + This script adjusts notes lengths so that they do not overlap.
--   + It respects chords, i.e. notes that starts around the same time (within a time threshold)

----------------------------------------------------------------------------------------------------------
do_debug = false

do_shorten = true
do_extend = false

threshold = 30

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

-----------------------------------------------------------------------------------------
function focus_to_reaper()
  reaper.JS_Window_SetForeground( reaper.GetMainHwnd() )
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

msg("",true)

nb_items = reaper.CountSelectedMediaItems(0)

if nb_items == 0 then
  reaper.MB('No items selected.','Error',0)
  return
end

--local retval, val = reaper.GetUserInputs("Chords detection threshold", 1, "Threshold (MIDI ticks):", "30")
--if retval ~= true then return end
--threshold = val

notes_to_trim = {}

--reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

for n_item = 0, nb_items-1 do
  local item =  reaper.GetSelectedMediaItem(0, n_item)
  local nb_takes = reaper.CountTakes(item)
  local n_take
  
  for n_take = 0, nb_takes-1 do
    local take = reaper.GetTake(item, n_take)
    if not take then break end
    
    if reaper.TakeIsMIDI(take) == true then
      local retval, nb_notes, _ = reaper.MIDI_CountEvts( take )      
      local last_note = -1
      local last_start = 0

      if(retval) then
        for pitch_to_check = 0, 127, 1 do
          notes_to_trim[pitch_to_check] = -1
        end
        
        for n_note = 0, nb_notes-1, 1 do
          local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, n_note)
          
          if(retval) then
            msg("last_start=" .. last_start)            
            msg("note id=" .. n_note .. " start=" .. tostring(startppqpos) .. " end=" .. tostring(endppqpos) .. " pitch=" .. tostring(pitch) .. " vel=" .. tostring(vel))
            
            if( startppqpos - last_start > threshold) then
              -- next note is far from current playing notes, so trim or extend previous ones if necessary
              
              for pitch_to_check = 0, 127, 1 do
                local n_note_to_trim = notes_to_trim[pitch_to_check]
                
                if(n_note_to_trim >= 0) then
                  local retval2, selected2, muted2, startppqpos2, endppqpos2, chan2, pitch2, vel2 = reaper.MIDI_GetNote(take, n_note_to_trim)
                  
                  if(retval2) then
                    if( do_shorten and endppqpos2 > startppqpos ) then
                      reaper.MIDI_SetNote(take,n_note_to_trim,selected2,muted2,startppqpos2,startppqpos,chan2, pitch2, vel2,true)
                      msg("shorten=" .. n_note_to_trim)            
                    elseif( do_extend and endppqpos2 < startppqpos) then
                      reaper.MIDI_SetNote(take,n_note_to_trim,selected2,muted2,startppqpos2,startppqpos,chan2, pitch2, vel2,true)
                      msg("extend=" .. n_note_to_trim)     
                    else
                      msg("untouched=" .. n_note_to_trim)            
                    end
                  end
                end
                
                notes_to_trim[pitch_to_check] = -1
              end
              
              last_start = startppqpos
            end
            
            -- store playing note to trim later...
            notes_to_trim[pitch] = n_note        
          end
          
        end
        
        reaper.MIDI_Sort(take)
      end
    end
  end
  reaper.UpdateItemInProject(item)
end

reaper.Undo_OnStateChange("Legato notes of selected items (keeping chords)")

reaper.PreventUIRefresh(-1)
--reaper.Undo_EndBlock("Legato notes of selected items (keeping chords)",-1)

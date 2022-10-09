-- @description Legato notes to avoid overlapping notes while keeping chords (selected items or notes)
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
--   + This script adjusts notes lengths so that they do not overlap.
--   + It respects chords, i.e. notes that starts around the same time (within a time threshold)
--   + Can be used on selected items in the arrange view, or selected notes in the MIDI editor

----------------------------------------------------------------------------------------------------------
do_debug = false

do_shorten = true
do_extend = true

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

----------------------------------------------------------------------------------------------------------
function legato_take(take, all_notes)
  if take and reaper.TakeIsMIDI(take) then
    local retval, nb_notes, _ = reaper.MIDI_CountEvts( take )      
    local last_note = -1
    local last_start = 0
    local pitch_to_check, n_note
    
    msg("new take")

    if(retval) then
      local notes_to_trim = {}
      
      for pitch_to_check = 0, 127, 1 do
        notes_to_trim[pitch_to_check] = -1
      end
      
      for n_note = 0, nb_notes-1, 1 do
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, n_note)
        
        if(retval and (all_notes or selected)) then
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

-----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

-- test window before user input...
arrangeview = reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000)
midiview = reaper.JS_Window_FindChild(reaper.MIDIEditor_GetActive(), "midiview", true)
focused = reaper.JS_Window_GetFocus()

msg("", true)
    
reaper.PreventUIRefresh(1)
    
if focused == midiview then 
  msg("mid") 
  local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  legato_take(take,false)
  
  reaper.Undo_OnStateChange("Legato selected notes")
elseif focused == arrangeview then 
  msg("arr") 
  local nb_items = reaper.CountSelectedMediaItems(0)
  
  for i = 0, nb_items-1 do
    local item =  reaper.GetSelectedMediaItem(0, i)
    local nb_takes = reaper.CountTakes(item)
    
    for t = 0, nb_takes-1 do
      local take = reaper.GetTake(item, t)
      legato_take(take,true)
    end
  end
  
  reaper.Undo_OnStateChange("Legato notes in selected items")
end
    
reaper.PreventUIRefresh(-1)
    
reaper.UpdateArrange()




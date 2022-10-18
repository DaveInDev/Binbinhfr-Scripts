-- @description Clean selected items of useless sustain pedal CC64
-- @author binbinhfr
-- @version 1.1
-- @links
--   Forum Thread https: https://forum.cockos.com/showthread.php?t=270885
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
--    + v1.1 also remomves redundant 0 or 127 values
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + This script cleans selected items of useless sustain pedal CC64 (between 1 and 126)
--     and also redundant 0 or 127 values

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

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

msg("",true)

nb_items = reaper.CountSelectedMediaItems(0)

if nb_items == 0 then
  reaper.MB('No items selected.','Error',0)
  return
end

--reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

for i = 0, nb_items-1 do
  local item =  reaper.GetSelectedMediaItem(0, i)
  local takes = reaper.CountTakes(item)
  
  for t = 0, takes-1 do
    local take = reaper.GetTake(item, t)
    if not take then break end
    
    if reaper.TakeIsMIDI(take) == true then
      local retval, _, nb_ccs = reaper.MIDI_CountEvts( take )      
      local last_cc64_value = -1

      if(retval) then
        for n_cc = nb_ccs-1, 0, -1 do
          local retval, selected, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take,n_cc)
          if(retval) then
            msg("cc id=" .. n_cc .. " sel=" .. tostring(selected) .. " mut=" .. tostring(muted) .. " msg2=" .. tostring(msg2) .. "msg3=" .. tostring(msg3))
            if(msg2 == 64) then
              if(msg3 < 127 and msg3 >0) then
                reaper.MIDI_DeleteCC(take,n_cc)
                last_n_cc_value = -1
              elseif(msg3 == last_cc64_value) then
                reaper.MIDI_DeleteCC(take,n_cc+1)
                last_cc64_value = msg3
              else
                last_cc64_value = msg3
              end
            else
              last_cc64_value = -1
            end
          end
        end
      end
    end
  end
  reaper.UpdateItemInProject(item)
end

reaper.Undo_OnStateChange("Clean pedal sustain CC64")

reaper.PreventUIRefresh(-1)
--reaper.Undo_EndBlock("Clean pedal sustain CC64",-1)

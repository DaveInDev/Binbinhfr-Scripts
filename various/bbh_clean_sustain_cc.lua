-- @description Clean Sustain Pedal CC
-- @author binbinhfr
-- @version 1.0
-- @links
--   Forum Thread https: https://forum.cockos.com/showthread.php?t=270885
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + This script clean useless MIDI CC 64 between 1 and 126 and keeps 0 and 127.

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
function focus_to_reaper()
  reaper.JS_Window_SetForeground( reaper.GetMainHwnd() )
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

msg("",true)

reaper.Undo_BeginBlock()

nb_items = reaper.CountSelectedMediaItems(0)

for n_item=0, nb_items-1 do
  item = reaper.GetSelectedMediaItem(0,n_item)
  take = reaper.GetActiveTake(item)
  retval, nb_notes, nb_ccs, nb_texts_sysexs = reaper.MIDI_CountEvts( take )
  
  msg("notes=" .. nb_notes .. " ccs=" .. nb_ccs .. " txt/sys=" .. nb_texts_sysexs)
  
  id_cc = -1
  
  for n_cc=nb_ccs-1, 0, -1 do
    retval, selected, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take,n_cc)
      if(retval) then
        msg("cc id=" .. n_cc .. " sel=" .. tostring(selected) .. " mut=" .. tostring(muted) .. " msg2=" .. tostring(msg2) .. "msg3=" .. tostring(msg3))
        if(msg2 == 64 and msg3 < 127 and msg3 >0) then
          reaper.MIDI_DeleteCC(take,n_cc)
        end
      end
  end
end

reaper.Undo_EndBlock("Clean sustain CCs",-1)

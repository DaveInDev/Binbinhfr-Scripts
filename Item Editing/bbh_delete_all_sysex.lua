-- @description Delete all sysex in the project's MIDI items
-- @author binbinhfr
-- @version 1.0
-- @links
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + Delete all sysex in the project's MIDI items


function msg(...) 
  if do_debug then
    local nb = select("#",...) -- retrieve nb of parameters
    if nb == 1 then
      reaper.ShowConsoleMsg(...) 
    elseif nb > 1 then
      reaper.ShowConsoleMsg(string.format(...)) 
    end
    reaper.ShowConsoleMsg("\n") 
  end
end 

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh( 1 )

local nb_items = reaper.CountMediaItems(0)
local item, nb_takes, take

for n = 0, nb_items-1 do
  item = reaper.GetMediaItem(0, n)

  local nb_takes = reaper.GetMediaItemNumTakes(item)

  for t = 0, nb_takes-1 do
    take = reaper.GetTake(item, t)

    if take and reaper.TakeIsMIDI(take) then
      local _, _, _, textsyxevtcnt = reaper.MIDI_CountEvts( take )

      for i = textsyxevtcnt-1, 0, -1  do
        reaper.MIDI_DeleteTextSysexEvt( take, i )
      end 
    end
  end
end

reaper.PreventUIRefresh( -1 )

reaper.UpdateArrange()
reaper.Undo_EndBlock("Delete all sysexs", -1)



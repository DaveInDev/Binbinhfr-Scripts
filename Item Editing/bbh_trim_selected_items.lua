-- @description Trim selected items (deleting any invisible part)
-- @author binbinhfr
-- @version 1.0
-- @links
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + This script trims selected items, deleting invisible parts (audio or midi)
--   + Useful to clean unused audio parts, and reduced audio files sizes.

-------------------------------------------------------------------------------------------------------------------  

local nb_items = reaper.CountSelectedMediaItems(0)

if nb_items == 0 then
  reaper.MB('No items selected.','Error',0)
  return
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

items_old = {}
items_new = {}

for i=1,nb_items do
  items_old[i] = reaper.GetSelectedMediaItem(0,i-1)
end
 
reaper.SelectAllMediaItems(0,0);

for i=1, #items_old  do
  reaper.SetMediaItemSelected(items_old[i],true)
  
  take = reaper.GetActiveTake(items_old[i])
  
  if take then
    take_name = reaper.GetTakeName(take)
  else
    take_name = nil
  end
  
  reaper.Main_OnCommand(40362,0)  -- Glue items, ignoring time selection
  
  items_new[i] = reaper.GetSelectedMediaItem(0,0) -- new id after glue...
  
  if take_name then
    --take_name = take_name .. "-trimmed"
    take = reaper.GetActiveTake(items_new[i])
    if take then
      reaper.GetSetMediaItemTakeInfo_String(take,"P_NAME", take_name, true)
    end
  end

  reaper.SetMediaItemSelected(items_new[i],false)
end

reaper.SelectAllMediaItems(0,0);

for i=1, #items_new do
  reaper.SetMediaItemSelected(items_new[i],true)
end

reaper.Undo_OnStateChange('Trim selected items')
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Trim selected items',-1)

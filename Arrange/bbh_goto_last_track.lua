-- @description Go to last track (skip invisible)
-- @author binbinhfr
-- @version 1.0
-- @links
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
-- @license GPL v3
-- @reaper 6.6x
-- @about
--    + all is in the title

----------------------------------------------------------------------------------------------------------

local track
local idTrack = 1+reaper.CountTracks(0)
  
repeat
  idTrack = idTrack-1
  track = reaper.CSurf_TrackFromID(idTrack,false)
  if( track == reaper.GetMasterTrack() ) then
    vis = (reaper.GetMasterTrackVisibility() & 1 == 1)
  elseif track then
    vis = reaper.IsTrackVisible(track,false)
  end
until( track == nil or vis )

if(track) then
  reaper.SetOnlyTrackSelected(track)
end

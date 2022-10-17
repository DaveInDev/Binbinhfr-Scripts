-- @description Go to previous track or master track (skip invisible)
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

local track = reaper.GetSelectedTrack2(0, 0, true)
local idTrack, track2

if track then 
  idTrack = reaper.CSurf_TrackToID(track, false)
else
  idTrack = 1+reaper.CountTracks(0)
end
  
repeat
  idTrack = idTrack-1
  track2 = reaper.CSurf_TrackFromID(idTrack,false)
  if( track2 == reaper.GetMasterTrack() ) then
    vis = (reaper.GetMasterTrackVisibility() & 1 == 1)
  elseif track2 then
    vis = reaper.IsTrackVisible(track2,false)
  end
until( track2 == nil or vis )

if(track2) then
  reaper.SetOnlyTrackSelected(track2)
end

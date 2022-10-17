-- @description Go to next track (skip invisible)
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
  if( track == reaper.GetMasterTrack() ) then
    idTrack = 0
  else
    idTrack = reaper.CSurf_TrackToID(track, false)
  end
else
  idTrack = 0
end
  
repeat
  idTrack = idTrack+1
  track2 = reaper.CSurf_TrackFromID(idTrack,false)
until( track2 == nil or reaper.IsTrackVisible(track2,false) )

if(track2) then
  reaper.SetOnlyTrackSelected(track2)
end


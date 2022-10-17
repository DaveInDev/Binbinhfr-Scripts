-- @description Go to master track (if visible)
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

if(reaper.GetMasterTrackVisibility() & 1 == 1) then
  reaper.SetOnlyTrackSelected( reaper.GetMasterTrack() )
end

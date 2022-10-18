-- @description Reload project (without saving it)
-- @author binbinhfr
-- @version 1.0
-- @links
--   Repository: https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + This script reloads the current project, without saving it (so take care...)

-------------------------------------------------------------------------------------------------------------------  

retval, project_name = reaper.EnumProjects(-1)

if( project_name ~= nil ) then
  project_name = "noprompt:" .. project_name
  reaper.Main_openProject( project_name )
end

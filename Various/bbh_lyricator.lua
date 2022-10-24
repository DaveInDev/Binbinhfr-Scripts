-- @description Lyricator (display smoothly scrolling lyrics in a separate window)
-- @author binbinhfr
-- @version 1.10
-- @links
--   Forum Thread https://forum.cockos.com/showthread.php?t=270738
--   https://raw.githubusercontent.com/DaveInDev/Binbinhfr-Scripts/master/index.xml
-- @changelog
--    + v1.0 initial release
--    + v1.1 correct default opening path, docking problems
--    + v1.2 pre color next line, 
--           separate auto_resize options for playing and recording
--    + v1.3 possibility to customize colors.
--    + v1.4 option to choose number of visible lines before and after current one.
--    + v1.5 dependancies checking at startup, 
--    + v1.6 directory separator by OS
--    + v1.7 variable length defer loop
--    + v1.8 various code cleaning
--    + v1.10 provides 2 sample files
-- @license GPL v3
-- @reaper 6.6x
-- @provides
--   [projecttpl] bbh_lyricator_sample.rpp
--   [projecttpl] bbh_lyricator_sample.txt
-- @about
--   + This script displays smoothly scrolling lyrics in a separate window.
--   + Lyrics are imported from a TEXT file (one sentence per line, empty lines are excluded) in the form of media items 
--     in a dedicated lyrics track, named "Lyrics" (not case sensitive)
--   + If not existing, this track is automaticaly created.
--   + By default, the TEXT file browser points in the project directory.
--   + During import, lyrics can be added at the end of the existing lyrics as new items, or can replace the existing ones.
--   + After import, you can move and resize items to synchronize currently displayed lyrics with the underlying music.
--   + The currently displayed lyric lines depend on the position of the edit or play cursor on the timeline.
--   + By default, the size of the lyrics window becomes bigger when the project is playing, 
--     to easily read the lyrics from your recording position, far from the screen.
--   + On the contrary, when the project is stopped, the window size is reduced to allow easy editing of the tracks underneath.
--   + You can disable this behaviour with the "auto resize" options, if you want.
--   + You can also change the fonts sizes.
--   + You can change the colors of lines, depending on their status (reading, preparing, offline)
--   + You can choose how many lines you want to see before of after the current one.
--   + You can change the position and size of the window in both playing/stopped modes. 
--   + You can change the default duration of a lyric item, and the default duration of the gap between lyric items.
--   + All these choices/options are memorized for the next reaper session.
--   + Note that the first track  called "Lyrics" is taken into account, so you can have several tracks scalled "Lyrics";
--     just put the active one in the upper position.
--   + To avoid useless cpu work, note that, if you modify the lyric track during playback, the display is not updated.
--     you have to stop and resume playback to refresh the lyrics.
--   + Use the context menu (mouse right click).

do_debug = false

----------------------------------------------------------------------------------------------------------
local reaper_version = reaper.GetAppVersion()
reaper_version = tonumber(reaper_version:match("(%d%.%d*)"))

if reaper_version < 6.20 then 
  reaper.MB("Please install Reaper 6.20 or higher\n" ..
    "https://www.reaper.fm/download.php",
    "Installation",0) 
  return 
end

if( reaper.CF_GetSWSVersion == nil or tonumber(reaper.CF_GetSWSVersion():match("(%d%.%d*)")) < 2.0) then
  reaper.ShowMessageBox("Please install SWS 2.12 or higher (using ReaPack ?).\n" ..
    "https://www.sws-extension.org/\n", 
    "Installation", 0)
  return
end

if reaper.JS_ReaScriptAPI_Version == nil or reaper.JS_ReaScriptAPI_Version() < 1.3 then 
  reaper.MB("Please install JS-extension-plugin 1.3 or higher.\n" ..
    "https://forum.cockos.com/showthread.php?t=212174\n" ..
    "https://github.com/juliansader/ReaExtensions/tree/master/js_ReaScriptAPI/\n",
    "Installation",0) 
  return 
end

if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
  dir_separator = "\\"
else
  dir_separator = "/"
end

----------------------------------------------------------------------------------------------------------
extension = "bbh_lyricator"
win_title = {"Lyricator (stopped)", "Lyricator (playing)"}

lyric_duration = 2.0
lyric_gap = 1.0
win_dock = 0
win_w = {500,1000}
win_h = {115,290}
win_x = {200,250}
win_y = {200,250}
win_font_size = {18,48}
win_font_height = {18,48}
win_idx = 1
auto_resize_playing = 1
auto_resize_recording = 1

track_lyrics = nil
track_lyrics_name = "Lyrics"

color_offline = {0.55,0.55,0.5}
color_preparing = {0.6,0.85,0.6}
color_reading = {1,1,1}

nb_lines_before = 3
nb_lines_after = 3

path_default = ""

count_defer = 0.0
count_defer_max = 15.0
count_defer_max1 = count_defer_max-2.0
count_defer_max2 = count_defer_max+2.0

playstate = -1
last_playstate = -1
is_running = false
is_playing = false
is_recording = false
ask_reset = false

lyrics = {}
starts = {}
ends = {}
nb_lyrics = -1

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
function set_font(n, font_size)
  win_font_size[n] = font_size
  gfx.setfont(n,"verdana",font_size)
  win_font_height[n] = gfx.texth
end

-----------------------------------------------------------------------------------------
function msg_wins(title)
  msg(title)
  msg("dur " .. lyric_duration .. " gap " .. lyric_gap)
  msg("dock " .. win_dock .. " .. " .. auto_resize_playing .. " auto_resize_recording " .. auto_resize_recording)
  msg("win[1] ".. win_w[1] .. "," .. win_h[1] .. " " .. win_x[1] .. "," .. win_y[1] )
  msg("font[1] " .. win_font_size[1])
  msg("win[2] ".. win_w[2] .. "," .. win_h[2] .. " " .. win_x[2] .. "," .. win_y[2] )
  msg("font[2] " .. win_font_size[2])
end

-----------------------------------------------------------------------------------------
function get_ext_states()
  lyric_duration = tonumber(reaper.GetExtState(extension,"lyric_duration")) or lyric_duration
  lyric_gap = tonumber(reaper.GetExtState(extension,"lyric_gap")) or lyric_gap

  win_dock = tonumber(reaper.GetExtState(extension,"win_dock")) or win_dock
  auto_resize_playing = tonumber(reaper.GetExtState(extension,"auto_resize_playing")) or auto_resize_playing
  auto_resize_recording = tonumber(reaper.GetExtState(extension,"auto_resize_recording")) or auto_resize_recording

  win_w[1] = tonumber(reaper.GetExtState(extension,"win_w1")) or win_w[1]
  win_h[1] = tonumber(reaper.GetExtState(extension,"win_h1")) or win_h[1]
  win_x[1] = tonumber(reaper.GetExtState(extension,"win_x1")) or win_x[1]
  win_y[1] = tonumber(reaper.GetExtState(extension,"win_y1")) or win_y[1]
    
  win_w[2] = tonumber(reaper.GetExtState(extension,"win_w2")) or win_w[2]
  win_h[2] = tonumber(reaper.GetExtState(extension,"win_h2")) or win_h[2]
  win_x[2] = tonumber(reaper.GetExtState(extension,"win_x2")) or win_x[2]
  win_y[2] = tonumber(reaper.GetExtState(extension,"win_y2")) or win_y[2]
    
  set_font(1,tonumber(reaper.GetExtState(extension,"win_font_size1")) or win_font_size[1])
  set_font(2,tonumber(reaper.GetExtState(extension,"win_font_size2")) or win_font_size[2])

  color_reading[1] = tonumber(reaper.GetExtState(extension,"color_reading1")) or color_reading[1]
  color_reading[2] = tonumber(reaper.GetExtState(extension,"color_reading2")) or color_reading[2]
  color_reading[3] = tonumber(reaper.GetExtState(extension,"color_reading3")) or color_reading[3]
  
  color_preparing[1] = tonumber(reaper.GetExtState(extension,"color_preparing1")) or color_preparing[1]
  color_preparing[2] = tonumber(reaper.GetExtState(extension,"color_preparing2")) or color_preparing[2]
  color_preparing[3] = tonumber(reaper.GetExtState(extension,"color_preparing3")) or color_preparing[3]
  
  color_offline[1] = tonumber(reaper.GetExtState(extension,"color_offline1")) or color_offline[1]
  color_offline[2] = tonumber(reaper.GetExtState(extension,"color_offline2")) or color_offline[2]
  color_offline[3] = tonumber(reaper.GetExtState(extension,"color_offline3")) or color_offline[3]
  
  nb_lines_before = tonumber(reaper.GetExtState(extension,"nb_lines_before")) or nb_lines_before
  nb_lines_after = tonumber(reaper.GetExtState(extension,"nb_lines_after")) or nb_lines_after
  
  msg_wins("init")
end

-----------------------------------------------------------------------------------------
function raz_extstate()
  --reaper.SetExtState(extension,"","",true)

  reaper.DeleteExtState(extension,"lyric_duration",true)
  reaper.DeleteExtState(extension,"lyric_gap",true)
  
  reaper.DeleteExtState(extension,"win_dock",true)
  reaper.DeleteExtState(extension,"auto_resize_playing",true)
  reaper.DeleteExtState(extension,"auto_resize_recording",true)

  reaper.DeleteExtState(extension,"win_w1",true)
  reaper.DeleteExtState(extension,"win_h1",true)
  reaper.DeleteExtState(extension,"win_x1",true)
  reaper.DeleteExtState(extension,"win_y1",true)  
  
  reaper.DeleteExtState(extension,"win_w2",true)
  reaper.DeleteExtState(extension,"win_h2",true)
  reaper.DeleteExtState(extension,"win_x2",true)
  reaper.DeleteExtState(extension,"win_y2",true)  
  
  reaper.DeleteExtState(extension,"win_font_size1",true)
  reaper.DeleteExtState(extension,"win_font_size2",true)
  
  reaper.DeleteExtState(extension,"color_reading1",true)
  reaper.DeleteExtState(extension,"color_reading2",true)
  reaper.DeleteExtState(extension,"color_reading3",true)
  
  reaper.DeleteExtState(extension,"color_preparing1",true)
  reaper.DeleteExtState(extension,"color_preparing2",true)
  reaper.DeleteExtState(extension,"color_preparing3",true)
  
  reaper.DeleteExtState(extension,"color_offline1",true)
  reaper.DeleteExtState(extension,"color_offline2",true)
  reaper.DeleteExtState(extension,"color_offline3",true)

  reaper.DeleteExtState(extension,"nb_lines_before",true)
  reaper.DeleteExtState(extension,"nb_lines_after",true)
 
  reaper.SetProjExtState(0,extension,"","")
end

-----------------------------------------------------------------------------------------
function quit()
  if( ask_reset ) then
    raz_extstate()
  else
    local d,x,y,w,h = gfx.dock(-1, 0, 0, 0, 0)
  
    win_dock = d
    if(win_dock == 0) then
      -- only if not docked, retrieve current window size
      win_x[win_idx], win_y[win_idx], win_w[win_idx], win_h[win_idx] = x,y,w,h
    end
    
    reaper.SetExtState(extension,"lyric_duration",lyric_duration,true)
    reaper.SetExtState(extension,"lyric_gap",lyric_gap,true)
    
    reaper.SetExtState(extension,"win_dock",win_dock,true)
    reaper.SetExtState(extension,"auto_resize_playing",auto_resize_playing,true)
    reaper.SetExtState(extension,"auto_resize_recording",auto_resize_recording,true)
    
    reaper.SetExtState(extension,"win_w1",win_w[1],true)
    reaper.SetExtState(extension,"win_h1",win_h[1],true)
    reaper.SetExtState(extension,"win_x1",win_x[1],true)
    reaper.SetExtState(extension,"win_y1",win_y[1],true) 
    
    reaper.SetExtState(extension,"win_w2",win_w[2],true)
    reaper.SetExtState(extension,"win_h2",win_h[2],true)
    reaper.SetExtState(extension,"win_x2",win_x[2],true)   
    reaper.SetExtState(extension,"win_y2",win_y[2],true) 
    
    reaper.SetExtState(extension,"win_font_size1",win_font_size[1],true)
    reaper.SetExtState(extension,"win_font_size2",win_font_size[2],true)

    reaper.SetExtState(extension,"color_reading1",color_reading[1],true)
    reaper.SetExtState(extension,"color_reading2",color_reading[2],true)
    reaper.SetExtState(extension,"color_reading3",color_reading[3],true)
    
    reaper.SetExtState(extension,"color_preparing1",color_preparing[1],true)
    reaper.SetExtState(extension,"color_preparing2",color_preparing[2],true)
    reaper.SetExtState(extension,"color_preparing3",color_preparing[3],true)
    
    reaper.SetExtState(extension,"color_offline1",color_offline[1],true)
    reaper.SetExtState(extension,"color_offline2",color_offline[2],true)
    reaper.SetExtState(extension,"color_offline3",color_offline[3],true)
    
    reaper.SetExtState(extension,"nb_lines_before",nb_lines_before,true)
    reaper.SetExtState(extension,"nb_lines_after",nb_lines_after,true)
  end
  
  msg_wins("quit")  
  
  gfx.quit()
end

-----------------------------------------------------------------------------------------
function find_lyrics_track()
  local track, retval, track_name
  
  for track_idx = 0, reaper.CountTracks(0) - 1 do
    track = reaper.GetTrack(0, track_idx)
    retval, track_name = reaper.GetTrackName(track, "")
    if( retval and string.lower(track_name) == string.lower(track_lyrics_name) ) then
      return track
    end
  end
  
  return null
end

-----------------------------------------------------------------------------------------
function select_lyrics_track()
  local track, retval, track_name
  
  for track_idx = 0, reaper.CountTracks(0) - 1 do
    track = reaper.GetTrack(0, track_idx)
    retval, track_name = reaper.GetTrackName(track, "")
    reaper.SetTrackSelected(track, (retval and string.lower(track_name) == string.lower(track_lyrics_name)) )
  end
end

-----------------------------------------------------------------------------------------
function read_lyrics_from_items()
  local item, retval

  track_lyrics = find_lyrics_track()
  
  lyrics = {}
  starts = {}
  ends = {}
  nb_lyrics = 0
  
  if(track_lyrics) then
    nb_lyrics =  reaper.CountTrackMediaItems(track_lyrics)
    
    for n_item = 0, nb_lyrics-1 do
      item = reaper.GetTrackMediaItem(track_lyrics, n_item)
      if item ~= nil then
        retval, lyrics[n_item] = reaper.GetSetMediaItemInfo_String(item,"P_NOTES","",false)
        starts[n_item] = reaper.GetMediaItemInfo_Value(item, "D_POSITION" )
        ends[n_item] =  starts[n_item] + reaper.GetMediaItemInfo_Value(item, "D_LENGTH" )
      end
    end
  else
    nb_lyrics = 0
  end
end

-----------------------------------------------------------------------------------------
function find_lyrics_track_end()
  local item
  local t_end = 0

  if(track_lyrics) then
    nb_lyrics =  reaper.CountTrackMediaItems(track_lyrics)
    
    if(nb_lyrics > 0) then
      item = reaper.GetTrackMediaItem(track_lyrics, nb_lyrics-1)
      if item ~= nil then
        t_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION" ) + reaper.GetMediaItemInfo_Value(item, "D_LENGTH" )
      end
    end
  end
  
  msg(t_end)
  
  return(t_end)
end

-----------------------------------------------------------------------------------------
function import_lyrics(do_add)
  local item, n_item, take, n_take
  local track_created = false
  local path = ""
  
  local retval, filename = reaper.EnumProjects(-1, '')
  
  if(retval) then
    msg("project:" .. filename)
    if(filename == "") then
      path = path_default
    else
      path = filename:match("^(.+[\\/])") 
    end
    msg("path:" .. path)
  end
  
  if(do_add) then
    retval, filename = reaper.GetUserFileNameForRead(path, "Open a lyrics text file (add lyrics)", "*.txt" )
  else
    retval, filename = reaper.GetUserFileNameForRead(path, "Open a lyrics text file (replace lyrics)", "*.txt" )
  end
  
  if(retval) then
    reaper.Undo_BeginBlock()

    track_lyrics = find_lyrics_track()
    
    if( not track_lyrics ) then
      reaper.InsertTrackAtIndex(0,false)
      track_lyrics = reaper.GetTrack(0,0)
      reaper.GetSetMediaTrackInfo_String(track_lyrics,"P_NAME",track_lyrics_name,true)
      if(track_lyrics) then track_created = true end
    end
    
    if(track_lyrics) then
      msg("importing:" .. filename)
      
      io.input(filename)
      
      local t = 0
      local p, d
      local lyrics_file = {}
  
      for l in io.lines() do
        if(l ~= "") then
          table.insert(lyrics_file, l)
        end
      end
      
      io.close()
      
      if(do_add) then
        -- add after last item
        t = find_lyrics_track_end()
        if( t > 0 ) then t = t + lyric_gap end
        msg(t)
        
        for i, l in ipairs(lyrics_file) do 
          msg("[" .. l .. "]")
        
          item = reaper.AddMediaItemToTrack(track_lyrics)
          reaper.SetMediaItemPosition(item,t,true)
          reaper.SetMediaItemLength(item,lyric_duration,true)
          reaper.GetSetMediaItemInfo_String(item,"P_NOTES",l,true)
          t = t + lyric_duration + lyric_gap
        end
      else
        -- replace existing items and complete with new items if needed
        nb_lyrics =  reaper.CountTrackMediaItems(track_lyrics)
        n_item = 0
  
        for i, l in ipairs(lyrics_file) do 
          msg("[" .. l .. "]")
          
          if( n_item < nb_lyrics ) then
            item = reaper.GetTrackMediaItem(track_lyrics, n_item)
            if item ~= nil then
              p = reaper.GetMediaItemInfo_Value(item, "D_POSITION" )
              d =  reaper.GetMediaItemInfo_Value(item, "D_LENGTH" )
              if(reaper.CountTakes(item) > 0 ) then
                reaper.DeleteTrackMediaItem(track_lyrics, item)
                item = reaper.AddMediaItemToTrack(track_lyrics)
                if(item) then
                  reaper.SetMediaItemPosition(item,p,true)
                  reaper.SetMediaItemLength(item,d,true)
                  reaper.GetSetMediaItemInfo_String(item,"P_NOTES", l,true)
                end
              else
                reaper.GetSetMediaItemInfo_String(item,"P_NOTES", l,true)
              end
              t = p + d + lyric_gap
            end
          else
            item = reaper.AddMediaItemToTrack(track_lyrics)
            reaper.SetMediaItemPosition(item,t,true)
            reaper.SetMediaItemLength(item,lyric_duration,true)
            reaper.GetSetMediaItemInfo_String(item,"P_NOTES",l,true)
            t = t + lyric_duration + lyric_gap
          end
          
          n_item = n_item + 1
        end      
      end
    end
    
    reaper.Undo_EndBlock("Import lyrics",-1)
  end
  
  reaper.UpdateArrange()
end

-----------------------------------------------------------------------------------------
function ask_color(color)
  local retval, retvals_csv = reaper.GetUserInputs("Color", 3, 
    "Red (0.0 - 0.1),Green (0.0 - 0.1),Blue  (0.0 - 0.1) separator=\n", 
    tonumber(color[1]) .. "\n" .. tonumber(color[2]) .. "\n" .. tonumber(color[3]))

  if(retval) then
    msg(retvals_csv)
    local r, g, b = retvals_csv:match("(.+)\n(.+)\n(.+)")
    
    color[1] = tonumber(r) or color[1]
    color[2] = tonumber(g) or color[2]
    color[3] = tonumber(b) or color[3]
    msg(string.format( "%f,%f,%f", color[1], color[2], color[3]))
  end
end

-----------------------------------------------------------------------------------------
function menu_ctx()
  local menu = ""
  --menu = menu .. "#LYRICATOR"
  menu = menu .. test(is_running,"#","") .. "Import lyrics text file (add)"
  menu = menu .. "|" .. test(is_running,"#","") .. "Import lyrics text file (replace)"
  menu = menu .. "||Lyric media duration (" .. lyric_duration .. "s)"
  menu = menu .. "|Gap between lyric medias (" .. lyric_gap .. "s)"
  menu = menu .. "||" ..test(auto_resize_playing == 1,"!","") ..  test(is_running,"#","") .. "Auto resize (while playing)"
  menu = menu .. "|" .. test(auto_resize_recording == 1,"!","") .. test(is_running,"#","") .. "Auto resize (while recording)"
  menu = menu .. "||Font size while stopped (" .. win_font_size[1] .. "px)" 
  menu = menu .. "|Font size while playing (" .. win_font_size[2] .. "px)" 
  menu = menu .. "||Font color (reading)" 
  menu = menu .. "|Font color (preparing)" 
  menu = menu .. "|Font color (offline)" 
  menu = menu .. "||Number of lines before (" .. nb_lines_before .. ")" 
  menu = menu .. "|Number of lines after (" .. nb_lines_after .. ")" 
  menu = menu .. "||" .. test(is_running,"#","") .. "Reset to default values, sizes and positions "
  
  msg(menu)

  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local choice = gfx.showmenu(menu)
  local retval, value
  
  msg("choice ".. choice)
  
  if choice == 1 then
    import_lyrics(true)
    
  elseif choice == 2 then
    import_lyrics(false)
    
  elseif choice == 3 then
    retval, value = reaper.GetUserInputs("Lyric media duration", 1, "Duration", tostring(lyric_duration))
    if(retval) then 
      value = tonumber(value) or lyric_duration
      if(value < 0.1) then value = 0.1 end
      if(value > 20.0) then value = 20.0 end
      lyric_duration = value
    end
    
  elseif choice == 4 then
    retval, value = reaper.GetUserInputs("Gap between lyric medias", 1, "Duration", tostring(lyric_gap))
    if(retval) then 
      value = tonumber(value) or lyric_gap
      if(value < 0.1) then value = 0.1 end
      if(value > 20.0) then value = 20.0 end
      lyric_gap = value
    end
    
  elseif choice == 5 then
    if( not is_running ) then
      auto_resize_playing = 1 - auto_resize_playing
    end
    
  elseif choice == 6 then
    if( not is_running ) then
      auto_resize_recording = 1 -  auto_resize_recording
    end
    
  elseif choice == 7 then
    retval, value = reaper.GetUserInputs("Font size while stopped", 1, "font size", tostring(win_font_size[1]))
    if(retval) then 
      value = tonumber(value) or win_font_size[1]
      if(value < 8) then value = 8 end
      if(value > 100) then value = 100 end
      set_font(1,value)
      gfx.setfont(win_idx)
    end
    
  elseif choice == 8 then
    retval, value = reaper.GetUserInputs("Font size while playing", 1, "font size", tostring(win_font_size[2]))
    if(retval) then 
      value = tonumber(value) or win_font_size[2]
      if(value < 8) then value = 8 end
      if(value > 100) then value = 100 end
      set_font(2,value)
      gfx.setfont(win_idx)
    end  
    
  elseif choice == 9 then
    ask_color(color_reading)
    
  elseif choice == 10 then
    ask_color(color_preparing)
    
  elseif choice == 11 then
    ask_color(color_offline)
    
  elseif choice == 12 then
    retval, value = reaper.GetUserInputs("Number of lines before", 1, "number", tostring(nb_lines_before))
    if(retval) then 
      value = tonumber(value) or nb_lines_before
      if(value < 0) then value = 0 end
      if(value > 16) then value = 16 end
      nb_lines_before = value
    end  
    
  elseif choice == 13 then
    retval, value = reaper.GetUserInputs("Number of lines after", 1, "number", tostring(nb_lines_after))
    if(retval) then 
      value = tonumber(value) or nb_lines_after
      if(value < 0) then value = 0 end
      if(value > 16) then value = 16 end
      nb_lines_after = value
    end  
    
  elseif choice == 14 then
    ask_reset = true
  end
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
function main()
  local cursor
  local last_win_idx = win_idx
  local last_win_dock = win_dock
  local x,y,w,h

  count_defer_max = count_defer_max + 0.0329
  if count_defer_max > count_defer_max2 then count_defer_max = count_defer_max1 end
  
  count_defer = count_defer + 1
  if(count_defer >= count_defer_max) then count_defer = 0 end
  
  playstate = reaper.GetPlayState()
  is_running = (playstate & 1 ~= 0)
  is_recording = (playstate & 4 ~= 0)
  is_playing = (playstate & 1 ~= 0) and not is_recording
  
  if( is_running ) then
    -- song running
    cursor = reaper.GetPlayPosition()
    if(nb_lyrics < 0) then
      read_lyrics_from_items()
    end    

    if((is_playing and auto_resize_playing == 1) or (is_recording and auto_resize_recording == 1)) then
      win_idx = 2
    else
      win_idx = 1
    end
  else
    -- song stopped 
    cursor = reaper.GetCursorPosition()
    if(count_defer == 0 or nb_lyrics <= 0) then
      read_lyrics_from_items()
    end
    win_idx = 1
  end

  if(last_playstate == -1) then
     -- first time opening
     gfx.init(win_title[win_idx],win_w[win_idx],win_h[win_idx],win_dock,win_x[win_idx],win_y[win_idx])
     focus_to_reaper()
  else
    win_dock,x,y,w,h = gfx.dock(-1, 0, 0, 0, 0)
  end
  
  if(last_win_dock ~= 0 and win_dock == 0) then
    -- returning from docked state
    gfx.init(win_title[win_idx])
    gfx.init("",win_w[win_idx],win_h[win_idx],win_dock,win_x[win_idx],win_y[win_idx])
  end
  
  if( last_playstate ~= playstate ) then
    -- swapping stopped/playing
    if(last_playstate ~= -1) then
      if(last_win_idx ~= win_idx ) then
        if(win_dock == 0) then
          -- swap window size
          win_x[last_win_idx], win_y[last_win_idx], win_w[last_win_idx], win_h[last_win_idx] = x,y,w,h
          gfx.init(win_title[win_idx])
          gfx.init("",win_w[win_idx],win_h[win_idx],win_dock,win_x[win_idx],win_y[win_idx])
        end
      end
    end
    
    gfx.setfont(win_idx)

    last_playstate = playstate
  end
  
  if( do_debug ) then
    gfx.x = win_w[win_idx] - 6 * win_font_size[win_idx]
    gfx.y = 10
    
    if( is_running ) then
      -- song running
      if(is_recording) then
        gfx.set(1,0.2,0.2)
        gfx.printf("R")
      else
        gfx.set(0.2,1,0.2)
        gfx.printf("P")
      end
    else
      -- song stopped
      gfx.set(0.9,0.9,0.9)
      gfx.printf("S")
    end
    
    gfx.printf("%d/%.2f", count_defer, count_defer_max)
  end
  
  if( nb_lyrics > 0 ) then
    local n_item_cur, start1, start2, end1 
 
    gfx.x = 10
    gfx.y = -win_font_height[win_idx]
    
    n_item_cur = nb_lyrics-1
    start1 = starts[n_item_cur]
    end1 = ends[n_item_cur]
    start2 = start1+end1
    
    for n_item = 0, nb_lyrics-1 do
      if( cursor <= starts[n_item] ) then
        n_item_cur = n_item-1
        if( n_item_cur < 0 ) then
          start1 = 0
          end1 = 0
        else
          start1 = starts[n_item_cur]
          end1 = ends[n_item_cur]
        end
        start2 = starts[n_item]
        break
      end
    end       
    
    if( start1 < start2) then
      gfx.y = gfx.y + win_font_height[win_idx] * (start2 - cursor) / (start2-start1)
    else
      gfx.y = gfx.y + win_font_height[win_idx]
    end 
     
    for n_item = n_item_cur-nb_lines_before, n_item_cur+nb_lines_after do
      if(n_item == n_item_cur and cursor <= end1) then
        gfx.set(color_reading[1],color_reading[2],color_reading[3])
      elseif(n_item == n_item_cur+1 and cursor > end1) then
        gfx.set(color_preparing[1],color_preparing[2],color_preparing[3])
      else
        gfx.set(color_offline[1],color_offline[2],color_offline[3])
      end

      if(n_item < 0) then
        gfx.x = 10
        gfx.y = gfx.y + win_font_height[win_idx]
      elseif(n_item < nb_lyrics) then
        gfx.printf( "%s", lyrics[n_item] )
        gfx.x = 10
        gfx.y = gfx.y + win_font_height[win_idx]
      end
    end
  else
    gfx.set(color_reading[1],color_reading[2],color_reading[3])
    
    gfx.x = 10
    gfx.y = 10
    gfx.printf( "No lyrics found..." )

    gfx.x = 10
    gfx.y = gfx.y + win_font_height[win_idx]
    gfx.printf( "Please import a lyrics text file (right mouse click for menu).")
  end
  
  if( gfx.mouse_cap & 2 ~= 0 ) then
    menu_ctx()
  end

  local c = gfx.getchar()
  if (c >= 0) and (not ask_reset) then
    reaper.defer(main)
  end  
  
  gfx.update()
end

-----------------------------------------------------------------------------------------

msg("",true)

reaper.atexit(quit)

get_ext_states()

retval, path_default = reaper.get_config_var_string("defsavepath")
if(path_default == "" ) then
  path_default = reaper.GetProjectPath()
end
      
path_default = path_default .. dir_separator
msg("path_default=" .. path_default)

main()



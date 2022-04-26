-- @description Mavriq Debugging Tools
-- @version 1.0.0
-- @author Mavriq, Amagalma
-- @about
--   # Mavriq Debugging Tool 
--   Allows you to easily use an interactive debugger with Lua ReaScripts. Currently supports ZeroBrane IDE and plan to support more soon.
--   
--   Now available via Reapack and works on Windows, macos and Linux. 
--   
--   ### Known Bugs
--   On `macos` and `Linux` you MUST have the `Command ID` and `ReaScript Path` columns showing. `Right Click` on the `Action` window and select the appropriate settings.
--
--   ### Thanks
--   * [Amagalma](https://forum.cockos.com/member.php?u=32436) who's script for the original debugging helper script that inspired this version. It saved many coding hours for me.</br>
--   * [daniellumertz](https://forum.cockos.com/member.php?u=121892) foraged on where I gave up and figured out part of the answer to having core.dll live outside the predefined paths.</br>
--   * [Julian Sader](https://forum.cockos.com/member.php?u=14710) for his API which vastly extended the capabilities of scripting.</br>
--   * And of course [cfillion](https://forum.cockos.com/member.php?u=98780) for ReaImGui which is a game changer for the scripting community.</br>
--   * And the countless coders out there who have contributed to the ReaScript community and laid the groundwork for all of us.
-- @donation: https://www.paypal.com/paypalme/mavriqdev
-- @links
--   Forum Thread https://github.com/available_soon
-- @changelog
--   v1.0.0
--    + initial release
-- @provides
--   /Various/Debugging/*.mav
--   /Various/Debugging/*.ttf
--   /Various/Debugging/*.lua


r = reaper
local script_path = "" -- "C:/Users/geoff_obr9bt1/Desktop/reaper/Scripts/Mavriq ReaScript Repository/Various/Debugging/mavriq_test.lua"
local sockets_path = r.GetResourcePath() .. '/Scripts/Mavriq ReaScript Repository/Various/Mavriq-Lua-Sockets/'
local injected_code_path = r.GetResourcePath() ..  '/Scripts/Mavriq ReaScript Repository/Various/Debugging/ZeroBrane_Injection_Code.mav'
--local match_expr = "%-%- start %-%-%c+[% %w%p]*%c+[% %w%p]*%c+[% %w%p]*%c+[% %w%p]*%c+[% %w%p]*%c+[% %w%p]*%c+[% %w%p]*%c+[% %w%p]*%c+[% %w%p]*%c+%-%- end %-%-%c+"
local match_expr = "%-%- Start Mavriq Debugging %-%-.+%-%- End Mavriq Debugging %-%-%c+"

local mav_debug = {
   zerobrane_path = "",
   editor_type=   "Internal",
   editor_path =  "",
   code_injected = false,
   script_set =   false,
   script_name = "",
   script_path = "",
   btn_txt_col =  0xFFFFFFFF,
   wind_rnd =     4,
   frame_rnd =    3,
   item_spc =     7,
   ttl_bg_act =   0xC0BFC0FF,
   ttl_bg =       0xC0BFC0FF,
   wnd_bg =       0xF5F5F5FF,
   pop_bg =       0xF5F5F5FF,
   frame_bg =     0xC0BFC0FF,
   frame_hov =    0x30AD1777,
   btn =          0x30AD17EE,
   btn_hov =      0x3CDA1DFF,
   btn_act =      0x3CDA1DFF,        
   check =        0x3CDA1DFF,
   text =         0x151515FF,
   undock_win_x = 0,
   undock_win_y = 0,
   undock_sz_w =  0,
   undock_sz_h =  0,
}




function Set_Theme()
   r.ImGui_PushFont(ctx,font)
   r.ImGui_PushStyleVar(ctx,   r.ImGui_StyleVar_WindowRounding(), mav_debug.wind_rnd) 
   r.ImGui_PushStyleVar(ctx,   r.ImGui_StyleVar_FrameRounding(),  mav_debug.frame_rnd) 
   r.ImGui_PushStyleVar(ctx,   r.ImGui_StyleVar_ItemSpacing(),    mav_debug.item_spc,mav_debug.item_spc) 
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TitleBgActive(),       mav_debug.ttl_bg_act)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TitleBg(),             mav_debug.ttl_bg)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg() ,           mav_debug.wnd_bg)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PopupBg() ,            mav_debug.pop_bg)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg() ,            mav_debug.frame_bg)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(),      mav_debug.frame_hov)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),              mav_debug.btn)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(),       mav_debug.btn_hov)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),        mav_debug.btn_act)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_CheckMark(),           mav_debug.check)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),                mav_debug.text)
end


function DrawHeader()
   r.ImGui_BeginTable(ctx, "Main Table", 3, r.ImGui_TableFlags_SizingFixedFit())
   r.ImGui_TableSetupColumn(ctx, "1", r.ImGui_TableColumnFlags_WidthStretch(), 305)
   r.ImGui_TableSetupColumn(ctx, "2", r.ImGui_TableColumnFlags_WidthFixed(),22)
   r.ImGui_TableSetupColumn(ctx, "3", r.ImGui_TableColumnFlags_WidthFixed(),22)

   r.ImGui_TableNextRow(ctx)
   r.ImGui_TableSetColumnIndex(ctx, 0)
   r.ImGui_Text(ctx, "Script: ") r.ImGui_SameLine(ctx) r.ImGui_Text(ctx, mav_debug.script_name) 

   r.ImGui_TableSetColumnIndex(ctx, 1)
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), mav_debug.btn_txt_col)
   r.ImGui_PushFont(ctx, symbols)
   if r.ImGui_IsWindowDocked(ctx) then
      if r.ImGui_Button(ctx, "þ", 22, 20) then mav_debug.dock_id = 0 end
   else
      if r.ImGui_Button(ctx, "þ", 22, 20) then 
         mav_debug.undock_win_x, mav_debug.undock_win_y = r.ImGui_GetWindowPos(ctx)
         mav_debug.undock_sz_w, mav_debug.undock_sz_h = r.ImGui_GetWindowSize(ctx)
         mav_debug.dock_id = -1 
      end
   end 
   r.ImGui_PopFont(ctx)

   r.ImGui_TableSetColumnIndex(ctx, 2)
   r.ImGui_PopStyleColor(ctx, 1)
   Settings()
   r.ImGui_EndTable(ctx)

   r.ImGui_Separator(ctx)
end



function SelectScript()
   local btn_text
   if mav_debug.editor_type == "Internal" then
      btn_text = "Set Script"
   else
      btn_text = "Select Script"
   end
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),       mav_debug.btn_txt_col)
   if r.ImGui_Button(ctx, btn_text, 100, 20) then
      if mav_debug.editor_type == "Internal" then
         local reascript_ide = r.JS_Window_Find( " - ReaScript Development Environment", false )
         if not reascript_ide then 
            r.MB("You have the interal REAPER editor selected under settings. \nPlease open a script in the editor before clicking 'Select Script'","No Script Open In Editor",0)
         else
            local script_name =   r.JS_Window_GetTitle( reascript_ide ):gsub(" %- ReaScript Development Environment", "")
            set_script_path(script_name)
         end
      else
         local prompt = r.PromptForAction(1, 0, 0)
         local function GetSelectedAction()
           action = r.PromptForAction(0, 0, 0)
           if action > 0 then
             while action > 0 do
               set_external_editor_script(action)
               action = r.PromptForAction(-1, 0, 0)
             end
             r.PromptForAction(-1,0,0) -- we don't have to end the session if we want the user to be able to select actions multiple times
           elseif action == 0 then
             r.defer(GetSelectedAction)
           end
         end
         GetSelectedAction()
      end
   end 
   r.ImGui_PopStyleColor(ctx, 1)
end


function OpenEditor()
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),       mav_debug.btn_txt_col)
   if r.ImGui_Button(ctx, "Open Editor", 100, 20) then
      if r.file_exists( mav_debug.script_path ) and (r.file_exists( mav_debug.editor_path ) or reaper.EnumerateSubdirectories(mav_debug.zerobrane_path, 0)) then
         code_is_injected = check_if_debug_code_injected()
         if not code_is_injected then inject_debug_code() end
         _os = r.GetOS()
         if _os == "OSX64" then 
            os.execute("open -a '" .. mav_debug.editor_path .. "' \'" .. mav_debug.script_path .. "\'", -1)
         else
            r.ExecProcess("\"" .. mav_debug.editor_path .. "\" \"" .. mav_debug.script_path .. "\"", -1)
         end


      end
   end 
   r.ImGui_PopStyleColor(ctx, 1)
end


function set_external_editor_script(action)
   local script_name = r.CF_GetCommandText(0, action)
   set_script_path(script_name)
   if mav_debug.script_path and mav_debug.editor_path ~= "" then
      --r.ExecProcess('"' .. mav_debug.editor_path .. '" "' .. script_path .. '"', -1)
   end
end



function set_script_path(script_name)
   local opened_actionlist = false        
   local restore_columns
   local listview_item_to_get 

   if r.GetToggleCommandState( 40605 ) ~= 1 then
      r.Main_OnCommand(40605, 0) -- Show action list
      opened_actionlist = true
   end

   local action_window =  r.JS_Window_Find("Actions", true)
   local filter_tbox =      r.JS_Window_FindChildByID(action_window, 1324)
   local current_search_filter =   r.JS_Window_GetTitle( filter_tbox )
   local listview =    r.JS_Window_FindChildByID(action_window, 1323)
   
   -- Make sure ReaScript path column is visible
   local listview_header =  r.JS_Window_HandleFromAddress(r.JS_WindowMessage_Send(listview, "0x101F", 0,0,0,0)) -- 0x101F = LVM_GETHEADER
   local list_view_column_count = r.JS_ListView_GetItemCount(listview_header)
   listview_item_to_get = 4 -- fifth
   if list_view_column_count == 3 then
      restore_columns = {41170, 41387}
      r.JS_WindowMessage_Send(action_window, "WM_COMMAND", 41170, 0, 0, 0) -- IDs
      r.JS_WindowMessage_Send(action_window, "WM_COMMAND", 41387, 0, 0, 0) -- Paths
   elseif list_view_column_count == 4 then
      local fourth_item = r.JS_ListView_GetItem( listview, 0, 3 )
      if fourth_item:match("%d+") or fourth_item:match("^_") then
         -- Is Command ID
         restore_columns = {41387}
         r.JS_WindowMessage_Send(action_window, "WM_COMMAND", 41387, 0, 0, 0) -- Paths
      else
         -- Is Path
         listview_item_to_get = 3 -- fourth
      end
   end
   r.JS_Window_SetTitle( filter_tbox, script_name )

   local sep = package.config:sub(1,1)
   local wanted_column_name
   script_name = string.gsub(script_name, "Script: ", "") 
   wanted_column_name = "Script: " .. script_name

   local end_time = r.time_precise() + 10
 

   function action_window_MainLoop()
      local time = r.time_precise()

      if r.JS_ListView_GetItem( listview, 0, 1 ) == wanted_column_name then
         local ScriptPath = r.JS_ListView_GetItem( listview, 0, listview_item_to_get )
         r.JS_Window_SetTitle( filter_tbox, current_search_filter )
         if restore_columns then
            for i = 1, #restore_columns do
               r.JS_WindowMessage_Send(action_window, "WM_COMMAND", restore_columns[i], 0, 0, 0)
            end
         end

         if opened_actionlist then
            r.JS_Window_Destroy( action_window )
         end
         -- check if path is absolute
         local absolute
         if (r.GetOS()):match("Win") then
            if ScriptPath:match("^%a:\\") or ScriptPath:match("^\\\\") then
               absolute = true
            end
         else -- unix
            absolute = ScriptPath:match("^/")
         end

         ScriptPath = ScriptPath .. sep .. script_name --- cehck if sep neede on win or linux is doulbe on mac
         if not absolute then
            ScriptPath = r.GetResourcePath() .. sep .. "Scripts" .. sep .. ScriptPath
         end
         mav_debug.script_path = ScriptPath
         mav_debug.script_name = script_name
         script_set = true;

         return r.defer(function() end)
      elseif time > end_time then
       return r.defer(function() end)
      else
       r.defer(action_window_MainLoop)
      end
   end

   action_window_MainLoop()
end



function Debug()
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),       mav_debug.btn_txt_col)
   if r.ImGui_Button(ctx, "Debug Script", 100, 20) then
      if r.file_exists( mav_debug.script_path ) then
         f = assert (loadfile (mav_debug.script_path))
         f () -- execute function now
      end
   end
   r.ImGui_PopStyleColor(ctx, 1)
end



function OpenDebugger()
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),       mav_debug.btn_txt_col)
   if r.ImGui_Button(ctx, "Open Debugger", 110, 20) then
      if r.file_exists( mav_debug.script_path ) and (r.file_exists( mav_debug.zerobrane_path ) or reaper.EnumerateSubdirectories(mav_debug.zerobrane_path, 0)) then
         code_is_injected = check_if_debug_code_injected()
         if not code_is_injected then inject_debug_code() end
         _os = r.GetOS()
         if _os == "OSX64" then 
            os.execute("open -a '" .. mav_debug.zerobrane_path .. "' \'" .. mav_debug.script_path .. "\'", -1)
         else
            r.ExecProcess("\"" .. mav_debug.zerobrane_path .. "\" \"" .. mav_debug.script_path .. "\"", -1)
         end
      end
   end 
   r.ImGui_PopStyleColor(ctx, 1)
end



function Settings()
   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),       mav_debug.btn_txt_col)
   r.ImGui_PushFont(ctx, symbols)
   local settings_pressed = r.ImGui_Button(ctx, "ÿ", 22, 20)
   r.ImGui_PopFont(ctx)
   r.ImGui_PopStyleColor(ctx, 1)

   if settings_pressed then
      r.ImGui_OpenPopup(ctx, 'Settings Window')
   end



   local center = {r.ImGui_Viewport_GetCenter(r.ImGui_GetMainViewport(ctx))} 
   r.ImGui_SetNextWindowPos(ctx, center[1], center[2], r.ImGui_Cond_Appearing(), 0.5, 0.5)

   if r.ImGui_BeginPopupModal(ctx, 'Settings Window', nil, r.ImGui_WindowFlags_AlwaysAutoResize()) then   

      r.ImGui_Text(ctx, "ZeroBrane Path") 
      rv, mav_debug.zerobrane_path = r.ImGui_InputText(ctx, "##1", mav_debug.zerobrane_path) r.ImGui_SameLine(ctx)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),       mav_debug.btn_txt_col)
      if r.ImGui_Button(ctx, "Find",50,20) then
         _os = r.GetOS()
         if _os =="Win64" then
            rv, fileName = r.JS_Dialog_BrowseForOpenFiles( "Browse for zbstudio.exe", "C:/", "zbstudio.exe", "Executable files (.exe)\0*.exe\0\0", false ) 
         elseif _os == "OSX64" then 
            rv, fileName = r.JS_Dialog_BrowseForOpenFiles( "Browse for ZeroBraneStudio.app", "", "ZeroBraneStudio.app", "Executable files (.app)\0*.app\0\0", false ) 
         else
            rv, fileName = r.JS_Dialog_BrowseForOpenFiles( "Browse for zbstudio.sh", "", "zbstudio.sh", "Script files (.sh)\0*.sh\0\0", false ) 
         end
      end
      r.ImGui_PopStyleColor(ctx, 1)

      if rv == 1 and (fileName:match("zbstudio%.exe") or fileName:match("ZeroBraneStudio.app") or fileName:match("zbstudio.sh")) then
         mav_debug.zerobrane_path = fileName
      elseif rv == 1 then
         r.ShowMessageBox("Selected file is not ZeroBrane Studio. \nPlease select zbstudio (Win) or ZeroBraneStudio.app (macos)", "Not a valid Executable", 1)
      end

      r.ImGui_Separator(ctx)
      r.ImGui_Text(ctx, "Editor Selection")  --r.ImGui_SameLine(ctx)
      if r.ImGui_RadioButton(ctx, 'Internal', mav_debug.editor_type == "Internal" or mav_debug.editor_type == nil ) then mav_debug.editor_type= "Internal" end r.ImGui_SameLine(ctx)
      if r.ImGui_RadioButton(ctx, 'External', mav_debug.editor_type == "External") then mav_debug.editor_type= "External" end 
      if mav_debug.editor_type== "Internal" then r.ImGui_BeginDisabled(ctx) end
      
      rv, mav_debug.editor_path = r.ImGui_InputText(ctx, "Editor Path", mav_debug.editor_path) r.ImGui_SameLine(ctx)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),       mav_debug.btn_txt_col)
      if r.ImGui_Button(ctx, "Find##2",50,20) then
         _os = r.GetOS()
         if _os =="Win64" then
            rv, fileName = r.JS_Dialog_BrowseForOpenFiles( "Browse for Editor", "C:/", "", "Executable files (.exe)\0*.exe\0\0", false ) 
         elseif _os == "OSX64" then 
            rv, fileName = r.JS_Dialog_BrowseForOpenFiles( "Browse for Editor", "", "", "Executable files (.app)\0*.app\0\0", false ) 
         else
            rv, fileName = r.JS_Dialog_BrowseForOpenFiles( "Browse for Editor", "", "", "All files (*.*)\0*.*\0\0", false ) 

         end

         if rv == 1 then
            mav_debug.editor_path = fileName
         end

      end
      r.ImGui_PopStyleColor(ctx, 1)
      if mav_debug.editor_type== "Internal" then r.ImGui_EndDisabled(ctx) end 

      r.ImGui_Separator(ctx)

      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), mav_debug.btn_txt_col)
      if r.ImGui_Button(ctx, 'OK', 120, 0) then r.ImGui_CloseCurrentPopup(ctx) end
      r.ImGui_PopStyleColor(ctx, 1)
      
      r.ImGui_SetItemDefaultFocus(ctx)
      r.ImGui_EndPopup(ctx)
   end 
end



function DrawFrame()

   DrawHeader() 
   SelectScript() r.ImGui_SameLine(ctx)
   
   if not script_set then r.ImGui_BeginDisabled(ctx) end

   if mav_debug.editor_type == "External" then
      OpenEditor() r.ImGui_SameLine(ctx)
   end

   OpenDebugger()  r.ImGui_SameLine(ctx)

   if mav_debug.editor_type == "External" then
      Debug() r.ImGui_SameLine(ctx)
   end

   if not script_set then r.ImGui_EndDisabled(ctx) end

   --r.ImGui_Separator(ctx)

   return 
end



function MainLoop()
   local visible = nil

   main_viewport = r.ImGui_GetMainViewport(ctx)
   work_pos = {r.ImGui_Viewport_GetWorkPos(main_viewport)}
   r.ImGui_SetNextWindowPos(ctx, work_pos[1] + 20, work_pos[2] + 20, r.ImGui_Cond_FirstUseEver())
   
   r.ImGui_SetNextWindowSizeConstraints(ctx, 440, 100, 10000, 10000)
   r.ImGui_SetNextWindowSize(ctx, 0, 0, r.ImGui_Cond_Once()) 
   Set_Theme()

   if mav_debug.dock_id == -1 then
      r.ImGui_SetNextWindowDockID(ctx, mav_debug.dock_id)
      mav_debug.dock_id = nil
   elseif mav_debug.dock_id == 0 then
      r.ImGui_SetNextWindowPos(ctx, mav_debug.undock_win_x, mav_debug.undock_win_y)
      r.ImGui_SetNextWindowSize(ctx, mav_debug.undock_sz_w, mav_debug.undock_sz_h) 
      mav_debug.dock_id = nil
   end
   
   visible, open = r.ImGui_Begin(ctx, "Mavriq Debugging", true)

   if visible then
      DrawFrame()
      r.ImGui_End(ctx)
   end

   r.ImGui_PopFont(ctx)
   r.ImGui_PopStyleColor(ctx, 11)
   r.ImGui_PopStyleVar(ctx, 3)
   if open then
      r.defer(MainLoop)
   else
      extract_debug_code()
      save_state()
      r.ImGui_DestroyContext(ctx)
   end
end



--[[
-------------------------------------------------------------
------------------ Utility Functions ------------------------
-------------------------------------------------------------
]]

function zzzzzzUtilityzzzzzzzzzzzzzzzzzz() end

function set_initial_state()
   if r.HasExtState("Mavriq Debugging", "editor_type") then
      mav_debug.zerobrane_path =       r.GetExtState("Mavriq Debugging", "zerobrane_path")
      mav_debug.editor_type =          r.GetExtState("Mavriq Debugging", "editor_type")
      mav_debug.editor_path =          r.GetExtState("Mavriq Debugging", "editor_path")
   end
end



function save_state()
   r.SetExtState("Mavriq Debugging", "zerobrane_path", mav_debug.zerobrane_path, true)
   r.SetExtState("Mavriq Debugging", "editor_type",    mav_debug.editor_type, true) 
   r.SetExtState("Mavriq Debugging", "editor_path",    mav_debug.editor_path, true)
end


function dependancies_are_installed() 
   if not r.APIExists("ImGui_AcceptDragDropPayload") then
      r.MB("You must have ReaIMGui installed to use Debugging Tools.", "IMGui missing...", 0);
      return false
   elseif not r.APIExists("JS_Window_Find") then
      r.MB( "Please, install the JS_ReaScriptAPI to use Debugging Tools.", "JS_ReaScriptAPI missing...", 0 )
      return false
   end
   if (not r.file_exists(sockets_path .. "socket/core.dll")) and (not r.file_exists(sockets_path .. "socket/core.so")) then
      r.MB( "Please, install the Mavriq Sockets to use Debugging Tools.", "Mavirq Sockets missing...", 0 )
      return false
   end
   return true
end

function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end



function check_if_debug_code_injected()
   local target_script = readAll(mav_debug.script_path)
   if target_script.match(target_script, match_expr) then
      return true
   end
   return false
end



function inject_debug_code()
   local injected_code = readAll(injected_code_path)
   local script = readAll(mav_debug.script_path)
   script = injected_code .. script
   file = io.open(mav_debug.script_path, "wb")
   io.output(file)
   io.write(script)
   io.close()
   mav_debug.code_injected = true
end



function extract_debug_code()
   if string.len(mav_debug.script_path) > 5 then
      local script = readAll(mav_debug.script_path)
      s = string.gsub(script, match_expr, "")
      file = io.open(mav_debug.script_path, "wb")
         io.output(file)
      io.write(s)
      io.close()
   end
end


--[[
-------------------------------------------------------------
--------------------- Global Code ---------------------------
-------------------------------------------------------------
]]


if not dependancies_are_installed() then goto exit end
set_initial_state()

ctx = r.ImGui_CreateContext('Mavriq Debugging',
   r.ImGui_ConfigFlags_DockingEnable())
font = r.ImGui_CreateFont("sans-serif", 14)
r.ImGui_AttachFont(ctx,font)
symbols = r.ImGui_CreateFont( reaper.GetResourcePath() .."/Scripts/Mavriq ReaScript Repository/Various/Debugging/Mavriq-Debugging.ttf", 14)
r.ImGui_AttachFont(ctx,symbols)


r.defer(MainLoop)

::exit::
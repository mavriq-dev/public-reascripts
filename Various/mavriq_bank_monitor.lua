--[[
 * ReaScript Name: Mavriq ReaLearn Bank Monitor
 * Screenshot: https://i.postimg.cc/HLCgSW0x/Relearn-Monitor.png
 * Author: Mavriq
 * Repository: GitHub > mavriq-dev > public-reascripts
 * Repository URI: https://github.com/mavriq-dev/public-reascripts
 * License: GPL v3
 * REAPER: 5.0
 * Version: 0.3.3
 * Donation: https://www.paypal.com/paypalme/mavriqdev
 * About: # Mavriq ReaLearn Bank Monitor
 *  A reaper script to monitor what bank is currently selected in ReLearn.
 *   
 *  To setup the script you must select a ReaLearn Instance and the parameter that holds the bank information.
 *  
 *  The instance can be on the Monitoring FX Chain, The Master FX Chain or on a regular "Track". Select the appropriate location From the "ReaLearn FX Chain" Drop down. If you selected "Track", enter the track number below it.
 *  
 *  Pick the ReaLearn instance in the "FX List" drop-down.
 *   
 *  Select the parameter number that stores the bank information. If you are using DAW Control (see ReaLearn documentation) then that is Master parameter #1. To select a  compartment parameter, select 101 - 200. IE 101 = compartment #1.
 *  
 *  The bank size parameter is how many controls are in each bank. If you have 10 sliders, then select 10. The tracks display will then show the correct amount of tracks "targeted" by the bank.
 *  
 *  There are 4 Theme Layout settings. 2 each for the mixer and tcp tracks. The default settings are the Theme Layout you want to apply when the tracks are not targeted by the current bank. The active is for when they are. For example you may pick a track layout with red slider knobs when the bank is active, and grey when not. This lets you see quickly which tracks are in the current bank.
 *  
 *  You can type the name of the layout manually or you can set a track up with the required layout and press "Set". The name will be pulled from the track. This is useful when the name has special characters not easy to enter via the keyboard.
 *  
 *  Use the "Dock" and "Undock" buttons to control docking
 *  
 *  That's it, the bank and track information should appear and update when you change banks.
 *  
 *  A huge thanks to cfillion for ReaImGui.
 --]]

 --[[
 * Changelog:
 *  v0.3.3 (2022-04-20)
 *      + give props to cfillion for ReaImGUI
 *  v0.3.2 (2022-02-07)
 *      + added notification for missing ReaImGUI extension
 *      # removed dependancy on Ultrashall API.
 *  v0.3.1 (2022-01-19)
 *      + Added Track Layout Application to Banks
 *      + Reorganized GUI
 *  v0.2.0 (2022-01-18)
 *      # bug fix (crash when docking)
 *  v0.1.0 (2022-01-18)
 *      + Initial Release
--]] 



-- Todo: Remember window settings when undocking and between open and closing

if reaper.ImGui_AcceptDragDropPayload == nil then
  reaper.ShowMessageBox("You must have ReaIMGui installed to use Bank Monitor. \nPlease see: https://forums.cockos.com/showthread.php?t=250419", "Bank Monitor Exception", 0);
  return
end

local r = reaper

bankmon = {
    isopen = true,
    bank_size = 8,
    realearn_cur_bank = 1,
    realearn_param_num = 0,
    realearn_track = nil,
    realearn_fxchain_slot = -1,
    realearn_track_num = 1,
    fxchain_type = "Monitoring",
    fx_list = {},
    bank_track_numbers = "",
    -- bg_color = 0,
    theme_mix_layout_def = "",
    theme_mix_layout_act = "",
    theme_trk_layout_def = "",
    theme_trk_layout_act = "",
    initial_load = true
}

function bankmon.get_FXList()
    if not next(bankmon.fx_list) then
        if bankmon.fxchain_type == "Track" then
            bankmon.realearn_track = r.GetTrack(0,
                                                bankmon.realearn_track_num - 1)
        else
            bankmon.realearn_track = r.GetMasterTrack(0)
        end

        fx_count = 0
        if bankmon.fxchain_type ~= "Monitoring" then
            fx_count = r.TrackFX_GetCount(bankmon.realearn_track)
        else
            fx_count = r.TrackFX_GetRecCount(bankmon.realearn_track)
        end

        for i = 1, fx_count do
            if bankmon.fxchain_type == "Monitoring" then
                _, fx_name = r.TrackFX_GetFXName(bankmon.realearn_track,
                                                 (i - 1) | 0x1000000)
            else
                _, fx_name = r.TrackFX_GetFXName(bankmon.realearn_track, i - 1)
            end
            bankmon.fx_list[i] = fx_name
        end
    end
end

function set_initial_state()
    if r.HasExtState("Mavirq Bank Display", "realearn_fxchain_slot") then
        bankmon.bank_size = tonumber(r.GetExtState("Mavirq Bank Display",
                                                   "bank_size"))
        bankmon.realearn_cur_bank = tonumber(
                                        r.GetExtState("Mavirq Bank Display",
                                                      "realearn_cur_bank"))
        bankmon.realearn_param_num = tonumber(
                                         r.GetExtState("Mavirq Bank Display",
                                                       "realearn_param_num"))
        bankmon.realearn_fxchain_slot = tonumber(
                                            r.GetExtState("Mavirq Bank Display",
                                                          "realearn_fxchain_slot"))
        bankmon.realearn_track_num = tonumber(
                                         r.GetExtState("Mavirq Bank Display",
                                                       "realearn_track_num"))
        bankmon.fxchain_type = r.GetExtState("Mavirq Bank Display",
                                             "fxchain_type")
        bankmon.theme_mix_layout_def = r.GetExtState("Mavirq Bank Display",
                                                     "theme_mix_layout_def")
        bankmon.theme_mix_layout_act = r.GetExtState("Mavirq Bank Display",
                                                     "theme_mix_layout_act")
        bankmon.theme_trk_layout_def = r.GetExtState("Mavirq Bank Display",
                                                     "theme_trk_layout_def")
        bankmon.theme_trk_layout_act = r.GetExtState("Mavirq Bank Display",
                                                     "theme_trk_layout_act")
        bankmon.get_FXList()
    end
end

function save_state()
    r.SetExtState("Mavirq Bank Display", "bank_size", bankmon.bank_size, true)
    r.SetExtState("Mavirq Bank Display", "realearn_cur_bank",
                  bankmon.realearn_cur_bank, true)
    r.SetExtState("Mavirq Bank Display", "realearn_param_num",
                  bankmon.realearn_param_num, true)
    r.SetExtState("Mavirq Bank Display", "realearn_fxchain_slot",
                  bankmon.realearn_fxchain_slot, true)
    r.SetExtState("Mavirq Bank Display", "realearn_track_num",
                  bankmon.realearn_track_num, true)
    r.SetExtState("Mavirq Bank Display", "fxchain_type", bankmon.fxchain_type,
                  true)
    r.SetExtState("Mavirq Bank Display", "theme_mix_layout_def",
                  bankmon.theme_mix_layout_def, true)
    r.SetExtState("Mavirq Bank Display", "theme_mix_layout_act",
                  bankmon.theme_mix_layout_act, true)
    r.SetExtState("Mavirq Bank Display", "theme_trk_layout_def",
                  bankmon.theme_trk_layout_def, true)
    r.SetExtState("Mavirq Bank Display", "theme_trk_layout_act",
                  bankmon.theme_trk_layout_act, true)
end

set_initial_state()

bg_color = r.ImGui_ColorConvertNative(r.GetThemeColor("col_mixerbg"))
bg_color = (bg_color << 8) | 0xff

local ctx = r.ImGui_CreateContext('ReaImGui Demo',
                                  r.ImGui_ConfigFlags_DockingEnable())

function bankmon.loop()
    bankmon.isopen = bankmon.ShowBankmonWindow()
    if bankmon.isopen then
        r.defer(bankmon.loop)
    else
        save_state()
        local cur_low_track, cur_high_track =
            bankmon.get_track_numbers(bankmon.realearn_cur_bank)
        bankmon.SetTrackLayout(cur_low_track, cur_high_track, "P_MCP_LAYOUT",
                               bankmon.theme_mix_layout_def)
        bankmon.SetTrackLayout(cur_low_track, cur_high_track, "P_TCP_LAYOUT",
                               bankmon.theme_mix_layout_def)
        r.ImGui_DestroyContext(ctx)
    end
end

r.defer(bankmon.loop)

function bankmon.ShowBankmonWindow()
    local visible, isopen = nil

    -- r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), bg_color)
    main_viewport = r.ImGui_GetMainViewport(ctx)
    work_pos = {r.ImGui_Viewport_GetWorkPos(main_viewport)}
    r.ImGui_SetNextWindowPos(ctx, work_pos[1] + 20, work_pos[2] + 20,
                             r.ImGui_Cond_FirstUseEver())
    r.ImGui_SetNextWindowSize(ctx, 0, 0, r.ImGui_Cond_Once()) -- NOte make sure to change this to first use after ui finalized

    if bankmon.dock_id then
        r.ImGui_SetNextWindowDockID(ctx, bankmon.dock_id)
        bankmon.dock_id = nil
    end

    -- r.ImGui_PopStyleColor(ctx)
    visible, isopen = r.ImGui_Begin(ctx, "Mavriq Bank Monitor", true)

    if not visible then return isopen end

--[[
      ------------ FX Chain Selection ---------------
--]]

    r.ImGui_BeginTable(ctx, "Main Table", 3, r.ImGui_TableFlags_SizingFixedFit())
    r.ImGui_TableSetupColumn(ctx, "1", r.ImGui_TableColumnFlags_NoResize(), 305)
    r.ImGui_TableSetupColumn(ctx, "2", r.ImGui_TableColumnFlags_NoResize(), 5)
    r.ImGui_TableSetupColumn(ctx, "3", r.ImGui_TableColumnFlags_NoResize(), 100)
    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)

    r.ImGui_Text(ctx, "ReaLean Instance")
    r.ImGui_TableSetColumnIndex(ctx, 2)
    if r.ImGui_IsWindowDocked(ctx) then
        if r.ImGui_Button(ctx, "Undock", 60, 20) then bankmon.dock_id = 0 end
    else
        if r.ImGui_Button(ctx, "Dock", 60, 20) then bankmon.dock_id = -1 end
    end

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    r.ImGui_SetNextItemWidth(ctx, 150)
    if r.ImGui_BeginCombo(ctx, "ReaLearn FX Chain", bankmon.fxchain_type) then
        local is_selected = bankmon.fxchain_type == "Monitoring"
        if r.ImGui_Selectable(ctx, "Monitoring", is_selected) then
            bankmon.fxchain_type = "Monitoring"
            r.ImGui_SetItemDefaultFocus(ctx)
            bankmon.fx_list = {}
            bankmon.realearn_fxchain_slot = -1
        end
        is_selected = bankmon.fxchain_type == "Master"
        if r.ImGui_Selectable(ctx, "Master", is_selected) then
            bankmon.fxchain_type = "Master"
            r.ImGui_SetItemDefaultFocus(ctx)
            bankmon.fx_list = {}
            bankmon.realearn_fxchain_slot = -1
        end
        is_selected = bankmon.fxchain_type == "Track"
        if r.ImGui_Selectable(ctx, "Track", is_selected) then
            bankmon.fxchain_type = "Track"
            r.ImGui_SetItemDefaultFocus(ctx)
            bankmon.fx_list = {}
            bankmon.realearn_fxchain_slot = -1
        end
        r.ImGui_EndCombo(ctx)
    end
    r.ImGui_SameLine(ctx)
    HelpMarker(
        "Select where the ReaLearn instance is you want to monitor; in the Monitoring FX Chain, The Master FX Chain or on a regular Track.")

--[[
      ------------ Track # Selection ---------------
--]]

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    if bankmon.fxchain_type ~= "Track" then r.ImGui_BeginDisabled(ctx) end
    r.ImGui_SetNextItemWidth(ctx, 150)
    rv, bankmon.realearn_track_num = r.ImGui_DragInt(ctx, "Track #",
                                                     bankmon.realearn_track_num,
                                                     0.5, 1, 300, "%d",
                                                     r.ImGui_SliderFlags_AlwaysClamp())
    if rv then
        bankmon.fx_list = {}
        bankmon.realearn_fxchain_slot = -1
    end
    r.ImGui_SameLine(ctx)
    HelpMarker(
        "Enter the track number where you want to target the ReaLearn instance in the FX Chain. Only enabled when Track is selected by ReaLearn FX Chain above.")
    if bankmon.fxchain_type ~= "Track" then r.ImGui_EndDisabled(ctx) end

--[[
      ------------ VST Selection ---------------
--]]

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    preview_text = "Select Relearn VST"
    if bankmon.realearn_fxchain_slot ~= -1 then
        preview_text = bankmon.fx_list[bankmon.realearn_fxchain_slot]
    end
    r.ImGui_SetNextItemWidth(ctx, 150)
    if r.ImGui_BeginCombo(ctx, "FX List", preview_text) then
        bankmon.get_FXList()
        for i, fx_name in ipairs(bankmon.fx_list) do
            local is_selected = bankmon.realearn_fxchain_slot == i
            if r.ImGui_Selectable(ctx, fx_name, is_selected) then
                bankmon.realearn_fxchain_slot = i
                r.ImGui_SetItemDefaultFocus(ctx)
            end
        end
        r.ImGui_EndCombo(ctx)
    end
    r.ImGui_SameLine(ctx)
    HelpMarker("Select the target ReaLearn Instance.")

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    r.ImGui_Dummy(ctx, 50, 20)

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    r.ImGui_Text(ctx, "Bank Information")

--[[
      ------------ Bank Size ---------------
--]]

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    -- r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), bg_color)
    r.ImGui_SetNextItemWidth(ctx, 150)
    bankmon.bank_size = ({
        r.ImGui_DragInt(ctx, "Bank Size", bankmon.bank_size, 0.5, 0, 100, "%d",
                        r.ImGui_SliderFlags_AlwaysClamp())
    })[2]
    r.ImGui_SameLine(ctx)
    HelpMarker("Enter the number sliders etc that are in one bank.")

--[[
      ------------ Relearn Param # ---------------
--]]

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    r.ImGui_SetNextItemWidth(ctx, 150)
    bankmon.realearn_param_num = ({
        r.ImGui_DragInt(ctx, "ReaLearn Parameter #",
                        bankmon.realearn_param_num + 1, 0.5, 1, 200, "%d",
                        r.ImGui_SliderFlags_AlwaysClamp())
    })[2] - 1
    r.ImGui_SameLine(ctx)
    HelpMarker(
        "Enter the number that corresponds to ReaLearn's parameter that holds the bank value. " ..
            "If you are using DAW Control that is parameter #1 in main. Controller compartment parameters start at #101.")
    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    r.ImGui_Dummy(ctx, 50, 20)

--[[
      ------------ Theme Settings ---------------
--]]

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    r.ImGui_Text(ctx, "Theme Settings")

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    r.ImGui_SetNextItemWidth(ctx, 150)
    bankmon.theme_mix_layout_def = ({
        r.ImGui_InputText(ctx, "Mix Default Layout",
                          bankmon.theme_mix_layout_def)
    })[2]

    r.ImGui_SameLine(ctx)
    HelpMarker(
        "Set the mix theme layout you want to use when tracks ARE NOT in an active bank.")
    r.ImGui_TableSetColumnIndex(ctx, 2)
    if r.ImGui_Button(ctx, "Set", 60, 20) then
        bankmon.theme_mix_layout_def = bankmon.get_first_sel_trk_layout(
                                           "P_MCP_LAYOUT")
    end
    r.ImGui_SameLine(ctx)
    HelpMarker("Select a track to copy the Theme Layout from.")

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    r.ImGui_SetNextItemWidth(ctx, 150)
    bankmon.theme_mix_layout_act = ({
        r.ImGui_InputText(ctx, "Mix Active Layout", bankmon.theme_mix_layout_act)
    })[2]
    r.ImGui_SameLine(ctx)
    HelpMarker(
        "Set the mix theme layout you want to use when tracks ARE in an active bank.")
    r.ImGui_TableSetColumnIndex(ctx, 2)
    if r.ImGui_Button(ctx, " Set ", 60, 20) then -- NOTE: this is a hack. Buttons with the same label will not function. I added spaces to make them unique.
        bankmon.theme_mix_layout_act = bankmon.get_first_sel_trk_layout(
                                           "P_MCP_LAYOUT")
    end
    r.ImGui_SameLine(ctx)
    HelpMarker("Select a track to copy the Theme Layout from.")

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    r.ImGui_SetNextItemWidth(ctx, 150)
    bankmon.theme_trk_layout_def = ({
        r.ImGui_InputText(ctx, "Trk Default Layout",
                          bankmon.theme_trk_layout_def)
    })[2]

    r.ImGui_SameLine(ctx)
    HelpMarker(
        "Set the tcp theme layout you want to use when tracks ARE NOT in an active bank.")
    r.ImGui_TableSetColumnIndex(ctx, 2)
    if r.ImGui_Button(ctx, "  Set  ", 60, 20) then -- NOTE: this is a hack. Buttons with the same label will not function. I added spaces to make them unique.
        bankmon.theme_trk_layout_def = bankmon.get_first_sel_trk_layout(
                                           "P_TCP_LAYOUT")
    end
    r.ImGui_SameLine(ctx)
    HelpMarker("Select a track to copy the Theme Layout from.")

    r.ImGui_TableNextRow(ctx)
    r.ImGui_TableSetColumnIndex(ctx, 0)
    r.ImGui_SetNextItemWidth(ctx, 150)
    bankmon.theme_trk_layout_act = ({
        r.ImGui_InputText(ctx, "Trk Active Layout", bankmon.theme_trk_layout_act)
    })[2]
    r.ImGui_SameLine(ctx)
    HelpMarker(
        "Set the tcp theme layout you want to use when tracks ARE in an active bank.")
    r.ImGui_TableSetColumnIndex(ctx, 2)
    if r.ImGui_Button(ctx, "  Set    ", 60, 20) then -- NOTE: this is a hack. Buttons with the same label will not function. I added spaces to make them unique.
        bankmon.theme_trk_layout_act = bankmon.get_first_sel_trk_layout(
                                           "P_TCP_LAYOUT")
    end
    r.ImGui_SameLine(ctx)
    HelpMarker("Select a track to copy the Theme Layout from.")

    r.ImGui_EndTable(ctx)

    bankmon.update_layouts()

    r.ImGui_Dummy(ctx, 50, 20)
    r.ImGui_SetNextItemWidth(ctx, 70)
    r.ImGui_LabelText(ctx, "Active Bank", bankmon.realearn_cur_bank)
    r.ImGui_SetNextItemWidth(ctx, 70)
    r.ImGui_LabelText(ctx, "Tracks", bankmon.bank_track_numbers)

    r.ImGui_End(ctx)

    return isopen
end

function bankmon.update_layouts()
    if bankmon.realearn_fxchain_slot ~= -1 then
        local fx_pos = bankmon.realearn_fxchain_slot
        if bankmon.fxchain_type == "Monitoring" then
            fx_pos = fx_pos | 0x1000000
        end

        local raw_bank_data = r.TrackFX_GetParamNormalized(
                                  bankmon.realearn_track, fx_pos - 1,
                                  bankmon.realearn_param_num)
        local dec_place = 10 ^ (2)
        local cur_low_track, cur_high_track =
            bankmon.get_track_numbers(bankmon.realearn_cur_bank)
        local cur_bank = bankmon.realearn_cur_bank
        bankmon.realearn_cur_bank = math.floor(
                                        raw_bank_data * 12.5 * dec_place + 0.01) +
                                        1

        local low_track_num, high_track_num =
            bankmon.get_track_numbers(bankmon.realearn_cur_bank)
        bankmon.bank_track_numbers = string.format("%.0f", low_track_num) ..
                                         " - " ..
                                         string.format("%.0f", high_track_num)

        if (cur_bank ~= bankmon.realearn_cur_bank or bankmon.initial_load) then
            bankmon.SetTrackLayout(cur_low_track, cur_high_track,
                                   "P_MCP_LAYOUT", bankmon.theme_mix_layout_def)
            bankmon.SetTrackLayout(low_track_num, high_track_num,
                                   "P_MCP_LAYOUT", bankmon.theme_mix_layout_act)
            bankmon.SetTrackLayout(cur_low_track, cur_high_track,
                                   "P_TCP_LAYOUT", bankmon.theme_trk_layout_def)
            bankmon.SetTrackLayout(low_track_num, high_track_num,
                                   "P_TCP_LAYOUT", bankmon.theme_trk_layout_act)
            bankmon.initial_load = false
        end
    end
end

function bankmon.SetTrackLayout(low_track_num, high_track_num, track_attribute,
                                layout_name)
    if layout_name ~= "" then
        for i = low_track_num - 1, high_track_num - 1, 1 do
            track = r.GetTrack(0, i)
            if track then
                r.GetSetMediaTrackInfo_String(track, track_attribute,
                                              layout_name, true)
            end
        end
    end
end

function bankmon.get_track_numbers(banknumber)
    local low_track_num = (banknumber - 1) * bankmon.bank_size + 1
    local high_track_num = low_track_num + bankmon.bank_size - 1
    return low_track_num, high_track_num
end

function bankmon.get_first_sel_trk_layout(track_attribute)
    track = reaper.GetSelectedTrack(0, 0)
    rv = ({r.GetSetMediaTrackInfo_String(track, track_attribute, "", false)})[2]
    return rv
end

function HelpMarker(desc) -- Function to show a ?
    r.ImGui_TextDisabled(ctx, '(?)')
    if r.ImGui_IsItemHovered(ctx) then
        r.ImGui_BeginTooltip(ctx)
        r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
        r.ImGui_Text(ctx, desc)
        r.ImGui_PopTextWrapPos(ctx)
        r.ImGui_EndTooltip(ctx)
    end
end


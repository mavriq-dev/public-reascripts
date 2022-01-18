--[[
 * ReaScript Name: Mavriq ReaLearn Bank Monitor
 * Screenshot: https://i.postimg.cc/HLCgSW0x/Relearn-Monitor.png
 * Author: Mavriq
 * Repository: GitHub > mavriq-dev > public-reascripts
 * Repository URI: https://github.com/mavriq-dev/public-reascripts
 * Licence: GPL v3
 * REAPER: 5.0
 * Version: 0.1
 * Donation: https://www.paypal.com/paypalme/mavriqdev
 * About: # Mavriq Realearn Bank Monitor
 * A reaper script to monitor what bank is currently selected in ReLearn.
 *
 To setup the script you must select a Relearn Instance and the parameter that holds the bank information.
 
 The instance can be on the Monitoring FX Chain, The Master FX Chain or on a regular track. Select the appropriate location then pick the Relearn instance in the dropdown.
 
 Select the parameter number that stores the bank information. If you are using DAW Control (see ReaLearn documentation) then that is Master parameter #1. To select a  compartment parameter, select 101 - 200. IE 101 = compartment #1.
 
 The bank size parameter is how many controls are in each bank. If you have 10 sliders, then select 10. The tracks display will then show the correct amount of tracks "targeted" by the bank.
 * Changelog:
  + Initial Release
--]]



dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

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
  bg_color = 0
}


function bankmon.get_FXList()
  if not next(bankmon.fx_list) then
    if bankmon.fxchain_type == "Track" then
      bankmon.realearn_track = r.GetTrack(0, bankmon.realearn_track_num - 1)
    else
      bankmon.realearn_track = r.GetMasterTrack(0)
    end

    fx_count = 0
    if bankmon.fxchain_type ~= "Monitoring" then
      fx_count = r.TrackFX_GetCount(bankmon.realearn_track)
    else
      fx_count = r.TrackFX_GetRecCount(bankmon.realearn_track) 
    end
    
    for i = 1, fx_count   do
      if bankmon.fxchain_type == "Monitoring" then 
        _, fx_name = r.TrackFX_GetFXName(bankmon.realearn_track, (i -1)|0x1000000 )
      else
        _, fx_name = r.TrackFX_GetFXName(bankmon.realearn_track, i -1)
      end
      bankmon.fx_list[i] = fx_name
    end
  end
end


function set_initial_state()
    if r.HasExtState("Mavirq Bank Display", "realearn_fxchain_slot") then
		bankmon.bank_size = tonumber(r.GetExtState("Mavirq Bank Display", "bank_size"))
		bankmon.realearn_cur_bank = tonumber(r.GetExtState("Mavirq Bank Display", "realearn_cur_bank"))
		bankmon.realearn_param_num = tonumber(r.GetExtState("Mavirq Bank Display", "realearn_param_num"))
		bankmon.realearn_fxchain_slot = tonumber(r.GetExtState("Mavirq Bank Display", "realearn_fxchain_slot"))
		bankmon.realearn_track_num = tonumber(r.GetExtState("Mavirq Bank Display", "realearn_track_num"))
		bankmon.fxchain_type = r.GetExtState("Mavirq Bank Display", "fxchain_type")
		bankmon.get_FXList()
    end
end


function save_state()
  r.SetExtState("Mavirq Bank Display", "bank_size", bankmon.bank_size, true)   
  r.SetExtState("Mavirq Bank Display", "realearn_cur_bank", bankmon.realearn_cur_bank, true)  
  r.SetExtState("Mavirq Bank Display", "realearn_param_num", bankmon.realearn_param_num, true)  
  r.SetExtState("Mavirq Bank Display", "realearn_fxchain_slot", bankmon.realearn_fxchain_slot, true)  
  r.SetExtState("Mavirq Bank Display", "realearn_track_num", bankmon.realearn_track_num, true)  
  r.SetExtState("Mavirq Bank Display", "fxchain_type", bankmon.fxchain_type, true)  
end

set_initial_state()

bg_color = r.ImGui_ColorConvertNative(r.GetThemeColor("col_mixerbg"))
bg_color =  (bg_color << 8) | 0xff

local ctx = r.ImGui_CreateContext('ReaImGui Demo', r.ImGui_ConfigFlags_DockingEnable())



function bankmon.loop()
  bankmon.isopen = bankmon.ShowBankmonWindow()
  if bankmon.isopen then
    r.defer(bankmon.loop)
  else
    save_state()
    r.ImGui_DestroyContext(ctx)
  end
end

r.defer(bankmon.loop)



function bankmon.ShowBankmonWindow()
  local visible, isopen = nil 

  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), bg_color)
  main_viewport = r.ImGui_GetMainViewport(ctx)
  work_pos = {r.ImGui_Viewport_GetWorkPos(main_viewport)}
  r.ImGui_SetNextWindowPos(ctx, work_pos[1] + 20, work_pos[2] + 20,r.ImGui_Cond_FirstUseEver() )
  r.ImGui_SetNextWindowSize(ctx, 0, 0, r.ImGui_Cond_Once()) -- NOte make sure to change this to first use after ui finalized

  if bankmon.dock_id then
    r.ImGui_SetNextWindowDockID(ctx, bankmon.dock_id)
    bankmon.dock_id = nil 
  end

  visible, isopen = r.ImGui_Begin(ctx, "Mavriq Bank Monitor", true)

  if not visible then return isopen end

  r.ImGui_SetNextItemWidth(ctx, 200)
  bankmon.bank_size = ({r.ImGui_DragInt(ctx, "Bank Size", bankmon.bank_size, 0.5, 0, 100, "%d", r.ImGui_SliderFlags_AlwaysClamp())})[2]
  r.ImGui_SameLine(ctx)
  HelpMarker("Enter the number sliders etc that are in one bank.")
  r.ImGui_SameLine(ctx)  
  r.ImGui_Dummy(ctx, 50, 20)
  r.ImGui_SameLine(ctx)  

  if r.ImGui_IsWindowDocked(ctx) then
    if r.ImGui_Button(ctx, "Undock", 60, 20) then
      bankmon.dock_id = 0
    end
  else
    if r.ImGui_Button(ctx, "Dock", 60, 20) then
      bankmon.dock_id = -1
    end
  end


  r.ImGui_SetNextItemWidth(ctx, 200)
  bankmon.realearn_param_num = ({r.ImGui_DragInt(ctx, "Realearn Parameter #", bankmon.realearn_param_num + 1, 0.5, 1, 200, "%d", r.ImGui_SliderFlags_AlwaysClamp())})[2] -1 
  r.ImGui_SameLine(ctx)
  HelpMarker("Enter the number that corrisponds to Realearn's parameter that holds the bank value. If you are using DAW Control that is parameter #1 in main. Controller compartment parameters start at #101")

  r.ImGui_SetNextItemWidth(ctx, 200)
  if r.ImGui_BeginCombo(ctx, "Realearn FX Chain", bankmon.fxchain_type) then
    local is_selected = bankmon.fxchain_type == "Monitoring"
    if r.ImGui_Selectable(ctx, "Monitoring", is_selected) then
      bankmon.fxchain_type = "Monitoring"
      r.ImGui_SetItemDefaultFocus(ctx)
      bankmon.fx_list = {}
      bankmon.realearn_fxchain_slot =  -1
    end
    is_selected = bankmon.fxchain_type == "Master"
    if r.ImGui_Selectable(ctx, "Master", is_selected) then
      bankmon.fxchain_type = "Master"
      r.ImGui_SetItemDefaultFocus(ctx)
      bankmon.fx_list = {}
      bankmon.realearn_fxchain_slot =  -1
    end
    is_selected = bankmon.fxchain_type == "Track"
    if r.ImGui_Selectable(ctx, "Track", is_selected) then
      bankmon.fxchain_type = "Track"
      r.ImGui_SetItemDefaultFocus(ctx)
      bankmon.fx_list = {}
      bankmon.realearn_fxchain_slot =  -1
    end
    r.ImGui_EndCombo(ctx)
  end

  if bankmon.fxchain_type ~= "Track" then
    r.ImGui_BeginDisabled(ctx)
  end
  r.ImGui_SetNextItemWidth(ctx, 200)
  rv, bankmon.realearn_track_num = r.ImGui_DragInt(ctx, "Track #", bankmon.realearn_track_num, 0.5, 1, 300, "%d", r.ImGui_SliderFlags_AlwaysClamp())
  if rv then
    bankmon.fx_list = {}
    bankmon.realearn_fxchain_slot =  -1
  end
  r.ImGui_SameLine(ctx)
  HelpMarker("Enter the track number where you want to target the ReaLearn instance in the FX Chain. Only enabled when Track is selected by ReaLearn FX Chain above.")
  if bankmon.fxchain_type ~= "Track" then
    r.ImGui_EndDisabled(ctx)
  end

  preview_text = "Select Relearn VST" 
  if bankmon.realearn_fxchain_slot ~= -1 then preview_text = bankmon.fx_list[bankmon.realearn_fxchain_slot] end
  r.ImGui_SetNextItemWidth(ctx, 200)
  if r.ImGui_BeginCombo(ctx, "FX List", preview_text) then    
    bankmon.get_FXList() 
    for i , fx_name in ipairs(bankmon.fx_list) do
      local is_selected = bankmon.realearn_fxchain_slot == i 
      if r.ImGui_Selectable(ctx, fx_name, is_selected) then 
        bankmon.realearn_fxchain_slot = i 
        r.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    r.ImGui_EndCombo(ctx)
  end
  
  bankmon.get_selected_bank()

  r.ImGui_Dummy(ctx, 50, 20)
  r.ImGui_SetNextItemWidth(ctx, 70)
  r.ImGui_LabelText(ctx, "Active Bank", bankmon.realearn_cur_bank)
  r.ImGui_SetNextItemWidth(ctx, 70)
    r.ImGui_LabelText(ctx, "Tracks", bankmon.bank_track_numbers)

    r.ImGui_PopStyleColor(ctx)

  r.ImGui_End(ctx)

  return isopen
end



function bankmon.get_selected_bank()
  if bankmon.realearn_fxchain_slot ~= -1 then
    local fx_pos = bankmon.realearn_fxchain_slot
    if bankmon.fxchain_type == "Monitoring" then
      fx_pos = fx_pos|0x1000000
    end

    local raw_bank_data = r.TrackFX_GetParamNormalized(bankmon.realearn_track, fx_pos - 1, bankmon.realearn_param_num)
      local dec_place = 10^(2)
      bankmon.realearn_cur_bank = math.floor(raw_bank_data * 12.5 * dec_place + 0.01) + 1

      local low_track_num = (bankmon.realearn_cur_bank - 1) * bankmon.bank_size + 1 
      local high_track_num = low_track_num + bankmon.bank_size - 1
      bankmon.bank_track_numbers = string.format("%.0f",low_track_num).." - "..string.format("%.0f",high_track_num)
  end
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



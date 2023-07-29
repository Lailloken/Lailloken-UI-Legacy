﻿#NoEnv
#SingleInstance, Force
#InstallKeybdHook
#InstallMouseHook
#Hotstring NoMouse
#Hotstring EndChars `n
#MaxThreads 100
#MaxMem 1024
#Include %A_ScriptDir%
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
OnMessage(0x0204, "LLK_Rightclick")
OnMessage(0x0200, "LLK_MouseMove")
SetKeyDelay, 20
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen
SendMode, Input
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2
SetBatchLines, -1
OnExit, Exit
Menu, Tray, Tip, Lailloken UI
#Include data\Class_CustomFont.ahk
font1 := New CustomFont("data\Fontin-SmallCaps.ttf")
timeout := 1
Menu, Tray, Icon, img\GUI\tray.ico

IniRead, enable_caps_toggling, ini\config.ini, Settings, enable CapsLock-toggling, 1
SetStoreCapsLockMode, %enable_caps_toggling%

If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}

SysGet, xborder, 32
SysGet, yborder, 33
SysGet, caption, 4

GroupAdd, poe_window, ahk_exe GeForceNOW.exe
GroupAdd, poe_window, ahk_exe boosteroid.exe
GroupAdd, poe_window, ahk_class POEWindowClass
GroupAdd, poe_ahk_window, ahk_class POEWindowClass
GroupAdd, poe_ahk_window, ahk_exe GeForceNOW.exe
GroupAdd, poe_ahk_window, ahk_exe boosteroid.exe
GroupAdd, poe_ahk_window, ahk_class AutoHotkeyGUI

IniRead, clone_frames_failcheck, ini\clone frames.ini
Loop, Parse, clone_frames_failcheck, `n, `n
{
	If InStr(A_LoopField, " ")
		IniDelete, ini\clone frames.ini, %A_LoopField%
}

If !FileExist("data\Resolutions.ini") || !FileExist("data\Class_CustomFont.ahk") || !FileExist("data\Fontin-SmallCaps.ttf") || !FileExist("data\JSON.ahk") || !FileExist("data\External Functions.ahk") || !FileExist("data\Map mods.ini")
|| !FileExist("data\Betrayal.ini") || !FileExist("data\Atlas.ini") || !FileExist("data\timeless jewels\") || !FileExist("data\leveling tracker\")
	LLK_Error("Critical files are missing. Make sure you have installed the script correctly.")

If !FileExist("ini\")
{
	FileCreateDir, ini\
	Sleep 250
}
If !FileExist("ini\")
	LLK_FilePermissionError("create")

IniRead, kill_timeout, ini\config.ini, Settings, kill-timeout, 1
IniRead, kill_script, ini\config.ini, Settings, kill script, 1

startup := A_TickCount

FileRead, json_mods, data\item info\mods.json
itemchecker_mod_data := Json.Load(json_mods)
json_mods := ""

FileRead, json_base_items, data\item info\base items.json
itemchecker_base_item_data := Json.Load(json_base_items)
json_base_items := ""

While !WinExist("ahk_group poe_window")
{
	If (A_TickCount >= startup + kill_timeout*60000) && (kill_script = 1)
		ExitApp
	win_not_exist := 1
	sleep, 100
}

If WinExist("ahk_group poe_window") && (win_not_exist = 1) ;band-aid fix for situations in which the script detected an unsupported resolution because the PoE-client window was being resized while launching
	client_start := A_TickCount

While (A_TickCount < client_start + 4000)
	sleep, 100

If !WinExist("ahk_exe GeForceNOW.exe") && !WinExist("ahk_exe boosteroid.exe")
{
	IniRead, poe_config_file, ini\config.ini, Settings, PoE config-file, %A_MyDocuments%\My Games\Path of Exile\production_Config.ini
	If !FileExist(poe_config_file)
	{
		FileSelectFile, poe_config_file, 3, %A_MyDocuments%\My Games\\production_Config.ini, Please locate the 'production_Config.ini' file which is stored in the same folder as loot-filters, config files (*.ini)
		If (ErrorLevel = 1) || !InStr(poe_config_file, "production_Config")
		{
			Reload
			ExitApp
		}
		FileRead, poe_config_check, % poe_config_file
		If !InStr(poe_config_check, "[Display]")
		{
			Reload
			ExitApp
		}
		IniWrite, "%poe_config_file%", ini\config.ini, Settings, PoE config-file
	}
	Else IniWrite, "%poe_config_file%", ini\config.ini, Settings, PoE config-file
	
	FileRead, poe_config_content, % poe_config_file
	If (poe_config_content = "")
		LLK_Error("Cannot read the PoE config-file. Please restart the game-client and then the script. If you still get this error repeatedly, please report the issue.`n`nError-message (for reporting): PoE-config returns empty")
	exclusive_fullscreen := InStr(poe_config_content, "`nfullscreen=true") ? "true" : InStr(poe_config_content, "fullscreen=false") ? "false" : ""
	If (exclusive_fullscreen = "")
	{
		IniDelete, ini\config.ini, Settings, PoE config-file
		LLK_Error("Cannot read the PoE config-file.`n`nThe script will restart and reset the first-time setup. If you still get this error repeatedly, please report the issue.`n`nError-message (for reporting): Cannot read state of exclusive fullscreen", 1)
	}
	Else If (exclusive_fullscreen = "true")
		LLK_Error("The game-client is set to exclusive fullscreen.`nPlease set it to windowed fullscreen.")
	
	fullscreen := InStr(poe_config_content, "borderless_windowed_fullscreen=true") ? "true" : InStr(poe_config_content, "borderless_windowed_fullscreen=false") ? "false" : ""
	If (fullscreen = "")
	{
		IniDelete, ini\config.ini, Settings, PoE config-file
		LLK_Error("Cannot read the PoE config-file.`n`nThe script will restart and reset the first-time setup. If you still get this error repeatedly, please report the issue.`n`nError-message (for reporting): Cannot read state of borderless fullscreen", 1)
	}
	IniRead, fullscreen_last, ini\config.ini, Settings, fullscreen, % A_Space
	If (fullscreen_last != fullscreen)
	{
		IniWrite, % fullscreen, ini\config.ini, Settings, fullscreen
		IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
	}
}
Else IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
	
hwnd_poe_client := WinExist("ahk_group poe_window")
last_check := A_TickCount
WinGetPos, xScreenOffset_initial, yScreenOffset_initial, poe_width_initial, poe_height_initial, ahk_group poe_window
poe_width := poe_width_initial, poe_height := poe_height_initial
xScreenOffSet := xScreenOffset_initial, yScreenOffSet := yScreenOffset_initial

;############################################################ delete old files from previous versions, or files that have been moved elsewhere
If FileExist("Resolutions.ini")
	FileDelete, Resolutions.ini
If FileExist("Class_CustomFont.ahk")
	FileDelete, Class_CustomFont.ahk
If FileExist("External Functions.ahk")
	FileDelete, External Functions.ahk
If FileExist("Fontin-SmallCaps.ttf")
	FileDelete, Fontin-SmallCaps.ttf
If FileExist("ini\lake helper.ini")
	FileDelete, ini\lake helper.ini
If FileExist("modules\overlayke.ahk")
	FileDelete, modules\overlayke.ahk
If FileExist("modules\gwennen regex.ahk")
	FileDelete, modules\gwennen regex.ahk
If FileExist("data\leveling tracker\gems.txt")
	FileDelete, data\leveling tracker\gems.txt
If FileExist("modules\bestiary search.ahk")
	FileDelete, modules\bestiary search.ahk
If FileExist("data\map search.ini")
	FileDelete, data\map search.ini
If FileExist("_ini\")
	FileRemoveDir, _ini\, 1
If FileExist("img\_Fallback\")
	FileRemoveDir, img\_Fallback\, 1
If FileExist("img\Recognition (" poe_height "p)\Sanctum\")
	FileRemoveDir, % "img\Recognition (" poe_height "p)\Sanctum\", 1
If FileExist("modules\sanctum.ahk")
	FileDelete, modules\sanctum.ahk
If FileExist("data\sanctum.ini")
	FileDelete, data\sanctum.ini
If FileExist("img\GUI\sanctum.jpg")
	FileDelete, img\GUI\sanctum.jpg
If FileExist("launcher.ahk")
	FileDelete, launcher.ahk
;############################################################

;determine native resolution of the active monitor
Gui, Test: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption
WinSet, Trans, 0
Gui, Test: Show, NA x%xScreenOffset% y%yScreenOffset% Maximize
WinGetPos, xScreenOffset_monitor, yScreenOffSet_monitor, width_native, height_native
Gui, Test: Destroy

IniRead, supported_resolutions, data\Resolutions.ini
supported_resolutions := "," StrReplace(supported_resolutions, "`n", ",")

WinGet, poe_log_file, ProcessPath, ahk_group poe_window
poe_log_file := FileExist(SubStr(poe_log_file, 1, InStr(poe_log_file, "\",,,LLK_InStrCount(poe_log_file, "\"))) "logs\client.txt") ? SubStr(poe_log_file, 1, InStr(poe_log_file, "\",,,LLK_InStrCount(poe_log_file, "\"))) "logs\client.txt" : SubStr(poe_log_file, 1, InStr(poe_log_file, "\",,,LLK_InStrCount(poe_log_file, "\"))) "logs\kakaoclient.txt"
	
If FileExist(poe_log_file)
{
	poe_log := FileOpen(poe_log_file, "r")
	poe_log_content := poe_log.Read()
	Loop, Parse, poe_log_content, `n, `r
	{
		If InStr(A_Loopfield, "generating level")
		{
			current_location := SubStr(A_Loopfield, InStr(A_Loopfield, "area """) + 6)
			current_location := SubStr(current_location, 1, InStr(current_location, """") -1) ;save PoE-internal location name in var
			in_lab := InStr(current_location, "labyrinth_") ? 1 : 0
			
			current_area_tier := SubStr(A_LoopField, InStr(A_LoopField, "level ") + 6, InStr(A_LoopField, " area """) - InStr(A_LoopField, "level ") - 6) - 67
			current_area_level := current_area_tier + 67
			If (current_area_tier > 0)
				current_area_tier := (current_area_tier < 10) ? 0 current_area_tier : current_area_tier ;save map-tier in var
		}
		If in_lab && InStr(A_LoopField, ": you have entered ")
		{
			lab_location_verbose := SubStr(A_LoopField, InStr(A_LoopField, "you have entered") + 17, -1)
			lab_location := current_location
		}
	}
	leveling_guide_fresh_login := 1
}
Else poe_log_file := 0

If (fullscreen = "false")
{
	poe_width -= xborder*2
	poe_height := poe_height - caption - yborder*2
	xScreenOffSet += xborder
	yScreenOffSet += caption + yborder
}

IniRead, fSize_config0, data\Resolutions.ini, %poe_height%p, font-size0, 16
IniRead, fSize_config1, data\Resolutions.ini, %poe_height%p, font-size1, 14
fSize0 := fSize_config0
fSize1 := fSize_config1

IniRead, window_docking, ini\config.ini, Settings, top-docking, 1
IniRead, custom_resolution_setting, ini\config.ini, Settings, enable custom-resolution
If (custom_resolution_setting != 0) && (custom_resolution_setting != 1)
{
	IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
	custom_resolution_setting := 0
}

If (custom_resolution_setting = 1)
{
	IniRead, custom_resolution, ini\config.ini, Settings, custom-resolution
	IniRead, custom_width, ini\config.ini, Settings, custom-width
	If !IsNumber(custom_resolution) || !IsNumber(custom_width)
	{
		MsgBox, Incorrect config.ini settings detected: custom resolution enabled but none selected.`nThe setting will be reset and the script restarted.
		IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
		Reload
		ExitApp
	}

	If (custom_resolution > height_native) || (custom_width > width_native) ;check resolution in case of manual .ini edit
	{
		MsgBox, Incorrect config.ini settings detected.`nThe script will now exit.
		IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
		IniWrite, %height_native%, ini\config.ini, Settings, custom-resolution
		IniWrite, %width_native%, ini\config.ini, Settings, custom-width
		ExitApp
	}
	If (fullscreen = "true")
		WinMove, ahk_group poe_window,, % xScreenOffset_monitor, % yScreenOffset_monitor, % poe_width, %custom_resolution%
	Else
	{
		WinMove, ahk_group poe_window,,, % (window_docking = 0) ? "" : yScreenOffset_monitor, % custom_width + xborder*2, % custom_resolution + caption + yborder*2
		WinGetPos, xScreenOffSet, yScreenOffSet,,, ahk_group poe_window
		xScreenOffSet += xborder
		yScreenOffSet += caption + yborder
		poe_width := custom_width
	}
	poe_height := custom_resolution
	IniRead, fSize_config0, data\Resolutions.ini, %poe_height%p, font-size0, 16
	IniRead, fSize_config1, data\Resolutions.ini, %poe_height%p, font-size1, 14
	fSize0 := fSize_config0
	fSize1 := fSize_config1
}

If !FileExist("img\Recognition (" poe_height "p)\GUI\")
	FileCreateDir, img\Recognition (%poe_height%p)\GUI\
If !FileExist("img\Recognition (" poe_height "p)\Betrayal\")
	FileCreateDir, img\Recognition (%poe_height%p)\Betrayal\

Sleep, 250

If !FileExist("img\Recognition (" poe_height "p)\")
	LLK_FilePermissionError("create")

GoSub, Init_variables
GoSub, Init_screenchecks
GoSub, Init_general
GoSub, Init_alarm
GoSub, Init_betrayal
GoSub, Init_cheatsheets
GoSub, Init_cloneframes
GoSub, Init_delve
If WinExist("ahk_exe GeForceNOW.exe") || WinExist("ahk_exe boosteroid.exe")
	GoSub, Init_geforce
GoSub, Init_hotkeys
GoSub, Init_itemchecker
GoSub, Init_legion
GoSub, Init_maps
GoSub, Init_notepad
GoSub, Init_searchstrings
GoSub, Init_leveling_guide
GoSub, Init_map_tracker
GoSub, Resolution_check
GoSub, Init_conversions

SetTimer, Loop, 1000
SetTimer, Log_loop, 1000

timeout := 0
If (custom_resolution_setting = 1)
	WinActivate, ahk_group poe_window
If !enable_startup_beep
	WinWaitActive, ahk_group poe_window
Else WinWaitActive, ahk_group poe_ahk_window

If enable_startup_beep
	SoundBeep, 100

GoSub, GUI
GoSub, Recombinators
GoSub, Lab_info

If (clone_frames_enabled != "")
	GoSub, GUI_clone_frames

SetTimer, MainLoop, 100
If (update_available = 1)
	ToolTip, % "New version available: " version_online "`nCurrent version:  " version_installed "`nPress TAB to open the release page.`nPress ESC to dismiss this notification.", % xScreenOffSet + poe_width/2*0.9, % yScreenOffSet

IniRead, restart_section, ini\config.ini, Versions, reload settings, % A_Space
If restart_section
	GoSub, Settings_menu
IniDelete, ini\config.ini, Versions, reload settings
Return

#Include *i modules\hotkeys custom.ahk

#Include modules\hotkeys.ahk

#Include modules\alarm-timer.ahk

Apply_settings_general:
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "custom_resolution_apply")
{
	custom_width := (custom_width > width_native) ? width_native : custom_width
	poe_width := (fullscreen = "true") ? width_native : custom_width
	If (fullscreen = "false")
	{
		custom_resolution += caption + yborder*2
		poe_width += (poe_width > width_native) ? 0 : xborder*2
	}
	WinMove, ahk_group poe_window,, % (fullscreen = "false") ? xScreenOffset_monitor - xborder : xScreenOffset_monitor, %yScreenOffset_monitor%, %poe_width%, %custom_resolution%
	WinGetPos,,, poe_width, custom_resolution, ahk_group poe_window
	If (fullscreen = "false")
	{
		xScreenOffSet := (poe_width < width_native) ? xScreenOffset_monitor + (width_native - poe_width)/2 : xScreenOffset_monitor - xborder
		yScreenOffSet := (custom_resolution < height_native) ? yScreenOffset_monitor + (height_native - custom_resolution)/2 : yScreenOffset_monitor - yborder - caption
		WinMove, ahk_group poe_window,, %xScreenOffSet%, % (window_docking = 1) ? yScreenOffset_monitor : yScreenOffSet_monitor + (height_native - custom_resolution)/2, %poe_width%, %custom_resolution%
	}
	IniWrite, %custom_resolution_setting%, ini\config.ini, Settings, enable custom-resolution
	IniWrite, % (fullscreen = "false") ? custom_resolution - caption - yborder*2 : custom_resolution, ini\config.ini, Settings, custom-resolution
	IniWrite, % (fullscreen = "false") ? custom_width : width_native, ini\config.ini, Settings, custom-width
	IniWrite, % settings_menu_section, ini\config.ini, Versions, reload settings
	Reload
	ExitApp
}

If (A_GuiControl = "custom_resolution_setting")
{
	IniWrite, % %A_GuiControl%, ini\config.ini, Settings, enable custom-resolution
	Return
}
If (A_GuiControl = "window_docking")
{
	IniWrite, % %A_GuiControl%, ini\config.ini, Settings, top-docking
	Return
}

If (A_GuiControl = "interface_size_minus")
{
	fSize_offset -= 1
	IniWrite, %fSize_offset%, ini\config.ini, UI, font-offset
}
If (A_GuiControl = "interface_size_plus")
{
	fSize_offset += 1
	IniWrite, %fSize_offset%, ini\config.ini, UI, font-offset
}
If (A_GuiControl = "interface_size_reset")
{
	fSize_offset := 0
	IniWrite, %fSize_offset%, ini\config.ini, UI, font-offset
}
fSize0 := fSize_config0 + fSize_offset
fSize1 := fSize_config1 + fSize_offset

Gui, font_size: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_font_size
Gui, font_size: Margin, 0, 0
Gui, font_size: Color, Black
Gui, font_size: Font, % "cWhite s"fSize0, Fontin SmallCaps
Gui, font_size: Add, Text, % "Border HWNDmain_text", % "7"
GuiControlGet, font_check_, Pos, % main_text
font_height := font_check_h
font_width := font_check_w
Gui, font_size: Destroy
hwnd_font_size := ""

If (A_GuiControl = "kill_script")
	IniWrite, %kill_script%, ini\config.ini, Settings, kill script
If (A_GuiControl = "kill_timeout")
{
	kill_timeout := (kill_timeout = "") ? 0 : kill_timeout
	IniWrite, %kill_timeout%, ini\config.ini, Settings, kill-timeout
}
If (A_GuiControl = "panel_position0")
	IniWrite, %panel_position0%, ini\config.ini, UI, panel-position0
If (A_GuiControl = "panel_position1")
	IniWrite, %panel_position1%, ini\config.ini, UI, panel-position1
If (A_GuiControl = "hide_panel")
	IniWrite, %hide_panel%, ini\config.ini, UI, hide panel
If (A_GuiControl = "enable_browser_features")
	IniWrite, %enable_browser_features%, ini\config.ini, Settings, enable browser features
If (A_GuiControl = "enable_caps_toggling")
{
	IniWrite, %enable_caps_toggling%, ini\config.ini, Settings, enable CapsLock-toggling
	IniWrite, % settings_menu_section, ini\config.ini, Versions, reload settings
	Reload
	ExitApp
}
SetTimer, Settings_menu, 10
GoSub, GUI
WinActivate, ahk_group poe_window
Return

#Include modules\betrayal-info.ahk

#Include modules\cheat sheets.ahk

#Include modules\clone-frames.ahk

#Include modules\delve-helper.ahk

Exit:
Gdip_Shutdown(pToken)
poe_log.Close()
If (map_tracker_map != "")
	LLK_MapTrackSave()
If (timeout != 1)
{
	If !(alarm_timestamp < A_Now) && (alarm_loop != 1) && enable_alarm
		IniWrite, %alarm_timestamp%, ini\alarm.ini, Settings, alarm-timestamp
	
	If enable_notepad
	{
		IniWrite, %notepad_width%, ini\notepad.ini, UI, width
		IniWrite, %notepad_height%, ini\notepad.ini, UI, height
		notepad_text := StrReplace(notepad_text, "`n", ",,")
		IniWrite, %notepad_text%, ini\notepad.ini, Text, text
	}
	
	If enable_itemchecker_gear
	{
		Loop, Parse, gear_slots, `,
			IniWrite, % equipped_%A_LoopField%, ini\item-checker gear.ini, % A_LoopField
	}
	
	Loop, Parse, clone_frames_list, `n, `n
	{
		If (A_LoopField = "Settings")
			continue
		IniWrite, % clone_frame_%A_LoopField%_enable, ini\clone frames.ini, %A_LoopField%, enable
	}
	
	IniRead, guide_progress_ini, ini\leveling guide.ini, Progress,, % A_Space
	If (guide_progress != "") && (guide_progress != guide_progress_ini)
	{
		IniDelete, ini\leveling guide.ini, Progress
		IniWrite, % guide_progress, ini\leveling guide.ini, Progress
	}
	
	IniRead, leveling_guide_skilltree_last_ini, ini\leveling tracker.ini, Settings, last skilltree-image, % A_Space
	If (leveling_guide_skilltree_last != "") && (leveling_guide_skilltree_last != leveling_guide_skilltree_last_ini) && (leveling_guide_skilltree_last_ini != "")
		IniWrite, "%leveling_guide_skilltree_last%", ini\leveling tracker.ini, Settings, last skilltree-image
	
	IniRead, leveling_guide_time_ini, ini\leveling tracker.ini, current run, time, 0
	If (leveling_guide_time_ini != leveling_guide_time)
		IniWrite, % leveling_guide_time, ini\leveling tracker.ini, current run, time
}
ExitApp
Return

Geforce_now_apply:
Gui, settings_menu: Submit, NoHide
pixelsearch_variation := (pixelsearch_variation = "") ? 0 : pixelsearch_variation
pixelsearch_variation := (pixelsearch_variation > 255) ? 255 : pixelsearch_variation
imagesearch_variation := (imagesearch_variation = "") ? 0 : imagesearch_variation
imagesearch_variation := (imagesearch_variation > 255) ? 255 : imagesearch_variation
If (A_GuiControl = "pixelsearch_variation")
	IniWrite, % pixelsearch_variation, ini\geforce now.ini, Settings, pixel-check variation
If (A_GuiControl = "imagesearch_variation")
	IniWrite, % imagesearch_variation, ini\geforce now.ini, Settings, image-check variation
Return

#Include modules\GUI.ahk

Init_conversions:
IniRead, ini_version, ini\config.ini, Versions, ini-version, 0
If (ini_version < 12406) && FileExist("ini\pixel checks (" poe_height "p).ini") ;migrate pixel-check settings to screen-checks ini
{
	IniRead, pixel_gamescreen_color1, ini\pixel checks (%poe_height%p).ini, gamescreen, color 1
	IniRead, convert_pixelchecks, ini\pixel checks (%poe_height%p).ini, gamescreen
	IniWrite, % convert_pixelchecks, ini\screen checks (%poe_height%p).ini, gamescreen
	FileDelete, ini\pixel checks*.ini
}

If (ini_version < 12808)
{
	itemchecker_highlight := StrReplace(itemchecker_highlight, "added small passive skills also grant: ")
	itemchecker_highlight := StrReplace(itemchecker_highlight, "added Passive Skill is ")
	itemchecker_blacklist := StrReplace(itemchecker_blacklist, "added small passive skills also grant: ")
	itemchecker_blacklist := StrReplace(itemchecker_blacklist, "added Passive Skill is ")
	
	IniWrite, % itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods
	IniWrite, % itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods
}

If (ini_version < 12900) ;clean up item-info: highlight- and blacklist, default colors
{
	itemchecker_highlight := StrReplace(itemchecker_highlight, ".")
	While InStr(itemchecker_highlight, "  ")
		itemchecker_highlight := StrReplace(itemchecker_highlight, "  ", " ")
	
	Loop, parse, itemchecker_highlight, |
	{
		If (A_Index = 1)
			itemchecker_highlight := ""
		If (A_LoopField = "")
			continue
		parse := A_LoopField
		While (SubStr(parse, 1, 1) = " ")
			parse := SubStr(parse, 2)
		While (SubStr(parse, 0) = " ")
			parse := SubStr(parse, 1, -1)
		itemchecker_highlight .= InStr(itemchecker_highlight, "|" parse "|") ? "" : "|" parse "|"
	}
	
	itemchecker_blacklist := StrReplace(itemchecker_blacklist, ".")
	While InStr(itemchecker_blacklist, "  ")
		itemchecker_blacklist := StrReplace(itemchecker_blacklist, "  ", " ")
	
	Loop, parse, itemchecker_blacklist, |
	{
		If (A_Index = 1)
			itemchecker_blacklist := ""
		If (A_LoopField = "")
			continue
		parse := A_LoopField
		While (SubStr(parse, 1, 1) = " ")
			parse := SubStr(parse, 2)
		While (SubStr(parse, 0) = " ")
			parse := SubStr(parse, 1, -1)
		itemchecker_blacklist .= InStr(itemchecker_blacklist, "|" parse "|") || InStr(itemchecker_highlight, "|" parse "|") ? "" : "|" parse "|"
	}
	
	IniWrite, % itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods
	IniWrite, % itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods
	
	If (itemchecker_t1_color = "00ff00")
	{
		itemchecker_t1_color := "00bb00"
		IniWrite, % itemchecker_t1_color, ini\item-checker.ini, UI, tier 1
	}
	If (itemchecker_t5_color = "dc143c")
	{
		itemchecker_t5_color := "ff4040"
		IniWrite, % itemchecker_t5_color, ini\item-checker.ini, UI, tier 5
	}
	If (itemchecker_t6_color = "800000")
	{
		itemchecker_t6_color := "aa0000"
		IniWrite, % itemchecker_t6_color, ini\item-checker.ini, UI, tier 6
	}
	
	If (itemchecker_ilvl2_color = "00ff00")
	{
		itemchecker_ilvl2_color := "00bb00"
		IniWrite, % itemchecker_ilvl2_color, ini\item-checker.ini, UI, ilvl tier 2
	}
	If (itemchecker_ilvl6_color = "dc143c")
	{
		itemchecker_ilvl6_color := "ff4040"
		IniWrite, % itemchecker_ilvl6_color, ini\item-checker.ini, UI, ilvl tier 6
	}
	If (itemchecker_ilvl7_color = "800000")
	{
		itemchecker_ilvl7_color := "aa0000"
		IniWrite, % itemchecker_ilvl7_color, ini\item-checker.ini, UI, ilvl tier 7
	}
}

If (ini_version < 12903) ;move Gwennen regex-string to search-strings config
{
	IniRead, gwennen_check, ini\gwennen.ini, regex, regex, %A_Space%
	If (gwennen_check != "")
	{
		gwennen_check := """" gwennen_check """"
		IniWrite, (gwennen_1)`,, ini\stash search.ini, Settings, gwennen
		IniWrite, 1, ini\stash search.ini, gwennen_1, enable
		IniWrite, "%gwennen_check%", ini\stash search.ini, gwennen_1, string 1
		IniWrite, 0, ini\stash search.ini, gwennen_1, string 1 enable scrolling
		IniWrite, "", ini\stash search.ini, gwennen_1, string 2
		IniWrite, 0, ini\stash search.ini, gwennen_1, string 2 enable scrolling
	}
	FileDelete, ini\gwennen.ini
}

If (ini_version < 12905)
{
	FileDelete, img\GUI\item_info_*.png
	IniRead, itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods, %A_Space%
	IniRead, itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods, %A_Space%
	IniRead, itemchecker_highlight_implicits, ini\item-checker.ini, settings, highlighted implicits, %A_Space%
	IniRead, itemchecker_blacklist_implicits, ini\item-checker.ini, settings, blacklisted implicits, %A_Space%
	IniWrite, % itemchecker_highlight, ini\item-checker.ini, highlighting 1, highlight
	IniWrite, % itemchecker_highlight_implicits, ini\item-checker.ini, highlighting 1, highlight implicits
	IniWrite, % itemchecker_blacklist, ini\item-checker.ini, highlighting 1, blacklist
	IniWrite, % itemchecker_blacklist_implicits, ini\item-checker.ini, highlighting 1, blacklist implicits
	IniDelete, ini\item-checker.ini, settings, highlighted mods
	IniDelete, ini\item-checker.ini, settings, highlighted implicits
	IniDelete, ini\item-checker.ini, settings, blacklisted mods
	IniDelete, ini\item-checker.ini, settings, blacklisted implicits
	GoSub, Init_itemchecker
}

If (ini_version < 12905.1)
{
	Loop 5
		IniDelete, ini\item-checker.ini, highlighting %A_Index%*
}

If (ini_version < 13001)
{
	If InStr(buggy_resolutions, poe_height)
		LLK_Error("The script needs to convert some settings for an updated feature, but it couldn't correctly read your client-resolution.`nIt will now restart.", 1)
	conversion_searchstrings := "stash,gwennen,vendor,bestiarydex"
	Loop, Parse, conversion_searchstrings, `,
	{
		conversion_search := (A_LoopField = "bestiarydex") ? "beast index" : A_LoopField
		IniRead, conversion_strings, ini\stash search.ini, Settings, % A_LoopField, % A_Space
		If conversion_strings
		{
			IniWrite, 1, ini\search-strings.ini, searches, % conversion_search
			IniRead, conversion_coordinates, ini\screen checks (%poe_height%p).ini, % A_LoopField, last coordinates, % A_Space
			IniWrite, % conversion_coordinates, ini\search-strings.ini, % conversion_search, last coordinates
			If (A_LoopField = "stash")
				FileCopy, % "img\Recognition ("poe_height "p)\GUI\" A_LoopField ".bmp", % "img\Recognition ("poe_height "p)\GUI\[search-strings] " A_LoopField ".bmp", 1
			Else
			{
				FileMove, % "img\Recognition ("poe_height "p)\GUI\" A_LoopField ".bmp", % "img\Recognition ("poe_height "p)\GUI\[search-strings] " conversion_search ".bmp", 1
				IniDelete, ini\screen checks (%poe_height%p).ini, % A_LoopField
			}
		}
		Else continue
		
		Loop, Parse, conversion_strings, `,, ()
		{
			If (A_LoopField = "")
				continue
			conversion_string := A_LoopField
			IniRead, conversion_string1, ini\stash search.ini, % conversion_string, string 1, % A_Space
			IniRead, conversion_string2, ini\stash search.ini, % conversion_string, string 2, % A_Space
			
			If (conversion_string = "tracker_gems")
			{
				IniWrite, 1, ini\search-strings.ini, searches, hideout lilly
				IniWrite, % "", ini\search-strings.ini, hideout lilly, last coordinates
				IniWrite, % """" StrReplace(conversion_string1, ";", " " ";;;" " ") """", ini\search-strings.ini, hideout lilly, 00-exile leveling gems
				continue
			}
			
			If conversion_string1 && !conversion_string2
				IniWrite, % """" StrReplace(conversion_string1, ";", " " ";;;" " ") """", ini\search-strings.ini, % conversion_search, % StrReplace(conversion_string, "_", " ")
			Else If conversion_string1 && conversion_string2
			{
				IniWrite, % """" StrReplace(conversion_string1, ";", " " ";;;" " ") """", ini\search-strings.ini, % conversion_search, % StrReplace(conversion_string, "_", " ") " 1"
				IniWrite, % """" StrReplace(conversion_string2, ";", " " ";;;" " ") """", ini\search-strings.ini, % conversion_search, % StrReplace(conversion_string, "_", " ") " 2"
			}
		}
		IniRead, conversion_check, ini\search-strings.ini, vendor,, % A_Space ;double-check the vendor searches after conversion in order to see if it's blank now because the gem-string was the only one to be converted
		If !InStr(conversion_check, "`n")
		{
			IniDelete, ini\search-strings.ini, vendor
			IniDelete, ini\search-strings.ini, searches, vendor
		}
	}
	
	IniRead, conversion_coordinates, ini\screen checks (%poe_height%p).ini, bestiary, last coordinates, % A_Space
	IniWrite, % conversion_coordinates, ini\search-strings.ini, beast crafting, last coordinates
	IniDelete, ini\screen checks (%poe_height%p).ini, bestiary
	FileMove, % "img\Recognition ("poe_height "p)\GUI\bestiary.bmp", % "img\Recognition ("poe_height "p)\GUI\[search-strings] beast crafting.bmp", 1
	
	GoSub, Init_searchstrings
	
	FileDelete, img\GUI\gwennen.jpg
	FileDelete, img\GUI\bestiary.jpg
	FileDelete, img\GUI\vendor.jpg
	FileDelete, img\GUI\bestiary-dex.jpg
}

If (ini_version < 13002)
{
	If FileExist("ini\map info.ini")
		FileCopy, ini\map info.ini, ini\map info pre-1.30.2.ini, 1
	
	IniDelete, ini\map info.ini, Version
	IniDelete, ini\map info.ini, Settings, enable pixel-check
	IniDelete, ini\map info.ini, Settings, transparency
	IniDelete, ini\map info.ini, Settings, side
	IniDelete, ini\map info.ini, Settings, short descriptions
	IniDelete, ini\map info.ini, Settings, x-coordinate
	IniDelete, ini\map info.ini, Settings, y-coordinate
	
	Loop 99
		IniDelete, ini\map info.ini, % (A_Index < 10) ? "00" A_Index : "0" A_Index
	
	IniWrite, % "", ini\map info.ini, UI
	IniWrite, % "", ini\map info.ini, last map ;create a section for a potential reload feature in case of hard crashes
}

If (ini_version < 13003)
{
	IniWrite, % "", ini\leveling tracker.ini, current run, time
	IniWrite, % "", ini\leveling tracker.ini, current run, name
	Loop 10
		IniWrite, % "", ini\leveling tracker.ini, current run, act %A_Index%
	
	IniDelete, ini\screen checks (%poe_height%p).ini, sanctum
	IniRead, conversion, ini\screen checks (%poe_height%p).ini
	Loop, Parse, conversion, `n
	{
		If (A_LoopField = "")
			continue
		IniDelete, ini\screen checks (%poe_height%p).ini, % A_LoopField, disable
	}
}

If (ini_version < 13004)
{
	IniDelete, ini\timeless jewels.ini, Settings
	Loop 5
		IniDelete, ini\timeless jewels.ini, % (A_Index = 1) ? "favorites" : "favorites_" A_Index
}

If (ini_version < 13005)
{
	IniRead, conversion, ini\config.ini, Settings, highlight-key, % A_Space
	IniDelete, ini\config.ini, Settings, highlight-key
	If conversion
	{
		IniWrite, 1, ini\hotkeys.ini, Settings, advanced item-info rebound
		IniWrite, % conversion, ini\hotkeys.ini, Hotkeys, item-descriptions key
	}
	
	IniRead, conversion, ini\config.ini, Settings, omni-hotkey, % A_Space
	IniDelete, ini\config.ini, Settings, omni-hotkey
	If conversion
		IniWrite, % conversion, ini\hotkeys.ini, Hotkeys, omni-hotkey
	
	IniRead, conversion, ini\config.ini, Settings, omni-hotkey2, % A_Space
	IniDelete, ini\config.ini, Settings, omni-hotkey2
	If conversion
	{
		IniWrite, 1, ini\hotkeys.ini, Settings, c-key rebound
		IniWrite, % conversion, ini\hotkeys.ini, Hotkeys, omni-hotkey2
	}
}

IniWrite, 13005, ini\config.ini, Versions, ini-version ;1.24.1 = 12401, 1.24.10 = 12410, 1.24.1-hotfixX = 12401.X

If (ini_version < 13005)
{
	Reload
	ExitApp
	Return
}
Return

Init_geforce:
IniRead, pixelsearch_variation, ini\geforce now.ini, Settings, pixel-check variation, 0
IniRead, imagesearch_variation, ini\geforce now.ini, Settings, image-check variation, 25
Return

Init_general:
IniRead, enable_startup_beep, ini\config.ini, Settings, beep, 0
IniRead, panel_xpos, ini\config.ini, UI, button xcoord, 0
IniRead, panel_ypos, ini\config.ini, UI, button ycoord, 0
IniRead, hide_panel, ini\config.ini, UI, hide panel, 0

IniRead, enable_notepad, ini\config.ini, Features, enable notepad, 0
IniRead, enable_alarm, ini\config.ini, Features, enable alarm, 0
IniRead, enable_pixelchecks, ini\config.ini, Settings, background pixel-checks, 1
IniRead, enable_browser_features, ini\config.ini, Settings, enable browser features, 1
IniRead, settings_enable_maptracker, ini\config.ini, Features, enable map tracker, 0
IniRead, enable_map_info, ini\config.ini, Features, enable map-info panel, 0

IniRead, game_version, ini\config.ini, Versions, game-version, 31800 ;3.17.4 = 31704, 3.17.10 = 31710
IniRead, fSize_offset, ini\config.ini, UI, font-offset, 0
fSize0 := fSize_config0 + fSize_offset
fSize1 := fSize_config1 + fSize_offset

IniRead, ultrawide_warning, ini\config.ini, Versions, ultrawide warning, 0
Return

Init_variables:
click := 1
trans := 230
write_test_running := 0
hwnd_win_hover := 0
hwnd_control_hover := 0
blocked_hotkeys := "!,^,+"
pixel_inventory_x1 := 0, pixel_inventory_x2 := 0, pixel_inventory_x3 := 6
pixel_inventory_y1 := 0, pixel_inventory_y2 := 6, pixel_inventory_y3 := 0
inventory := 0
imagesearch_variation := 15
pixelsearch_variation := 0
imagechecks_list := "skilltree,betrayal" ;sorted for better omni-key performance: image-checks with fixed coordinates are checked first, then dynamic ones
imagechecks_list_copy := imagechecks_list ",stash" ;will be sorted alphabetically for screen-checks section in the menu
Sort, imagechecks_list_copy, D`,
scrollboards := 0
lab_mode := 0, lab_checkpoint := 0
guilist := "LLK_panel|notepad_edit|notepad|notepad_sample|alarm|alarm_sample|mapinfo_panel|map_mods_toggle|betrayal_info|betrayal_info_overview|betrayal_search|betrayal_info_members|"
guilist .= "betrayal_prioview_transportation|betrayal_prioview_fortification|betrayal_prioview_research|betrayal_prioview_intervention|legion_window|legion_list|legion_treemap|legion_treemap2|notepad_drag|itemchecker|map_tracker|map_tracker_log|"
guilist .= "cheatsheet|settings_menu|"
buggy_resolutions := "768,1024,1050"
allowed_recomb_classes := "shield,sword,quiver,bow,claw,dagger,mace,ring,amulet,helmet,glove,boot,belt,wand,staves,axe,sceptre,body,sentinel"
delve_directions := "u,d,l,r,"
gear_tracker_limit := 6
gear_tracker_filter := 1
global affixes := [], affix_tiers := [], affix_levels := [], item_type
Loop 20
{
	hwnd_itemchecker_panel%A_Index% := ""
	hwnd_itemchecker_panel%A_Index%_text := ""
	hwnd_itemchecker_panel%A_Index%_button := ""
	itemchecker_panel%A_Index%_tooltip := ""
	hwnd_itemchecker_implicit%A_Index% := ""
	hwnd_itemchecker_implicit%A_Index%_text := ""
	hwnd_itemchecker_implicit%A_Index%_button := ""
	hwnd_itemchecker_implicit%A_Index%_button1 := ""
	hwnd_itemchecker_tier%A_Index%_button := ""
	hwnd_itemchecker_ilvl%A_Index%_button := ""
}
hwnd_itemchecker_cluster := ""
hwnd_itemchecker_cluster_text := ""
hwnd_itemchecker_cluster_button := ""
hwnd_itemchecker_cluster_button1 := ""
hwnd_pob_crop1 := ""
gear_mouse_over := 0
gear_slots := "mainhand,offhand,helmet,body,amulet,ring1,ring2,belt,gloves,boots"
leveling_guide_landmarks := "encampment entrance, as the waypoint, by entrances, pillars near the waypoint, touching the road, broken waypoint, petrified soldiers, opposite the waypoint, west wall"
leveling_guide_skilltree_active := 1, leveling_guide_valid_skilltree_files := 0, enable_omnikey_pob := 0, leveling_guide_screencap_caption := "", leveling_guide_valid_images := ""

LLK_FontSize(fSize0, font_height, font_width)
Return

#Include modules\item-checker.ahk

#Include modules\lab-info.ahk

#Include modules\seed-explorer.ahk

#Include modules\leveling tracker.ahk

Log_loop:
;function quick-jump: LLK_MapTrack(), LLK_MapTrackSave()
If !WinActive("ahk_group poe_ahk_window") || (poe_log_file = 0)
{
	map_entered += 1000
	Return
}

If !map_tracker_paused && (map_tracker_map != "")
{
	If (map_tracker_refresh_kills = 1)
	{
		SetTimer, LLK_MapTrackKillStart, 10
		/*
		map_tracker_panel_color := (map_tracker_panel_color = "green") ? "black" : "green"
		Gui, map_tracker: Color, % map_tracker_panel_color
		WinSet, Redraw,, ahk_id %hwnd_map_tracker%
		*/
	}
	Else If (map_tracker_refresh_kills = 2)
	{
		Gui, map_tracker: Color, Green
		map_tracker_panel_color := "Green"
		GuiControl, map_tracker: +BackgroundGreen, map_tracker_button_complete_bar
		WinSet, Redraw,, ahk_id %hwnd_map_tracker%
		map_tracker_refresh_kills := 3
	}
	
	If InStr(map_tracker_map, current_location) || ((map_tracker_enable_side_areas = 1) && (InStr(current_location, "abyssleague") || InStr(current_location, "labyrinth_trials") || InStr(current_location, "mapsidearea"))) ;advance map-timer only while in specific map (or side area within it)
		map_tracker_ticks := A_TickCount - map_entered

	If (InStr(map_tracker_map, current_location) || ((map_tracker_enable_side_areas = 1) && (InStr(current_location, "abyssleague") || InStr(current_location, "labyrinth_trials") || InStr(current_location, "mapsidearea")))) && WinExist("ahk_id " hwnd_map_tracker) ;update timer UI
	{
		If (map_tracker_refresh_kills = 3)
		{
			Gui, map_tracker: Color, Black
			GuiControl, map_tracker: +BackgroundBlack, map_tracker_button_complete_bar
			WinSet, Redraw,, ahk_id %hwnd_map_tracker%
			map_tracker_refresh_kills := 0
		}
		map_tracker_time := Format("{:0.0f}", map_tracker_ticks//1000)
		map_tracker_time := (Mod(map_tracker_time, 60) >= 10) ? map_tracker_time//60 ":" Mod(map_tracker_time, 60) : map_tracker_time//60 ":0" Mod(map_tracker_time, 60)
		map_tracker_time := (StrLen(map_tracker_time) < 5) ? 0 map_tracker_time : map_tracker_time
		GuiControl, map_tracker: text, map_tracker_label_time, % map_tracker_time
	}
}

If map_tracker_paused
	map_entered += 1000

poe_log_content := poe_log.Read() ;read newest lines from client.txt
StringLower, poe_log_content, poe_log_content
Loop, Parse, poe_log_content, `n, `r ;parse client.txt data
{
	If InStr(A_Loopfield, "generating level")
	{
		If InStr(A_LoopField, "1_1_1") && WinExist("ahk_id " hwnd_alarm)
			alarm_timestamp := A_Now
		portal_modifier := InStr(current_location, "hideout") ? 1 : 0 ;only count portals when entering from hideout, not side-area (lab trial, abyss, etc.)
		
		current_location := SubStr(A_Loopfield, InStr(A_Loopfield, "area """) + 6)
		current_location := SubStr(current_location, 1, InStr(current_location, """") -1) ;save PoE-internal location name in var
		
		in_lab := InStr(current_location, "labyrinth_") ? 1 : 0
		
		current_area_tier := SubStr(A_LoopField, InStr(A_LoopField, "level ") + 6, InStr(A_LoopField, " area """) - InStr(A_LoopField, "level ") - 6) - 67
		current_area_level := current_area_tier + 67
		If (current_area_tier > 0)
			current_area_tier := (current_area_tier < 10) ? 0 current_area_tier : current_area_tier ;save map-tier in var
		
		current_seed := SubStr(A_LoopField, InStr(A_LoopField, "seed ") + 5)
		current_seed := StrReplace(current_seed, "`n") ;save map seed in var
		
		If !map_tracker_paused && settings_enable_maptracker
		{
			date_time := SubStr(A_LoopField, 1, InStr(A_LoopField, " ",,, 2) - 1) ;save date & time from client.txt
			
			If (InStr(current_location, "abyssleague") || InStr(current_location, "labyrinth_trials") || InStr(current_location, "mapsidearea")) && (map_tracker_side_area = "" || map_tracker_side_area != current_location "|" current_area_tier "|" current_seed)
			{
				map_tracker_side_area := current_location "|" current_area_tier "|" current_seed
				map_tracker_verbose_side_area := 0
			}
			
			If enable_killtracker && (map_tracker_map != "") && InStr(A_LoopField, """Hideout")
				map_tracker_refresh_kills := 2
			
			If LLK_MapTrackInstance(A_LoopField)
			{
				If (map_tracker_map = "") || (map_tracker_map != current_location "|" current_area_tier "|" current_seed) ;current area is the first since launch, or current area is different from previous one
				{
					If enable_killtracker
					{
						map_tracker_refresh_kills := 1
						map_tracker_kills_start := 0
					}
					map_tracker_map := (map_tracker_map = "") ? current_location "|" current_area_tier "|" current_seed : map_tracker_map
					If (map_tracker_map != current_location "|" current_area_tier "|" current_seed) ;current area is different from previous -> reset tracker, and save log for previous map
					{
						LLK_MapTrackSave()
						map_tracker_map := current_location "|" current_area_tier "|" current_seed
					}
					map_tracker_content := "|"
					current_location_verbose := ""
					map_tracker_ticks := 0
					portals := 0
					map_tracker_deaths := 0
					map_entered_date_time := date_time
				}
				portals += portal_modifier ;portal counter
				map_entered := A_TickCount - map_tracker_ticks
			}
		}
	}
	
	If !in_lab && (lab_location_verbose != "")
	{
		lab_location_verbose := ""
		lab_location := ""
		lab_current_ID := ""
		lab_checkpoint := 0
		Loop, % lab_json.rooms.Count()
		{
			GuiControl, lab_layout:, lab_room%A_Index%, img\GUI\square_blank.png
			GuiControl, lab_layout: text, lab_text%A_Index%,
		}
	}
	If in_lab && InStr(A_LoopField, ": you have entered ")
	{
		lab_location_verbose := SubStr(A_LoopField, InStr(A_LoopField, "you have entered") + 17, -1)
		lab_location := current_location
	}
	
	If !map_tracker_paused && settings_enable_maptracker
	{
		If InStr(A_LoopField, "you have killed ") && (map_tracker_kills_start = 0)
		{
			map_tracker_kills_start := SubStr(A_LoopField, InStr(A_LoopField, "you have killed ") + 16)
			map_tracker_kills_start := StrReplace(map_tracker_kills_start, " monsters.")
			Loop, Parse, map_tracker_kills_start
			{
				If (A_Index = 1)
					map_tracker_kills_start := ""
				If IsNumber(A_LoopField)
					map_tracker_kills_start .= A_LoopField
			}
		}
		Else If InStr(A_LoopField, "you have killed ") && (map_tracker_kills_start > 0)
		{
			map_tracker_kills_end := SubStr(A_LoopField, InStr(A_LoopField, "you have killed ") + 16)
			map_tracker_kills_end := StrReplace(map_tracker_kills_end, " monsters.")
			Loop, Parse, map_tracker_kills_end
			{
				If (A_Index = 1)
					map_tracker_kills_end := ""
				If IsNumber(A_LoopField)
					map_tracker_kills_end .= A_LoopField
			}
			map_tracker_kills := map_tracker_kills_end - map_tracker_kills_start
		}
		If InStr(A_LoopField, "has been slain") && InStr(map_tracker_map, current_location) && !map_tracker_paused ;count deaths
			map_tracker_deaths += 1
		If InStr(A_LoopField, "you have entered ") && (map_tracker_verbose_side_area = 0)
		{
			map_tracker_verbose_side_area := SubStr(A_LoopField, InStr(A_LoopField, "you have entered ") + 17)
			map_tracker_verbose_side_area := StrReplace(map_tracker_verbose_side_area, ".")
			If InStr(current_location, "abyssleagueboss")
				map_tracker_verbose_side_area .= " (boss)"
			If InStr(current_location, "mapsidearea")
				map_tracker_verbose_side_area .= " (vaal area)"
			map_tracker_content .= map_tracker_verbose_side_area "|"
		}
		If InStr(A_LoopField, "you have entered ") && (current_location_verbose = "") && (map_tracker_map != "") ;parse verbose area name
		{
			current_location_verbose := SubStr(A_LoopField, InStr(A_LoopField, "you have entered ") + 17)
			current_location_verbose := StrReplace(current_location_verbose, ".")
			current_location_verbose := (SubStr(current_location_verbose, 1, 4) = "the ") ? SubStr(current_location_verbose, 5) : current_location_verbose
			current_location_verbose := InStr(map_tracker_map, "heist") ? "heist: " current_location_verbose : current_location_verbose
			current_location_verbose := InStr(map_tracker_map, "expedition") ? "logbook: " current_location_verbose : current_location_verbose
			current_map_tier := current_area_tier
			map_tracker_panel_color := (enable_killtracker = 1) ? "Green" : "Black"
			LLK_MapTrack()
		}
	}
	
	If settings_enable_levelingtracker && InStr(A_LoopField, "is now level") && InStr(A_LoopField, "/")
	{
		parsed_level := SubStr(A_Loopfield, InStr(A_Loopfield, "is now level "))
		parsed_level := StrReplace(parsed_level, "is now level ")
		parsed_character := SubStr(A_Loopfield, InStr(A_Loopfield, " : ") + 3, InStr(A_Loopfield, ")"))
		parsed_character := SubStr(parsed_character, 1, InStr(parsed_character, "(") - 2)
		gear_tracker_characters[parsed_character] := parsed_level
		gear_tracker_characters.Delete("lvl 2 required")
	}
	
	If (gear_tracker_char != "")
	{
		If InStr(A_Loopfield, "is now level") && InStr(A_LoopField, "/") && InStr(A_Loopfield, gear_tracker_char)
			gear_tracker_characters[gear_tracker_char] := SubStr(A_Loopfield, InStr(A_Loopfield, "is now level ") + 13)
	}
}
If !lab_mismatch && in_lab && lab_location_verbose && IsObject(lab_json) && (lab_location != lab_previous)
{
	Loop, % lab_json.rooms.Count()
		GuiControl, lab_layout: text, lab_text%A_Index%,
	
	Loop, % lab_json.rooms.Count()
	{
		If (A_Index <= lab_checkpoint)
			continue
		lab_loop := A_Index
		If (lab_json.rooms[A_Index].name = lab_location_verbose) && (SubStr(current_location, StrLen(current_location) - StrLen(lab_json.rooms[A_Index].areacode) + 1) = lab_json.rooms[A_Index].areacode || lab_json.rooms[A_Index].areacode = "")
		{
			If lab_current_ID
				GuiControl, lab_layout:, lab_room%lab_current_ID%, img\GUI\square_green_trans.png
			lab_previous_verbose := lab_location_verbose
			lab_previous := lab_location
			lab_current_ID := A_Index
			GuiControl, lab_layout:, lab_room%A_Index%, img\GUI\square_fuchsia_trans.png
			If (lab_location_verbose = "aspirant's trial")
			{
				lab_checkpoint := A_Index
				Break
			}
			For dir, id in lab_json.rooms[lab_loop].exits
			{
				If (lab_json.rooms[lab_loop].exits.Count() < 2)
					Break
				If (dir = "C")
					continue
				lab_parse := SubStr(lab_json.rooms[id].name, 1, 2) " " SubStr(lab_json.rooms[id].name, InStr(lab_json.rooms[id].name, " ") + 1, 2) ""
				GuiControl, lab_layout: text, lab_text%id%, % lab_parse
			}
			Break
		}
	}
}

If (gear_tracker_parse != "`n") && WinExist("ahk_id " hwnd_gear_tracker_indicator)
{
	gear_tracker_count := 0
	Loop, Parse, gear_tracker_parse, `n, `n
	{
		If (A_Loopfield = "")
			continue
		If (SubStr(A_Loopfield, 2, 2) <= gear_tracker_characters[gear_tracker_char])
			gear_tracker_count += 1
	}
	GuiControl, gear_tracker_indicator:, gear_tracker_upgrades, % (gear_tracker_count = 0) ? "" : gear_tracker_count
}

If WinExist("ahk_id " hwnd_leveling_guide2)
{
	If (areas = "")
	{
		FileRead, json_areas, data\leveling tracker\areas.json
		areas := Json.Load(json_areas)
		json_areas := ""
	}
	
	target_location := InStr(guide_panel2_text, "`n") ? SubStr(guide_panel2_text, InStr(guide_panel2_text, "`n",,, LLK_InStrCount(guide_panel2_text, "`n"))) : guide_panel2_text
	target_location := SubStr(target_location, -1*StrLen(current_location) + 1)
	If (target_location = current_location)
	{
		guide_progress .= (guide_progress = "") ? guide_panel2_text : "`n" guide_panel2_text
		guide_text := StrReplace(guide_text, guide_panel2_text "`n",,, 1)
		GoSub, Leveling_guide_progress
	}
	
	If leveling_guide_enable_timer && !InStr(current_location, "hideout") && (leveling_guide_act < 11) && WinExist("ahk_id " hwnd_leveling_guide2) && WinActive("ahk_group poe_ahk_window") && !leveling_guide_fresh_login
	{
		leveling_guide_time += 1
		LLK_LevelGuideTimer(leveling_guide_time, leveling_guide_time_total + leveling_guide_time)
	}
	
	pAct := areas[current_location]["act"]
	If leveling_guide_enable_timer && !leveling_guide_fresh_login && IsNumber(pAct) && (pAct = leveling_guide_act + 1) ;entering the next act
	{
		IniWrite, % leveling_guide_time, ini\leveling tracker.ini, current run, act %leveling_guide_act% ;save the time of the current act
		LLK_LevelGuideCSV()
		leveling_guide_act := pAct
		leveling_guide_time_total += leveling_guide_time ;add act-time to run-time
		If (leveling_guide_act = 11) ;if campaign is done
		{
			LLK_LevelGuideTimer(leveling_guide_time, leveling_guide_time_total)
			Gui, leveling_guide3: Color, Green
			WinSet, Redraw,, ahk_id %hwnd_leveling_guide3%
		}
		leveling_guide_time := 0
		IniWrite, 0, ini\leveling tracker.ini, current run, time
	}
}

If (enable_delvelog = 1)
{
	If (current_location = "delve_main" && !WinExist("ahk_id " hwnd_delve_panel))
		LLK_Overlay("delve_panel", "show")
	If (current_location != "delve_main" && WinExist("ahk_id " hwnd_delve_panel))
		LLK_Overlay("delve_panel", "hide")
}
poe_log_content := ""
Return

Loop:
If !WinExist("ahk_group poe_window")
{
	poe_window_closed := 1
	hwnd_poe_client := ""
	ToolTip
	update_available := 0
}
If !WinExist("ahk_group poe_window") && (A_TickCount >= last_check + kill_timeout*60000) && (kill_script = 1) && ((alarm_timestamp = "") || (alarm_loop = 1))
	ExitApp
If WinExist("ahk_group poe_window")
{
	
	last_check := A_TickCount
	If (hwnd_poe_client = "")
		hwnd_poe_client := WinExist("ahk_group poe_window")
	If (poe_window_closed = 1) && (custom_resolution_setting = 1)
	{
		Sleep, 4000
		If (fullscreen = "true")
			WinMove, ahk_group poe_window,, %xScreenOffset%, %yScreenOffset%, %poe_width%, %custom_resolution%
		Else WinMove, ahk_group poe_window,, % xScreenOffset - xborder, % (window_docking = 0) ? yScreenOffset - caption - yborder : yScreenOffset_monitor, % custom_width + xborder*2, % custom_resolution + caption + yborder*2
		poe_height := custom_resolution
	}
	If (poe_window_closed = 1) && (custom_resolution_setting = 0) && (fullscreen != "true")
	{
		Sleep, 4000
		WinMove, ahk_group poe_window,, % xScreenOffSet - xborder, % yScreenOffSet - caption - yborder
	}
	poe_window_closed := 0
}

If (enable_alarm != 0) && (alarm_timestamp != "")
{
	alarm_timestamp0 := alarm_timestamp
	EnvSub, alarm_timestamp0, %A_Now%, S
	If (alarm_timestamp0 > 0)
	{
		countdown_min := (StrLen(Floor(alarm_timestamp0//60)) = 1) ? 0 Floor(alarm_timestamp0//60) : Floor(alarm_timestamp0//60)
		countdown_sec := (StrLen(Mod(alarm_timestamp0, 60)) = 1) ? 0 Mod(alarm_timestamp0, 60) : Mod(alarm_timestamp0, 60)
		GuiControl, alarm: Text, alarm_countdown, % countdown_min ":" countdown_sec
	}
	Else
	{
		If (alarm_loop = 1) && (alarm_minutes > 0)
		{
			SoundBeep, 500, 100
			EnvAdd, alarm_timestamp, % alarm_minutes, S
			Return
		}
		alarm_fontcolor0 := (alarm_fontcolor0 = "Blue") ? alarm_fontcolor : "Blue"
		Gui, alarm: Font, c%alarm_fontcolor0%
		GuiControl, alarm: Font, alarm_countdown
		countdown_min := (StrLen(Floor(alarm_timestamp0//-60)) = 1) ? 0 Floor(alarm_timestamp0//-60) : Floor(alarm_timestamp0//-60)
		countdown_sec := (StrLen(Mod(alarm_timestamp0, -60)) < 3) ? 0 Mod(alarm_timestamp0, -60) * -1 : Mod(alarm_timestamp0, -60) * -1
		GuiControl, alarm: Text, alarm_countdown, % countdown_min ":" countdown_sec
		If !WinActive("ahk_group poe_window")
		{
			WinSet, Style, +0xC00000, ahk_id %hwnd_alarm%
			WinSet, ExStyle, -0x20, ahk_id %hwnd_alarm%
			Gui, alarm: Show, % "NA AutoSize"
			Gui, alarm_drag: Destroy
			hwnd_alarm_drag := ""
		}
		If !WinExist("ahk_id " hwnd_alarm) && WinExist("ahk_group poe_window")
			LLK_Overlay("alarm", "show")
	}
}
Return

MainLoop:
If !WinActive("ahk_group poe_ahk_window")
{
	inactive_counter += 1
	If (inactive_counter = 3)
	{
		;Gui, notepad_contextmenu: Destroy
		Gui, context_menu: Destroy
		Gui, bestiary_menu: Destroy
		Gui, map_info_menu: Destroy
		hwnd_map_info_menu := ""
		Gui, legion_help: Destroy
		LLK_Overlay("hide")
	}
}
If WinActive("ahk_id " hwnd_itemchecker)
	WinActivate, ahk_group poe_window
If !gui_force_hide && WinActive("ahk_group poe_ahk_window") && (poe_window_closed != 1) && !WinActive("ahk_id " hwnd_screencap_setup) && !WinActive("ahk_id " hwnd_snip) && !WinActive("ahk_id " hwnd_cheatsheets_menu) && !WinActive("ahk_id " hwnd_searchstrings_menu)
{
	mouse_hover += 1
	If (mouse_hover >= 5) && (mousemove != 1)
	{
		MouseGetPos,,, hwnd_win_hover, hwnd_control_hover, 2
		mouse_hover := 0
		;last_hover := 0
		;hwnd_win_hover := (hwnd_win_hover = "") ? 0 : hwnd_win_hover
		;hwnd_control_hover := (hwnd_control_hover = "") ? 0 : hwnd_control_hover
	}
	If (inactive_counter != 0)
	{
		inactive_counter := 0
		LLK_Overlay("show")
	}
	If (pixelchecks_enabled != "") && (enable_pixelchecks = 1)
	{
		Loop, Parse, pixelchecks_enabled, `,, `,
		{
			If (A_LoopField = "")
				break
			LLK_PixelSearch(A_LoopField)
		}
	}
	If (!inventory && pixel_inventory_color1 != "") && WinExist("ahk_id " hwnd_itemchecker)
	{
		Gui, itemchecker: Destroy
		hwnd_itemchecker := ""
	}
	If (!inventory && pixel_inventory_color1 != "") && WinExist("ahk_id " hwnd_itemchecker_vendor1)
	{
		Loop
		{
			If (hwnd_itemchecker_vendor%A_Index% != "")
			{
				Gui, itemchecker_vendor%A_Index%: Destroy
				hwnd_itemchecker_vendor%A_Index% := ""
			}
			Else Break
		}
		itemchecker_vendor_count := 0
		Return
	}
	If enable_itemchecker_gear
	{
		If inventory
		{
			MouseGetPos, gearXpos, gearYpos
			gear_mouse_over := LLK_ItemCheckGearMouse(gearXpos, gearYpos)
		}
		Else gear_mouse_over := 0
		If inventory && (settings_menu_section = "itemchecker") && !WinExist("ahk_id " hwnd_itemchecker_gear_mainhand)
		{
			Loop, Parse, gear_slots, `,
				LLK_Overlay("itemchecker_gear_" A_LoopField, "show")
		}
		Else If (!inventory || settings_menu_section != "itemchecker") && WinExist("ahk_id " hwnd_itemchecker_gear_mainhand)
		{
			Loop, Parse, gear_slots, `,
				LLK_Overlay("itemchecker_gear_" A_LoopField, "hide")
		}
	}
	If (!clone_frames_hideout_enable || (clone_frames_hideout_enable && !InStr(current_location, "hideout") && !InStr(current_location, "_town"))) && (((clone_frames_enabled != "") && (clone_frames_pixelcheck_enable = 0) && !WinExist("ahk_id " hwnd_map_tracker_log)) || ((clone_frames_enabled != "") && (clone_frames_pixelcheck_enable = 1) && (gamescreen = 1) && !WinExist("ahk_id " hwnd_map_tracker_log)))
	{
		Loop, Parse, clone_frames_enabled, `,, `,
		{
			If (A_LoopField = "")
				Break
			If !WinExist("ahk_id " hwnd_%A_Loopfield%)
				Gui, clone_frames_%A_Loopfield%: Show, NA
			p%A_LoopField% := Gdip_BitmapFromScreen(xScreenOffset + clone_frame_%A_LoopField%_topleft_x "|" yScreenOffset + clone_frame_%A_LoopField%_topleft_y "|" clone_frame_%A_LoopField%_width "|" clone_frame_%A_LoopField%_height)
			w%A_LoopField% := clone_frame_%A_LoopField%_width
			h%A_LoopField% := clone_frame_%A_LoopField%_height
			w%A_LoopField%_dest := clone_frame_%A_LoopField%_width * clone_frame_%A_LoopField%_scale_x//100
			h%A_LoopField%_dest := clone_frame_%A_LoopField%_height * clone_frame_%A_LoopField%_scale_y//100
			hbm%A_LoopField% := CreateDIBSection(w%A_LoopField%_dest, h%A_LoopField%_dest)
			hdc%A_LoopField% := CreateCompatibleDC()
			obm%A_LoopField% := SelectObject(hdc%A_LoopField%, hbm%A_LoopField%)
			g%A_LoopField% := Gdip_GraphicsFromHDC(hdc%A_LoopField%)
			Gdip_SetInterpolationMode(g%A_LoopField%, 0)
			Gdip_DrawImage(g%A_LoopField%, p%A_LoopField%, 0, 0, w%A_LoopField%_dest, h%A_LoopField%_dest, 0, 0, w%A_LoopField%, h%A_LoopField%, 0.2 + 0.16 * clone_frame_%A_LoopField%_opacity)
			Gdip_DisposeImage(p%A_LoopField%)
			UpdateLayeredWindow(hwnd_%A_LoopField%, hdc%A_LoopField%, xScreenOffset + clone_frame_%A_LoopField%_target_x, yScreenOffset + clone_frame_%A_LoopField%_target_y, w%A_LoopField%_dest, h%A_LoopField%_dest)
			SelectObject(hdc%A_Loopfield%, obm%A_Loopfield%)
			DeleteObject(hbm%A_Loopfield%)
			DeleteDC(hdc%A_Loopfield%)
			Gdip_DeleteGraphics(g%A_Loopfield%)
		}
	}
	Else
	{
		Loop, Parse, clone_frames_enabled, `,, `,
		{
			If WinExist("ahk_id " hwnd_%A_Loopfield%)
				Gui, clone_frames_%A_Loopfield%: Hide
		}
	}
}
Return

#Include modules\map-info.ahk

#Include modules\map tracker.ahk

#Include modules\notepad.ahk

#Include modules\omni-key.ahk

Panel_drag:
MouseGetPos, panelXpos, panelYpos
panelXpos := (panelXpos >= xScreenOffSet + poe_width*0.998) ? xScreenOffSet + poe_width : panelXpos ;snap panel to edge when close (MouseGetPos coords are off by one pixel when on the edge)
panelXpos := (panelXpos < xScreenOffSet) ? xScreenOffSet : panelXpos
panelXpos := (!InStr(A_Gui, "itemchecker_gear_") && (panelXpos >= xScreenOffSet + poe_width/2)) ? panelXpos - wGui : panelXpos
panelYpos := (panelYpos >= yScreenOffset + poe_height*0.998) ? yScreenOffSet + poe_height : panelYpos ;snap panel to edge when close (MouseGetPos coords are off by one pixel when on the edge)
panelYpos := (panelYpos < yScreenOffset) ? yScreenOffset : panelYpos
panelYpos := (!InStr(A_Gui, "itemchecker_gear_") && (panelYpos >= yScreenOffSet + poe_height/2)) ? panelYpos - hGui : panelYpos
panelXpos -= xScreenOffSet
panelYpos -= yScreenOffSet
If (panelXpos + wGui >= poe_width - pixel_gamescreen_x1 - 1) && (panelYpos <= pixel_gamescreen_y1 + 1) ;protect pixel-check area
	panelYpos := pixel_gamescreen_y1 + 2
Gui, %A_Gui%: Show, % "NA x"xScreenOffSet + panelXpos " y"yScreenOffSet + panelYpos
If InStr(A_Gui, "map_mods")
{
	panelYpos2 := (panelYpos >= poe_height/2) ? panelYpos - hGui2 + 1 : panelYpos + hGui - 1
	Gui, map_mods_window: Show, % "NA x"xScreenOffSet + panelXpos " y"yScreenOffSet + panelYpos2
}
If InStr(A_Gui, "notepad_drag")
{
	notepad_gui := "notepad" StrReplace(A_Gui, "notepad_drag")
	panelXpos2 := (panelXpos >= poe_width/2) ? panelXpos - wGui2 + wGui : panelXpos
	panelYpos2 := (panelYpos >= poe_height/2) ? panelYpos - hGui2 + hGui : panelYpos
	Gui, %notepad_gui%: Show, % "NA x"xScreenOffSet + panelXpos2 " y"yScreenOffSet + panelYpos2
}
If (A_Gui = "alarm_drag")
{
	panelXpos2 := (panelXpos >= poe_width/2) ? panelXpos - wGui2 + wGui : panelXpos
	panelYpos2 := (panelYpos >= poe_height/2) ? panelYpos - hGui2 + hGui : panelYpos
	Gui, alarm: Show, % "NA x"xScreenOffSet + panelXpos2 " y"yScreenOffSet + panelYpos2
}
Return

#Include modules\recombinators.ahk

Resolution_check:
If InStr(buggy_resolutions, poe_height) || !InStr(supported_resolutions, "," poe_height "p")
{
	If InStr(buggy_resolutions, poe_height)
	{
text =
(
Unsupported resolution detected!

The script has detected a vertical screen-resolution of %poe_height% pixels which has caused issues with the game-client and the script in the past.

I have decided to end support for this resolution.
You have to run the client with a custom resolution, which you can set up in the following window, to use this script.

You should also consider enabling "confine mouse to window" in the game's UI options to prevent the mouse from leaving the client area.
)
	}
	Else If !InStr(supported_resolutions, "," poe_height "p")
	{
	
text =
(
Unsupported resolution detected!

The script has detected a vertical screen-resolution of %poe_height% pixels which is not supported.

You have to run the client with a custom resolution, which you can set up in the following window, to use this script.

You should also consider enabling "confine mouse to window" in the game's UI options to prevent the mouse from leaving the client area.
)
	}
	MsgBox, % text
	safe_mode := 1
	GoSub, settings_menu
	sleep, 2000
	Loop
	{
		If !WinExist("ahk_id " hwnd_settings_menu)
		{
			MsgBox, The script will now shut down.
			ExitApp
		}
		Sleep, 100
	}
	Return
}
Return

#Include modules\screen-checks.ahk

#Include modules\settings menu.ahk

#Include modules\search-strings.ahk

Timeout_chromatics()
{
	global
	KeyWait, v, D T0.5
	If !ErrorLevel
	{
		KeyWait, v
		SendInput, %strength%{tab}%dexterity%{tab}%intelligence%
	}
	If WinActive("ahk_group poe_window") || !ErrorLevel
	{
		SetTimer, Timeout_chromatics, delete
		ToolTip,,,, 15
	}
}

Timeout_cluster_jewels()
{
	global
	KeyWait, F3, D T0.5
	If !ErrorLevel
	{
		KeyWait, F3
		sleep, 250
		SendInput, %wiki_cluster%
	}
	If WinActive("ahk_group poe_window") || !ErrorLevel
	{
		SetTimer, Timeout_cluster_jewels, delete
		ToolTip,,,, 15
	}
}

LLK_AddEntry(name)
{
	global
	While (SubStr(name, 1, 1) = " ")
		name := SubStr(name, 2)
	While (SubStr(name, 0) = " ")
		name := SubStr(name, 1, -1)
	If (name = "")
	{
		LLK_ToolTip("name cannot be blank",, xPos_settings_menu_searchstrings_edit, yPos_settings_menu_searchstrings_edit + height_settings_menu_searchstrings_edit)
		Return 0
	}
	Loop, Parse, name
	{
		If !LLK_IsAlpha(A_LoopField) && (A_LoopField != " ")
		{
			LLK_ToolTip("name cannot contain numbers",, xPos_settings_menu_searchstrings_edit, yPos_settings_menu_searchstrings_edit + height_settings_menu_searchstrings_edit)
			Return 0
		}
	}
	local newname_check
	IniRead, newname_check, ini\search-strings.ini, searches, % name, % A_Space
	If newname_check
	{
		LLK_ToolTip("a search with the same`nname already exists", 2, xPos_settings_menu_searchstrings_edit, yPos_settings_menu_searchstrings_edit + height_settings_menu_searchstrings_edit)
		Return 0
	}
	Return name
}

LLK_ArrayHasVal(array, value, allresults := 0)
{
	hits := ""
	Loop, % array.Length()
	{
		If (array[A_Index] = value) && (allresults = 0)
			Return %A_Index%
		Else If (array[A_Index] = value) && (allresults = 1)
			hits .= A_Index ","
	}
	If (allresults = 0)
		Return 0
	Else
	{
		hits := (hits = "") ? 0 : hits
		Return hits
	}
}

LLK_Error(ErrorMessage, restart := 0)
{
	MsgBox, % ErrorMessage
	If restart
		Reload
	ExitApp
}

LLK_FilePermissionError(issue)
{
	Gui, cheatsheets_context_menu: Destroy
	global hwnd_cheatsheets_context_menu := ""
	
	text := "The script couldn't "issue " a file/folder."
	text .= "`nThere seem to be write-permission issues in the current folder location."
	text .= "`nTry moving the script to another location or running it as administrator."
	text .= "`n`nThere is a write-permissions test in the settings menu that you can use to trouble-shoot this issue."
	MsgBox, % text
}

LLK_FontSize(size, ByRef font_height_x, ByRef font_width_x)
{
	Gui, font_size: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_font_size
	Gui, font_size: Margin, 0, 0
	Gui, font_size: Color, Black
	Gui, font_size: Font, % "cWhite s"size, Fontin SmallCaps
	Gui, font_size: Add, Text, % "Border HWNDmain_text", % "7"
	GuiControlGet, font_check_, Pos, % main_text
	font_height_x := font_check_h
	font_width_x := font_check_w
	Gui, font_size: Destroy
}

LLK_HotstringClip(hotstring, mode := 0)
{
	global
	hotstring := StrReplace(hotstring, ":")
	hotstring := StrReplace(hotstring, "?")
	hotstring := StrReplace(hotstring, ".")
	hotstring := StrReplace(hotstring, "*")
	clipboard := ""
	SendInput, ^{a}
	sleep, 100
	SendInput, ^{c}
	ClipWait, 0.05

	If (mode = 1)
		SendInput, {ESC}
	hotstringboard := InStr(clipboard, "@") ? SubStr(clipboard, InStr(clipboard, " ") + 1) : clipboard
	hotstringboard := (SubStr(hotstringboard, 0) = " ") ? SubStr(hotstringboard, 1, -1) : hotstringboard
	If (hotstring = "synd")
		GoSub, Betrayal_search
	/*
	If (hotstring = "llk")
	{
		If (hotstringboard = "r")
		{
			Reload
			ExitApp
		}
		GoSub, Settings_menu
	}
	*/
	If (hotstring = "lab")
		GoSub, Lab_info
	If (hotstring = "wiki")
	{
		hotstringboard := StrReplace(hotstringboard, A_Space, "+")
		hotstringboard := StrReplace(hotstringboard, "'", "%27")
		Run, https://www.poewiki.net/index.php?search=%hotstringboard%
	}
	hotstringboard := ""
}

LLK_hwnd(hwnd)
{
	global
	Loop, 100
	{
		check := hwnd A_Index
		If (%hwnd% != "") || (%check% != "")
			Return 1
	}
	Return 0
}

LLK_InStrCount(string, character, delimiter := "")
{
	count := 0
	Loop, Parse, string, %delimiter%, %delimiter%
	{
		If (A_Loopfield = character)
			count += 1
	}
	Return count
}

LLK_IsAlpha(string)
{
	If (string = "")
		Return 0
	If string is alpha
		Return 1
	Else Return 0
}

LLK_IsAlnum(string)
{
	If string is alnum
		Return 1
	Else Return 0
}

LLK_ItemInfoCheck()
{
	If !InStr(Clipboard, "prefix modifier") && !InStr(Clipboard, "suffix modifier") && !InStr(Clipboard, "unique modifier") && !InStr(Clipboard, "`nRarity: Normal", 1) && !InStr(Clipboard, "unidentified")
	{
		LLK_ToolTip("failed to copy advanced item-info.`nconfigure the omni-key in the settings menu.", 3)
		Return 0
	}
	Else Return 1
}

LLK_MouseMove()
{
	global
	If (A_TickCount < last_hover + 25) && (last_hover != "") ;only execute function in intervals (script is running full-speed due to batchlines -1)
		Return
	mousemove := 1
	last_hover := A_TickCount
	MouseGetPos, xHover, yHover, hwnd_win_hover, hwnd_control_hover, 2
	hwnd_win_hover := (hwnd_win_hover = "") ? 0 : hwnd_win_hover
	hwnd_control_hover := (hwnd_control_hover = "") ? 0 : hwnd_control_hover
	If (hwnd_win_hover = hwnd_legion_help)
		Gui, legion_help: Destroy
	If (hwnd_win_hover = hwnd_legion_treemap2) && !WinExist("ahk_id " hwnd_legion_treemap) ;magnify passive tree on hover
	{
		LLK_Overlay("legion_treemap", "show")
		SetTimer, Legion_seeds_hover_check, 250
	}
	Else If (hwnd_win_hover != hwnd_legion_treemap) && WinExist("ahk_id " hwnd_legion_treemap)
		LLK_Overlay("legion_treemap", "hide")
	
	If (hwnd_control_hover != last_control_hover) ;only update hover-tooltip when hovered control is different from previous update
	{
		last_control_hover := hwnd_control_hover
		If (hwnd_win_hover = hwnd_legion_window || hwnd_win_hover = hwnd_legion_list)
			GoSub, Legion_seeds_hover
	}	
	mousemove := 0
}

LLK_Overlay(gui, toggleshowhide:="toggle", NA:=1)
{
	global
	If (gui="hide")
	{
		Loop, Parse, guilist, |, |
		{
			If (A_Loopfield = "")
				Break
			Gui, %A_LoopField%: Hide
		}
		Return
	}
	If (gui="show")
	{
		Loop, Parse, guilist, |, |
		{
			If (A_Loopfield = "")
				Break
			If (state_%A_LoopField%=1) && (hwnd_%A_LoopField% != "")
				Gui, %A_LoopField%: Show, NA
		}
		Return
	}
	If (toggleshowhide="toggle")
	{
		If !WinExist("ahk_id " hwnd_%gui%) && (hwnd_%gui% != "")
		{
			Gui, %gui%: Show, NA
			state_%gui% := 1
			Return
		}
		If WinExist("ahk_id " hwnd_%gui%)
		{
			Gui, %gui%: Hide
			state_%gui% := 0
			Return
		}
	}
	If (toggleshowhide="show") && (hwnd_%gui% != "")
	{
		If (NA = 1)
			Gui, %gui%: Show, NA
		Else Gui, %gui%: Show
		state_%gui% := 1
	}
	If (toggleshowhide="hide")
	{
		Gui, %gui%: Hide
		state_%gui% := 0
	}
}

LLK_ProgressBar(gui, control_id)
{
	progress := 0
	start := A_TickCount
	While GetKeyState("LButton", "P") || GetKeyState("RButton", "P")
	{
		If (progress >= 400)
		{
			GuiControl, %gui%:, %control_id%, 0
			Return 1
		}
		If (A_TickCount >= start + 10)
		{
			progress += 10
			start := A_TickCount
			GuiControl, %gui%:, %control_id%, % progress
		}
	}
	GuiControl, %gui%:, %control_id%, 0
	;WinSet, Redraw,, % "ahk_id " hwnd_%gui%
	Return 0
}

LLK_Rightclick()
{
	global
	click := 2
	SendInput, {LButton}
	KeyWait, RButton
	click := 1
}

/* ; alternative to Windows clipping tool - scrapped for now (freeze-frame required for some screen-caps)
LLK_ScreenCap()
{
	global width_native, height_native, click, hwnd_screencap, hwnd_screencap_frame, screencap_x1, screencap_y1, screencap_x2, screencap_y2
	valid_screencap := 0
	If (A_Gui = "")
	{
		Gui, screencap: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_screencap
		Gui, screencap: Margin, 0, 0
		Gui, screencap: Color, White
		WinSet, Trans, 75
		Gui, screencap: Font, % "cWhite s"fSize0 + fSize_offset_itemchecker, Fontin SmallCaps
		Gui, screencap: Add, Picture, % "BackgroundTrans gLLK_ScreenCap w"width_native " h"height_native, img\GUI\square_blank.png
		Gui, screencap: Show, Maximize
	}
	Else
	{
		If (click = 1)
			MouseGetPos, screencap_x1, screencap_y1
		Else MouseGetPos, screencap_x2, screencap_y2
		
		If (screencap_x1 < screencap_x2) && (screencap_y1 < screencap_y2)
		{
			Loop 4
			{
				loop := A_Index - 1
				screencap_x1_copy := screencap_x1 - loop, screencap_y1_copy := screencap_y1 - loop, screencap_x2_copy := screencap_x2 + loop, screencap_y2_copy := screencap_y2 + loop
				Gui, screencap_frame%A_Index%: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_screencap_frame
				Gui, screencap_frame%A_Index%: Margin, 0, 0
				Gui, screencap_frame%A_Index%: Color, Black
				WinSet, Transparent, 255
				WinSet, TransColor, Black
				Gui, screencap_frame%A_Index%: Show, % "NA x"screencap_x1_copy " y"screencap_y1_copy " w"screencap_x2_copy - screencap_x1_copy " h"screencap_y2_copy - screencap_y1_copy
			}
		}
		Else
		{
			Gui, screencap_frame: Destroy
			hwnd_screencap_frame := ""
			Return
		}
	}
}
*/

LLK_Snip(mode)
{
	global
	If (mode = 1) && !WinExist("ahk_id " hwnd_snip)
	{
		Gui, snip: New, -DPIScale +LastFound +ToolWindow +AlwaysOnTop +Resize HWNDhwnd_snip, Lailloken UI: snipping widget
		Gui, snip: Color, Aqua
		WinSet, trans, 100
		Gui, snip: Add, Picture, % "x"font_width*5 " y"font_height*2 " h"font_height " w-1 BackgroundTrans gSettings_menu_help vCheatsheets_snip_help", img\GUI\help.png
		If wSnip_widget
			Gui, snip: Show, % "w"wSnip_widget " h"hSnip_widget
		Else Gui, snip: Show, % "w"font_width*31 " h"font_height*11
		Return -1
	}
	If (mode = 2) && WinExist("ahk_id " hwnd_snip)
		snipGuiClose()
	
	gui_force_hide := 1
	LLK_Overlay("hide")
	If (mode = 1)
	{
		Local xSnip, ySnip, wSnip, hSnip
		WinGetPos, xSnip, ySnip, wSnip, hSnip, ahk_id %hwnd_snip%
		Gui, snip: Hide
		sleep 100
		local pSnip := Gdip_BitmapFromScreen(xSnip + xborder "|" ySnip + yborder + caption "|" wSnip - xborder*2 "|" hSnip - yborder*2 - caption)
	}
	Else If (mode = 2)
	{
		Clipboard := ""
		SendInput, #+{s}
		WinWaitActive, ahk_exe ScreenClippingHost.exe,, 2
		WinWaitNotActive, ahk_exe ScreenClippingHost.exe
		local pSnip := Gdip_CreateBitmapFromClipboard()
	}
	gui_force_hide := 0
	If (mode = 1)
		Gui, snip: Show
	If (pSnip <= 0)
		Return 0
	Return pSnip
}

LLK_SortArray(array, options := "")
{
	options := options ? " " options : options
	Loop, % array.Length()
	{
		If (array[A_Index] = "")
			continue
		list .= array[A_Index] "`n"
	}
	If (SubStr(list, 0) = "`n")
		list := SubStr(list, 1, -1)
	Sort, list, % options
	array := []
	Loop, Parse, list, `n
		array.Push(A_LoopField)
	Return array
}

LLK_SubStrCount(string, substring, delimiter := "", strict := 0)
{
	count := 0
	Loop, Parse, string, % delimiter, % delimiter
	{
		If (A_Loopfield = "")
			continue
		If (strict = 0) && InStr(A_Loopfield, substring)
			count += 1
		If (strict = 1) && (SubStr(A_Loopfield, 1, StrLen(substring)) = substring)
			count += 1
	}
	Return count
}

LLK_ToolTip(message, duration := 1, x := "", y := "")
{
	global
	mouseYpos := ""
	MouseGetPos,, mouseYpos
	mouseYpos -= fSize0
	If (y = "")
		ToolTip, % message, %x%, %mouseYpos%, 17
	Else ToolTip, % message, %x%, %y%, 17
	SetTimer, ToolTipClear, % -1000 * duration
}

ToolTipClear()
{
	ToolTip,,,, 17
}

LLK_WinExist(hwnd)
{
	global
	Loop, 100
	{
		check := hwnd A_Index
		If WinExist("ahk_id " %hwnd%) || WinExist("ahk_id " %check%)
			Return 1
	}
	Return 0
}

LLK_WriteTest()
{
	global settings_menu_section
	If (A_GuiControl = "AdminStart")
	{
		IniWrite, % settings_menu_section, ini\config.ini, Versions, reload settings
		Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
		ExitApp
	}
	global write_test_running
	If write_test_running
		Return
	write_test_running := 1
	
	If FileExist("data\write-test\")
	{
		write_test_running := 0
		MsgBox,, Write-permissions test, There are some leftover files from a previous test. Please delete the 'write-test' folder in %A_WorkingDir%\data\
		Run, explore %A_WorkingDir%\data\
		Return
	}
	If A_IsAdmin
		status .= "script launched with admin rights: yes`n`n"
	Else status .= "script launched with admin rights: no`n`n"
	FileCreateDir, data\write-test\
	LLK_ToolTip("test 1/7")
	sleep, 250
	If FileExist("data\write-test\")
	{
		status .= "can create folders: yes`n`n"
		folder_creation := 1
	}
	Else status .= "can create folders: no`n`n"
	
	FileAppend,, data\write-test.ini
	LLK_ToolTip("test 2/7")
	sleep, 250
	If FileExist("data\write-test.ini")
	{
		status .= "can create ini-files: yes`n`n"
		ini_creation := 1
	}
	Else status .= "can create ini-files: no`n`n"
	
	IniWrite, 1, data\write-test.ini, write-test, test
	LLK_ToolTip("test 3/7")
	sleep, 250
	IniRead, ini_test, data\write-test.ini, write-test, test, 0
	If ini_test
		status .= "can write to ini-files: yes`n`n"
	Else status .= "can write to ini-files: no`n`n"
	
	pWriteTest := Gdip_BitmapFromScreen("0|0|100|100")
	Gdip_SaveBitmapToFile(pWriteTest, "data\write-test.bmp", 100)
	Gdip_DisposeImage(pWriteTest)
	LLK_ToolTip("test 4/7")
	sleep, 250
	If FileExist("data\write-test.bmp")
	{
		status .= "can create image-files: yes`n`n"
		img_creation := 1
	}
	Else status .= "can create image-files: no`n`n"
	
	If folder_creation
	{
		FileRemoveDir, data\write-test\
		sleep, 250
		If !FileExist("data\write-test\")
			status .= "can delete folders: yes`n`n"
		Else status .= "can delete folders: no`n`n"
	}
	Else status .= "can delete folders: unknown`n`n"
	LLK_ToolTip("test 5/7")
	
	If ini_creation
	{
		FileDelete, data\write-test.ini
		sleep, 250
		If !FileExist("data\write-test.ini")
			status .= "can delete ini-files: yes`n`n"
		Else status .= "can delete ini-files: no`n`n"
	}
	Else status .= "can delete ini-files: unknown`n`n"
	LLK_ToolTip("test 6/7")
	
	If img_creation
	{
		FileDelete, data\write-test.bmp
		sleep, 250
		If !FileExist("data\write-test.bmp")
			status .= "can delete image-files: yes`n`n"
		Else status .= "can delete image-files: no`n`n"
	}
	Else status .= "can delete image-files: unknown`n`n"
	LLK_ToolTip("test 7/7")
	
	MsgBox,, Test results, % status
	write_test_running := 0
}

SetTextAndResize(controlHwnd, newText, fontOptions := "", fontName := "", divisor := 1)
{
	Gui 9: New, -DPIscale
	Gui 9: Font, %fontOptions%, %fontName%
	Gui 9: Add, Text, R1, %newText%
	GuiControlGet T, 9: Pos, Static1
	Gui 9: Destroy
	GuiControl,, %controlHwnd%, %newText%
	While Mod(TW, divisor)
		TW += 1
	GuiControl, Move, %controlHwnd%, % "h" TH " w" TW
}

snipGuiClose()
{
	global
	WinGetPos,,, wSnip_widget, hSnip_widget, ahk_id %hwnd_snip%
	Gui, snip: Destroy
	hwnd_snip := ""
}

LLK_IsNumber(var)
{
	If var is number
		Return number
	Else Return 0
}

FormatSeconds(seconds, mode := 1)  ; Convert the specified number of seconds to hh:mm:ss format.
{
	time := 19990101  ; *Midnight* of an arbitrary date.
	time += seconds, seconds
	FormatTime, time, %time%, HH:mm:ss
	While !mode && InStr("0:", SubStr(time, 1, 1)) && (StrLen(time) > 4) ;remove leading 0s and colons
		time := SubStr(time, 2)
	return time
    /*
    ; Unlike the method used above, this would not support more than 24 hours worth of seconds:
    FormatTime, hmmss, %time%, h:mm:ss
    return hmmss
    */
}

#include data\External Functions.ahk
#include data\JSON.ahk

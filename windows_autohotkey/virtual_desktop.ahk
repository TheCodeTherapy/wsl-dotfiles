SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance force
#Persistent


; Globals
DesktopCount = 4 ;   Windows starts with 4 desktops at boot
CurrentDesktop = 1 ; Desktop count is 1-indexed by Microsoft
SetTitleMatchMode 3


; Examines the registry to build an accurate list of the
; current virtual desktops and which one we're currently on.
; Current desktop UUID appears to be in
; HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\...
; ...SessionInfo\1\VirtualDesktops
; List of desktops appears to be in
; HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\...
; ...VirtualDesktops
mapDesktopsFromRegistry() {
	global CurrentDesktop, DesktopCount
	; Get the current desktop UUID. Length should be 32 always, but there's no guarantee this couldn't change in a later Windows release so we check.
	IdLength := 32
	SessionId := getSessionId()
	if (SessionId) {
		RegRead, CurrentDesktopId, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\%SessionId%\VirtualDesktops, CurrentVirtualDesktop
		if (CurrentDesktopId) {
			IdLength := StrLen(CurrentDesktopId)
		}
	}
	; Get a list of the UUIDs for all virtual desktops on the system
	RegRead, DesktopList, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops, VirtualDesktopIDs
	if (DesktopList) {
		DesktopListLength := StrLen(DesktopList)
		; Figure out how many virtual desktops there are
		DesktopCount := DesktopListLength / IdLength
	}
	else {
		DesktopCount := 1
	}
	; Parse the REG_DATA string that stores the array of UUID's for virtual desktops in the registry.
	i := 0
	while (CurrentDesktopId and i < DesktopCount) {
		StartPos := (i * IdLength) + 1
		DesktopIter := SubStr(DesktopList, StartPos, IdLength)
		OutputDebug, The iterator is pointing at %DesktopIter% and count is %i%.
		; Break out if we find a match in the list. If we didn't find anything, keep the
		; old guess and pray we're still correct :-D.
		if (DesktopIter = CurrentDesktopId) {
			CurrentDesktop := i + 1
			OutputDebug, Current desktop number is %CurrentDesktop% with an ID of %DesktopIter%.
			break
		}
		i++
	}
}


; Finds out ID of current session.
getSessionId()
{
	ProcessId := DllCall("GetCurrentProcessId", "UInt")
	if ErrorLevel {
		OutputDebug, Error getting current process id: %ErrorLevel%
		return
	}
	OutputDebug, Current Process Id: %ProcessId%
	DllCall("ProcessIdToSessionId", "UInt", ProcessId, "UInt*", SessionId)
	if ErrorLevel {
		OutputDebug, Error getting session id: %ErrorLevel%
		return
	}
	OutputDebug, Current Session Id: %SessionId%
	return SessionId
}


; Switches to the desktop number provided.
switchDesktopByNumber(targetDesktop)
{
	global CurrentDesktop, DesktopCount
	; Re-generate the list of desktops and where we fit in that. We do this because
	; the user may have switched desktops via some other means than the script.
	mapDesktopsFromRegistry()
	; Don't attempt to switch to an invalid desktop
	if (targetDesktop > DesktopCount || targetDesktop < 1) {
		OutputDebug, [invalid] target: %targetDesktop% current: %CurrentDesktop%
		return
	}
	; Go right until we reach the desktop we want
	while(CurrentDesktop < targetDesktop) {
		Send ^#{Right}
		CurrentDesktop++
		OutputDebug, [right] target: %targetDesktop% current: %CurrentDesktop%
	}
	; Go left until we reach the desktop we want
	while(CurrentDesktop > targetDesktop) {
		Send ^#{Left}
		CurrentDesktop--
		OutputDebug, [left] target: %targetDesktop% current: %CurrentDesktop%
	}
}


; Creates a new virtual desktop and switches to it
createVirtualDesktop()
{
	global CurrentDesktop, DesktopCount
	Send, #^d
	DesktopCount++
	CurrentDesktop = %DesktopCount%
	OutputDebug, [create] desktops: %DesktopCount% current: %CurrentDesktop%
}


; Deletes the current virtual desktop
deleteVirtualDesktop()
{
	global CurrentDesktop, DesktopCount
	Send, #^{F4}
	DesktopCount--
	CurrentDesktop--
	OutputDebug, [delete] desktops: %DesktopCount% current: %CurrentDesktop%
}


; Shows the mouse coords with a tooltip on upper left corner
showMouseCoordsTooltip()
{
	CoordMode, ToolTip, Screen ; tooltip relative to screen.
	CoordMode, Mouse, Screen ;   mouse coordinates relative to screen.
	MouseGetPos xx, yy ;         get mouse x and y position, store as %xx% and %yy%
	tooltip %xx% %yy%, 0, 0 ;    display tooltip of %xx% %yy% at coordinates x0 y0.
}


; Resets any tooltip present on the screen
hideTooltips()
{
	tooltip
}


; Generates and returns a random number between min and max arguments
ran(min, max)
{
	random, ran, min, max
	return ran
}

; Main
; SetKeyDelay, 75
mapDesktopsFromRegistry()
OutputDebug, [loading] desktops: %DesktopCount% current: %CurrentDesktop%
; User config!
; Binds the key combo to the switch/create/delete actions
LWin & 1::switchDesktopByNumber(1)
LWin & 2::switchDesktopByNumber(2)
LWin & 3::switchDesktopByNumber(3)
LWin & 4::switchDesktopByNumber(4)
^1::switchDesktopByNumber(CurrentDesktop - 1)
^2::switchDesktopByNumber(CurrentDesktop + 1)
^3::switchDesktopByNumber(CurrentDesktop + 1)
^4::showMouseCoordsTooltip()
^5::hideTooltips()
;CapsLock & c::createVirtualDesktop()
;CapsLock & d::deleteVirtualDesktop()
; Alternate keys for this config.
;^!c::createVirtualDesktop()
;^!d::deleteVirtualDesktop()

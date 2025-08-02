-- Copyright (C) 2017 - 2025 SmashHammer Games Inc. - All Rights Reserved.
local WindowMan = require("WindowMan")
local channelColours =
{
	Colour.__new( 255, 128, 128, 255 ),
	Colour.__new( 128, 255, 128, 255 ),
	Colour.__new( 128, 128, 255, 255 ),
	Colour.__new( 128, 255, 255, 255 ),
	Colour.__new( 255, 128, 255, 255 ),
	Colour.__new( 255, 255, 128, 255 )
}

local currentTargetedPart

local openGraphWindow
math.round = function ( number, precision )
    return tonumber( string.format( string.format( '%%0.%df', precision ), number ) )
 end
----- Init UI -----

local win = Windows.CreateWindow()
win.SetAlignment( align_RightEdge, 20, 250 )
win.SetAlignment( align_TopEdge, 80, 80 )
local function onWindowClose()
	UnloadScript.Raise( ScriptName )	-- Window closed, so unload this script.
end
win.OnClose.add( onWindowClose )
win.Title = 'Part Behaviour Graph'
win.Show( true )

local openGraphWindowButton = win.CreateTextButton()
openGraphWindowButton.SetAlignment( align_HorizEdges, 10, 10 )
openGraphWindowButton.SetAlignment( align_VertEdges, 10, 10 )
local function onOpenGraphWindow()
	if currentTargetedPart then
		openGraphWindow( currentTargetedPart )
	end
end
openGraphWindowButton.OnClick.add( onOpenGraphWindow )
openGraphWindowButton.Text = 'Open Graph Window <i>(Tab)</i>'
openGraphWindowButton.IsInteractable = false

----- Local Functions -----

local function hasDataChannels( part )
	for behaviour in part.Behaviours do
		if behaviour.NumChannels > 0 then
			return true
		end
	end

	return false
end

-- Track created windows and graphs.
local partWins = {}
local partGraphs = {}
local graphSettingsWins = {}
openGraphWindow = function( part )
	if partWins[part.ID] == nil then
		-- Create a window for this part.
		local partWin = Windows.CreateWindow()
		partWin.SetAlignment( align_RightEdge, 320, 350 )
		partWin.SetAlignment( align_TopEdge, 80, 200 )
		local function onPartWindowClose()
			-- Clear entries for this part.
			if partWins[part.ID] then
				WindowMan.DestroyWindow(partWins[part.ID])
			end
			if graphSettingsWins[part.ID].W then
				WindowMan.DestroyWindow(graphSettingsWins[part.ID].W)
			end
			partWins[part.ID] = nil
			partGraphs[part.ID] = nil
			graphSettingsWins[part.ID] = nil
		end
		partWin.OnClose.add( onPartWindowClose )
		partWin.Title = part.FullDisplayName
		partWin.Show( true )
		local ButtonWidth = 300
		local ButtonHeight = 30
		local ButtonsN = 1 + 4
		local SettingsWin = {}
		SettingsWin.PW_MaxValue = WindowMan.CreateLabel(0,0, 300, 20, "000", partWin)
		SettingsWin.PW_MinValue = WindowMan.CreateLabel(0,0, 300, 20, "000", partWin)
		SettingsWin.PW_MinValue.SetAlignment(align_BottomEdge, 5, 20)
		SettingsWin.PW_ZeroValue = WindowMan.CreateLabel(0, 90, 300, 20, "0", partWin)
		-- Create a time series graph for this part.
		local partGraph = partWin.CreateTimeSeriesGraph()
		partGraph.SetAlignment( align_LeftEdge, 55, 290 )
		partGraph.SetAlignment( align_VertEdges, 5, 5 )
		partGraph.TimeSpan = 10
		partGraph.ShowReferenceLines = true
		partGraph.ReferenceLineInterval = 100
		-- Iterate through all the part behaviour data channels, creating a time series for each of them.
		local i = 0
		local toggles = {}
		SettingsWin.labels = {}
		SettingsWin.channels = {}
		for behaviour in part.Behaviours do
			for channel in behaviour.Channels do
				if type( channel.Value ) == 'number' then
					toggles[i] = {}
					-- Pick a colour for this channel.
					toggles[i].colour = channelColours[(i % #channelColours) + 1]
					
					-- Create a time series.
					partGraph.CreateTimeSeries( toggles[i].colour, 2 )
					
					-- Create a toggle that allows a channel's time series to be hidden, and also acts as its label on the graph.
					toggles[i].Y = i * ButtonHeight
					toggles[i].I = i
					toggles[i].Text = channel.Label
					SettingsWin.labels[i] = channel.Label
					ButtonsN = ButtonsN + 1
					SettingsWin.channels[i] = {}
					SettingsWin.channels[i].Max = 0
					SettingsWin.channels[i].Min = 0
					i = i + 1
				end
			end
		end
		
		SettingsWin.W = WindowMan.CreateWindow(ButtonHeight*ButtonsN, ButtonWidth, onPartWindowClose, 320, 290)
		SettingsWin.W.Title = part.FullDisplayName
		local buttonI = 0 
		for toggle in toggles do
			local channelToggle = SettingsWin.W.CreateLabelledToggle()
			channelToggle.SetAlignment( align_RightEdge, 0, ButtonWidth )
			channelToggle.SetAlignment( align_TopEdge, toggle.Y, ButtonHeight )
			local function onChannelToggleChanged()
				-- Set the time series visibility and reset the graph's y axis min max (auto scaling).
				partGraph.SetVisible( toggle.I, channelToggle.Value )
				partGraph.ResetMinMax() 
				for channel in SettingsWin.channels do
					channel.Max = 0
					channel.Min = 0
				end
			end
			channelToggle.OnChanged.add( onChannelToggleChanged )
			channelToggle.Colour = toggle.colour
			channelToggle.Text = toggle.Text
			if toggle.I > buttonI then
				buttonI = toggle.I
			end
		end
		buttonI = buttonI + 1
		SettingsWin.labels[buttonI] = "Auto"
		SettingsWin.RefNumDropdown = WindowMan.CreateLabelledDropdown(0, buttonI*ButtonHeight, ButtonWidth, ButtonHeight, "Ref Value:", SettingsWin.W, SettingsWin.labels)
		buttonI = buttonI + 1
		SettingsWin.TimeSpanTextBox = WindowMan.CreateLabelledInputField(0, buttonI*ButtonHeight, ButtonWidth, ButtonHeight, "Time Span:", SettingsWin.W, 10)
		buttonI = buttonI + 1
		SettingsWin.LineIntervalTextBox = WindowMan.CreateLabelledInputField(0, buttonI*ButtonHeight, ButtonWidth, ButtonHeight, "Line Interval:", SettingsWin.W, 100)
		local function resetMinMax()
			partGraph.ResetMinMax() 
			for channel in SettingsWin.channels do
				channel.Min = 0
				channel.Max = 0
			end
		end
		buttonI = buttonI + 1
		SettingsWin.ResetMinMaxes = WindowMan.CreateButton(0, buttonI*ButtonHeight, ButtonWidth, ButtonHeight, "Reset Mins + Maxes", SettingsWin.W, resetMinMax)
		buttonI = buttonI + 1
		
		-- Add entries for this part.
		partWins[part.ID] = partWin
		partGraphs[part.ID] = partGraph
		graphSettingsWins[part.ID] = SettingsWin
	end
end

----- Entry functions -----

function Update()
	local localPlayer = LocalPlayer.Value
	local targetedPart
	if localPlayer and localPlayer.Targeter then
		targetedPart = localPlayer.Targeter.TargetedPart
	end
	
	-- Update the window title with the part's name, and update the open window button's interactability.
	if targetedPart ~= currentTargetedPart then
		if targetedPart then
			win.Title = targetedPart.FullDisplayName
			openGraphWindowButton.IsInteractable = hasDataChannels( targetedPart )
		else
			win.Title = 'Part Behaviour Graph'
			openGraphWindowButton.IsInteractable = false
		end
		currentTargetedPart = targetedPart
	end

	-- Check for keyboard shortcuts.
	if Input.GetKeyDown( 'tab' ) then
		if openGraphWindowButton.IsInteractable then
			onOpenGraphWindow()
		end
	end
	
	-- Update each of the time series graphs.
	for k, v in pairs( partGraphs ) do
		local part = Parts.GetInstance( k )
		local partGraph = v
		local SWin = graphSettingsWins[k]
		if SWin.TimeSpanTextBox.Value then
			if not (partGraph.TimeSpan == tonumber(SWin.TimeSpanTextBox.Value)) then
				partGraph.TimeSpan = tonumber(SWin.TimeSpanTextBox.Value)
			end 
		end
		if not (partGraph.ReferenceLineInterval  == tonumber(SWin.LineIntervalTextBox.Value)) then
			partGraph.ReferenceLineInterval  =  tonumber(SWin.LineIntervalTextBox.Value)
		end 
		if part and partGraph then
			-- Iterate through all the part behaviour data channels, getting their values and updating the graphs.
			local i = 0
			for behaviour in part.Behaviours do
				for channel in behaviour.Channels do
					if type( channel.Value ) == 'number' then
						-- Add this channel's current value to the time series.
						if SWin.channels[i].Max < channel.Value then
							SWin.channels[i].Max = math.round(channel.Value, 6)
						end
						if SWin.channels[i].Min > channel.Value then
							SWin.channels[i].Min = math.round(channel.Value, 6)
						end
						partGraph.AddDataPoint( i, channel.Value )
						if SWin.labels[SWin.RefNumDropdown.Value] == channel.Label then
							SWin.PW_MaxValue.Text = SWin.channels[i].Max
							SWin.PW_MinValue.Text = SWin.channels[i].Min
							if not ((SWin.channels[i].Min == 0)) and not (SWin.channels[i].Max == 0) then
								SWin.PW_ZeroValue.Text = "0"
								SWin.PW_ZeroValue.SetAlignment(align_TopEdge, ((SWin.channels[i].Max/(SWin.channels[i].Max-(SWin.channels[i].Min)))*180)-20, 20)
							else
								SWin.PW_ZeroValue.Text = ""
							end
						else
							local max = 0
							local min = 0
							for channel in SWin.channels do
								if channel.value > max then
									max = channel.value
								end
								if channel.value < min then
									min = channel.value
								end
							end
							if not ((min == 0)) and not (max == 0) then
								SWin.PW_ZeroValue.Text = "0"
								SWin.PW_ZeroValue.SetAlignment(align_TopEdge, ((max/(max-(min)))*180)-20, 20)
							else
								SWin.PW_ZeroValue.Text = ""
							end
							SWin.PW_MaxValue.Text = max
							SWin.PW_MinValue.Text = min
						end
						i = i + 1
					end
				end
			end
		end
	end
end

function Cleanup()
	for partWin in partWins do
		if partWin then
			WindowMan.DestroyWindow( partWin )
		end
	end
	for Swin in graphSettingsWins do
		if Swin.W then
			WindowMan.DestroyWindow(Swin.W)
		end
	end
	Windows.DestroyWindow( win )
end

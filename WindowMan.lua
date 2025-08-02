local WindowMan = {}

local function CreateWindow(l, w, closefunc, x, y)
    local localwindow
    x = x or 80
    y = y or 20
    localwindow = Windows.CreateWindow()
    localwindow.SetAlignment(align_RightEdge, x, w)
    localwindow.SetAlignment(align_TopEdge, y, l)
    localwindow.OnClose.add(closefunc)
    localwindow.Title = ""
    localwindow.Show(true)
    return localwindow
end
local function CreateLabel(x, y, w, h, txt, localwindow)
    local lbl = localwindow.CreateLabel()
    lbl.SetAlignment(align_LeftEdge,  x, w)
    lbl.SetAlignment(align_TopEdge,  y, h)
    lbl.Text = txt
    return lbl
    
end
local function CreateButton(x, y, w, h, txt, localwindow, clickfunc)
    local btn = localwindow.CreateTextButton()
    btn.SetAlignment(align_LeftEdge,  x, w)
    btn.SetAlignment(align_TopEdge,  y, h)
    btn.OnClick.add( clickfunc )
    btn.Text = txt
    return btn
end
local function createSlider(x, y, w, h, localwindow, min, max, default)
    local slider = localwindow.CreateSlider()
    slider.SetAlignment( align_LeftEdge, x, w )
    slider.SetAlignment( align_TopEdge, y, h )
    slider.MinValue = min
    slider.MaxValue = max
    slider.Value = default
    return slider
end
local function GenericOnWindowClose()
    UnloadScript.Raise(ScriptName) -- Window closed, so unload this script.
end
local function CreateLabelledToggle(x, y, w, h, txt, localwindow, clickfunc)
    local toggle = localwindow.CreateLabelledToggle()
    toggle.SetAlignment( align_LeftEdge, x, w )
    toggle.SetAlignment( align_TopEdge, y, h )
    toggle.Text = txt
    return toggle
end
local function CreateInputField(x, y, w, h, localwindow, default)
    local input = localwindow.CreateInputField()
    input.SetAlignment( align_LeftEdge, x, w )
    input.SetAlignment( align_TopEdge, y, h )
    input.Value = default
    return input
end
local function CreateLabelledInputField(x, y, w, h, txt, localwindow, default)
    local input = localwindow.CreateLabelledInputField()
    input.SetAlignment( align_LeftEdge, x, w )
    input.SetAlignment( align_TopEdge, y, h )
    input.Text = txt
    input.Value = default
    return input
end
local function CreateLabelledDropdown(x, y, w, h, txt, localwindow, values)
    local dropdown = localwindow.CreateLabelledDropdown()
    dropdown.SetAlignment( align_LeftEdge, x, w )
    dropdown.SetAlignment( align_TopEdge, y, h )
    dropdown.Text = txt
    for i, value in pairs(values) do
        dropdown.AddOption(value)
    end
    return dropdown
end


WindowMan.CreateWindow = CreateWindow
WindowMan.CreateLabel = CreateLabel
WindowMan.CreateButton = CreateButton
WindowMan.CreateSlider = createSlider
WindowMan.GenericOnWindowClose = GenericOnWindowClose
WindowMan.CreateLabelledToggle = CreateLabelledToggle
WindowMan.CreateInputField = CreateInputField
WindowMan.CreateLabelledInputField = CreateLabelledInputField
WindowMan.CreateLabelledDropdown = CreateLabelledDropdown
WindowMan.DestroyWindow = Windows.DestroyWindow
return WindowMan
-- Direct Lite 0.2: adjustable visuals, replicated inventory and character preview.
-- No external loaders, requests, game remotes, license code or telemetry.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
assert(player, "Direct Lite must run on the client")
local env = (getgenv and getgenv()) or _G
if env.DirectLiteCleanup then pcall(env.DirectLiteCleanup) end
local connections, markers, lootMarkers = {}, {}, {}
local alive = true
local config = {esp=false, boxes=true, names=true, skeleton=false, chams=false,
    radar=false, loot=false, maxDistance=1500, radarRange=250,
    fullInventory=true, previewBox=true, previewTint=true, rotation=0,
    menuScale=100, radarSize=178, radarWeapons=true, weaponLabels=true, labelSize=12}
local cyan = Color3.fromRGB(56, 191, 255)
local muted = Color3.fromRGB(143, 159, 186)
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end
local function make(class, parent, props)
    local object = Instance.new(class)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local gui = make("ScreenGui", player:WaitForChild("PlayerGui"), {
    Name="DirectLite", ResetOnSpawn=false, IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=80})
local function round(object, radius)
    make("UICorner", object, {CornerRadius=UDim.new(0, radius or 8)})
end
local function text(parent, value, position, size, color, fontSize)
    return make("TextLabel", parent, {BackgroundTransparency=1, Text=value,
        Position=position, Size=size, Font=Enum.Font.Gotham,
        TextSize=fontSize or 13, TextColor3=color or Color3.new(1,1,1),
        TextXAlignment=Enum.TextXAlignment.Left})
end
local function button(parent, value, position, size)
    local b = make("TextButton", parent, {Text=value, Position=position, Size=size,
        BackgroundColor3=Color3.fromRGB(24,38,61), BorderSizePixel=0,
        TextColor3=Color3.fromRGB(218,232,250), TextSize=13,
        Font=Enum.Font.Gotham, AutoButtonColor=true})
    round(b,6)
    return b
end
local window = make("Frame", gui, {Size=UDim2.fromOffset(860,560),
    Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=Color3.fromRGB(9,16,29), BorderSizePixel=0, ZIndex=10})
round(window,12)
make("UIStroke",window,{Color=Color3.fromRGB(35,65,101),Thickness=1})
local scale = make("UIScale", window, {})
local top = make("Frame",window,{Size=UDim2.new(1,0,0,55),
    BackgroundColor3=Color3.fromRGB(13,24,43), BorderSizePixel=0,Active=true})
round(top,12)
text(top,"DIRECT",UDim2.fromOffset(20,5),UDim2.fromOffset(76,42),nil,20)
text(top,"LITE",UDim2.fromOffset(101,5),UDim2.fromOffset(65,42),cyan,20)
text(top,"0.2  /  VISUALS + INVENTORY",UDim2.fromOffset(183,6),UDim2.fromOffset(300,40),muted,11)
local close = button(top,"Unload",UDim2.new(1,-87,0,13),UDim2.fromOffset(72,28))
local reopen = button(gui,"DL",UDim2.fromOffset(12,80),UDim2.fromOffset(44,36))
reopen.ZIndex=20
connect(reopen.Activated,function() window.Visible = not window.Visible end)
local content = make("Frame",window,{Position=UDim2.fromOffset(18,108),
    Size=UDim2.fromOffset(479,428),BackgroundTransparency=1})
local pages = {}
local function page(name)
    local p=make("ScrollingFrame",content,{Name=name,Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
        ScrollBarImageColor3=cyan,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false})
    make("UIListLayout",p,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
    make("UIPadding",p,{PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,12)})
    pages[name]=p
    return p
end
local visuals, inventory, settings = page("Visuals"),page("Inventory"),page("Settings")
local tabs={}
for i,name in ipairs({"Visuals","Inventory","Settings"}) do
    local b=button(window,name,UDim2.fromOffset(18+(i-1)*160,69),UDim2.fromOffset(151,28))
    tabs[name]=b
    connect(b.Activated,function()
        for key,p in pairs(pages) do
            p.Visible=key==name
            tabs[key].BackgroundColor3=key==name and Color3.fromRGB(24,67,103) or Color3.fromRGB(24,38,61)
        end
    end)
end
visuals.Visible=true
tabs.Visuals.BackgroundColor3=Color3.fromRGB(24,67,103)
local order=0
local refreshControls={}
local function row(parent,height)
    order=order+1
    return make("Frame",parent,{Size=UDim2.new(1,0,0,height or 38),
        BackgroundColor3=Color3.fromRGB(15,26,44),BorderSizePixel=0,LayoutOrder=order})
end
local function heading(parent,label)
    local r=row(parent,25)
    r.BackgroundTransparency=1
    text(r,label,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),cyan,11)
end
local function toggle(parent,label,key)
    local r=row(parent)
    round(r,6)
    text(r,label,UDim2.fromOffset(12,0),UDim2.new(1,-90,1,0))
    local b=button(r,"",UDim2.new(1,-66,0,7),UDim2.fromOffset(54,24))
    local function refresh()
        b.Text=config[key] and "ON" or "OFF"
        b.BackgroundColor3=config[key] and Color3.fromRGB(22,100,143) or Color3.fromRGB(31,43,61)
    end
    refresh()
    table.insert(refreshControls,refresh)
    connect(b.Activated,function() config[key]=not config[key]; refresh() end)
end
local function slider(parent,label,key,low,high)
    local r=row(parent,58)
    round(r,6)
    local title=text(r,"",UDim2.fromOffset(12,1),UDim2.new(1,-24,0,28))
    local track=make("TextButton",r,{Text="",AutoButtonColor=false,BorderSizePixel=0,
        BackgroundColor3=Color3.fromRGB(38,53,75),Position=UDim2.fromOffset(14,37),
        Size=UDim2.new(1,-28,0,7)})
    round(track,4)
    local fill=make("Frame",track,{BorderSizePixel=0,BackgroundColor3=cyan,Size=UDim2.fromScale(0,1)})
    round(fill,4)
    local function refresh()
        title.Text=label.."  "..tostring(config[key])
        fill.Size=UDim2.fromScale((config[key]-low)/(high-low),1)
    end
    local dragging=false
    local function update(x)
        local f=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
        config[key]=math.floor(low+(high-low)*f+0.5)
        refresh()
    end
    connect(track.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; update(input.Position.X)
        end
    end)
    connect(UIS.InputChanged,function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then update(input.Position.X) end
    end)
    connect(UIS.InputEnded,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    table.insert(refreshControls,refresh)
    refresh()
end
heading(visuals,"PLAYER OVERLAY")
toggle(visuals,"Player ESP", "esp")
toggle(visuals,"Bounding boxes", "boxes")
toggle(visuals,"Player name / distance", "names")
toggle(visuals,"Equipped-gun labels", "weaponLabels")
slider(visuals,"Label text size", "labelSize",10,20)
toggle(visuals,"Skeleton lines", "skeleton")
toggle(visuals,"Cyan character highlight", "chams")
slider(visuals,"Maximum distance (studs)","maxDistance",100,3000)
heading(visuals,"RADAR + DROPPED ITEMS")
toggle(visuals,"Player radar", "radar")
slider(visuals,"Radar range (studs)","radarRange",50,1000)
slider(visuals,"Radar size (pixels)","radarSize",120,500)
toggle(visuals,"Gun labels beside radar dots","radarWeapons")
toggle(visuals,"Dropped-item labels", "loot")
heading(inventory,"SELECT PLAYER")
local selector=row(inventory,38)
local prev=button(selector,"<",UDim2.fromOffset(4,4),UDim2.fromOffset(33,30))
local nextPlayer=button(selector,">",UDim2.new(1,-37,0,4),UDim2.fromOffset(33,30))
local selectedLabel=text(selector,"",UDim2.fromOffset(47,0),UDim2.new(1,-94,1,0),nil,12)
selectedLabel.TextTruncate=Enum.TextTruncate.AtEnd
toggle(inventory,"Include nested clothing / containers","fullInventory")
local search=make("TextBox",inventory,{Size=UDim2.new(1,0,0,33),
    LayoutOrder=10000,BackgroundColor3=Color3.fromRGB(21,35,55),BorderSizePixel=0,
    PlaceholderText="Filter items...",Text="",TextColor3=Color3.new(1,1,1),
    PlaceholderColor3=muted,Font=Enum.Font.Gotham,TextSize=12,ClearTextOnFocus=false})
round(search,6)
local inventoryStatus=row(inventory,35)
inventoryStatus.LayoutOrder=10001
local status=text(inventoryStatus,"",UDim2.fromOffset(8,0),UDim2.new(1,-16,1,0),muted,11)
local itemText=make("TextLabel",inventory,{LayoutOrder=10002,Size=UDim2.new(1,-8,0,0),
    AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="",
    TextColor3=Color3.fromRGB(204,218,238),Font=Enum.Font.Code,TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
    TextWrapped=true})
heading(settings,"MENU SIZE")
slider(settings,"Menu scale (%)","menuScale",50,150)
heading(settings,"CHARACTER PREVIEW")
toggle(settings,"Preview bounding box","previewBox")
toggle(settings,"Cyan model material","previewTint")
slider(settings,"Preview rotation","rotation",-180,180)
heading(settings,"CONTROLS")
local help=row(settings,96)
local h=text(help,"Right Shift or DL: show / hide menu\nDrag the title bar to move\nUse < and > in Inventory to inspect players\nUnload removes overlays and connections",UDim2.fromOffset(10,6),UDim2.new(1,-20,1,-12),muted,12)
h.TextYAlignment=Enum.TextYAlignment.Top
h.TextWrapped=true
local save=button(settings,"Save settings",UDim2.new(),UDim2.new(1,0,0,34))
save.LayoutOrder=10000
local load=button(settings,"Load settings",UDim2.new(),UDim2.new(1,0,0,34))
load.LayoutOrder=10001
local notice=text(settings,"",UDim2.new(),UDim2.new(1,0,0,30),muted,11)
notice.LayoutOrder=10002
connect(save.Activated,function()
    if type(writefile)~="function" then notice.Text="File saving is unavailable in this runtime."; return end
    local ok=pcall(function() writefile("DirectLite.settings.json",HttpService:JSONEncode(config)) end)
    notice.Text=ok and "Settings saved." or "Could not save settings."
end)
connect(load.Activated,function()
    if type(readfile)~="function" then notice.Text="File loading is unavailable in this runtime."; return end
    local ok,data=pcall(function() return HttpService:JSONDecode(readfile("DirectLite.settings.json")) end)
    if not ok or type(data)~="table" then notice.Text="No readable settings file."; return end
    for k,v in pairs(config) do if typeof(data[k])==typeof(v) then config[k]=data[k] end end
    config.maxDistance=math.clamp(config.maxDistance,100,3000)
    config.radarRange=math.clamp(config.radarRange,50,1000)
    config.rotation=math.clamp(config.rotation,-180,180)
    config.menuScale=math.clamp(config.menuScale,50,150)
    config.radarSize=math.clamp(config.radarSize,120,500)
    config.labelSize=math.clamp(config.labelSize,10,20)
    for _,refresh in ipairs(refreshControls) do refresh() end
    notice.Text="Settings loaded."
end)
-- Preview: a real character clone in a private WorldModel, not a screenshot.
local preview=make("Frame",window,{Position=UDim2.fromOffset(515,69),Size=UDim2.fromOffset(327,467),
    BackgroundColor3=Color3.fromRGB(12,22,37),BorderSizePixel=0})
round(preview,8)
text(preview,"CHARACTER PREVIEW",UDim2.fromOffset(15,10),UDim2.fromOffset(260,22),muted,11)
local previewName=text(preview,"",UDim2.fromOffset(15,36),UDim2.fromOffset(297,26),cyan,13)
previewName.TextXAlignment=Enum.TextXAlignment.Center
previewName.TextTruncate=Enum.TextTruncate.AtEnd
local viewport=make("ViewportFrame",preview,{Position=UDim2.fromOffset(26,70),
    Size=UDim2.fromOffset(275,330),BackgroundTransparency=1,
    Ambient=Color3.fromRGB(170,185,210),LightColor=Color3.new(1,1,1),
    LightDirection=Vector3.new(-1,-1,-1)})
local previewStroke=make("UIStroke",viewport,{Color=cyan,Thickness=1,Transparency=0.2})
local world=make("WorldModel",viewport,{})
local previewCamera=make("Camera",viewport,{FieldOfView=35})
viewport.CurrentCamera=previewCamera
local previewInfo=text(preview,"",UDim2.fromOffset(15,405),UDim2.fromOffset(297,50),cyan,12)
previewInfo.TextXAlignment=Enum.TextXAlignment.Center
local selected=player
local clonedCharacter, sourceCharacter, previewError=nil,nil,""
local lastTint=nil
local originals={}
local previewLines={}
local function equipped(character)
    if not character then return "No character" end
    local tool=character:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    local target=Players:GetPlayerFromCharacter(character)
    local folder=RS:FindFirstChild("Players")
    local entry=folder and folder:FindFirstChild(target and target.Name or character.Name)
    local statusFolder=entry and entry:FindFirstChild("Status")
    local gameplay=statusFolder and statusFolder:FindFirstChild("GameplayVariables")
    local held=gameplay and gameplay:FindFirstChild("EquippedTool")
    if held and held:IsA("ValueBase") then
        local value=held.Value
        if typeof(value)=="Instance" then return value.Name end
        if value~=nil and tostring(value)~="" and tostring(value)~="None" then return tostring(value) end
    end
    return "No equipped weapon replicated"
end
local function distanceTo(character)
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local me=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return root and me and (root.Position-me.Position).Magnitude or nil
end
local function rebuildPreview()
    world:ClearAllChildren()
    clonedCharacter=nil; originals={}; lastTint=nil
    sourceCharacter=selected and selected.Character
    if not sourceCharacter then previewError="Waiting for character"; return end
    local old=sourceCharacter.Archivable
    sourceCharacter.Archivable=true
    local ok,model=pcall(function() return sourceCharacter:Clone() end)
    sourceCharacter.Archivable=old
    if not ok or not model then previewError="Character could not be cloned"; return end
    for _,object in ipairs(model:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") or object:IsA("Sound") or object:IsA("ParticleEmitter") or object:IsA("Trail") then
            object:Destroy()
        elseif object:IsA("BasePart") then
            object.Anchored=true; object.CanCollide=false; object.CastShadow=false
            originals[object]={object.Color,object.Material}
            object.LocalTransparencyModifier=0
        end
    end
    model.Parent=world
    clonedCharacter=model
    previewError=""
end
local function cycle(direction)
    local list=Players:GetPlayers()
    table.sort(list,function(a,b) return a.Name:lower()<b.Name:lower() end)
    local index=table.find(list,selected) or 1
    selected=list[((index-1+direction)%#list)+1]
    rebuildPreview()
end
connect(prev.Activated,function() cycle(-1) end)
connect(nextPlayer.Activated,function() cycle(1) end)
local function inventoryRoot(target)
    local container=RS:FindFirstChild("Players")
    local entry=container and container:FindFirstChild(target.Name)
    return entry and entry:FindFirstChild("Inventory")
end
local function updateInventory()
    if not selected or selected.Parent~=Players then selected=player; rebuildPreview() end
    selectedLabel.Text=selected.DisplayName.." (@"..selected.Name..")"
    local root=inventoryRoot(selected)
    if not root then
        status.Text="Inventory is not replicated or not loaded for this player."
        itemText.Text="No inventory data available."
        return
    end
    local lines, count, visited={},0,{}
    local filter=search.Text:lower()
    local function walk(container,depth)
        if depth>8 or visited[container] or count>=400 then return end
        visited[container]=true
        local children=container:GetChildren()
        table.sort(children,function(a,b) return a.Name:lower()<b.Name:lower() end)
        for _,item in ipairs(children) do
            if count>=400 then return end
            local slot=item:GetAttribute("Slot")
            local amount=item:GetAttribute("Amount") or item:GetAttribute("Quantity")
            local suffix=(amount and " x"..tostring(amount) or "")..(slot and " ["..tostring(slot).."]" or "")
            if filter=="" or (item.Name..suffix):lower():find(filter,1,true) then
                table.insert(lines,string.rep("  ",depth)..item.Name..suffix)
                count=count+1
            end
            local nested=item:FindFirstChild("Inventory")
            if config.fullInventory and nested then walk(nested,depth+1) end
        end
    end
    walk(root,0)
    status.Text=tostring(count).." matching entries / replicated data only"..(count>=400 and " / capped at 400" or "")
    itemText.Text=#lines>0 and table.concat(lines,"\n") or "No matching items."
end
-- World overlays use Roblox UI and Highlights; there is no Drawing dependency.
local overlay=make("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
local radar=make("Frame",gui,{Position=UDim2.new(1,-198,0,20),Size=UDim2.fromOffset(178,178),
    BackgroundColor3=Color3.fromRGB(10,22,39),BackgroundTransparency=0.15,
    BorderSizePixel=0,Visible=false})
make("UICorner",radar,{CornerRadius=UDim.new(0.5,0)})
radar.Active=true
make("UIStroke",radar,{Color=cyan,Transparency=0.3})
text(radar,"N",UDim2.new(0.5,-5,0,5),UDim2.fromOffset(12,16),muted,11)
make("Frame",radar,{Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(4,4),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0})
local radarDragging,radarDragStart,radarPosition=false,nil,nil
connect(radar.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        radarDragging=true; radarDragStart=input.Position; radarPosition=radar.Position
    end
end)
connect(UIS.InputChanged,function(input)
    if radarDragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta=input.Position-radarDragStart
        radar.Position=UDim2.new(radarPosition.X.Scale,radarPosition.X.Offset+delta.X,
            radarPosition.Y.Scale,radarPosition.Y.Offset+delta.Y)
    end
end)
connect(UIS.InputEnded,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then radarDragging=false end
end)
local function newMarker(target)
    local frame=make("Frame",overlay,{BackgroundTransparency=1,Visible=false})
    local box=make("UIStroke",frame,{Color=cyan,Thickness=1})
    local label=text(frame,"",UDim2.new(0,-50,0,-30),UDim2.new(1,100,0,28),cyan,11)
    label.TextXAlignment=Enum.TextXAlignment.Center
    local dot=make("Frame",radar,{Size=UDim2.fromOffset(5,5),BackgroundColor3=cyan,BorderSizePixel=0,Visible=false})
    round(dot,3)
    local radarLabel=text(dot,"",UDim2.fromOffset(8,-5),UDim2.fromOffset(150,16),cyan,10)
    radarLabel.TextTruncate=Enum.TextTruncate.AtEnd
    markers[target]={frame=frame,box=box,label=label,dot=dot,radarLabel=radarLabel,lines={}}
end
local function removeMarker(target)
    local m=markers[target]
    if not m then return end
    m.frame:Destroy(); m.dot:Destroy()
    for _,line in ipairs(m.lines) do line:Destroy() end
    if m.highlight then m.highlight:Destroy() end
    markers[target]=nil
end
for _,target in ipairs(Players:GetPlayers()) do if target~=player then newMarker(target) end end
connect(Players.PlayerAdded,function(target) if target~=player then newMarker(target) end end)
connect(Players.PlayerRemoving,removeMarker)
local function drawLine(line,a,b)
    local delta=b-a
    line.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
    line.Size=UDim2.fromOffset(delta.Magnitude,1)
    line.Rotation=math.deg(math.atan2(delta.Y,delta.X))
    line.Visible=true
end
local function previewPoint(position)
    local p=previewCamera.CFrame:PointToObjectSpace(position)
    if p.Z>=-0.01 then return nil end
    local size=viewport.AbsoluteSize
    local focal=size.Y/(2*math.tan(math.rad(previewCamera.FieldOfView/2)))
    -- Child UI sizes are in the unscaled menu coordinate system.
    local factor=math.max(0.01,scale.Scale)
    return Vector2.new((size.X/2+p.X*focal/(-p.Z))/factor,
        (size.Y/2-p.Y*focal/(-p.Z))/factor)
end
local function updatePreviewSkeleton()
    for _,line in ipairs(previewLines) do line.Visible=false end
    if not config.skeleton or not clonedCharacter or not window.Visible then return end
    local i=0
    for _,motor in ipairs(clonedCharacter:GetDescendants()) do
        if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 and motor.Name~="RootJoint" and motor.Name~="Root" then
            local a,b=previewPoint(motor.Part0.Position),previewPoint(motor.Part1.Position)
            if a and b then
                i=i+1
                if not previewLines[i] then
                    previewLines[i]=make("Frame",viewport,{AnchorPoint=Vector2.new(0.5,0.5),
                        BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),ZIndex=3})
                end
                drawLine(previewLines[i],a,b)
            end
        end
    end
end
local function updateLoot()
    for object,marker in pairs(lootMarkers) do
        if not config.loot or not object.Parent then marker:Destroy(); lootMarkers[object]=nil end
    end
    if not config.loot then return end
    local dropped=workspace:FindFirstChild("DroppedItems")
    if not dropped then return end
    local used=0
    for _,object in ipairs(dropped:GetChildren()) do
        if used>=80 then break end
        local part=object:IsA("BasePart") and object or object:FindFirstChildWhichIsA("BasePart",true)
        if part then
            used=used+1
            if not lootMarkers[object] then
                local billboard=make("BillboardGui",gui,{Adornee=part,Size=UDim2.fromOffset(180,24),
                    AlwaysOnTop=true,MaxDistance=config.maxDistance,StudsOffset=Vector3.new(0,1.2,0)})
                local label=text(billboard,object.Name,UDim2.new(),UDim2.fromScale(1,1),Color3.fromRGB(245,202,102),11)
                label.TextXAlignment=Enum.TextXAlignment.Center
                lootMarkers[object]=billboard
            end
            lootMarkers[object].MaxDistance=config.maxDistance
        end
    end
end
local dragging,dragStart,originalPosition=false,nil,nil
connect(top.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position; originalPosition=window.Position
    end
end)
connect(UIS.InputChanged,function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta=input.Position-dragStart
        window.Position=UDim2.new(originalPosition.X.Scale,originalPosition.X.Offset+delta.X,
            originalPosition.Y.Scale,originalPosition.Y.Offset+delta.Y)
    end
end)
connect(UIS.InputEnded,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
connect(UIS.InputBegan,function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.RightShift then window.Visible=not window.Visible end
end)
local function cleanup()
    if not alive then return end
    alive=false
    for _,connection in ipairs(connections) do connection:Disconnect() end
    local list={}
    for target in pairs(markers) do table.insert(list,target) end
    for _,target in ipairs(list) do removeMarker(target) end
    gui:Destroy()
    if env.DirectLiteCleanup==cleanup then env.DirectLiteCleanup=nil end
end
env.DirectLiteCleanup=cleanup
connect(close.Activated,cleanup)
rebuildPreview()
local timer,previewTimer=0,0
connect(RunService.RenderStepped,function(dt)
    if not alive then return end
    local camera=workspace.CurrentCamera
    if not camera then return end
    scale.Scale=math.max(0.1,math.min(config.menuScale/100,(camera.ViewportSize.X-24)/860,(camera.ViewportSize.Y-24)/560))
    local radarSize=math.min(config.radarSize,math.max(80,math.min(camera.ViewportSize.X,camera.ViewportSize.Y)-24))
    radar.Size=UDim2.fromOffset(radarSize,radarSize)
    if not radarDragging then
        local pos=radar.AbsolutePosition
        local x=math.clamp(pos.X,0,math.max(0,camera.ViewportSize.X-radarSize))
        local y=math.clamp(pos.Y,0,math.max(0,camera.ViewportSize.Y-radarSize))
        radar.Position=UDim2.fromOffset(x,y)
    end
    radar.Visible=config.radar
    local me=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for target,m in pairs(markers) do
        local character=target.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local distance=root and me and (root.Position-me.Position).Magnitude or math.huge
        local valid=root and humanoid and humanoid.Health>0 and distance<=config.maxDistance
        m.frame.Visible=false; m.dot.Visible=false
        for _,line in ipairs(m.lines) do line.Visible=false end
        if m.highlight and m.highlight.Adornee~=character then m.highlight:Destroy(); m.highlight=nil end
        if config.esp and config.chams and valid and not m.highlight then
            m.highlight=make("Highlight",gui,{Adornee=character,FillColor=cyan,FillTransparency=0.65,
                OutlineColor=cyan,OutlineTransparency=0.1,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop})
        end
        if m.highlight then m.highlight.Enabled=not not (config.esp and config.chams and valid) end
        if valid then
            if config.esp then
                local point,onScreen=camera:WorldToViewportPoint(root.Position)
                if onScreen and point.Z>0 then
                    local above=camera:WorldToViewportPoint(root.Position+Vector3.new(0,3.5,0))
                    local below=camera:WorldToViewportPoint(root.Position-Vector3.new(0,3.5,0))
                    local height=math.clamp(math.abs(below.Y-above.Y),8,2000)
                    local width=height*0.53
                    m.frame.Position=UDim2.fromOffset(point.X-width/2,point.Y-height/2)
                    m.frame.Size=UDim2.fromOffset(width,height)
                    m.frame.Visible=true; m.box.Enabled=config.boxes
                    m.label.Visible=config.names or config.weaponLabels
                    m.label.TextSize=config.labelSize
                    m.label.Size=UDim2.new(1,100,0,config.labelSize*2+6)
                    m.label.Position=UDim2.new(0,-50,0,-config.labelSize*2-8)
                    m.label.Text=(config.names and target.DisplayName.." / "..math.floor(distance).." studs" or "")
                        ..(config.names and config.weaponLabels and "\n" or "")
                        ..(config.weaponLabels and equipped(character) or "")
                    if config.skeleton then
                        local i=0
                        for _,motor in ipairs(character:GetDescendants()) do
                            if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 and motor.Name~="RootJoint" and motor.Name~="Root" then
                                local a,av=camera:WorldToViewportPoint(motor.Part0.Position)
                                local b,bv=camera:WorldToViewportPoint(motor.Part1.Position)
                                if av and bv and a.Z>0 and b.Z>0 then
                                    i=i+1
                                    if not m.lines[i] then m.lines[i]=make("Frame",overlay,{AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,BackgroundColor3=cyan}) end
                                    drawLine(m.lines[i],Vector2.new(a.X,a.Y),Vector2.new(b.X,b.Y))
                                end
                            end
                        end
                    end
                end
            end
            if config.radar and me then
                local relative=root.Position-me.Position
                local radius=radarSize/2-13
                local point=Vector2.new(relative.X,relative.Z)*(radius/config.radarRange)
                if point.Magnitude<=radius then
                    m.dot.Position=UDim2.fromOffset(radarSize/2+point.X-2,radarSize/2+point.Y-2)
                    m.dot.Visible=true
                    m.radarLabel.Visible=config.radarWeapons
                    m.radarLabel.Text=equipped(character)
                end
            end
        end
    end
    timer=timer+dt; previewTimer=previewTimer+dt
    if timer>=1 then
        timer=0
        updateInventory(); updateLoot()
    end
    if previewTimer>=2 and window.Visible then previewTimer=0; rebuildPreview() end
    previewStroke.Enabled=config.previewBox
    previewName.Text=selected and selected.DisplayName or "No player"
    if selected and sourceCharacter~=selected.Character then rebuildPreview() end
    if clonedCharacter and window.Visible then
        if lastTint~=config.previewTint then
            for part,original in pairs(originals) do
                if part.Parent then
                    part.Color=config.previewTint and cyan or original[1]
                    part.Material=config.previewTint and Enum.Material.Neon or original[2]
                end
            end
            lastTint=config.previewTint
        end
        clonedCharacter:PivotTo(CFrame.Angles(0,math.rad(config.rotation),0))
        local cf,size=clonedCharacter:GetBoundingBox()
        local aspect=viewport.AbsoluteSize.X/math.max(1,viewport.AbsoluteSize.Y)
        local tangent=math.tan(math.rad(previewCamera.FieldOfView/2))
        local distance=math.max(size.Y/2/tangent,size.X/2/(tangent*aspect))+size.Z/2+0.5
        previewCamera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(0,0,-distance),cf.Position)
    end
    updatePreviewSkeleton()
    local d=selected and distanceTo(selected.Character)
    previewInfo.Text=previewError~="" and previewError or ((d and tostring(math.floor(d)).." studs" or "Distance unavailable").."\n"..equipped(selected and selected.Character))
end)
updateInventory()

-- Direct Lite 0.4: rig-aware overlays, square threat radar and workspace menu.
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
    menuScale=100, radarSize=230, radarWeapons=false, weaponLabels=false, labelSize=11,
    aimbot=false, silentAim=false, noRecoil=false, aimHold=true, aimVisible=true,
    aimTeamCheck=false, aimBody=false, aimFov=120, aimSmooth=6, aimCircle=true,
    silentChance=100, perfectSilent=false, npcESP=true, threatLines=true,
    threatAngle=25, climb=false, climbSpeed=22, fovOverride=false, cameraFov=70,
    modAlerts=true, modNames="", radarRotate=true, lineThickness=2}
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
local window = make("Frame", gui, {Size=UDim2.fromOffset(980,620),
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
text(top,"0.4    /    WORKSPACE",UDim2.fromOffset(183,6),UDim2.fromOffset(300,40),muted,11)
local close = button(top,"Unload",UDim2.new(1,-87,0,13),UDim2.fromOffset(72,28))
local reopen = button(gui,"DL",UDim2.fromOffset(12,80),UDim2.fromOffset(44,36))
reopen.ZIndex=20
connect(reopen.Activated,function() window.Visible = not window.Visible end)
local sidebar=make("Frame",window,{Position=UDim2.fromOffset(0,60),Size=UDim2.new(0,155,1,-60),
    BackgroundColor3=Color3.fromRGB(11,21,37),BorderSizePixel=0})
text(sidebar,"WORKSPACE",UDim2.fromOffset(18,16),UDim2.fromOffset(120,25),muted,10)
text(sidebar,"DIRECT LITE\nCLIENT 0.4",UDim2.new(0,18,1,-65),UDim2.fromOffset(120,45),muted,10)
local content = make("Frame",window,{Position=UDim2.fromOffset(175,86),
    Size=UDim2.fromOffset(438,510),BackgroundTransparency=1})
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
local combat=page("Combat")
local movement=page("Movement")
local radarPage=page("Radar")
local weapons=page("Weapons")
local tabs={}
for i,name in ipairs({"Combat","Visuals","Radar","Movement","Weapons","Inventory","Settings"}) do
    local display=({Combat="Aim",Visuals="ESP"})[name] or name
    local b=button(sidebar,display,UDim2.fromOffset(12,58+(i-1)*46),UDim2.fromOffset(131,36))
    tabs[name]=b
    connect(b.Activated,function()
        for key,p in pairs(pages) do
            p.Visible=key==name
            tabs[key].BackgroundColor3=key==name and Color3.fromRGB(24,67,103) or Color3.fromRGB(24,38,61)
        end
    end)
end
combat.Visible=true
tabs.Combat.BackgroundColor3=Color3.fromRGB(24,67,103)
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
    local b=button(r,"",UDim2.new(1,-66,0,7),UDim2.fromOffset(48,24))
    round(b,12)
    local knob=make("Frame",b,{Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(3,3),
        BackgroundColor3=Color3.fromRGB(240,248,255),BorderSizePixel=0})
    round(knob,9)
    local function refresh()
        b.Text=""
        knob.Position=UDim2.fromOffset(config[key] and 27 or 3,3)
        b.BackgroundColor3=config[key] and Color3.fromRGB(0,147,255) or Color3.fromRGB(53,75,99)
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
heading(combat,"AIM / SILENT AIM")
toggle(combat,"Aimbot (camera aim)","aimbot")
toggle(combat,"Silent aim (takes priority over camera aim)","silentAim")
toggle(combat,"Hold right mouse to activate","aimHold")
toggle(combat,"Visibility check","aimVisible")
toggle(combat,"Skip teammates / same clan","aimTeamCheck")
toggle(combat,"Aim at torso instead of head","aimBody")
toggle(combat,"Show FOV circle","aimCircle")
slider(combat,"FOV radius (pixels)","aimFov",20,500)
slider(combat,"Camera smoothing (1 = instant)","aimSmooth",1,20)
slider(combat,"Silent hit chance (%)","silentChance",0,100)
toggle(combat,"Silent aim: attachment-point variant","perfectSilent")
heading(weapons,"WEAPON CONTROL")
toggle(weapons,"No recoil","noRecoil")
local combatStatusRow=row(combat,65)
local combatStatus=text(combatStatusRow,"Combat is off",UDim2.fromOffset(10,5),UDim2.new(1,-20,1,-10),muted,11)
combatStatus.TextWrapped=true
combatStatus.TextYAlignment=Enum.TextYAlignment.Top
heading(visuals,"PLAYER OVERLAY")
toggle(visuals,"Player ESP", "esp")
toggle(visuals,"Include NPCs / test dummies", "npcESP")
toggle(visuals,"Bounding boxes", "boxes")
toggle(visuals,"Player name / distance", "names")
toggle(visuals,"Equipped-gun labels", "weaponLabels")
slider(visuals,"Label text size", "labelSize",10,20)
toggle(visuals,"Skeleton lines", "skeleton")
slider(visuals,"Line thickness (pixels)","lineThickness",1,4)
toggle(visuals,"Cyan character highlight", "chams")
slider(visuals,"Maximum distance (studs)","maxDistance",100,3000)
heading(radarPage,"TOP-DOWN RADAR")
toggle(radarPage,"Player radar", "radar")
toggle(radarPage,"Radar follows camera rotation","radarRotate")
slider(radarPage,"Radar range (studs)","radarRange",50,1000)
slider(radarPage,"Radar size (pixels)","radarSize",120,500)
toggle(radarPage,"Facing / clear sight red lines","threatLines")
slider(radarPage,"Facing angle tolerance (degrees)","threatAngle",5,60)
heading(visuals,"DROPPED ITEMS")
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
heading(movement,"WALL CLIMB")
toggle(movement,"Wall climb: hold W + Space near wall","climb")
slider(movement,"Climb speed (studs / second)","climbSpeed",5,50)
heading(movement,"CAMERA")
toggle(movement,"Override camera FOV","fovOverride")
slider(movement,"Camera field of view (degrees)","cameraFov",40,110)
heading(settings,"MODERATOR WATCHLIST")
toggle(settings,"Notify for known moderator accounts","modAlerts")
local modNames=make("TextBox",settings,{Size=UDim2.new(1,0,0,38),LayoutOrder=order+1,
    BackgroundColor3=Color3.fromRGB(21,35,55),BorderSizePixel=0,Text=config.modNames,
    PlaceholderText="Exact usernames or user IDs, comma separated",TextColor3=Color3.new(1,1,1),
    PlaceholderColor3=muted,Font=Enum.Font.Gotham,TextSize=11,ClearTextOnFocus=false})
order=order+1
round(modNames,6)
connect(modNames.FocusLost,function() config.modNames=modNames.Text end)
table.insert(refreshControls,function() modNames.Text=config.modNames end)
local modHint=row(settings,48)
local mh=text(modHint,"Add known accounts above. No automatic moderator roster is configured.",UDim2.fromOffset(10,4),UDim2.new(1,-20,1,-8),muted,11)
mh.TextWrapped=true
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
    config.aimFov=math.clamp(config.aimFov,20,500)
    config.aimSmooth=math.clamp(config.aimSmooth,1,20)
    config.silentChance=math.clamp(config.silentChance,0,100)
    config.threatAngle=math.clamp(config.threatAngle,5,60)
    config.climbSpeed=math.clamp(config.climbSpeed,5,50)
    config.cameraFov=math.clamp(config.cameraFov,40,110)
    config.lineThickness=math.clamp(config.lineThickness,1,4)
    for _,refresh in ipairs(refreshControls) do refresh() end
    notice.Text="Settings loaded."
end)
-- Preview: a real character clone in a private WorldModel, not a screenshot.
local preview=make("Frame",window,{Position=UDim2.fromOffset(635,86),Size=UDim2.fromOffset(327,510),
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
round(radar,8)
radar.Active=true
make("UIStroke",radar,{Color=cyan,Transparency=0.3})
local radarTitle=text(radar,"THREAT RADAR",UDim2.fromOffset(10,5),UDim2.new(1,-20,0,16),cyan,10)
text(radar,"RED = FACING + CLEAR SIGHT (EST.)",UDim2.new(0,7,1,-22),UDim2.new(1,-14,0,18),muted,8)
for i=1,3 do
    make("Frame",radar,{Position=UDim2.fromScale(i/4,0.12),Size=UDim2.new(0,1,0.76,0),
        BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(36,58,78)})
    make("Frame",radar,{Position=UDim2.fromScale(0.06,0.12+i*0.19),Size=UDim2.new(0.88,0,0,1),
        BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(36,58,78)})
end
for _,fraction in ipairs({0.25,0.5,0.75}) do
    local ring=make("Frame",radar,{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromScale(fraction,fraction),BackgroundTransparency=1})
    make("UICorner",ring,{CornerRadius=UDim.new(0.5,0)})
    make("UIStroke",ring,{Color=Color3.fromRGB(31,83,121),Thickness=1})
end
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
    label.TextStrokeTransparency=0.35
    label.TextStrokeColor3=Color3.fromRGB(0,0,0)
    local dot=make("Frame",radar,{Size=UDim2.fromOffset(5,5),BackgroundColor3=cyan,BorderSizePixel=0,Visible=false})
    round(dot,3)
    local radarLabel=text(dot,"",UDim2.fromOffset(8,-5),UDim2.fromOffset(150,16),cyan,10)
    radarLabel.TextTruncate=Enum.TextTruncate.AtEnd
    local facing=make("Frame",radar,{AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,
        BackgroundColor3=Color3.fromRGB(255,76,90),Visible=false})
    markers[target]={frame=frame,box=box,label=label,dot=dot,radarLabel=radarLabel,facing=facing,lines={}}
end
local function removeMarker(target)
    local m=markers[target]
    if not m then return end
    m.frame:Destroy(); m.dot:Destroy(); m.facing:Destroy()
    for _,line in ipairs(m.lines) do line:Destroy() end
    if m.highlight then m.highlight:Destroy() end
    markers[target]=nil
end
for _,target in ipairs(Players:GetPlayers()) do if target~=player then newMarker(target) end end
connect(Players.PlayerAdded,function(target) if target~=player then newMarker(target) end end)
connect(Players.PlayerRemoving,removeMarker)
local function entityCharacter(target)
    if target:IsA("Player") then return target.Character end
    return target
end
local function entityName(target)
    return target:IsA("Player") and target.DisplayName or target.Name.." [NPC]"
end
local function rootPart(character)
    if not character then return nil end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    return character:FindFirstChild("HumanoidRootPart") or (humanoid and humanoid.RootPart)
        or character.PrimaryPart or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end
local function scanRigs()
    local remove={}
    for target in pairs(markers) do
        if not target:IsA("Player") and (not config.npcESP or not target:IsDescendantOf(workspace)) then table.insert(remove,target) end
    end
    for _,target in ipairs(remove) do removeMarker(target) end
    if not config.npcESP then return end
    local count=0
    for _,object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Humanoid") and object.Parent and object.Parent:IsA("Model") then
            local model=object.Parent
            if model~=player.Character and not Players:GetPlayerFromCharacter(model)
                and not (workspace.CurrentCamera and model:IsDescendantOf(workspace.CurrentCamera)) then
                count=count+1
                if not markers[model] then newMarker(model) end
                if count>=100 then break end
            end
        end
    end
end
local function drawLine(line,a,b)
    local delta=b-a
    line.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
    line.Size=UDim2.fromOffset(delta.Magnitude,config.lineThickness)
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
-- Combat adaptation: ammo attributes, camera steering and viewmodel orientation.
-- Does not send remotes, install hooks or run the supplied loader.
local recoilOriginals={}
local recoilTimer=0
local viewPart,viewOffset=nil,nil
local aimCircleFrame=make("Frame",overlay,{AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundTransparency=1,Visible=false})
make("UICorner",aimCircleFrame,{CornerRadius=UDim.new(0.5,0)})
make("UIStroke",aimCircleFrame,{Color=cyan,Thickness=1,Transparency=0.4})
local function restoreRecoil()
    for ammo,snapshot in pairs(recoilOriginals) do
        if ammo.Parent and ammo:GetAttribute("RecoilStrength")==0 then
            ammo:SetAttribute("RecoilStrength",snapshot.value)
        end
        recoilOriginals[ammo]=nil
    end
end
local function applyRecoil()
    local ammoTypes=RS:FindFirstChild("AmmoTypes")
    if not ammoTypes then return 0 end
    local count=0
    for _,ammo in ipairs(ammoTypes:GetChildren()) do
        local strength=ammo:GetAttribute("RecoilStrength")
        if type(strength)=="number" then
            if not recoilOriginals[ammo] then recoilOriginals[ammo]={value=strength} end
            ammo:SetAttribute("RecoilStrength",0)
            count=count+1
        end
    end
    return count
end
local function releaseViewmodel()
    if viewPart and viewPart.Parent and viewOffset and workspace.CurrentCamera then
        viewPart.CFrame=workspace.CurrentCamera.CFrame*viewOffset
    end
    viewPart=nil; viewOffset=nil
end
local function clan(target)
    local folder=RS:FindFirstChild("Players")
    local entry=folder and folder:FindFirstChild(target.Name)
    local s=entry and entry:FindFirstChild("Status")
    local journey=s and s:FindFirstChild("Journey")
    local group=journey and journey:FindFirstChild("Clan")
    local name=group and group:GetAttribute("CurrentClan")
    return name and tostring(name)~="nil" and tostring(name)~="" and tostring(name) or nil
end
local function teammate(target)
    if player.Team and target.Team==player.Team and not player.Neutral and not target.Neutral then return true end
    local a,b=clan(player),clan(target)
    return a~=nil and b~=nil and a==b
end
local function aimTarget(camera)
    local best,bestPart=nil,nil
    local closest=config.aimFov
    local center=camera.ViewportSize/2
    local myRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil,nil end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={player.Character,camera}
    for _,target in ipairs(Players:GetPlayers()) do
        if target~=player and not (config.aimTeamCheck and teammate(target)) then
            local character=target.Character
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            local part=character and (config.aimBody and
                (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart"))
                or character:FindFirstChild("Head"))
            if part and part:IsA("BasePart") and humanoid and humanoid.Health>0 and (part.Position-myRoot.Position).Magnitude<=config.maxDistance then
                local point,onScreen=camera:WorldToViewportPoint(part.Position)
                if onScreen and point.Z>0 then
                    local delta=(Vector2.new(point.X,point.Y)-center).Magnitude
                    if delta<closest then
                        local hit=nil
                        if config.aimVisible then hit=workspace:Raycast(camera.CFrame.Position,part.Position-camera.CFrame.Position,params) end
                        if not hit or hit.Instance:IsDescendantOf(character) then best=target; bestPart=part; closest=delta end
                    end
                end
            end
        end
    end
    return best,bestPart
end
local recoilCount=0
local wasNoRecoil=false
local cameraOriginals={}
local alerted={}
local function restoreFov()
    for camera,original in pairs(cameraOriginals) do
        if camera.Parent then camera.FieldOfView=original end
        cameraOriginals[camera]=nil
    end
end
local function checkModerators()
    if not config.modAlerts then return end
    local names={}
    for value in config.modNames:gmatch("[^,]+") do names[value:match("^%s*(.-)%s*$"):lower()]=true end
    for _,target in ipairs(Players:GetPlayers()) do
        if target~=player and (names[target.Name:lower()] or names[tostring(target.UserId)]) and not alerted[target.UserId] then
            alerted[target.UserId]=true
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{
                Title="Direct Lite / moderator watchlist",Text=target.Name.." is in this server",Duration=10}) end)
            local toast=make("Frame",gui,{Position=UDim2.new(0.5,-180,0,20),Size=UDim2.fromOffset(360,52),
                BackgroundColor3=Color3.fromRGB(110,33,50),BorderSizePixel=0,ZIndex=30})
            round(toast,8)
            local message=text(toast,"WATCHLIST: "..target.Name.." joined",UDim2.fromOffset(12,6),UDim2.new(1,-24,1,-12),nil,13)
            message.ZIndex=31
            task.delay(10,function() if toast.Parent then toast:Destroy() end end)
        end
    end
end
connect(Players.PlayerRemoving,function(target) alerted[target.UserId]=nil end)
local bindName="DirectLiteCombat"
local function updateCombat(dt)
    if not alive then return end
    local camera=workspace.CurrentCamera
    if not camera then return end
    if config.fovOverride then
        if not cameraOriginals[camera] then cameraOriginals[camera]=camera.FieldOfView end
        camera.FieldOfView=config.cameraFov
    elseif next(cameraOriginals) then restoreFov() end
    if config.climb and not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.W) and UIS:IsKeyDown(Enum.KeyCode.Space) then
        local character=player.Character
        local root=rootPart(character)
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health>0 then
            local params=RaycastParams.new()
            params.FilterType=Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances={character,camera}
            local wall=workspace:Raycast(root.Position,root.CFrame.LookVector*3.5,params)
            if wall and math.abs(wall.Normal.Y)<0.35 then
                local velocity=root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity=Vector3.new(velocity.X,config.climbSpeed,velocity.Z)
            end
        end
    end
    recoilTimer=recoilTimer+dt
    if config.noRecoil then
        if not wasNoRecoil or recoilTimer>=0.5 then recoilTimer=0; recoilCount=applyRecoil() end
    elseif wasNoRecoil then restoreRecoil(); recoilCount=0 end
    wasNoRecoil=config.noRecoil
    aimCircleFrame.Position=UDim2.fromOffset(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    aimCircleFrame.Size=UDim2.fromOffset(config.aimFov*2,config.aimFov*2)
    aimCircleFrame.Visible=config.aimCircle and (config.aimbot or config.silentAim)
    local recoilText=config.noRecoil and ("Recoil: "..recoilCount.." ammo types updated") or "Recoil: off"
    local active=(config.aimbot or config.silentAim) and not UIS:GetFocusedTextBox()
        and (not config.aimHold or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    if not active then
        releaseViewmodel()
        combatStatus.Text=recoilText.."\n"..((config.aimbot or config.silentAim) and "Hold right mouse to aim" or "Aim: off")
        return
    end
    local target,part=aimTarget(camera)
    if not part then releaseViewmodel(); combatStatus.Text=recoilText.."\nNo eligible target inside FOV"; return end
    if config.silentAim then
        local model=camera:FindFirstChild("ViewModel")
        local root=nil
        if model and config.perfectSilent then
            local item=model:FindFirstChild("Item")
            local points=item and item:FindFirstChild("AttachmentPoints")
            root=points and points:FindFirstChild("Extra")
        elseif model then root=model:FindFirstChild("HumanoidRootPart") end
        if not root or not root:IsA("BasePart") then
            releaseViewmodel()
            combatStatus.Text=recoilText.."\nSilent aim: expected viewmodel part is unavailable"
            return
        end
        if viewPart~=root then releaseViewmodel(); viewPart=root; viewOffset=camera.CFrame:ToObjectSpace(root.CFrame) end
        if math.random()*100<config.silentChance then
            local offset=config.perfectSilent and 0.15 or 1.75
            local position=part.Position-Vector3.new(0,offset,0)
            if (root.Position-position).Magnitude>0.001 then root.CFrame=CFrame.lookAt(root.Position,position) end
        else
            releaseViewmodel()
        end
        combatStatus.Text=recoilText.."\nSilent aim: "..target.DisplayName
    else
        releaseViewmodel()
        local position=camera.CFrame.Position
        if (position-part.Position).Magnitude>0.001 then
            local alpha=config.aimSmooth<=1 and 1 or 1-(1-1/config.aimSmooth)^(dt*60)
            camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(position,part.Position),alpha)
        end
        combatStatus.Text=recoilText.."\nCamera aim: "..target.DisplayName
    end
end
RunService:BindToRenderStep(bindName,Enum.RenderPriority.Camera.Value+1,updateCombat)
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
    RunService:UnbindFromRenderStep(bindName)
    restoreRecoil()
    restoreFov()
    releaseViewmodel()
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
local timer,previewTimer,rigTimer=0,0,3
connect(RunService.RenderStepped,function(dt)
    if not alive then return end
    local camera=workspace.CurrentCamera
    if not camera then return end
    scale.Scale=math.max(0.1,math.min(config.menuScale/100,(camera.ViewportSize.X-24)/980,(camera.ViewportSize.Y-24)/620))
    local radarSize=math.min(config.radarSize,math.max(80,math.min(camera.ViewportSize.X,camera.ViewportSize.Y)-24))
    radar.Size=UDim2.fromOffset(radarSize,radarSize)
    radarTitle.Text=config.radarRotate and "THREAT RADAR / CAMERA UP" or "THREAT RADAR / NORTH UP"
    if not radarDragging then
        local pos=radar.AbsolutePosition
        local x=math.clamp(pos.X,0,math.max(0,camera.ViewportSize.X-radarSize))
        local y=math.clamp(pos.Y,0,math.max(0,camera.ViewportSize.Y-radarSize))
        radar.Position=UDim2.fromOffset(x,y)
    end
    radar.Visible=config.radar
    local me=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for target,m in pairs(markers) do
        local character=entityCharacter(target)
        local root=rootPart(character)
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local distance=root and me and (root.Position-me.Position).Magnitude or math.huge
        local valid=root and humanoid and humanoid.Health>0 and distance<=config.maxDistance
        m.frame.Visible=false; m.dot.Visible=false; m.facing.Visible=false
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
                    m.box.Thickness=config.lineThickness
                    m.label.Visible=config.names or config.weaponLabels
                    m.label.TextSize=config.labelSize
                    m.label.Size=UDim2.new(1,100,0,config.labelSize*2+6)
                    m.label.Position=UDim2.new(0,-50,0,-config.labelSize*2-8)
                    m.label.Text=(config.names and entityName(target).." / "..math.floor(distance).." studs" or "")
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
                local radius=radarSize/2-30
                local forward=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
                if forward.Magnitude<0.001 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
                local right=Vector3.new(-forward.Z,0,forward.X)
                local function project(vector)
                    if config.radarRotate then return Vector2.new(vector:Dot(right),-vector:Dot(forward))*(radius/config.radarRange) end
                    return Vector2.new(vector.X,vector.Z)*(radius/config.radarRange)
                end
                local point=project(relative)
                if math.abs(point.X)<=radius and math.abs(point.Y)<=radius then
                    m.dot.Position=UDim2.fromOffset(radarSize/2+point.X-2,radarSize/2+point.Y-2)
                    m.dot.Visible=true
                    m.radarLabel.Visible=false
                    local head=character:FindFirstChild("Head") or root
                    local toward=me.Position-head.Position
                    local facing= toward.Magnitude>0.001 and head.CFrame.LookVector:Dot(toward.Unit)>=math.cos(math.rad(config.threatAngle))
                    local visible=false
                    if facing then
                        local params=RaycastParams.new()
                        params.FilterType=Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances={character,camera}
                        local hit=workspace:Raycast(head.Position,toward,params)
                        visible=not hit or hit.Instance:IsDescendantOf(player.Character)
                    end
                    local danger=facing and visible
                    m.dot.BackgroundColor3=danger and Color3.fromRGB(255,76,90) or cyan
                    if config.threatLines then
                        local start=Vector2.new(radarSize/2+point.X,radarSize/2+point.Y)
                        local finish=danger and Vector2.new(radarSize/2,radarSize/2) or start+project(head.CFrame.LookVector*math.min(config.radarRange*0.12,30))
                        finish=Vector2.new(math.clamp(finish.X,20,radarSize-20),math.clamp(finish.Y,25,radarSize-25))
                        m.facing.BackgroundColor3=danger and Color3.fromRGB(255,76,90) or Color3.fromRGB(67,111,143)
                        drawLine(m.facing,start,finish)
                    end
                end
            end
        end
    end
    timer=timer+dt; previewTimer=previewTimer+dt; rigTimer=rigTimer+dt
    if rigTimer>=3 then rigTimer=0; scanRigs() end
    if timer>=1 then
        timer=0
        updateInventory(); updateLoot(); checkModerators()
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

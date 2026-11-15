-- Direct Lite 0.9.1: profile-exclusive Arsenal fly and BedWars client hitbox controls.
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
local config = {esp=true, boxes=true, names=true, skeleton=false, chams=false,
    radar=true, loot=false, maxDistance=3000, radarRange=500,
    fullInventory=true, previewBox=true, previewTint=true, rotation=0,
    menuScale=100, radarSize=230, radarWeapons=false, weaponLabels=false, labelSize=11,
    aimbot=false, silentAim=false, noRecoil=false, aimHold=true, aimVisible=true,
    aimTeamCheck=false, aimBody=false, aimFov=120, aimSmooth=6, aimCircle=true,
    silentChance=100, perfectSilent=false, npcESP=true, threatLines=true,
    threatAngle=25, climb=false, climbSpeed=22, fovOverride=false, cameraFov=70,
    modAlerts=true, modNames="", radarRotate=true, lineThickness=2,
    healthBar=true, espRed=56, espGreen=191, espBlue=255,
    modGroup="3765739", modRoles="moderator,head moderator,admin,developer,lead developer",
    friendESP=false, corpseESP=false, minesESP=false, bossTracker=false,
    fastRun=false, runSpeed=24, infiniteJump=false, noVisorFlash=false, statsGui=false,
    zoom=false, zoomFov=35, alwaysDay=false, noFog=false, fullbright=false,
    lootContainers=false, lootCashRegister=true, lootFilingCabinet=true,
    lootFridge=true, lootGrenadeCrate=true, lootHiddenCache=true,
    radarAutoRange=true,radarNames=true,nameHealth=true,silentHeadLine=true,
    arsenalFly=false,arsenalFlySpeed=45,bedwarsHitboxes=false,bedwarsHitboxSize=6}
local cyan = Color3.fromRGB(56, 191, 255)
local muted = Color3.fromRGB(143, 159, 186)
local sectionTargets={}
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end
local function make(class, parent, props)
    parent=sectionTargets[parent] or parent
    local object = Instance.new(class)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local gui = make("ScreenGui", player:WaitForChild("PlayerGui"), {
    Name="DirectLite", ResetOnSpawn=false, IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=80})
local startupCancel
env.DirectLiteCleanup=function()
    alive=false
    if startupCancel then startupCancel() end
    for _,connection in ipairs(connections) do connection:Disconnect() end
    gui:Destroy()
    env.DirectLiteCleanup=nil
end
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
local loading=make("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(4,10,20),
    BackgroundTransparency=0.08,BorderSizePixel=0,ZIndex=100,Active=true})
local loadingTitle=text(loading,"DIRECT LITE",UDim2.new(0.5,-180,0.5,-65),UDim2.fromOffset(360,45),cyan,30)
loadingTitle.TextXAlignment=Enum.TextXAlignment.Center; loadingTitle.ZIndex=101
local loadingStatus=text(loading,"Initializing",UDim2.new(0.5,-200,0.5,-15),UDim2.fromOffset(400,26),muted,13)
loadingStatus.TextXAlignment=Enum.TextXAlignment.Center; loadingStatus.ZIndex=101
local loadingTrack=make("Frame",loading,{Position=UDim2.new(0.5,-160,0.5,28),Size=UDim2.fromOffset(320,5),
    BackgroundColor3=Color3.fromRGB(32,48,69),BorderSizePixel=0,ZIndex=101})
round(loadingTrack,3)
local loadingFill=make("Frame",loadingTrack,{Size=UDim2.fromScale(0.05,1),BackgroundColor3=cyan,BorderSizePixel=0,ZIndex=102})
round(loadingFill,3)
local function loadingPhase(fraction,label)
    loadingFill.Size=UDim2.fromScale(fraction,1)
    loadingStatus.Text=label
    task.wait()
end
local selectedProfile,isDelta,settingsFile,enforceProfile
do
    local elapsed=0
    while elapsed<3 do
        if not alive then return end
        local delta=task.wait(0.05)
        elapsed=elapsed+(type(delta)=="number" and delta>0 and delta or 0.05)
        loadingFill.Size=UDim2.fromScale(math.min(1,elapsed/3),1)
        loadingStatus.Text="Welcome / choose your game next"
    end
end
do
local profiles={"Project Delta","Rivals","Arsenal","Operation 1","BedWars","Phantom Forces"}
local profileChoice=make("BindableEvent",nil,{})
startupCancel=function() profileChoice:Fire("__cancel") end
local profilePicker=make("Frame",loading,{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
    Size=UDim2.fromOffset(580,350),BackgroundColor3=Color3.fromRGB(8,20,37),BorderSizePixel=0,ZIndex=103})
round(profilePicker,12)
make("UIStroke",profilePicker,{Color=cyan,Transparency=0.3})
local pickerScale=make("UIScale",profilePicker,{})
local viewportSize=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
if viewportSize then pickerScale.Scale=math.min(1,(viewportSize.X-30)/580,(viewportSize.Y-30)/350) end
local pickerTitle=text(profilePicker,"DIRECT LITE / CHOOSE YOUR GAME",UDim2.fromOffset(20,16),UDim2.new(1,-40,0,34),cyan,19)
pickerTitle.ZIndex=104
local cancelPicker=button(profilePicker,"X",UDim2.new(1,-43,0,12),UDim2.fromOffset(30,27))
cancelPicker.ZIndex=105
connect(cancelPicker.Activated,function() if env.DirectLiteCleanup then env.DirectLiteCleanup() end end)
local pickerHint=text(profilePicker,"Choose a game to open its available tools and saved settings.",UDim2.fromOffset(20,53),UDim2.new(1,-40,0,32),muted,11)
pickerHint.ZIndex=104
local choiceSent=false
for i,name in ipairs(profiles) do
    local column=(i-1)%2
    local line=math.floor((i-1)/2)
    local b=button(profilePicker,name,UDim2.fromOffset(20+column*275,100+line*76),UDim2.fromOffset(265,62))
    b.ZIndex=104
    local sub=text(b,name=="Project Delta" and "Current integrated tools" or name=="Arsenal" and "Fly + common controls / live test needed" or name=="BedWars" and "Client hitboxes / aura module not installed" or "Shared controls / specific module not installed",UDim2.fromOffset(8,37),UDim2.new(1,-16,0,17),muted,9)
    sub.ZIndex=105
    connect(b.Activated,function() if not choiceSent then choiceSent=true; profileChoice:Fire(name) end end)
end
loadingTitle.Visible=false; loadingStatus.Visible=false; loadingTrack.Visible=false
selectedProfile=profileChoice.Event:Wait()
profileChoice:Destroy(); profilePicker:Destroy()
startupCancel=nil
if not alive or selectedProfile=="__cancel" then return end
loadingTitle.Visible=true; loadingStatus.Visible=true; loadingTrack.Visible=true
isDelta=selectedProfile=="Project Delta"
settingsFile="DirectLite."..selectedProfile:gsub("[^%w]","")..".settings.json"
enforceProfile=function()
    if selectedProfile~="Arsenal" then config.arsenalFly=false end
    if selectedProfile~="BedWars" then config.bedwarsHitboxes=false end
    if isDelta then return end
    config.silentAim=false; config.noRecoil=false; config.loot=false; config.lootContainers=false
    config.corpseESP=false; config.minesESP=false; config.bossTracker=false; config.noVisorFlash=false
end
if not isDelta then config.modGroup=""; config.modRoles="owner,admin,administrator,moderator,staff"; config.npcESP=false end
enforceProfile()
loadingPhase(0.1,"Opening "..selectedProfile.." settings")
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
text(top,"0.9.1 / "..selectedProfile,UDim2.fromOffset(183,6),UDim2.fromOffset(340,40),muted,11)
local close = button(top,"Unload",UDim2.new(1,-87,0,13),UDim2.fromOffset(72,28))
local reopen = button(gui,"DL",UDim2.fromOffset(12,80),UDim2.fromOffset(44,36))
reopen.ZIndex=20
connect(reopen.Activated,function() window.Visible = not window.Visible end)
local sidebar=make("Frame",window,{Position=UDim2.fromOffset(0,60),Size=UDim2.new(0,155,1,-60),
    BackgroundColor3=Color3.fromRGB(11,21,37),BorderSizePixel=0})
text(sidebar,"WORKSPACE",UDim2.fromOffset(18,16),UDim2.fromOffset(120,25),muted,10)
text(sidebar,"DIRECT LITE / 0.9.1",UDim2.new(0,12,1,-25),UDim2.fromOffset(131,20),muted,9)
local sceneStatus=text(sidebar,"Checking scene...",UDim2.fromOffset(12,478),UDim2.fromOffset(131,48),muted,10)
sceneStatus.TextWrapped=true
local pageTitle=text(window,"Aim",UDim2.fromOffset(175,65),UDim2.fromOffset(650,30),nil,21)
local content = make("Frame",window,{Position=UDim2.fromOffset(175,108),
    Size=UDim2.fromOffset(787,488),BackgroundTransparency=1})
local pages = {}
local columns,sectionCounts={},{}
local preview
local function page(name)
    local p=make("ScrollingFrame",content,{Name=name,Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
        ScrollBarImageColor3=cyan,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false})
    make("UIListLayout",p,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder,
        FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Top})
    make("UIPadding",p,{PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,12)})
    pages[name]=p
    columns[p]={}
    sectionCounts[p]=0
    for i=1,2 do
        local column=make("Frame",p,{Size=name=="Inventory" and UDim2.new(1,-8,0,0) or UDim2.new(0.5,-10,0,0),
            AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=i,Visible=name~="Inventory" or i==1})
        make("UIListLayout",column,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
        columns[p][i]=column
    end
    return p
end
local visuals, inventory, settings = page("Visuals"),page("Inventory"),page("Settings")
local combat=page("Combat")
local movement=page("Movement")
local radarPage=page("Radar")
local weapons=page("Weapons")
local staff=page("Staff")
local lootPage=page("Loot")
local worldPage=page("World")
local home=page("Home")
local tabs={}
for i,name in ipairs({"Home","Combat","Visuals","Loot","Radar","Movement","Weapons","World","Inventory","Staff","Settings"}) do
    local display=({Combat="Aim",Visuals="ESP"})[name] or name
    local b=button(sidebar,display,UDim2.fromOffset(12,43+(i-1)*38),UDim2.fromOffset(131,32))
    if not isDelta and (name=="Loot" or name=="Weapons" or name=="Inventory") then b.Visible=false end
    tabs[name]=b
    connect(b.Activated,function()
        pageTitle.Text=display
        content.Size=UDim2.fromOffset(name=="Inventory" and 438 or 787,488)
        if preview then preview.Visible=name=="Inventory" end
        for key,p in pairs(pages) do
            p.Visible=key==name
            tabs[key].BackgroundColor3=key==name and Color3.fromRGB(24,67,103) or Color3.fromRGB(24,38,61)
        end
    end)
end
home.Visible=true
pageTitle.Text="Direct Lite / control room"
tabs.Home.BackgroundColor3=Color3.fromRGB(24,67,103)
local order=0
local refreshControls={}
local function row(parent,height)
    order=order+1
    return make("Frame",parent,{Size=UDim2.new(1,0,0,height or 38),
        BackgroundColor3=Color3.fromRGB(15,26,44),BorderSizePixel=0,LayoutOrder=order})
end
local function heading(parent,label)
    sectionCounts[parent]=sectionCounts[parent]+1
    local index=parent==inventory and 1 or (sectionCounts[parent]-1)%2+1
    local card=make("Frame",columns[parent][index],{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=Color3.fromRGB(11,28,46),BorderSizePixel=0,LayoutOrder=sectionCounts[parent]})
    round(card,9)
    make("UIStroke",card,{Color=Color3.fromRGB(39,75,106),Transparency=0.15})
    make("UIPadding",card,{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)})
    make("UIListLayout",card,{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
    local title=text(card,label,UDim2.new(),UDim2.new(1,0,0,30),cyan,13)
    title.LayoutOrder=-10000
    sectionTargets[parent]=card
end
local function toggle(parent,label,key)
    local r=row(parent,42)
    if not isDelta and (key=="silentAim" or key=="silentHeadLine" or key=="perfectSilent" or key=="corpseESP" or key=="minesESP" or key=="bossTracker" or key=="noVisorFlash") then r.Visible=false end
    round(r,6)
    local labelText=text(r,label,UDim2.fromOffset(8,0),UDim2.new(1,-80,1,0),nil,12)
    labelText.TextWrapped=true
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
    connect(b.Activated,function()
        config[key]=not config[key]
        for _,update in ipairs(refreshControls) do update() end
    end)
end
local function slider(parent,label,key,low,high)
    local r=row(parent,58)
    if not isDelta and key=="silentChance" then r.Visible=false end
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
heading(home,"QUICK VISUALS")
toggle(home,"Player ESP","esp")
toggle(home,"Player names / distance","names")
toggle(home,"Health bars","healthBar")
toggle(home,"Skeleton ESP","skeleton")
toggle(home,"Radar","radar")
heading(home,"PROJECT TOOLS")
toggle(home,"Stats card","statsGui")
toggle(home,"Staff alerts","modAlerts")
local homeInfo=row(home,103)
local homeStatus=text(homeInfo,"Checking loaded players...",UDim2.fromOffset(8,5),UDim2.new(1,-16,1,-10),muted,11)
homeStatus.TextWrapped=true
homeStatus.TextYAlignment=Enum.TextYAlignment.Top
heading(home,"WORLD + CAMERA")
toggle(home,"Fullbright","fullbright")
toggle(home,"No fog","noFog")
toggle(home,"Always day","alwaysDay")
toggle(home,"Zoom","zoom")
heading(home,isDelta and "HOW TO INSPECT" or "PROFILE STATUS")
local inspectorInfo=row(home,118)
local inspectorText=text(inspectorInfo,"Hold I while looking near a player to inspect their items. Release I to close.\nHover a tile for its name.\nRight Shift: show / hide menu.\nScene status shows actual loaded targets.",UDim2.fromOffset(8,5),UDim2.new(1,-16,1,-10),muted,11)
inspectorText.TextWrapped=true
inspectorText.TextYAlignment=Enum.TextYAlignment.Top
if not isDelta then inspectorText.Text=selectedProfile=="Arsenal" and "Arsenal profile: Fly controls are in Movement. Common visuals and camera controls are available. Live-game compatibility is unverified. Separate saved settings." or selectedProfile=="BedWars" and "BedWars profile: client hitbox controls are in Aim. Server-side hit registration is unverified. Hit aura is not installed. Separate saved settings." or "Shared player visuals, radar, camera and world controls. Dedicated features for "..selectedProfile.." are not installed. Project Delta-only controls are disabled. Settings save separately for this profile." end
heading(combat,"AIM / SILENT AIM")
toggle(combat,"Aimbot (camera aim)","aimbot")
toggle(combat,"Silent aim (takes priority over camera aim)","silentAim")
toggle(combat,"Silent target line to head","silentHeadLine")
toggle(combat,"Hold right mouse to activate","aimHold")
heading(combat,"TARGET FILTERS")
toggle(combat,"Visibility check","aimVisible")
toggle(combat,"Skip teammates / same clan","aimTeamCheck")
toggle(combat,"Aim at torso instead of head","aimBody")
toggle(combat,"Show FOV circle","aimCircle")
heading(combat,"AIM TUNING")
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
toggle(visuals,"Friend ESP (green)","friendESP")
toggle(visuals,"Include NPCs / test dummies", "npcESP")
toggle(visuals,"Corpse ESP","corpseESP")
toggle(visuals,"Mines ESP","minesESP")
toggle(visuals,"Boss tracker","bossTracker")
toggle(visuals,"Bounding boxes", "boxes")
toggle(visuals,"Health bars", "healthBar")
toggle(visuals,"Player name / distance", "names")
toggle(visuals,"Health number in name tags","nameHealth")
toggle(visuals,"Equipped-gun labels", "weaponLabels")
slider(visuals,"Label text size", "labelSize",10,20)
toggle(visuals,"Skeleton lines", "skeleton")
slider(visuals,"Line thickness (pixels)","lineThickness",1,4)
heading(visuals,"ESP COLOR")
slider(visuals,"Red","espRed",0,255)
slider(visuals,"Green","espGreen",0,255)
slider(visuals,"Blue","espBlue",0,255)
toggle(visuals,"Cyan character highlight", "chams")
slider(visuals,"Maximum distance (studs)","maxDistance",100,3000)
heading(radarPage,"TOP-DOWN RADAR")
toggle(radarPage,"Player radar", "radar")
toggle(radarPage,"Radar follows camera rotation","radarRotate")
toggle(radarPage,"Automatically fit loaded targets","radarAutoRange")
toggle(radarPage,"Names beside radar markers","radarNames")
slider(radarPage,"Radar range (studs)","radarRange",50,1000)
slider(radarPage,"Radar size (pixels)","radarSize",120,500)
heading(radarPage,"SIGHT ESTIMATES")
toggle(radarPage,"Facing / clear sight red lines","threatLines")
slider(radarPage,"Facing angle tolerance (degrees)","threatAngle",5,60)
heading(visuals,"DROPPED ITEMS")
toggle(visuals,"Dropped-item labels", "loot")
heading(lootPage,"LOOT DETECTION")
toggle(lootPage,"Dropped-item ESP","loot")
toggle(lootPage,"Container ESP","lootContainers")
heading(lootPage,"CONTAINER FILTERS")
for _,name in ipairs({"CashRegister","FilingCabinet","Fridge","GrenadeCrate","HiddenCache"}) do
    toggle(lootPage,name,"loot"..name)
end
heading(worldPage,"ENVIRONMENT")
toggle(worldPage,"Always day","alwaysDay")
toggle(worldPage,"No fog","noFog")
toggle(worldPage,"Fullbright","fullbright")
heading(worldPage,"DISPLAY")
toggle(worldPage,"Stats card","statsGui")
toggle(worldPage,"Hide known visor / flash overlays","noVisorFlash")
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
if selectedProfile=="Arsenal" then
    heading(movement,"ARSENAL / FLY")
    toggle(movement,"Fly (WASD / Space up / Ctrl down)","arsenalFly")
    slider(movement,"Fly speed","arsenalFlySpeed",10,100)
elseif selectedProfile=="BedWars" then
    heading(combat,"BEDWARS / HITBOXES")
    toggle(combat,"Client hitbox size override","bedwarsHitboxes")
    slider(combat,"Hitbox size (studs)","bedwarsHitboxSize",2,12)
    heading(combat,"BEDWARS / HIT AURA")
    local note=row(combat,80)
    local label=text(note,"Hit aura requires a compatible BedWars combat module. It is not installed; there is no active aura toggle.",UDim2.fromOffset(8,4),UDim2.new(1,-16,1,-8),muted,11)
    label.TextWrapped=true
end
heading(movement,"MOVEMENT")
toggle(movement,"Fast run","fastRun")
slider(movement,"Run speed","runSpeed",16,40)
toggle(movement,"Infinite jump (may be rejected by game)","infiniteJump")
heading(movement,"CAMERA")
toggle(movement,"Override camera FOV","fovOverride")
slider(movement,"Camera field of view (degrees)","cameraFov",40,110)
toggle(movement,"Zoom camera","zoom")
slider(movement,"Zoom field of view","zoomFov",15,60)
heading(staff,"KNOWN ACCOUNT WATCHLIST")
toggle(staff,"Enable staff alerts","modAlerts")
local modNames=make("TextBox",staff,{Size=UDim2.new(1,0,0,38),LayoutOrder=order+1,
    BackgroundColor3=Color3.fromRGB(21,35,55),BorderSizePixel=0,Text=config.modNames,
    PlaceholderText="Exact usernames or user IDs, comma separated",TextColor3=Color3.new(1,1,1),
    PlaceholderColor3=muted,Font=Enum.Font.Gotham,TextSize=11,ClearTextOnFocus=false})
order=order+1
round(modNames,6)
connect(modNames.FocusLost,function() config.modNames=modNames.Text end)
table.insert(refreshControls,function() modNames.Text=config.modNames end)
local modHint=row(staff,58)
local mh=text(modHint,"Exact account matches and public group-role evidence only. Hidden staff cannot be identified reliably.",UDim2.fromOffset(10,4),UDim2.new(1,-20,1,-8),muted,11)
mh.TextWrapped=true
heading(staff,"PUBLIC GROUP ROLES")
local groupInput=make("TextBox",staff,{Size=UDim2.new(1,0,0,36),LayoutOrder=order+1,
    Text=config.modGroup,PlaceholderText="Group ID (blank: experience creator group)",ClearTextOnFocus=false,
    Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.new(1,1,1),PlaceholderColor3=muted,
    BackgroundColor3=Color3.fromRGB(21,35,55),BorderSizePixel=0})
order=order+1
local rolesInput=make("TextBox",staff,{Size=UDim2.new(1,0,0,55),LayoutOrder=order+1,
    Text=config.modRoles,PlaceholderText="Exact public role names, comma separated",ClearTextOnFocus=false,
    TextWrapped=true,Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.new(1,1,1),PlaceholderColor3=muted,
    BackgroundColor3=Color3.fromRGB(21,35,55),BorderSizePixel=0})
order=order+1
connect(groupInput.FocusLost,function() config.modGroup=groupInput.Text end)
connect(rolesInput.FocusLost,function() config.modRoles=rolesInput.Text end)
table.insert(refreshControls,function() groupInput.Text=config.modGroup; rolesInput.Text=config.modRoles end)
local roleStatus=text(staff,"Waiting for public-role scan",UDim2.new(),UDim2.new(1,0,0,0),muted,11)
roleStatus.AutomaticSize=Enum.AutomaticSize.Y
roleStatus.TextWrapped=true
roleStatus.LayoutOrder=order+1
order=order+1
local scanStaff=button(staff,"Refresh public-role evidence",UDim2.new(),UDim2.new(1,0,0,32))
scanStaff.LayoutOrder=order+1
order=order+1
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
    local ok=pcall(function() writefile(settingsFile,HttpService:JSONEncode(config)) end)
    notice.Text=ok and "Settings saved." or "Could not save settings."
end)
connect(load.Activated,function()
    if type(readfile)~="function" then notice.Text="File loading is unavailable in this runtime."; return end
    local ok,data=pcall(function() return HttpService:JSONDecode(readfile(settingsFile)) end)
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
    config.espRed=math.clamp(config.espRed,0,255)
    config.espGreen=math.clamp(config.espGreen,0,255)
    config.espBlue=math.clamp(config.espBlue,0,255)
    config.runSpeed=math.clamp(config.runSpeed,16,40)
    config.zoomFov=math.clamp(config.zoomFov,15,60)
    config.arsenalFlySpeed=math.clamp(config.arsenalFlySpeed,10,100)
    config.bedwarsHitboxSize=math.clamp(config.bedwarsHitboxSize,2,12)
    enforceProfile()
    for _,refresh in ipairs(refreshControls) do refresh() end
    notice.Text="Settings loaded."
end)
-- Preview: a real character clone in a private WorldModel, not a screenshot.
preview=make("Frame",window,{Position=UDim2.fromOffset(635,108),Size=UDim2.fromOffset(327,488),
    BackgroundColor3=Color3.fromRGB(12,22,37),BorderSizePixel=0,Visible=false})
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
local rosterState={signature="",buttons={},dirty=false,manual=false}
for _,candidate in ipairs(Players:GetPlayers()) do if candidate~=player then selected=candidate; break end end
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
    return ""
end
local function distanceTo(character)
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local me=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return root and me and (root.Position-me.Position).Magnitude or nil
end
local function rebuildPreview()
    if not window.Visible or not preview.Visible then return end
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
    rosterState.manual=true
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
loadingPhase(0.55,"Preparing player selection and inventory")
local roster=row(inventory,150)
roster.LayoutOrder=5
local rosterTitle=text(roster,"SELECT A PLAYER",UDim2.fromOffset(8,1),UDim2.new(1,-16,0,24),cyan,10)
local rosterScroll=make("ScrollingFrame",roster,{Position=UDim2.fromOffset(8,27),Size=UDim2.new(1,-16,1,-35),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=cyan,
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
make("UIListLayout",rosterScroll,{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder})
connect(Players.PlayerAdded,function(target)
    if selected==player and not rosterState.manual then selected=target; rosterState.dirty=true; rebuildPreview() end
end)
local function rebuildRoster()
    local list=Players:GetPlayers()
    table.sort(list,function(a,b) if a==player then return false end; if b==player then return true end; return a.Name:lower()<b.Name:lower() end)
    local keys={}
    for _,target in ipairs(list) do table.insert(keys,tostring(target.UserId)) end
    local signature=table.concat(keys,",")
    if signature~=rosterState.signature then
        for _,object in ipairs(rosterState.buttons) do object:Destroy() end
        rosterState.buttons={}; rosterState.signature=signature
        for i,target in ipairs(list) do
            local b=button(rosterScroll,target.DisplayName.." (@"..target.Name..")"..(target==player and " / YOU" or ""),UDim2.new(),UDim2.new(1,-5,0,30))
            b.LayoutOrder=i; b.TextSize=11
            table.insert(rosterState.buttons,b)
            -- This connection belongs to its button, and is destroyed with it.
            b.Activated:Connect(function() selected=target; rosterState.manual=true; rosterState.dirty=true; rebuildPreview() end)
        end
    end
    for i,target in ipairs(list) do
        local b=rosterState.buttons[i]
        if b then b.BackgroundColor3=target==selected and Color3.fromRGB(15,93,141) or Color3.fromRGB(24,38,61) end
    end
    rosterTitle.Text="SELECT A PLAYER / "..math.max(0,#list-1).." OTHER PLAYERS"
end
-- Independent side panel remains available with the main menu hidden.
local inventoryPanel=make("Frame",gui,{AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-12,0.5,0),Size=UDim2.fromOffset(325,520),
    BackgroundColor3=Color3.fromRGB(8,19,34),BorderSizePixel=0,Visible=false,ZIndex=15})
round(inventoryPanel,10)
make("UIStroke",inventoryPanel,{Color=cyan,Transparency=0.35})
text(inventoryPanel,"PLAYER INVENTORY",UDim2.fromOffset(14,8),UDim2.new(1,-65,0,25),cyan,12)
local dismissInventory=button(inventoryPanel,"X",UDim2.new(1,-38,0,8),UDim2.fromOffset(27,25))
connect(dismissInventory.Activated,function() inventoryPanel.Visible=false end)
local sideName=text(inventoryPanel,"",UDim2.fromOffset(14,40),UDim2.new(1,-28,0,26),nil,13)
sideName.TextTruncate=Enum.TextTruncate.AtEnd
local sideValue=text(inventoryPanel,"VALUE: --",UDim2.new(1,-145,0,8),UDim2.fromOffset(98,25),Color3.fromRGB(245,211,90),10)
sideValue.TextXAlignment=Enum.TextXAlignment.Right
local sideStatus=text(inventoryPanel,"",UDim2.fromOffset(14,70),UDim2.new(1,-28,0,36),muted,10)
sideStatus.TextWrapped=true
local sideScroll=make("ScrollingFrame",inventoryPanel,{Position=UDim2.fromOffset(14,112),
    Size=UDim2.new(1,-28,1,-148),BackgroundTransparency=1,BorderSizePixel=0,
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=cyan})
local sideItems=text(sideScroll,"",UDim2.new(),UDim2.new(1,-10,0,0),Color3.fromRGB(210,226,245),12)
sideItems.AutomaticSize=Enum.AutomaticSize.Y
sideItems.TextWrapped=true
sideItems.TextYAlignment=Enum.TextYAlignment.Top
sideItems.Font=Enum.Font.Code
local tileState={entries={},fingerprint="",page=1}
local inspectState={held=false,target=nil,elapsed=0}
local tileContents=make("Frame",sideScroll,{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1})
make("UIListLayout",tileContents,{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder})
local tilePrev=button(inventoryPanel,"<",UDim2.new(0,14,1,-29),UDim2.fromOffset(28,23))
local tileNext=button(inventoryPanel,">",UDim2.new(1,-42,1,-29),UDim2.fromOffset(28,23))
local tilePage=text(inventoryPanel,"Hold I to inspect",UDim2.new(0,50,1,-29),UDim2.new(1,-100,0,23),muted,10)
tilePage.TextXAlignment=Enum.TextXAlignment.Center
local function tileIcon(entry)
    local library=RS:FindFirstChild("ItemsList")
    local template=library and library:FindFirstChild(entry.name)
    local properties=template and template:FindFirstChild("ItemProperties")
    local itemIcon=properties and properties:FindFirstChild("ItemIcon")
    if itemIcon and (itemIcon:IsA("ImageLabel") or itemIcon:IsA("ImageButton")) and itemIcon.Image~="" then return itemIcon.Image end
    local icon=entry.source:GetAttribute("Image") or entry.source:GetAttribute("Icon") or entry.source:GetAttribute("ImageId")
    if type(icon)=="number" then return "rbxassetid://"..icon end
    if type(icon)=="string" and icon~="" then return tonumber(icon) and "rbxassetid://"..icon or icon end
    if entry.source:IsA("Tool") then return entry.source.TextureId end
    return nil
end
local function renderTiles()
    tileState.quantityLabels={}
    for _,object in ipairs(tileContents:GetChildren()) do if not object:IsA("UIListLayout") then object:Destroy() end end
    local pages=math.max(1,math.ceil(#tileState.entries/48))
    tileState.page=math.clamp(tileState.page,1,pages)
    tilePage.Text="Hold I / page "..tileState.page.." of "..pages
    tilePrev.Visible=pages>1; tileNext.Visible=pages>1
    local frames={}
    for i,label in ipairs({"EQUIPPED / TOP LEVEL","BACKPACK & CONTAINERS"}) do
        local title=text(tileContents,label,UDim2.new(),UDim2.new(1,0,0,22),cyan,10)
        title.LayoutOrder=i*2-1
        local grid=make("Frame",tileContents,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1,LayoutOrder=i*2})
        make("UIGridLayout",grid,{CellSize=UDim2.fromOffset(61,76),CellPadding=UDim2.fromOffset(5,5),SortOrder=Enum.SortOrder.LayoutOrder})
        frames[i]=grid
    end
    for index=(tileState.page-1)*48+1,math.min(#tileState.entries,tileState.page*48) do
        local entry=tileState.entries[index]
        local tile=make("Frame",frames[entry.depth==0 and 1 or 2],{BackgroundColor3=Color3.fromRGB(18,29,46),BorderSizePixel=0,LayoutOrder=index})
        tile.Active=true
        round(tile,6)
        make("UIStroke",tile,{Color=Color3.fromRGB(42,60,82),Transparency=0.2})
        local icon=tileIcon(entry)
        if icon and icon~="" then
            make("ImageLabel",tile,{Position=UDim2.fromOffset(6,5),Size=UDim2.new(1,-12,0,43),BackgroundTransparency=1,Image=icon,ScaleType=Enum.ScaleType.Fit})
        else
            local library=RS:FindFirstChild("ItemsList")
            local model=library and library:FindFirstChild(entry.name)
            if model and not (model:IsA("Model") or model:IsA("BasePart")) then model=model:FindFirstChildWhichIsA("Model") or model:FindFirstChildWhichIsA("BasePart") end
            if model then
                local view=make("ViewportFrame",tile,{Position=UDim2.fromOffset(4,4),Size=UDim2.new(1,-8,0,43),BackgroundTransparency=1,Ambient=Color3.fromRGB(180,180,180)})
                local wm=make("WorldModel",view,{})
                local ok,clone=pcall(function() return model:Clone() end)
                if ok and clone then
                    if clone:IsA("BasePart") then clone.Anchored=true; clone.CanCollide=false end
                    for _,object in ipairs(clone:GetDescendants()) do
                        if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") or object:IsA("Sound") then object:Destroy()
                        elseif object:IsA("BasePart") then object.Anchored=true; object.CanCollide=false end
                    end
                    clone.Parent=wm
                    local cf,size
                    if clone:IsA("Model") then cf,size=clone:GetBoundingBox() else cf,size=clone.CFrame,clone.Size end
                    local camera=make("Camera",view,{FieldOfView=35})
                    camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(0,0,-math.max(size.X,size.Y,size.Z)*2.5-0.2),cf.Position)
                    view.CurrentCamera=camera
                end
            else
                local initial=text(tile,"?",UDim2.fromOffset(4,4),UDim2.new(1,-8,0,40),muted,19)
                initial.TextXAlignment=Enum.TextXAlignment.Center
            end
        end
        local label=text(tile,entry.name,UDim2.fromOffset(4,48),UDim2.new(1,-8,0,24),nil,9)
        label.TextWrapped=true; label.TextXAlignment=Enum.TextXAlignment.Center
        label.Visible=false
        tile.MouseEnter:Connect(function() label.Visible=true end)
        tile.MouseLeave:Connect(function() label.Visible=false end)
        local qty=text(tile,entry.amount and "x"..entry.amount or "",UDim2.new(0,2,0,1),UDim2.new(1,-4,0,13),cyan,9)
        qty.TextXAlignment=Enum.TextXAlignment.Right
        tileState.quantityLabels[index]=qty
    end
end
connect(tilePrev.Activated,function() tileState.page=tileState.page-1; renderTiles() end)
connect(tileNext.Activated,function() tileState.page=tileState.page+1; renderTiles() end)
local function syncSideInventory(fullText,fullStatus,entries)
    sideName.Text=selected and selected.DisplayName.." (@"..selected.Name..")" or "No player"
    sideStatus.Text=fullStatus or status.Text
    sideItems.Text=fullText or itemText.Text
    tileContents.Visible=entries~=nil and #entries>0
    sideItems.Visible=not tileContents.Visible
    if entries then
        local total,priced=0,#entries>0
        for _,entry in ipairs(entries) do
            local props=entry.source:FindFirstChild("ItemProperties")
            local value=entry.source:GetAttribute("Price") or entry.source:GetAttribute("Value")
                or props and (props:GetAttribute("Price") or props:GetAttribute("Value"))
            if type(value)=="number" then total=total+value*(tonumber(entry.amount) or 1) else priced=false end
        end
        sideValue.Text=priced and "VALUE: $"..math.floor(total) or "VALUE: --"
        local keys={tostring(selected and selected.UserId)}
        for _,entry in ipairs(entries) do table.insert(keys,entry.name..":"..entry.depth..":"..tostring(entry.slot)) end
        local fingerprint=table.concat(keys,"|")
        tileState.entries=entries
        if inventoryPanel.Visible and fingerprint~=tileState.fingerprint then
            tileState.fingerprint=fingerprint; tileState.page=1; renderTiles()
        elseif inventoryPanel.Visible then
            for index,label in pairs(tileState.quantityLabels or {}) do
                local entry=entries[index]
                if entry and label.Parent then label.Text=entry.amount and "x"..entry.amount or "" end
            end
        end
    end
end
local function updateInventory()
    if inspectState.held and not inspectState.target then
        sideName.Text="Point at another player"
        sideStatus.Text="Hold I near a player's character. Release to close."
        tileContents.Visible=false; sideItems.Visible=false; sideValue.Text="VALUE: --"
        return
    end
    if not selected or selected.Parent~=Players then
        selected=player
        for _,candidate in ipairs(Players:GetPlayers()) do if candidate~=player then selected=candidate; break end end
        rebuildPreview()
    end
    rebuildRoster()
    selectedLabel.Text=selected.DisplayName.." (@"..selected.Name..")"
    local root=inventoryRoot(selected)
    if not root then
        local tools,entries={},{}
        for _,container in ipairs({selected.Character or false,selected:FindFirstChild("Backpack") or false}) do
            if container then for _,tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then table.insert(tools,tool.Name); table.insert(entries,{name=tool.Name,depth=0,source=tool}) end
            end end
        end
        status.Text="Delta inventory not available. Showing replicated Tools only."
        itemText.Text=#tools>0 and table.concat(tools,"\n") or "No inventory data is replicated for this player."
        syncSideInventory(nil,nil,entries)
        return
    end
    local lines, fullLines, entries, count, visited={},{},{},0,{}
    local filter=search.Text:lower()
    local function walk(container,depth)
        if depth>12 or visited[container] or count>=2000 then return end
        visited[container]=true
        local children=container:GetChildren()
        table.sort(children,function(a,b) return a.Name:lower()<b.Name:lower() end)
        for _,item in ipairs(children) do
            if count>=2000 then return end
            local slot=item:GetAttribute("Slot")
            local amount=item:GetAttribute("Amount") or item:GetAttribute("Quantity")
            local suffix=(amount and " x"..tostring(amount) or "")..(slot and " ["..tostring(slot).."]" or "")
            local line=string.rep("  ",depth)..item.Name..suffix
            table.insert(fullLines,line)
            table.insert(entries,{name=item.Name,amount=amount,depth=depth,slot=slot,source=item})
            count=count+1
            if (config.fullInventory or depth==0) and (filter=="" or (item.Name..suffix):lower():find(filter,1,true)) then
                table.insert(lines,line)
            end
            local nested=item:FindFirstChild("Inventory")
            if nested then walk(nested,depth+1) end
            do
                for _,name in ipairs({"Attachments","LoadedAmmo"}) do
                    local extra=item:FindFirstChild(name)
                    if extra then
                        local heading=string.rep("  ",depth+1).."["..name.."]"
                        table.insert(fullLines,heading)
                        if config.fullInventory and filter=="" then table.insert(lines,heading) end
                        walk(extra,depth+2)
                    end
                end
            end
        end
    end
    walk(root,0)
    status.Text=tostring(count).." entries / replicated data only"..(count>=2000 and " / truncated at 2000" or "")
    itemText.Text=#lines>0 and table.concat(lines,"\n") or "No matching items."
    syncSideInventory(#fullLines>0 and table.concat(fullLines,"\n") or "No replicated items.",status.Text,entries)
end
local openInventory=button(inventory,"Hold I near a player / release to close",UDim2.new(),UDim2.new(1,0,0,32))
openInventory.LayoutOrder=9999
connect(openInventory.Activated,function() updateInventory() end)
local function refreshHeldInspector()
    local camera=workspace.CurrentCamera
    local best,closest=nil,180
    if camera then
    for _,target in ipairs(Players:GetPlayers()) do
        local character=target.Character
        local root=character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
        if target~=player and root then
            local p,visible=camera:WorldToViewportPoint(root.Position)
            if visible and p.Z>0 then
                local d=(Vector2.new(p.X,p.Y)-camera.ViewportSize/2).Magnitude
                if d<closest then closest=d; best=target end
            end
        end
    end
    end
    local changed=inspectState.target~=best
    inspectState.target=best
    if best and selected~=best then selected=best; rosterState.manual=true; rebuildPreview() end
    inventoryPanel.Visible=true
    if changed or not best or tileState.fingerprint=="" then updateInventory() end
end
connect(UIS.InputBegan,function(input)
    if not isDelta then return end
    if UIS:GetFocusedTextBox() or input.KeyCode~=Enum.KeyCode.I then return end
    inspectState.held=true; inspectState.elapsed=0
    refreshHeldInspector()
end)
connect(UIS.InputEnded,function(input)
    if input.KeyCode==Enum.KeyCode.I then inspectState.held=false; inspectState.target=nil; inventoryPanel.Visible=false end
end)
connect(UIS.WindowFocusReleased,function()
    inspectState.held=false; inspectState.target=nil; inventoryPanel.Visible=false
end)
-- World overlays use Roblox UI and Highlights; there is no Drawing dependency.
local overlay=make("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
local radar=make("Frame",gui,{Position=UDim2.fromOffset(16,132),Size=UDim2.fromOffset(230,230),
    BackgroundColor3=Color3.fromRGB(8,19,34),BackgroundTransparency=0.04,
    BorderSizePixel=0,Visible=false})
round(radar,8)
radar.Active=true
make("UIStroke",radar,{Color=cyan,Transparency=0.3})
local radarTitle=text(radar,"THREAT RADAR",UDim2.fromOffset(10,5),UDim2.new(1,-20,0,16),cyan,10)
local radarFooter=text(radar,"",UDim2.new(0,9,1,-34),UDim2.new(1,-18,0,30),muted,9)
local radarPlot=make("Frame",radar,{Position=UDim2.fromOffset(10,29),Size=UDim2.new(1,-20,1,-68),
    BackgroundColor3=Color3.fromRGB(12,28,46),BorderSizePixel=0,ClipsDescendants=true})
round(radarPlot,5)
for i=1,3 do
    make("Frame",radarPlot,{Position=UDim2.fromScale(i/4,0),Size=UDim2.new(0,1,1,0),
        BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(36,58,78)})
    make("Frame",radarPlot,{Position=UDim2.fromScale(0,i/4),Size=UDim2.new(1,0,0,1),
        BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(36,58,78)})
end
for _,fraction in ipairs({0.25,0.5,0.75}) do
    local ring=make("Frame",radarPlot,{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromScale(fraction,fraction),BackgroundTransparency=1})
    make("UICorner",ring,{CornerRadius=UDim.new(0.5,0)})
    make("UIStroke",ring,{Color=Color3.fromRGB(31,83,121),Thickness=1})
end
text(radarPlot,"^",UDim2.new(0.5,-7,0.5,-8),UDim2.fromOffset(14,16),Color3.new(1,1,1),16)
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
    label.BackgroundColor3=Color3.fromRGB(6,17,29)
    label.BackgroundTransparency=0.22
    round(label,4)
    local health=make("Frame",frame,{Position=UDim2.fromOffset(-7,0),Size=UDim2.new(0,4,1,0),
        BackgroundColor3=Color3.fromRGB(18,22,29),BorderSizePixel=0,Visible=false})
    local healthFill=make("Frame",health,{AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),
        Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(60,230,100),BorderSizePixel=0})
    local dot=make("Frame",radarPlot,{Size=UDim2.fromOffset(6,6),BackgroundColor3=cyan,BorderSizePixel=0,Visible=false})
    round(dot,3)
    local radarLabel=text(dot,"",UDim2.fromOffset(8,-5),UDim2.fromOffset(150,16),cyan,10)
    radarLabel.TextTruncate=Enum.TextTruncate.AtEnd
    local facing=make("Frame",radarPlot,{AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,
        BackgroundColor3=Color3.fromRGB(255,76,90),Visible=false})
    markers[target]={frame=frame,box=box,label=label,dot=dot,radarLabel=radarLabel,facing=facing,
        health=health,healthFill=healthFill,lines={}}
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
local sceneIndex={humanoids={},special={}}
local function indexObject(object,remove)
    if object:IsA("Humanoid") then
        sceneIndex.humanoids[object]=not remove or nil
        if remove and object.Parent and not Players:GetPlayerFromCharacter(object.Parent) then removeMarker(object.Parent) end
    end
    if remove then sceneIndex.special[object]=nil; return end
    if object.Name=="PMN2" or object.Name=="MON50" or object.Name=="Anton" or object.Name=="Dozer"
        or object.Name=="Whisper" or object.Name=="Death" or object.Name=="MI24V" then
        sceneIndex.special[object]=not remove or nil
    end
end
connect(workspace.DescendantAdded,function(object) indexObject(object,false) end)
connect(workspace.DescendantRemoving,function(object) indexObject(object,true) end)
task.spawn(function()
    for i,object in ipairs(workspace:GetDescendants()) do
        if not alive then return end
        indexObject(object,false)
        if i%200==0 then task.wait() end
    end
end)
local function scanRigs()
    local remove={}
    for target in pairs(markers) do
        if not target:IsA("Player") and (not config.npcESP or not target:IsDescendantOf(workspace)) then table.insert(remove,target) end
    end
    for _,target in ipairs(remove) do removeMarker(target) end
    if not config.npcESP then return end
    local count=0
    for object in pairs(sceneIndex.humanoids) do
        if object:IsA("Humanoid") and object.Parent and object.Parent:IsA("Model") then
            local model=object.Parent
            if model~=player.Character and not Players:GetPlayerFromCharacter(model)
                and not (workspace.CurrentCamera and model:IsDescendantOf(workspace.CurrentCamera)) then
                count=count+1
                if not markers[model] then newMarker(model) end
                if count>=100 then break end
            end
        elseif not object.Parent then sceneIndex.humanoids[object]=nil end
    end
end
loadingPhase(0.8,"Connecting overlays, radar and scene checks")
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
    if not config.skeleton or not clonedCharacter or not window.Visible or not preview.Visible then return end
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
local silentLine=make("Frame",overlay,{AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=cyan,BorderSizePixel=0,Visible=false})
local silentHeadDot=make("Frame",overlay,{AnchorPoint=Vector2.new(0.5,0.5),
    Size=UDim2.fromOffset(6,6),BackgroundColor3=cyan,BorderSizePixel=0,Visible=false})
round(silentHeadDot,3)
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
        local world=workspace.CurrentCamera.CFrame*viewOffset
        if viewPart:IsA("Attachment") and viewPart.Parent:IsA("BasePart") then
            viewPart.CFrame=viewPart.Parent.CFrame:ToObjectSpace(world)
        elseif viewPart:IsA("BasePart") then viewPart.CFrame=world end
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
local extraState={lighting={},atmospheres={},walk={},effects={},markers={},friends={},started=os.clock()}
local footer=text(window,"DIRECT LITE / Right Shift to hide",UDim2.fromOffset(175,597),UDim2.new(1,-195,0,18),muted,10)
local statsCard=make("Frame",gui,{Position=UDim2.new(0,16,1,-110),Size=UDim2.fromOffset(282,88),
    BackgroundColor3=Color3.fromRGB(9,18,31),BorderSizePixel=0,Visible=false})
round(statsCard,10)
make("UIStroke",statsCard,{Color=cyan,Thickness=1})
local portrait=make("ImageLabel",statsCard,{Position=UDim2.fromOffset(10,13),Size=UDim2.fromOffset(58,58),
    BackgroundColor3=Color3.fromRGB(21,35,50),BorderSizePixel=0,
    Image="rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=100&h=100"})
round(portrait,8)
local statsText=text(statsCard,"",UDim2.fromOffset(78,8),UDim2.new(1,-86,1,-16),cyan,11)
statsText.TextYAlignment=Enum.TextYAlignment.Top
local function restoreExtra()
    local lighting=game:GetService("Lighting")
    for key,value in pairs(extraState.lighting) do lighting[key]=value end
    extraState.lighting={}
    for atmosphere,values in pairs(extraState.atmospheres) do
        if atmosphere.Parent then atmosphere.Density=values[1]; atmosphere.Haze=values[2] end
    end
    extraState.atmospheres={}
    for humanoid,speed in pairs(extraState.walk) do if humanoid.Parent then humanoid.WalkSpeed=speed end end
    extraState.walk={}
    for object,visible in pairs(extraState.effects) do if object.Parent then object.Visible=visible end end
    extraState.effects={}
end
local function updateExtra()
    local active=0
    for _,key in ipairs({"esp","friendESP","corpseESP","minesESP","bossTracker","radar","loot","lootContainers","aimbot","silentAim","noRecoil","climb","fastRun","infiniteJump","noVisorFlash","statsGui","zoom","alwaysDay","noFog","fullbright"}) do
        if config[key] then active=active+1 end
    end
    footer.Text="DIRECT LITE / "..active.." features enabled / Right Shift to hide"
    local lighting=game:GetService("Lighting")
    local values={ClockTime=config.alwaysDay and 14 or nil,
        FogStart=config.noFog and 100000 or nil,FogEnd=config.noFog and 1000000 or nil,
        Brightness=config.fullbright and 3 or nil,
        Ambient=config.fullbright and Color3.fromRGB(180,180,180) or nil,
        OutdoorAmbient=config.fullbright and Color3.fromRGB(180,180,180) or nil}
    for _,key in ipairs({"ClockTime","FogStart","FogEnd","Brightness","Ambient","OutdoorAmbient"}) do
        if values[key]~=nil then
            if extraState.lighting[key]==nil then extraState.lighting[key]=lighting[key] end
            lighting[key]=values[key]
        elseif extraState.lighting[key]~=nil then lighting[key]=extraState.lighting[key]; extraState.lighting[key]=nil end
    end
    if config.noFog then
        for _,object in ipairs(lighting:GetChildren()) do if object:IsA("Atmosphere") then
            if not extraState.atmospheres[object] then extraState.atmospheres[object]={object.Density,object.Haze} end
            object.Density=0; object.Haze=0
        end end
    else
        for object,original in pairs(extraState.atmospheres) do
            if object.Parent then object.Density=original[1]; object.Haze=original[2] end
            extraState.atmospheres[object]=nil
        end
    end
    local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if config.fastRun and humanoid then
        if not extraState.walk[humanoid] then extraState.walk[humanoid]=humanoid.WalkSpeed end
        humanoid.WalkSpeed=config.runSpeed
    elseif not config.fastRun then
        for object,speed in pairs(extraState.walk) do if object.Parent then object.WalkSpeed=speed end; extraState.walk[object]=nil end
    end
    local pg=player:FindFirstChild("PlayerGui")
    local noInset=pg and pg:FindFirstChild("NoInsetGui")
    local main=noInset and noInset:FindFirstChild("MainFrame")
    local effects=main and main:FindFirstChild("ScreenEffects")
    if config.noVisorFlash and effects then
        for _,name in ipairs({"Visor","Mask","HelmetMask","Flashbang"}) do
            local object=effects:FindFirstChild(name)
            if object and object:IsA("GuiObject") then
                if extraState.effects[object]==nil then extraState.effects[object]=object.Visible end
                object.Visible=false
            end
        end
    elseif not config.noVisorFlash then
        for object,visible in pairs(extraState.effects) do if object.Parent then object.Visible=visible end; extraState.effects[object]=nil end
    end
    statsCard.Visible=config.statsGui
    if config.statsGui then
        local entries=RS:FindFirstChild("Players")
        local entry=entries and entries:FindFirstChild(player.Name)
        local s=entry and entry:FindFirstChild("Status")
        local journey=s and s:FindFirstChild("Journey")
        local wipe=journey and journey:FindFirstChild("WipeStatistics")
        local kills=wipe and wipe:GetAttribute("Kills")
        local deaths=wipe and wipe:GetAttribute("Deaths")
        local leaderstats=player:FindFirstChild("leaderstats")
        local k=leaderstats and leaderstats:FindFirstChild("Kills")
        local d=leaderstats and leaderstats:FindFirstChild("Deaths")
        kills=type(kills)=="number" and kills or k and k.Value or nil
        deaths=type(deaths)=="number" and deaths or d and d.Value or nil
        local kd=type(kills)=="number" and type(deaths)=="number" and string.format("%.2f",kills/math.max(1,deaths)) or "--"
        statsText.Text="KILLS: "..tostring(kills or "--").."   DEATHS: "..tostring(deaths or "--")
            .."\nK/D: "..kd.."   SESSION: "..math.floor((os.clock()-extraState.started)/60).."m\n@"..player.Name
    end
    if config.friendESP then
        for _,target in ipairs(Players:GetPlayers()) do
            if target~=player and extraState.friends[target.UserId]==nil then
                extraState.friends[target.UserId]=false
                task.spawn(function()
                    local ok,value=pcall(function() return player:IsFriendsWithAsync(target.UserId) end)
                    if alive and ok then extraState.friends[target.UserId]=value end
                end)
            end
        end
    end
end
local function updateSpecialMarkers()
    local seen={}
    local count=0
    local function add(object,label,color)
        if count>=150 or seen[object] then return end
        local part=object:IsA("BasePart") and object or object:FindFirstChildWhichIsA("BasePart",true)
        if not part then return end
        count=count+1; seen[object]=true
        local record=extraState.markers[object]
        if not record then
            local bill=make("BillboardGui",gui,{Adornee=part,AlwaysOnTop=true,Size=UDim2.fromOffset(190,24),StudsOffset=Vector3.new(0,2,0)})
            local labelObject=text(bill,label,UDim2.new(),UDim2.fromScale(1,1),color,11)
            labelObject.TextXAlignment=Enum.TextXAlignment.Center
            labelObject.TextStrokeTransparency=0.4
            record={bill=bill,label=labelObject}; extraState.markers[object]=record
        end
        record.bill.MaxDistance=config.maxDistance
        record.label.Text=label; record.label.TextColor3=color
    end
    local dropped=workspace:FindFirstChild("DroppedItems")
    if config.corpseESP and dropped then
        for _,object in ipairs(dropped:GetChildren()) do
            if object:FindFirstChildOfClass("Humanoid") then add(object,object.Name.." / CORPSE",Color3.fromRGB(166,115,255)) end
        end
    end
    local containers=workspace:FindFirstChild("Containers")
    if config.lootContainers and containers then
        for _,object in ipairs(containers:GetChildren()) do
            if config["loot"..object.Name] then add(object,object.Name,Color3.fromRGB(249,205,98)) end
        end
    end
    local zones=workspace:FindFirstChild("AiZones")
    if zones and (config.minesESP or config.bossTracker) then
        local bosses={Anton=true,Dozer=true,Whisper=true,Death=true,MI24V=true}
        for object in pairs(sceneIndex.special) do
            if object.Parent and object:IsDescendantOf(zones) then
                if config.minesESP and (object.Name=="PMN2" or object.Name=="MON50") then add(object,"MINE / "..object.Name,Color3.fromRGB(255,92,77)) end
                if config.bossTracker and bosses[object.Name] and object:IsA("Model") then add(object,"BOSS / "..object.Name,Color3.fromRGB(255,110,67)) end
            elseif not object.Parent then sceneIndex.special[object]=nil end
        end
    end
    for object,record in pairs(extraState.markers) do
        if not seen[object] or not object.Parent then record.bill:Destroy(); extraState.markers[object]=nil end
    end
end
connect(UIS.JumpRequest,function()
    if config.infiniteJump and not UIS:GetFocusedTextBox() then
        local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health>0 then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
local cameraOriginals={}
local alerted={}
local roleCache={}
local staffBusy=false
local function splitSet(value)
    local result={}
    for item in value:gmatch("[^,]+") do
        local key=item:match("^%s*(.-)%s*$"):lower()
        if key~="" then result[key]=true end
    end
    return result
end
local function configuredGroup()
    local id=tonumber(config.modGroup)
    if id and id>0 then return math.floor(id) end
    if config.modGroup:match("^%s*$") and game.CreatorType==Enum.CreatorType.Group then return game.CreatorId end
    return nil
end
local alertToasts={}
local function arrangeAlerts()
    for i,toast in ipairs(alertToasts) do toast.Position=UDim2.new(1,-14,0,90+(i-1)*92) end
end
local function notifyStaff(target,reason)
    if alerted[target.UserId] or not config.modAlerts or not alive then return end
    alerted[target.UserId]=true
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{
        Title="Direct Lite / staff evidence",Text=target.Name..": "..reason,Duration=10}) end)
    local toast=make("Frame",gui,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,90),Size=UDim2.fromOffset(350,84),
        BackgroundColor3=Color3.fromRGB(110,33,50),BorderSizePixel=0,ZIndex=30})
    round(toast,8)
    table.insert(alertToasts,toast)
    if #alertToasts>3 then table.remove(alertToasts,1):Destroy() end
    arrangeAlerts()
    local message=text(toast,"STAFF ALERT / @"..target.Name.."\n"..reason,UDim2.fromOffset(12,6),UDim2.new(1,-24,1,-12),nil,12)
    message.TextWrapped=true; message.ZIndex=31
    task.delay(10,function()
        for i,value in ipairs(alertToasts) do if value==toast then table.remove(alertToasts,i); break end end
        if toast.Parent then toast:Destroy() end
        arrangeAlerts()
    end)
end
local function restoreFov()
    for camera,original in pairs(cameraOriginals) do
        if camera.Parent then camera.FieldOfView=original end
        cameraOriginals[camera]=nil
    end
end
local function checkModerators()
    local names=splitSet(config.modNames)
    local roles=splitSet(config.modRoles)
    local group=configuredGroup()
    local summary={group and "Public group: "..group or "No group selected; watchlist only."}
    for _,target in ipairs(Players:GetPlayers()) do
        if target~=player then
            local match=names[target.Name:lower()] or names[tostring(target.UserId)]
            if match then notifyStaff(target,"Exact configured account match") end
            local cached=group and roleCache[tostring(group)..":"..target.UserId]
            local details=match and "WATCHLIST" or "No watchlist match"
            if cached then
                if cached.error then details=details.." / role lookup unavailable"
                else
                    for _,role in ipairs(cached.roles) do
                        if roles[role.Name:lower()] then notifyStaff(target,"Public role: "..role.Name.." / group "..group) end
                    end
                    local labels={}
                    for _,role in ipairs(cached.roles) do table.insert(labels,role.Name.." ("..role.Rank..")") end
                    details=details.." / "..(#labels>0 and table.concat(labels,", ") or "No public role")
                end
            elseif group then details=details.." / awaiting role lookup" end
            table.insert(summary,target.Name..": "..details)
        end
    end
    roleStatus.Text=table.concat(summary,"\n").."\nNo match does not establish that an account is not staff."
    if not group or staffBusy then return end
    staffBusy=true
    task.spawn(function()
        for _,target in ipairs(Players:GetPlayers()) do
            if not alive then break end
            local key=tostring(group)..":"..target.UserId
            local cached=roleCache[key]
            if target~=player and (not cached or os.clock()-cached.time>(cached.error and 60 or 300)) then
                local ok,data=pcall(function() return game:GetService("GroupService"):GetRolesInGroupAsync(target.UserId,group) end)
                if not ok or type(data)~="table" or type(data.Roles)~="table" then
                    ok,data=pcall(function()
                        local name=target:GetRoleInGroupAsync(group)
                        return {Roles=name~="Guest" and {{Name=name,Rank=0}} or {}}
                    end)
                end
                local valid=ok and type(data)=="table" and type(data.Roles)=="table"
                if alive then roleCache[key]={roles=valid and data.Roles or {},error=not valid,time=os.clock()} end
            end
        end
        staffBusy=false
    end)
end
connect(scanStaff.Activated,function() roleCache={}; alerted={}; checkModerators() end)
connect(Players.PlayerAdded,function() task.defer(function() if alive then checkModerators() end end) end)
connect(Players.PlayerRemoving,function(target) alerted[target.UserId]=nil end)
local bindName="DirectLiteCombat"
local gameModule={}
do
    local state={fly=nil,boxes={},timer=0}
    local function stopFly()
        local fly=state.fly
        if not fly then return end
        fly.velocity:Destroy(); fly.orientation:Destroy(); fly.attachment:Destroy()
        if fly.humanoid.Parent then fly.humanoid.PlatformStand=fly.platform; fly.humanoid.AutoRotate=fly.rotate end
        if fly.root.Parent then fly.root.AssemblyLinearVelocity=Vector3.new(0,0,0) end
        state.fly=nil
    end
    local function restoreBoxes()
        for part,original in pairs(state.boxes) do
            if part.Parent then
                part.Size=original.size; part.Transparency=original.transparency
                part.CanCollide=original.collide; part.Massless=original.massless
            end
            state.boxes[part]=nil
        end
    end
    function gameModule.cleanup() stopFly(); restoreBoxes() end
    function gameModule.update(dt)
        if selectedProfile=="Arsenal" and config.arsenalFly then
            local character=player.Character
            local root=rootPart(character)
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            local camera=workspace.CurrentCamera
            if not root or not humanoid or humanoid.Health<=0 or not camera then stopFly(); return end
            if state.fly and state.fly.root~=root then stopFly() end
            if not state.fly then
                local attachment=make("Attachment",root,{Name="DirectLiteFlyAttachment"})
                local velocity=make("LinearVelocity",root,{Attachment0=attachment,RelativeTo=Enum.ActuatorRelativeTo.World,
                    ForceLimitsEnabled=false,VectorVelocity=Vector3.new(0,0,0)})
                local orientation=make("AlignOrientation",root,{Attachment0=attachment,Mode=Enum.OrientationAlignmentMode.OneAttachment,
                    MaxTorque=math.huge,Responsiveness=25})
                state.fly={root=root,humanoid=humanoid,attachment=attachment,velocity=velocity,orientation=orientation,
                    platform=humanoid.PlatformStand,rotate=humanoid.AutoRotate}
                humanoid.PlatformStand=true; humanoid.AutoRotate=false
            end
            local direction=Vector3.new(0,0,0)
            if not UIS:GetFocusedTextBox() then
                if UIS:IsKeyDown(Enum.KeyCode.W) then direction=direction+camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then direction=direction-camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then direction=direction+camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then direction=direction-camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then direction=direction+Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction=direction-Vector3.new(0,1,0) end
            end
            state.fly.velocity.VectorVelocity=direction.Magnitude>0 and direction.Unit*config.arsenalFlySpeed or direction
            state.fly.orientation.CFrame=camera.CFrame.Rotation
        else stopFly() end
        state.timer=state.timer+dt
        if selectedProfile=="BedWars" and config.bedwarsHitboxes then
            if state.timer<0.2 then return end
            state.timer=0
            local active={}
            for _,target in ipairs(Players:GetPlayers()) do
                local character=target.Character
                local root=character and character:FindFirstChild("HumanoidRootPart")
                local humanoid=character and character:FindFirstChildOfClass("Humanoid")
                if target~=player and not teammate(target) and root and humanoid and humanoid.Health>0 then
                    active[root]=true
                    if not state.boxes[root] then state.boxes[root]={size=root.Size,transparency=root.Transparency,collide=root.CanCollide,massless=root.Massless} end
                    root.Size=Vector3.new(config.bedwarsHitboxSize,config.bedwarsHitboxSize,config.bedwarsHitboxSize)
                    root.Transparency=0.65; root.CanCollide=false; root.Massless=true
                end
            end
            for part,original in pairs(state.boxes) do
                if not active[part] then
                    if part.Parent then part.Size=original.size; part.Transparency=original.transparency; part.CanCollide=original.collide; part.Massless=original.massless end
                    state.boxes[part]=nil
                end
            end
        elseif next(state.boxes) then restoreBoxes() end
    end
end
local function updateCombat(dt)
    if not alive then return end
    gameModule.update(dt)
    silentLine.Visible=false; silentHeadDot.Visible=false
    local camera=workspace.CurrentCamera
    if not camera then return end
    if config.fovOverride or config.zoom then
        if not cameraOriginals[camera] then cameraOriginals[camera]=camera.FieldOfView end
        camera.FieldOfView=config.zoom and config.zoomFov or config.cameraFov
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
    if config.silentAim and config.silentHeadLine then
        local head=target.Character and target.Character:FindFirstChild("Head")
        if head then
            local p,onScreen=camera:WorldToViewportPoint(head.Position)
            if onScreen and p.Z>0 then
                local color=Color3.fromRGB(config.espRed,config.espGreen,config.espBlue)
                silentLine.BackgroundColor3=color; silentHeadDot.BackgroundColor3=color
                drawLine(silentLine,camera.ViewportSize/2,Vector2.new(p.X,p.Y))
                silentHeadDot.Position=UDim2.fromOffset(p.X,p.Y)
                silentHeadDot.Visible=true
            end
        end
    end
    if config.silentAim then
        local model=camera:FindFirstChild("ViewModel")
        if not model then
            for _,candidate in ipairs(camera:GetChildren()) do
                if candidate.Name:lower()=="viewmodel" then model=candidate; break end
            end
        end
        local root=nil
        if model and config.perfectSilent then
            local item=model:FindFirstChild("Item")
            local points=item and item:FindFirstChild("AttachmentPoints")
            root=points and points:FindFirstChild("Extra")
        elseif model then root=model:FindFirstChild("HumanoidRootPart",true) end
        if not root and model then
            local item=model:FindFirstChild("Item")
            local points=item and item:FindFirstChild("AttachmentPoints")
            root=points and points:FindFirstChild("Extra")
        end
        if not model or not root or not (root:IsA("BasePart") or root:IsA("Attachment") and root.Parent:IsA("BasePart")) then
            releaseViewmodel()
            combatStatus.Text=recoilText.."\n"..(not model and "Silent aim unavailable: no weapon ViewModel. Baseplate Tools are unsupported." or "Silent aim: weapon root / Extra attachment not found. Try the attachment variant.")
            return
        end
        local world=root:IsA("Attachment") and root.WorldCFrame or root.CFrame
        if viewPart~=root then releaseViewmodel(); viewPart=root; viewOffset=camera.CFrame:ToObjectSpace(world) end
        if math.random()*100<config.silentChance then
            local offset=config.perfectSilent and 0.15 or 1.75
            local position=part.Position-Vector3.new(0,offset,0)
            if (world.Position-position).Magnitude>0.001 then
                local redirect=CFrame.lookAt(world.Position,position)
                if root:IsA("Attachment") then root.CFrame=root.Parent.CFrame:ToObjectSpace(redirect)
                else root.CFrame=redirect end
            end
        else
            releaseViewmodel()
        end
        combatStatus.Text=recoilText.."\nViewmodel redirected: "..target.DisplayName.." (hit registration unverified)"
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
    restoreExtra()
    gameModule.cleanup()
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
local overlayElapsed=0
connect(RunService.RenderStepped,function(dt)
    if not alive then return end
    overlayElapsed=overlayElapsed+dt
    if overlayElapsed<1/30 then return end
    dt=overlayElapsed; overlayElapsed=0
    if inspectState.held then
        inspectState.elapsed=inspectState.elapsed+dt
        if inspectState.elapsed>=0.15 then inspectState.elapsed=0; refreshHeldInspector() end
    end
    local camera=workspace.CurrentCamera
    if not camera then return end
    scale.Scale=math.max(0.1,math.min(config.menuScale/100,(camera.ViewportSize.X-24)/980,(camera.ViewportSize.Y-24)/620))
    local radarSize=math.min(config.radarSize,math.max(80,math.min(camera.ViewportSize.X-24,camera.ViewportSize.Y-72)))
    radar.Size=UDim2.fromOffset(radarSize,radarSize+48)
    radarTitle.Text=config.radarRotate and "RADAR / CAMERA UP" or "RADAR / NORTH UP"
    radarFooter.Text=config.radarRange.." studs\nRed: facing + clear sight (estimate)"
    inventoryPanel.Size=UDim2.fromOffset(math.min(430,camera.ViewportSize.X-24),math.min(650,camera.ViewportSize.Y-32))
    if not radarDragging then
        local pos=radar.AbsolutePosition
        local x=math.clamp(pos.X,0,math.max(0,camera.ViewportSize.X-radarSize))
        local y=math.clamp(pos.Y,0,math.max(0,camera.ViewportSize.Y-radarSize-48))
        radar.Position=UDim2.fromOffset(x,y)
    end
    radar.Visible=config.radar
    local espColor=Color3.fromRGB(config.espRed,config.espGreen,config.espBlue)
    local radarRange=config.radarRange
    local loadedCount=0
    if config.radarAutoRange then
        for target in pairs(markers) do
            local root=rootPart(entityCharacter(target))
            local meRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root and meRoot then
                local d=(root.Position-meRoot.Position).Magnitude
                if d<=config.maxDistance then radarRange=math.max(radarRange,math.ceil(d/100)*100) end
            end
        end
    end
    radarFooter.Text=radarRange.." studs / auto "..(config.radarAutoRange and "on" or "off").."\nRed: facing + clear sight (estimate)"
    local me=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for target,m in pairs(markers) do
        local isFriend=target:IsA("Player") and extraState.friends[target.UserId]==true
        local showESP=config.esp or (config.friendESP and isFriend)
        local entityColor=isFriend and config.friendESP and Color3.fromRGB(61,238,109) or espColor
        local character=entityCharacter(target)
        local root=rootPart(character)
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local distance=root and me and (root.Position-me.Position).Magnitude or math.huge
        local valid=root and humanoid and humanoid.Health>0 and distance<=config.maxDistance
        if valid then loadedCount=loadedCount+1 end
        m.frame.Visible=false; m.dot.Visible=false; m.facing.Visible=false
        for _,line in ipairs(m.lines) do line.Visible=false end
        if m.highlight and m.highlight.Adornee~=character then m.highlight:Destroy(); m.highlight=nil end
        if showESP and config.chams and valid and not m.highlight then
            m.highlight=make("Highlight",gui,{Adornee=character,FillColor=cyan,FillTransparency=0.65,
                OutlineColor=cyan,OutlineTransparency=0.1,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop})
        end
        if m.highlight then m.highlight.Enabled=not not (showESP and config.chams and valid) end
        if m.highlight then m.highlight.FillColor=entityColor; m.highlight.OutlineColor=entityColor end
        if valid then
            if showESP then
                local point,onScreen=camera:WorldToViewportPoint(root.Position)
                if onScreen and point.Z>0 then
                    local above=camera:WorldToViewportPoint(root.Position+Vector3.new(0,3.5,0))
                    local below=camera:WorldToViewportPoint(root.Position-Vector3.new(0,3.5,0))
                    local height=math.clamp(math.abs(below.Y-above.Y),8,2000)
                    local width=height*0.53
                    m.frame.Position=UDim2.fromOffset(point.X-width/2,point.Y-height/2)
                    m.frame.Size=UDim2.fromOffset(width,height)
                    m.frame.Visible=true; m.box.Enabled=config.boxes
                    m.box.Color=entityColor; m.label.TextColor3=entityColor
                    m.box.Thickness=config.lineThickness
                    m.health.Visible=config.healthBar
                    local hp=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
                    m.healthFill.Size=UDim2.fromScale(1,hp)
                    m.healthFill.BackgroundColor3=Color3.fromRGB(math.floor(255*(1-hp)),math.floor(70+180*hp),65)
                    m.label.Visible=config.names or config.weaponLabels
                    m.label.TextSize=config.labelSize
                    m.label.Size=UDim2.new(1,150,0,config.labelSize*2+10)
                    m.label.Position=UDim2.new(0,-75,0,-config.labelSize*2-12)
                    local weapon=config.weaponLabels and equipped(character) or ""
                    local name=target:IsA("Player") and (target.DisplayName.." (@"..target.Name..")") or entityName(target)
                    local details=math.floor(distance).." studs"..(config.nameHealth and " / "..math.floor(humanoid.Health).." HP" or "")
                    m.label.Text=(config.names and name.."\n"..details or "")..(config.names and weapon~="" and " / " or "")..weapon
                    if config.skeleton then
                        local i=0
                        if m.skeletonCharacter~=character then
                            m.skeletonCharacter=character; m.motors={}
                            for _,motor in ipairs(character:GetDescendants()) do
                                if motor:IsA("Motor6D") then table.insert(m.motors,motor) end
                            end
                        end
                        for _,motor in ipairs(m.motors) do
                            if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 and motor.Name~="RootJoint" and motor.Name~="Root" then
                                local a,av=camera:WorldToViewportPoint(motor.Part0.Position)
                                local b,bv=camera:WorldToViewportPoint(motor.Part1.Position)
                                if av and bv and a.Z>0 and b.Z>0 then
                                    i=i+1
                                    if not m.lines[i] then m.lines[i]=make("Frame",overlay,{AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,BackgroundColor3=cyan}) end
                                    m.lines[i].BackgroundColor3=entityColor
                                    drawLine(m.lines[i],Vector2.new(a.X,a.Y),Vector2.new(b.X,b.Y))
                                end
                            end
                        end
                    end
                end
            end
            if config.radar and me then
                local relative=root.Position-me.Position
                local plotSize=radarPlot.AbsoluteSize
                local center=plotSize/2
                local radius=math.max(1,math.min(plotSize.X,plotSize.Y)/2-8)
                local forward=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
                if forward.Magnitude<0.001 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
                local right=Vector3.new(-forward.Z,0,forward.X)
                local function project(vector)
                    if config.radarRotate then return Vector2.new(vector:Dot(right),-vector:Dot(forward))*(radius/radarRange) end
                    return Vector2.new(vector.X,vector.Z)*(radius/radarRange)
                end
                local point=project(relative)
                if math.abs(point.X)<=radius and math.abs(point.Y)<=radius then
                    m.dot.Position=UDim2.fromOffset(center.X+point.X-3,center.Y+point.Y-3)
                    m.dot.Visible=true
                    m.radarLabel.Visible=config.radarNames
                    m.radarLabel.Text=entityName(target)
                    m.radarLabel.Size=UDim2.fromOffset(math.max(20,plotSize.X/2-8),16)
                    local head=character:FindFirstChild("Head") or root
                    local toward=me.Position-head.Position
                    local facing= toward.Magnitude>0.001 and head.CFrame.LookVector:Dot(toward.Unit)>=math.cos(math.rad(config.threatAngle))
                    local visible=false
                    if facing and config.threatLines and (not m.sightTime or os.clock()-m.sightTime>=0.2) then
                        local params=RaycastParams.new()
                        params.FilterType=Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances={character,camera}
                        local hit=workspace:Raycast(head.Position,toward,params)
                        visible=not hit or hit.Instance:IsDescendantOf(player.Character)
                        m.sightTime=os.clock(); m.sightVisible=visible
                    elseif facing then visible=m.sightVisible or false
                    end
                    local danger=facing and visible
                    m.dot.BackgroundColor3=danger and Color3.fromRGB(255,76,90) or cyan
                    if config.threatLines then
                        local start=center+point
                        local finish=danger and center or start+project(head.CFrame.LookVector*math.min(config.radarRange*0.12,30))
                        finish=Vector2.new(math.clamp(finish.X,0,plotSize.X),math.clamp(finish.Y,0,plotSize.Y))
                        m.facing.BackgroundColor3=danger and Color3.fromRGB(255,76,90) or Color3.fromRGB(67,111,143)
                        drawLine(m.facing,start,finish)
                    end
                end
            end
        end
    end
    sceneStatus.Text=math.max(0,#Players:GetPlayers()-1).." other players\n"..loadedCount.." loaded targets in range"
    homeStatus.Text=selectedProfile..(isDelta and " / integrated tools" or (selectedProfile=="Arsenal" or selectedProfile=="BedWars") and " / profile-specific controls" or " / shared controls only").."\nOther players: "..math.max(0,#Players:GetPlayers()-1).."\nLoaded targets in range: "..loadedCount
        .."\nInspecting: @"..(selected and selected.Name or "none")
        .."\nIf an inventory is unavailable, that data is not exposed to this client."
    if rosterState.dirty then rosterState.dirty=false; updateInventory() end
    timer=timer+dt; previewTimer=previewTimer+dt; rigTimer=rigTimer+dt
    if rigTimer>=3 then rigTimer=0; scanRigs(); updateSpecialMarkers() end
    if timer>=1 then
        timer=0
        if inventoryPanel.Visible or window.Visible and inventory.Visible then updateInventory() end
        updateLoot(); checkModerators(); updateExtra()
    end
    if previewTimer>=5 and window.Visible and preview.Visible then previewTimer=0; rebuildPreview() end
    previewStroke.Enabled=config.previewBox
    previewName.Text=selected and selected.DisplayName or "No player"
    if window.Visible and preview.Visible and selected and sourceCharacter~=selected.Character then rebuildPreview() end
    if clonedCharacter and window.Visible and preview.Visible then
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
scanRigs()
updateInventory()
loadingPhase(1,"Ready / players and overlays initialized")
task.defer(function() if loading.Parent then loading:Destroy() end end)

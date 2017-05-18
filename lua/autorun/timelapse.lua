if SERVER then
    AddCSLuaFile("timelapse.lua")
return end
if Timelapse then
    for k,v in pairs(Timelapse.Cameras) do
        v[3]:Remove()
    end
end

Timelapse = {
    Cameras = {},
    Capturing = false
}

local CurrentCamera = 0

-- Load config

local function cvar(s,default)
    return CreateClientConVar("timelapse_" .. s,default,true,false)
end

local bIsDirty = true

function MakeUIDirty()

		bIsDirty = true

	end


Timelapse.Enablechat = cvar("enablechat",1)
Timelapse.FirstPerson = cvar("firstperson",1)
Timelapse.Current = cvar("current_timelapse","none")
Timelapse.Time = cvar("time",10)
Timelapse.Hud = cvar("drawhud",0)
Timelapse.Fov = cvar("fov",90)
Timelapse.ShowID = cvar("drawid",1)
Timelapse.Quality = cvar("quality",70)

file.CreateDir("timelapse")

local white = Color(255,255,255)
local gray = Color(240,240,240)
local green = Color(0,255,0)

function Timelapse.Say(s,d,f)
    if (Timelapse.Enablechat:GetBool() and not d ) or f then
        chat.AddText(white,"[",green,"TimeLapse",white,"] ",gray,s)
    else
        MsgC(white,"[",green,"TimeLapse",white,"] ",gray,s,"\n")
    end
end

cvars.AddChangeCallback( "timelapse_current_timelapse", function(_,_,name)
    local a = "timelapse/" .. Timelapse.Current:GetString() .. "/"
    file.CreateDir(a)
    if not file.Exists(a .. "current.txt","DATA") then
        file.Write(a .. "current.txt","0")
    end
end)

function Timelapse.GetDirectory()
    Timelapse.Say(util.RelativePathToFull("data/timelapse/" .. Timelapse.Current:GetString() .. "/current.txt"),false,true)
end
concommand.Add("timelapse_get_directory",Timelapse.GetDirectory)

function Timelapse.Start()
    Timelapse.Capturing = true
    file.CreateDir("timelapse/" .. Timelapse.Current:GetString())
    Timelapse.Say("Started capturing timelapse " .. Timelapse.Current:GetString() .. "!")
    Timelapse.MakeTimer()
end
concommand.Add("timelapse_start",Timelapse.Start)

function Timelapse.Pause()
    Timelapse.Capturing = false
    Timelapse.Say("Paused capturing,")
end
concommand.Add("timelapse_pause",Timelapse.Pause)

function Timelapse.MakeCamera()
    local mdl = ClientsideModel("models/dav0r/camera.mdl")

    mdl.id = CurrentCamera + 1
    mdl.entid = math.Round(math.Rand(0,10000))
    mdl:SetPos(LocalPlayer():GetShootPos())
    mdl:SetAngles(LocalPlayer():EyeAngles())

    Timelapse.Cameras[CurrentCamera + 1] = {
        LocalPlayer():GetShootPos(),
        LocalPlayer():EyeAngles(),
        mdl
    }
    Timelapse.Say("Made camera #" .. CurrentCamera + 1 .. "!")
    CurrentCamera = CurrentCamera + 1
    MakeUIDirty()
end
concommand.Add("timelapse_camera_make",Timelapse.MakeCamera)

function Timelapse.MakeTimer()
    timer.Create("TimeLapse.Velkon",Timelapse.Time:GetInt(),0,function()
        if not Timelapse.Capturing then return end
        print(1)
        Timelapse.Capture(Timelapse.GetFileName())
    end)
end

function Timelapse.GetFileName()
    local a = "timelapse/" .. Timelapse.Current:GetString() .. "/"
    file.CreateDir(a)
    if not file.Exists(a .. "current.txt","DATA") then
        file.Write(a .. "current.txt","0")
    end
    local cur = file.Read(a .. "current.txt","DATA")
    file.Write(a .. "current.txt",cur + 1)
    return a .. cur .. ".jpg"
end

local rc = {
    format = "jpeg",
    quality = 70,
    h = ScrH(),
    w = ScrW(),
    x = 0,
    y = 0
}

Kapture = false
hook.Add("ShouldDrawLocalPlayer","Timelapse",function(ply)
    return Kapture
end)

function Timelapse.NextCamera()
    if Timelapse.Cameras[CurrentCamera + 1] then
        CurrentCamera = CurrentCamera + 1
    else
        CurrentCamera = 1
    end
end

function Timelapse.NoDrawCameras(bool)
    for k,v in pairs(Timelapse.Cameras) do
        v[3]:SetNoDraw(bool)
    end
end

hook.Add("ShouldDrawLocalPlayer","Timelapse",function(ply)
    return Kapture
end)
function Timelapse.Capture(out)
     Timelapse.Say("Capturing screenshot..")
     local origin = LocalPlayer():EyePos()
     local angles = LocalPlayer():EyeAngles()
     if not Timelapse.FirstPerson:GetBool() and Timelapse.Cameras[CurrentCamera][1] then
         Kapture = true
         origin = Timelapse.Cameras[CurrentCamera][1]
         angles = Timelapse.Cameras[CurrentCamera][2]
         Timelapse.NoDrawCameras(true)
         Kapture = true
         Timelapse.NextCamera()
         LocalPlayer():SetNoDraw(false)
     end
     render.RenderView({
         origin = origin,
		 angles = angles,
         x = 0,
         y = 0,
         w = ScrW(),
         h = ScrH(),
         drawhud = false,
         dopostproccess = false,
         fov = Timelapse.Fov:GetInt(),
         drawviewmodel = Timelapse.FirstPerson:GetBool(),
         drawviewer = not Timelapse.FirstPerson:GetBool() })
         rc.quality = Timelapse.Quality:GetInt()
	  local capture = render.Capture(rc)
      if not Timelapse.FirstPerson:GetBool() then
          Timelapse.NoDrawCameras(false)
           LocalPlayer():SetNoDraw(true)
      end
      Kapture = false
	timer.Simple(Timelapse.Time:GetInt()/2,function() Timelapse.Say("Saving last screenshot...",true) file.Write(out,capture) end)
end


function Timelapse.Menu(CPanel)

    CPanel:AddControl( "TextBox", { Label = "Current Timelapse: ", Command = "timelapse_current_timelapse", WaitForEnter = "1" } )

    CPanel:Button("Get Directory","timelapse_get_directory")

    CPanel:Button("Start Timelapse","timelapse_start")

    CPanel:Button("Pause Timelapse","timelapse_pause")

    CPanel:AddControl( "Header", { Description = "Time inbetween pictures" } )

	CPanel:AddControl( "TextBox", { Label = "Seconds: ", Command = "timelapse_time", WaitForEnter = "1" } )

    CPanel:AddControl( "Header", { Description = "Quality of each pictures: ( 0 - 100) (Default 70)" } )

    CPanel:AddControl( "TextBox", { Label = "Quality: ", Command = "timelapse_quality", WaitForEnter = "1" } )

    CPanel:AddControl( "Header", { Description = "When taking a picture:" } )

	CPanel:AddControl( "CheckBox", { Label = "Show hud", Command = "timelapse_drawhud" } )

    CPanel:AddControl( "CheckBox", { Label = "Firstperson ( Thirdperson requires at least 1 camera )", Command = "timelapse_firstperson" } )

    CPanel:AddControl( "TextBox", { Label = "FOV (Default 90): ", Command = "timelapse_fov", WaitForEnter = "1" } )

    CPanel:AddControl( "Header", { Description = "When not taking a picture:" } )

    CPanel:AddControl( "CheckBox", { Label = "Output in chat", Command = "timelapse_enablechat" } )

    CPanel:AddControl( "CheckBox", { Label = "Show ID of cameras", Command = "timelapse_drawid" } )

    CPanel:AddControl( "Header", { Description = "--Cameras--" } )

    CPanel:Button("Make Camera","timelapse_camera_make")

    CPanel:AddControl( "Header", { Description = "List of Cameras:\nLeft click on one for more options" } )

		local ComboBox,label = CPanel:ListBox("(Cameras ID [Ent index])")
		ComboBox:SetTall( 200 )
        ComboBox:SetWide( 500 )

        local function CPanelUpdate( panel )
		if ( bIsDirty ) then
			timer.Simple( 0, function()
                ComboBox:Clear()
    		for k, v in pairs( Timelapse.Cameras ) do

    			local Item = ComboBox:AddItem( tostring("Camera " .. k .. " (" .. v[3].entid .. ")") )
                Item.DoClick = function()

                    local menu = DermaMenu()
                    menu:AddOption("Remove Camera",function()
                        Timelapse.Say("Removed camera " .. k .. "(" .. v[3].entid .. ")")
                        v[3]:Remove()
                        Timelapse.Cameras[k] = nil
                        for i,o in pairs(Timelapse.Cameras) do
                            if i > k then
                                Timelapse.Cameras[i-1] = o
                                Timelapse.Cameras[i] = nil
                            end
                        end
                        CurrentCamera = CurrentCamera - 1
                        MakeUIDirty()
                    end)
                    menu:AddOption("Move Camera",function()
                        v[3]:SetPos(LocalPlayer():GetShootPos())
                        v[3]:SetAngles(LocalPlayer():EyeAngles())
                        Timelapse.Cameras[k] = {
                            LocalPlayer():GetShootPos(),
                            LocalPlayer():EyeAngles(),
                            v[3]
                        }
                        Timelapse.Say("Moved camera " .. k .. "(" .. v[3].entid .. ")")
                    end)
                    menu:Open()
                    menu:SetPos(input.GetCursorPos())

                end

    		end

            end )
			bIsDirty = false

		end
	end

    CPanel.Think = CPanelUpdate

end

-- GUI
hook.Add( "PopulateToolMenu", "TimeLapse", function()

	spawnmenu.AddToolMenuOption( "Utilities", "tlapse", "t_lapse", "Timelapse", "", "", Timelapse.Menu )

end )


hook.Add( "AddToolMenuCategories", "CreateTimeLapse", function()

	spawnmenu.AddToolCategory( "Utilities", "tlapse", "Timelapse" )

end )


Timelapse.Say("Loaded Timelapse! ")

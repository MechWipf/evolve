/*-------------------------------------------------------------------------------------------------------------------------
	Message of the Day
-------------------------------------------------------------------------------------------------------------------------*/

local PLUGIN = {}
PLUGIN.Title = "MOTD"
PLUGIN.Description = "Message of the Day."
PLUGIN.Author = "Divran, MechWipf"
PLUGIN.ChatCommand = "motd"
PLUGIN.Usage = nil
PLUGIN.Privileges = nil

local CHUNK_SIZE = 1024 * 63

function PLUGIN:Call( ply, args )
	self:OpenMotd( ply )
end

function PLUGIN:PlayerInitialSpawn(ply)
	timer.Simple(1, function() ply:ConCommand("evolve_startmotd") end)
end

function PLUGIN:OpenMotd(ply)
	if (SERVER) then
		ply:ConCommand("evolve_motd")
	end
end

if (SERVER) then 
	PLUGIN.PlayerDownload = {}

	function PLUGIN:PlayerDisconnected( ply )
		self.PlayerDownload[ply] = nil
	end

	function PLUGIN:GetMotd()
		if file.Exists("evolvemotd.txt", "DATA") then
			self.Motd = file.Read("evolvemotd.txt", "DATA")
		end
	end
	PLUGIN:GetMotd()

	util.AddNetworkString("ev_sendmotd")
	util.AddNetworkString("ev_requestmotd")

	function PLUGIN:SendMotd( ply )
		local routine
		if self.PlayerDownload[ply] and coroutine.status( self.PlayerDownload[ply] ) ~= "dead" then
			routine = self.PlayerDownload[ply]
		else
			routine = coroutine.create(function ()
				local chunks = math.floor( self.Motd:len() / CHUNK_SIZE )

				for chunk = 0, chunks, 1 do
					if IsValid( ply ) then
						net.Start( "ev_sendmotd" )
							net.WriteBool( chunk == chunks )
							net.WriteString( self.Motd:sub( chunk * CHUNK_SIZE + 1, (chunk + 1) * CHUNK_SIZE ) )
						net.Send( ply )
					end

					if chunk ~= chunks then
						coroutine.yield()
					end
				end
			end)

			self.PlayerDownload[ply] = routine
		end

		coroutine.resume(routine)
	end

	net.Receive( "ev_requestmotd", function ( _len, ply )
		if PLUGIN.Motd != nil then
			PLUGIN:SendMotd( ply )
		end
	end)

	for k,v in pairs( player.GetAll() ) do
		v:ConCommand( "evolve_startmotd" )
	end
else
	function PLUGIN:CreateMenu()
		self.MotdPanel = vgui.Create("DFrame")
		local w,h = ScrW() - 200, ScrH() - 200
		self.MotdPanel:SetPos(100, 100)
		self.MotdPanel:SetSize(w, h)
		self.MotdPanel:SetTitle("MOTD")
		self.MotdPanel:SetVisible(false)
		self.MotdPanel:SetDraggable(false)
		self.MotdPanel:ShowCloseButton(false)
		self.MotdPanel:SetDeleteOnClose(false)
		self.MotdPanel:SetScreenLock(true)
		self.MotdPanel:MakePopup()
		
		self.MotdBox = vgui.Create("HTML", self.MotdPanel)
		self.MotdBox:StretchToParent(4, 25, 4, 34)

		self.MotdCloseButton = vgui.Create("DButton",self.MotdPanel)
		self.MotdCloseButton:SetSize(150, 20)
		self.MotdCloseButton:SetPos(w / 2 + 4, h - 29)
		self.MotdCloseButton:SetText("Accept")
		self.MotdCloseButton.DoClick = function() 
			PLUGIN.MotdPanel:SetVisible(false)
		end
	end

	concommand.Add("evolve_motd", function(ply,cmd,args)
		net.Start( "ev_requestmotd" )
		net.SendToServer()

		PLUGIN.Motd = ""
	end)

	concommand.Add("evolve_startmotd", function(ply,cmd,args)
		if not PLUGIN.MotdPanel then PLUGIN:CreateMenu() end
		net.Start( "ev_requestmotd" )
		net.SendToServer()

		PLUGIN.Motd = ""
	end)

	net.Receive( "ev_sendmotd", function ( _len )
		local done = net.ReadBool()

		PLUGIN.Motd = PLUGIN.Motd .. net.ReadString()

		if not done then
			net.Start( "ev_requestmotd" )
			net.SendToServer()
		elseif PLUGIN.Motd != nil then
			PLUGIN.MotdBox:SetHTML(PLUGIN.Motd)
			PLUGIN.MotdPanel:SetVisible(true)
		end
	end)
end

evolve:RegisterPlugin(PLUGIN)
--[[-------------------------------------------------------------------------------------------------------------------------
	Serverside autorun file
-------------------------------------------------------------------------------------------------------------------------]]--

-- Set up Evolve table
evolve = {}

-- Load vON
local von_bak = von
if not von then include( "../../includes/ev_von/von.lua") end
if not von then error( "Evolve loading aborted. vON not found!" )

evolve.von = von
von = von_bak

-- Distribute clientside and shared files
AddCSLuaFile( "autorun/client/ev_autorun.lua" )
AddCSLuaFile( "ev_framework.lua" )
AddCSLuaFile( "ev_cl_init.lua" )
AddCSLuaFile( "ev_menu/cl_menu.lua" )

-- Load serverside files
include( "ev_framework.lua" )
include( "ev_sv_init.lua" )
include( "ev_menu/sv_menu.lua" )

-- SourceBans integration
include( "ev_sourcebans.lua" )

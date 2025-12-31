DEFINE_BASECLASS "acf_base_simple"
AddCSLuaFile()

ENT.PrintName     = "ACF Airscrew"
ENT.WireDebugName = "ACF Airscrew"
ENT.PluralName    = "ACF Airscrews"
ENT.IsAirscrew = true
ENT.ACF_PreventArmoring = true

cleanup.Register("acf_airscrew")

local ACF      		= ACF
local Classes  		= ACF.Classes
local Entities 		= Classes.Entities

Classes.Entities.Register()
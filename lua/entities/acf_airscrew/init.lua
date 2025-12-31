AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF         = ACF
local Mobility    = ACF.Mobility
local MobilityObj = Mobility.Objects
local Sounds      = ACF.Utilities.Sounds

local function GenerateLinkTable(Entity, Target)
	local InPos = Target.In and Target.In.Pos or Vector()
	local InPosWorld = Target:LocalToWorld(InPos)
	local OutPos, Side

	local Plane
	if Entity:WorldToLocal(InPosWorld).y < 0 then
		Plane = Entity.OutL
		OutPos = Entity.OutL.Pos
		Side = 0
	else
		Plane = Entity.OutR
		OutPos = Entity.OutR.Pos
		Side = 1
	end

	local OutPosWorld = Entity:LocalToWorld(OutPos)
	local Excessive, Angle = ACF.IsDriveshaftAngleExcessive(Target, Target.In, Entity, Plane)
	if Excessive then return nil, Angle end

	local Link	= MobilityObj.Link(Entity, Target)

	Link:SetOrigin(OutPos)
	Link:SetTargetPos(InPos)
	Link:SetAxis(Target.In and Plane.Dir or Target:GetPhysicsObject():WorldToLocalVector(Entity:GetRight()))
	Link.OutDirection = Plane.Dir
	Link.Side = Side
	Link.RopeLen = (OutPosWorld - InPosWorld):Length()

	return Link, Angle
end

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.AirscrewSize = math.Clamp(ClientData.AirscrewSize or 1, 0.5, 1)
	ClientData.Size = Vector(ClientData.AirscrewSize, ClientData.AirscrewSize, ClientData.AirscrewSize)
end

function ENT:ACF_PreSpawn()
	self:SetScaledModel("models/props_phx/misc/propeller3x_small.mdl")
end

function ENT:ACF_PostUpdateEntityData(ClientData)
	self:SetScale(ClientData.Size)
end

ACF.Classes.Entities.Register()
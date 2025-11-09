DEFINE_BASECLASS "acf_base_simple"
AddCSLuaFile()

ENT.PrintName     = "ACF Landing Gear"
ENT.WireDebugName = "ACF Landing Gear"
ENT.PluralName    = "ACF Landing Gears"
ENT.IsACFLandingGear = true
ENT.ACF_PreventArmoring = false

-- Maps user var name to its type, whether it is client data and type specific arguments (all support defaults?)
ENT.ACF_UserVars = {
    ["PhysRadius"]      = {Type = "Number",   Min = 4,    Max = 80,  Default = 9,    Decimals = 2, ClientData = true},
    ["ShowModel"]       = {Type = "Boolean",                                                       ClientData = true},
    ["WheelZ"]          = {Type = "Number",   Min = 10,   Max = 256, Default = 45,   Decimals = 2, ClientData = true},
}

-- These are simply for networking these values to the client.
function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "WheelEntity")
    self:NetworkVar("Float", 0, "WheelAngle")
    self:NetworkVar("Bool", 0, "ShowVisualModel")

    if CLIENT then
        self:NetworkVarNotify("WheelEntity", self.CL_OnWheelChanged)
        self:NetworkVarNotify("ShowVisualModel", self.CL_OnShowVisualModelChanged)
    end
end

cleanup.Register("acf_landinggear")

local ACF      		= ACF
local Classes  		= ACF.Classes
local Entities 		= Classes.Entities

local Inputs = {
    "Retract (If != 0, deletes the wheel entity. If 0, respawns)",
    "Angle (Controls the wheels direction, local to the forward direction of the baseplate)",
    "Direction (Controls the wheel rotation for moving a plane slightly. -1 for backwards, 1 for forwards, 0 for no movement)",
    "Brake (If != 0, locks the wheels angular velocity)",
}

if CLIENT then
    function ENT:GetVisualModel()
        return "models/xqm/airplanewheel1.mdl"
    end
    function ENT:CreateDecoy()
        self:RemoveDecoy()
        if not self:GetShowVisualModel() then return end

        local ModelName = self:GetVisualModel()
        if ModelName == nil or #ModelName == 0 then return end

        self.Decoy = ClientsideModel(ModelName)

        self:CallOnRemove("ACF_CleanUpDecoy", function(ent)
            ent:RemoveDecoy()
        end)
        self.Decoy:SetColor(self:GetColor())

        return self.Decoy
    end

    function ENT:Think()
        self:SetNextClientThink(CurTime() + (1 / 60))

        local Decoy = self.Decoy
        local Wheel = self:GetWheelEntity()

        local Decoy_Valid = IsValid(Decoy)
        local Wheel_Valid = IsValid(Wheel)

        if Wheel_Valid and not Decoy_Valid then
            Decoy = self:CreateDecoy(self:GetWheelEntity())
            Decoy_Valid = IsValid(Decoy)
        end

        if Decoy_Valid and Wheel_Valid then
            Decoy:SetPos(Wheel:GetPos())

            local WheelForward = Wheel:GetAngles():Forward()
            local RightAxis = self:GetRight()

            local ProjectedForward = WheelForward - RightAxis * WheelForward:Dot(RightAxis)
            ProjectedForward:Normalize()

            local AncestorForward = self:GetForward()
            local ProjectedAncestorForward = AncestorForward - RightAxis * AncestorForward:Dot(RightAxis)
            ProjectedAncestorForward:Normalize()

            local DotProduct = ProjectedForward:Dot(ProjectedAncestorForward)
            local Angle = math.deg(math.acos(math.Clamp(DotProduct, -1, 1)))

            if ProjectedForward:Cross(ProjectedAncestorForward):Dot(RightAxis) < 0 then
                Angle = -Angle
            end

            local BaseAng = self:LocalToWorldAngles(_G.Angle(0, 90, 0) + _G.Angle(0, self:GetWheelAngle(), Angle))
            Decoy:SetAngles(BaseAng)
        else
            self:SetNextClientThink(CurTime() + (1 / 10))
        end

        return true
    end

    function ENT:RemoveDecoy()
        if IsValid(self.Decoy) then self.Decoy:Remove() end
        self:RemoveCallOnRemove("ACF_CleanUpDecoy")
    end

    function ENT:CL_OnWheelChanged(_, _, New)
        if not IsValid(New) then
            self:RemoveDecoy()
        else
            self:CreateDecoy(New)
        end
    end

    function ENT:CL_OnShowVisualModelChanged(_, _, New)
        if New then
            self:CreateDecoy()
        else
            self:RemoveDecoy()
        end
    end
end

if SERVER then
    local Utilities   	= ACF.Utilities
    local WireIO      	= Utilities.WireIO

    ENT.ACF_Limit                     = 8
    ENT.ACF_KillableButIndestructible = true

    function ENT:ACF_PreSpawn(_, _, _, _)
        self.ACF = {}
        self.ACF.Model = "models/sprops/rectangles/size_2/rect_12x24x3.mdl"
        self:SetModel(self.ACF.Model)
    end

    function ENT:ACF_PostSpawn(Owner, _, _, ClientData)
        WireIO.SetupInputs(self, Inputs)
        self:GetPhysicsObject():SetMass(200)
    end

    function ENT:ACF_PostMenuSpawn(Trace)
        self:SetPos(Trace.HitPos + (Trace.HitNormal * (10 + self.PhysRadius + self.WheelZ)))
        self:SetAngles(self:GetAngles() + Angle(0, -90, 0))
    end

    function ENT:ACF_PostUpdateEntityData(ClientData)
        self:SetShowVisualModel(ClientData.ShowModel)
        self.PhysRadius = ClientData.PhysRadius
        self.WheelZ     = ClientData.WheelZ
        if self.Deployed and self:IsSystemValid() then
            self:DestroySystem()
        end

        self:Deploy()
    end


    function ENT:IsSystemValid()
        return IsValid(self.Wheel) and IsValid(self.RopeV) and IsValid(self.RopeH1) and IsValid(self.RopeH2) and IsValid(self.RopeH3)
    end

    -- When reparented, the base target changes, so the landing gear constraint system must be remade
    function ENT:CFW_OnParentedTo(_, _)
        self:DestroySystem()
        -- I don't like that I have to do this, but I have to do this.
        timer.Simple(0.01, function()
            if IsValid(self) then
                self:CreateSystem()
            end
        end)
    end

    function ENT:CreateSystem()
        self:DestroySystem()

        -- Wheel
        local WheelZ = -self.WheelZ
        local Wheel = ents.Create("prop_physics"); self.Wheel = Wheel; Wheel.DoNotDuplicate = true
        Wheel:SetPos(self:LocalToWorld(Vector(0, 0, WheelZ)))
        --Wheel:SetModel("models/hunter/misc/sphere025x025.mdl")
        Wheel:SetModel("models/hunter/plates/plate025x025.mdl")
        Wheel:Spawn()
        Wheel:CPPISetOwner(self:CPPIGetOwner())
        Wheel:PhysicsInitSphere(self.PhysRadius, "phx_tire_normal")
        Wheel:GetPhysicsObject():SetMass(100)
        Wheel:SetRenderMode(RENDERGROUP_TRANSLUCENT)
        Wheel:SetColor4Part(255, 255, 255, 0)
        Wheel:SetModelScale(1.7)

        -- Determine the physical ancestor.
        -- If unparented, then we use ourselves
        local Physical = self:GetAncestor()
        if not IsValid(Physical) then Physical = self end

        Wheel:SetAngles(Physical:LocalToWorldAngles(Angle(0, 90, 0)))

        Wheel:GetPhysicsObject():SetVelocity(Physical:GetPhysicsObject():GetVelocity())
        Wheel:GetPhysicsObject():SetAngleVelocity(Physical:GetPhysicsObject():GetAngleVelocity())

        constraint.NoCollide(self, Wheel, 0, 0, true).DoNotDuplicate = true

        -- Locals for later
        local VecOffset

        local VisualizeRopes = false
        local RopeV = constraint.Elastic(
            Physical, Wheel, 0, 0,
            -- The position of the wheel local to the physical entity
            Physical:WorldToLocal(self:GetPos()),
            vector_origin,
            50000, 1555, 550, "", VisualizeRopes and 2 or 0
        )
        self.RopeV = RopeV; RopeV.DoNotDuplicate = true

        VecOffset = Vector(200, 0, 0) VecOffset:Rotate(Angle(0, 0, 0)) VecOffset = VecOffset + Vector(0, 0, WheelZ)
        local RopeH1 = constraint.Rope(
            Physical, Wheel, 0, 0,
            -- The position of the wheel local to the physical entity
            VecOffset,
            vector_origin,
            0, 0, 0, VisualizeRopes and 2 or 0
        )
        self.RopeH1 = RopeH1; RopeH1.DoNotDuplicate = true

        VecOffset = Vector(200, 0, 0) VecOffset:Rotate(Angle(0, 120, 0)) VecOffset = VecOffset + Vector(0, 0, WheelZ)
        local RopeH2 = constraint.Rope(
            Physical, Wheel, 0, 0,
            -- The position of the wheel local to the physical entity
            VecOffset,
            vector_origin,
            0, 0, 0, VisualizeRopes and 2 or 0
        )
        self.RopeH2 = RopeH2; RopeH2.DoNotDuplicate = true

        VecOffset = Vector(200, 0, 0) VecOffset:Rotate(Angle(0, 240, 0)) VecOffset = VecOffset + Vector(0, 0, WheelZ)
        local RopeH3 = constraint.Rope(
            Physical, Wheel, 0, 0,
            -- The position of the wheel local to the physical entity
            VecOffset,
            vector_origin,
            0, 0, 0, VisualizeRopes and 2 or 0
        )
        self.RopeH3 = RopeH3; RopeH3.DoNotDuplicate = true

        -- Everything is valid at this point
        self:SetWheelEntity(Wheel)
        self:CallOnRemove("ACF_CleanupLandingGearDeps", function(ent)
            ent:DestroySystem()
        end)
    end

    function ENT:DestroySystem()
        if IsValid(self.Wheel) then
            constraint.RemoveAll(self.Wheel)
            self.Wheel:Remove()
        end

        self.Wheel = nil
        self.RopeV = nil
        self.RopeH1 = nil
        self.RopeH2 = nil
        self.RopeH3 = nil
        self:SetWheelEntity(NULL)
        self:RemoveCallOnRemove("ACF_CleanupLandingGearDeps")
    end

    function ENT:Deploy()
        if self.Deployed and self:IsSystemValid() then return end
        self:CreateSystem()
        self.Deployed = true
    end

    function ENT:Retract()
        if not self.Deployed then return end
        self:DestroySystem()
        self.Deployed = false
    end

    function ENT:GetUserParams()
        local SelfTable = self:GetTable()

        local InAngle = SelfTable.IN_Angle or 0
        local OutAngle = SelfTable.OUT_Angle or 0
        local Delta = InAngle - OutAngle

        local Rate = 45 * engine.TickInterval()

        if math.abs(Delta) <= Rate then
            OutAngle = InAngle
        else
            OutAngle = OutAngle + Rate * (Delta > 0 and 1 or Delta < 0 and -1 or 0)
        end

        if SelfTable.OUT_Angle ~= OutAngle then
            self:SetWheelAngle(OutAngle)
        end
        SelfTable.OUT_Angle = OutAngle

        return OutAngle, SelfTable.IN_Direction or 0, SelfTable.IN_Brake
    end


    local LockingForce = 0.02
    local BrakingForce = 0.15
    function ENT:Think()
        if not self:IsSystemValid() then
            self:NextThink(CurTime() + 0.1)
            return true
        end

        local Ancestor = self:GetAncestor()
        if not IsValid(Ancestor) then Ancestor = self end

        local AncestorPhys = Ancestor:GetPhysicsObject()
        local Wheel = self.Wheel
        if not IsValid(Wheel) then return true end
        local WheelPhys = Wheel:GetPhysicsObject()

        local CurAngle, Direction, Brake = self:GetUserParams()

        if not IsValid(WheelPhys) or not IsValid(AncestorPhys) then
            self:NextThink(CurTime() + 0.1)
            return true
        end

        local WorldAngVel = WheelPhys:LocalToWorldVector(WheelPhys:GetAngleVelocity())
        local LocalAngVel = AncestorPhys:WorldToLocalVector(WorldAngVel)

        local a = math.rad(CurAngle)
        local cosA, sinA = math.cos(a), math.sin(a)

        local lx, ly, lz = LocalAngVel.x, LocalAngVel.y, LocalAngVel.z
        local rx = lx * cosA + ly * sinA
        local ry = -lx * sinA + ly * cosA
        local rz = lz

        rx = rx * LockingForce
        rz = rz * LockingForce
        if Brake then
            ry = rx * BrakingForce
        end
        ry = ry  + (Direction * 30) -- TODO: Scale this number?

        LocalAngVel.x = rx * cosA - ry * sinA
        LocalAngVel.y = rx * sinA + ry * cosA
        LocalAngVel.z = rz

        local AllowedWorldAngVel = AncestorPhys:LocalToWorldVector(LocalAngVel)
        local NewLocalAngVel = WheelPhys:WorldToLocalVector(AllowedWorldAngVel)

        WheelPhys:SetAngleVelocity(NewLocalAngVel)

        self:NextThink(CurTime())
        return true
    end
end

if SERVER then
    ACF.AddInputAction("acf_landinggear", "Retract", function(Entity, Value)
        if tobool(Value) then
            Entity:Retract()
        else
            Entity:Deploy()
        end
    end)
    ACF.AddInputAction("acf_landinggear", "Angle", function(Entity, Value)
        Entity.IN_Angle = -math.Clamp(Value, -45, 45)
    end)
    ACF.AddInputAction("acf_landinggear", "Direction", function(Entity, Value)
        Entity.IN_Direction = math.Clamp(math.Round(Value), -1, 1)
    end)
    ACF.AddInputAction("acf_landinggear", "Brake", function(Entity, Value)
        Entity.IN_Brake = tobool(Value)
    end)
end

Entities.Register()
local Types     = ACF.Classes.BaseplateTypes
local Baseplate = Types.Register("AircraftEx")

local AircraftSimulator_MT_methods = {}
local AircraftSimulator_MT = {__index = AircraftSimulator_MT_methods}
local function AircraftSimulator(BaseplateEnt)
    local Obj = setmetatable({
        Baseplate = BaseplateEnt
    }, AircraftSimulator_MT)

    Obj.LinearForce  = Vector(0, 0, 0)
    Obj.AngularForce = Vector(0, 0, 0)

    Obj:FullUpdateSystem()
    return Obj
end

function AircraftSimulator_MT_methods:FullUpdateSystem()

end

function AircraftSimulator_MT_methods:DetermineForces()

end

function AircraftSimulator_MT_methods:ApplyForces()

end

---
---
---

function Baseplate:OnLoaded()
    self.Name		 = "Aircraft Experiments"
    self.Icon        = "icon16/weather_clouds.png"
    self.Description = "A baseplate designed for aircraft entities (will eventually replace Aircraft). Experimental, don't expect backwards compatibility to work."
end

function Baseplate:OnInitialize()
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
end

function Baseplate:PhysicsCollide(Data)
    local Contraption = self:GetContraption()
    if not Contraption then return end

    if Data.HitEntity:GetContraption() == Contraption then return end
    if Data.Speed > 1000 then
        -- Timer simple to avoid "Changing collision rules within a callback is likely to cause crashes!"
        timer.Simple(0, function()
            local Position = IsValid(self) and self:GetPos() or nil
            for Player in ACF.PlayersInContraptionIterator(Contraption) do
                Player:Kill()
            end
            for Entity in pairs(Contraption.ents) do
                ACF.HEKill(Entity, Data.HitNormal, Data.Speed * 100, Data.HitPos, nil, true)
            end
            if Position then
                ACF.Damage.explosionEffect(Position, Data.HitNormal, 120)
            end
        end)
    end
end

function Baseplate:Think()
    local Simulator = self.Simulator
    if not Simulator then
        Simulator = AircraftSimulator(self)
        self.Simulator = Simulator
    end

    Simulator:DetermineForces()
    Simulator:ApplyForces()

    self:NextThink(CurTime())
    return true
end
include("shared.lua")

DEFINE_BASECLASS "acf_base_scalable"


function ENT:Draw()

    BaseClass.Draw(self)

end

ACF.Classes.Entities.Register()
local Classes         = ACF.Classes
local ControlSurfaces = Classes.ControlSurfaces
local Entries         = Classes.GetOrCreateEntries(ControlSurfaces)

function ControlSurfaces.Register(ID, Base)
	return Classes.AddObject(ID, Base, Entries)
end

Classes.AddSimpleFunctions(ControlSurfaces, Entries)
Classes.AddSboxLimit({
	Name   = "_acf_controlsurface",
	Amount = 16,
	Text   = "Maximum amount of ACF control surfaces a player can create"
})

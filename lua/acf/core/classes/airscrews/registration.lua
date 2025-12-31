local Classes    = ACF.Classes
local Airscrews  = Classes.Airscrews
local Entries    = Classes.GetOrCreateEntries(Airscrews)

function Airscrews.Register(ID, Base)
	return Classes.AddObject(ID, Base, Entries)
end

Classes.AddSimpleFunctions(Airscrews, Entries)
Classes.AddSboxLimit({
	Name   = "_acf_airscrew",
	Amount = 16,
	Text   = "Maximum amount of ACF airscrews a player can create"
})
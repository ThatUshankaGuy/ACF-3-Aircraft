local ACF        = ACF
local Components = ACF.Classes.Components


Components.Register("AIRSCREW", {
	Name   = "Airscrew",
	Entity = "acf_airscrew"
})

Components.RegisterItem("AIRSCREW-ITM", "AIRSCREW", {
	Name        = "Airscrew",
	-- TODO: redo this cause its literally a wikipedia description, also literally stolen from the landing gear files

	Description = "An airscrew converts rotary motion from an engine or other power source into a swirling slipstream which pushes the propeller forwards or backwards.",
	Model       = "models/props_phx/misc/propeller3x_small.mdl",

	CreateMenu = function(Data, Menu)
		local Base = Menu:AddCollapsible("Airscrew Information", nil, "icon16/dvd_edit.png")
	end

})
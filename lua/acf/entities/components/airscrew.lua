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
		local Base			= Menu:AddCollapsible("Airscrew Information", nil, "icon16/dvd_edit.png")
		
		local SizeX = Base:AddSlider("Size", 0.5, 1, 2)
		SizeX:SetClientData("AirscrewSize", "OnValueChanged")
		SizeX:SetValue(1)

		local BladePitch = Base:AddSlider("Blade Pitch", 15, 45, 2)
		BladePitch:SetClientData("BladePitch", "OnValueChanged")
		BladePitch:SetValue(15)

		ACF.SetClientData("Size", 1, true)
		ACF.SetClientData("BladePitch", 15, true)
	end,

})
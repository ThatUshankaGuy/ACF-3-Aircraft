local ACF        = ACF
local Components = ACF.Classes.Components


Components.Register("LAND-GEAR", {
	Name   = "Landing Gear",
	Entity = "acf_landinggear"
})

Components.RegisterItem("LAND-GEAR-ITM", "LAND-GEAR", {
	Name        = "Landing Gear",
	-- TODO: Rewrite this description it kinda sucks
	Description = "An entity which can deploy and retract a suspension load-bearing wheel. Has the ability to move/steer a plane at a slow speed, along with braking.",
	Model       = "models/xqm/airplanewheel1.mdl",
	CreateMenu = function(Data, Menu)
		local Base			= Menu:AddCollapsible("Landing Gear Information", nil, "icon16/dvd_edit.png")

		local _, _, Model   = Base:AddTextEntry("Model")
		Model:SetClientData("WheelModel", "OnValueChange")
		Model.OnLoseFocus = function(self)
			DTextEntry.OnLoseFocus(self)
			self:OnValueChange(self:GetText())
		end
		Model:SetValue("models/xqm/airplanewheel1.mdl")

		local PhysRadius = Base:AddSlider("Phys. Wheel Radius", 4, 80, 2)
		PhysRadius:SetClientData("PhysRadius")
		PhysRadius:SetValue(9)

		local WheelZ = Base:AddSlider("Wheel Height", 10, 256, 2)
		WheelZ:SetClientData("WheelZ")
		WheelZ:SetValue(45)

		local ShowModel = Base:AddCheckBox("Show Model?")
		ShowModel:SetClientData("ShowModel")
		ShowModel:SetValue(true)

		ACF.SetClientData("PhysRadius", 9)
		ACF.SetClientData("ShowModel", true)
		ACF.SetClientData("WheelZ", 45, true)
	end,
})
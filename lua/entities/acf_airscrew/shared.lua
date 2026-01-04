DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName      = "ACF Airscrew"
ENT.WireDebugName  = "ACF Airscrew"
ENT.PluralName     = "ACF Airscrews"
ENT.ACF_Limit      = 8
ENT.ACF_PreventArmoring = true

-- Maps user var name to its type, whether it is client data and type specific arguments (all support defaults?)
-- Code is literally copied over from waterjets, WIP!!

ENT.ACF_UserVars = {
    ["AirscrewSize"] = {Type = "Number", Min = 0.5, Max = 2, Default = 1, Decimals = 2, ClientData = true},
    ["BladePitch"] = {Type = "Number", Min = 15, Max = 45, Default = 15, Decimals = 1, ClientData = true},
    ["SoundPath"] = {Type = "String", Default = "ambient/machines/spin_loop.wav"},
    ["SoundPitch"] = {Type = "Number", Min = 0.1, Max = 2, Default = 1, Decimals = 2},
    ["SoundVolume"] = {Type = "Number", Min = 0.1, Max = 1, Default = 0.2, Decimals = 2},
}

ENT.ACF_WireInputs = {

}

cleanup.Register("acf_airscrew")
eHelicopter_PRESETS = eHelicopter_PRESETS or {}

--- SEE FILE: ExpandedHelicopter_PRESETGUIDE.lua FOR INSTRUCTIONS AND HELP MAKING A SUB-MOD ---

eHelicopter_PRESETS["military"] = {
	announcerVoice = true,
	forScheduling = true,
	crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 5},
	scrapVehicles = {"UH60GreenTail"},
	eventSpawnWeight = 20,
	schedulingFactor = 1.5,
	radioChatter = "AEBS_Military",
	presetProgression = {
		["patrol_only"] = 0,
		["patrol_only_emergency"] = 0.0066,
		["military_recon_hover"] = 0.0070,
		["patrol_only_quarantine"] = 0.0165,
		["attack_only_undead_evac"] = 0.033,
		["attack_only_undead"] = 0.066,
		["cargo_helicopter"] = 0.1900,
		["attack_only_all"] = 0.2145,
	}
}

eHelicopter_PRESETS["patrol_only"] = {
	inherit = {"military"},
}

-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
eHelicopter_PRESETS["patrol_only_emergency"] = {
	inherit = {"military"},
	dropItems = {["EHE.EmergencyFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"patrol_only_emergency", 25, {20,25}, "patrol_only_emergency", 10, {20,25}},
}

eHelicopter_PRESETS["patrol_only_quarantine"] = {
	inherit = {"military"},
	dropItems = {["EHE.QuarantineFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"patrol_only_quarantine", 25, {20,25}, "patrol_only_quarantine", 10, {20,25}},
}

eHelicopter_PRESETS["attack_only_undead_evac"] = {
	announcerVoice = false,
	inherit = {"military"},
	hostilePreference = "IsoZombie",
	radioChatter = "AEBS_PurgeMilitary",
	dropItems = {["EHE.EvacuationFlyer"]=250},
	formationIDs = {"attack_only_undead_evac", 25, {20,25}, "attack_only_undead_evac", 10, {20,25}},--"air_raid",
}

eHelicopter_PRESETS["attack_only_undead"] = {
	inherit = {"military"},
	announcerVoice = false,
	hostilePreference = "IsoZombie",
	radioChatter = "AEBS_PurgeMilitary",
	formationIDs = {"attack_only_undead", 25, {12,17}, "attack_only_undead", 10, {12,17}},--"air_raid",
}


local function hostilePredicateCivilian(target)
	if not target then return end
	local nonCivScore = 0
	---@type IsoPlayer|IsoGameCharacter
	local player = target
	local wornItems = player:getWornItems()
	if wornItems then
		for i=0, wornItems:size()-1 do
			---@type InventoryItem
			local item = wornItems:get(i):getItem()
			if item then
				if string.match(string.lower(item:getFullType()),"army")
						or string.match(string.lower(item:getFullType()),"military")
						or string.match(string.lower(item:getFullType()),"riot")
						or string.match(string.lower(item:getFullType()),"police")
						or item:getTags():contains("Police")
						or item:getTags():contains("Military") then
					nonCivScore = nonCivScore+1
				end
			end
		end
	end
	return nonCivScore<3
end

eHelicopter_PRESETS["attack_only_all"] = {
	inherit = {"military"},
	announcerVoice = false,
	hostilePreference = "IsoGameCharacter",
	hostilePredicate = hostilePredicateCivilian,
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH60GreenTail"},
	radioChatter = "AEBS_HostileMilitary",
	--formationIDs = {"air_raid"},
}

eHelicopter_PRESETS["cargo_helicopter"] = {
	inherit = {"military"},
	announcerVoice = false,
	crashType = false,
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	eventSoundEffects = {
		["flightSound"] = "eMiliHeliCargo",
	},
}

eHelicopter_PRESETS["military_recon_hover"] = {
	inherit = {"military"},
	announcerVoice = false,
	speed = 1.5,
	crashType = false,
	hoverOnTargetDuration = {200,400},
}

eHelicopter_PRESETS["FEMA_drop"] = {
	inherit = {"military"},
	announcerVoice = false,
	forScheduling = true,
	crashType = {"UH60MedevacFuselage"},
	hoverOnTargetDuration = 500,
	dropPackages = {"FEMASupplyDrop"},
	dropItems = {["EHE.QuarantineFlyer"]=150},
	speed = 0.9,
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorMedevac", 1, "Base.ScrapMetal", 5},
	scrapVehicles = {"UH60GreenTail"},
	eventSoundEffects = {
		["foundTarget"] = "eHeli_AidDrop_2",
		["droppingPackage"] = "eHeli_AidDrop_1and3",
	},
	formationIDs = {"patrol_only", 25, {12,17}, "patrol_only", 10, {12,17}},
	radioChatter = "AEBS_SupplyDrop",
	eventStartDayFactor = 0.034,
	eventCutOffDayFactor = 0.2145,
}


eHelicopter_PRESETS["jet"] = {
	speed = 15,
	topSpeedFactor = 2,
	flightVolume = 25,
	eventSoundEffects = {["flightSound"] = "eJetFlight"},
	crashType = false,
	shadow = false,
	eventMarkerIcon = "media/ui/jet.png",
	forScheduling = true,
	schedulingFactor = 4,
	eventSpawnWeight = 5,
	radioChatter = "AEBS_JetPass",
}

eHelicopter_PRESETS["air_raid"] = {
	doNotListForTwitchIntegration = true,
	crashType = false,
	shadow = false,
	speed = 0.5,
	topSpeedFactor = 3,
	flightVolume = 0,
	eventSoundEffects = {["flightSound"]="IGNORE",["soundAtEventOrigin"] = "eAirRaid"},
	eventMarkerIcon = false,
	forScheduling = true,
	flightHours = {11, 11},
	eventSpawnWeight = 50,
	schedulingFactor = 99999,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.067,
	ignoreContinueScheduling = true,
	radioChatter = "AEBS_AirRaid",
}


eHelicopter_PRESETS["jet_bombing"] = {
	inherit = {"jet"},
	doNotListForTwitchIntegration = true,
	--eventSoundEffects = {["flightSound"] = "eJetFlight", ["soundAtEventOrigin"] = "eCarpetBomb"},
	addedFunctionsToEvents = {["OnLaunch"] = eHelicopter_jetBombing},
	flightHours = {12, 12},
	eventSpawnWeight = 50,
	schedulingFactor = 99999,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.067,
	ignoreContinueScheduling = true,
	radioChatter = "AEBS_JetBombing",
}


eHelicopter_PRESETS["news_chopper"] = {
	presetRandomSelection = {"news_chopper_hover", 1, "news_chopper_fleeing", 2, },
	eventSoundEffects = { ["additionalFlightSound"] = "eHeli_newscaster", ["flightSound"] = "eHelicopter", },
	speed = 1,
	crew = {"EHECivilianPilot", "EHENewsReporterVest", "EHENewsReporterVest", 40},
	crashType = {"Bell206LBMWFuselage"},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade1", 2, "EHE.Bell206RotorBlade2", 2,  "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206LBMWTail"},
	forScheduling = true,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	radioChatter = "AEBS_UnauthorizedEntryNews",
}

eHelicopter_PRESETS["news_chopper_hover"] = {
	inherit = {"news_chopper"},
	hoverOnTargetDuration = {750,1200},
}

eHelicopter_PRESETS["news_chopper_fleeing"] = {
	inherit = {"news_chopper"},
	speed = 1.6,
}

eHelicopter_PRESETS["police"] = {
	presetRandomSelection = {"police_heli_emergency",3, "police_heli_firing",2},
	crashType = {"Bell206PoliceFuselage"},
	crew = {"EHEPolicePilot", "EHEPoliceOfficer", "EHEPoliceOfficer", 75},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade1", 2, "EHE.Bell206RotorBlade2", 2,  "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206PoliceTail"},
	announcerVoice = "Police",
	eventSoundEffects = {
		["foundTarget"] = "eHeli_PoliceSpotted",
	},
	forScheduling = true,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	radioChatter = "AEBS_UnauthorizedEntryPolice",
}

eHelicopter_PRESETS["police_heli_emergency"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["additionalFlightSound"] = "eHeliPoliceSiren",
		["flightSound"] = "eHelicopter",
	},

}

eHelicopter_PRESETS["police_heli_firing"] = {
	inherit = {"police"},
	attackDelay = 1700,
	attackSpread = 4,
	speed = 1.0,
	attackHitChance = 95,
	attackDamage = 12,
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["attackSingle"] = "eHeliAlternatingShots",
		["attackLooped"] = "eHeliAlternatingShots",
		["additionalFlightSound"] = "eHeliPoliceSiren",
		["flightSound"] = "eHelicopter",
	},
	hoverOnTargetDuration = {375,575},
}


eHelicopter_PRESETS["samaritan_drop"] = {
	crashType = false,
	crew = {"EHESurvivorPilot", 100, 0},
	dropPackages = {"SurvivorSupplyDrop"},
	speed = 1.0,
	eventMarkerIcon = "media/ui/jet.png",
	eventSoundEffects = {["flightSound"] = "ePropPlane"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	eventSpawnWeight = 3,
	radioChatter = "AEBS_SamaritanDrop"
}


eHelicopter_PRESETS["survivor_heli"] = {
	speed = 1.5,
	crashType = {"Bell206SurvivalistFuselage"},
	crew = {"EHESurvivorPilot", 100, 0, "EHESurvivor", 100, 0, "EHESurvivor", 75, 0},
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade1", 2, "EHE.Bell206RotorBlade2", 2,  "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206SurvivalistTail"},
	forScheduling = true,
	crashType = false,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_SurvivorHeli",
}


eHelicopter_PRESETS["raiders"] = {
	presetRandomSelection = {"raider_heli_passive",3,"raider_heli_harasser",1,"raider_heli_hostile",1},
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH60GreenTail"},
	addedFunctionsToEvents = {["OnFlyaway"] = eHelicopter_dropTrash},
	crew = {"EHERaiderPilot", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaiderLeader", 75, 0},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_Raiders",
}


eHelicopter_PRESETS["raider_heli_passive"] = {
	inherit = {"raiders"},
	speed = 0.5,
	flightVolume = 750,
	crashType = false,
	eventSoundEffects = {
		["flightSound"] = "eMiliHeli",
		["additionalFlightSound"] = "eHeliMusicPassive",
	},
}

eHelicopter_PRESETS["raider_heli_harasser"] = {
	inherit = {"raiders"},
	hoverOnTargetDuration = {450,850},
	speed = 2,
	attackDelay = 1000,
	attackSpread = 4,
	attackHitChance = 70,
	attackDamage = 50,
	flightVolume = 750,
	crashType = false,
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["flightSound"] = "eMiliHeli",
		["attackSingle"] = "eHeliAlternatingShots",
		["attackLooped"] = "eHeliAlternatingShots",
		["additionalFlightSound"] = "eHeliMusicAggressive",
	},
}


eHelicopter_PRESETS["raider_heli_hostile"] = {
	inherit = {"raiders"},
	hoverOnTargetDuration = {650,1500},
	speed = 1.5,
	attackDelay = 650,
	attackSpread = 4,
	attackHitChance = 60,
	attackDamage = 10,
	flightVolume = 750,
	crashType = false,
	hostilePreference = "IsoPlayer",
	eventSoundEffects = {
		["flightSound"] = "eMiliHeli",
		["attackSingle"] = "eHeliAlternatingShots",
		["attackLooped"] = "eHeliAlternatingShots",
		["additionalFlightSound"] = "eHeliMusicAggressive",
	},
}
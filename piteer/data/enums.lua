local enums = {
    quests = {
        pit_ongoing = 0871815152,
        pit_started = 0871922713
    },
    portal_names = {
        guardians_lair = "EGD_MSWK_World_PortalToFinalEncounter",
        demise = "EGD_MSWK_World_PortalTileSetTravel",
        pit_portal = "EGD_MSWK_World_Portal_01",
        belial_portal = "S11_EGD_MSWK_World_BelialPortalToFinalEncounter"
    },
    misc = {
        obelisk = "TWN_Kehj_IronWolves_PitKey_Crafter",
        start_location_0 = "start_location_0",
        start_location = "Start_Location_0",
        traversal_controller = "traversal_footprints_01_fxMesh",
        blacksmith = "TWN_Scos_Cerrigar_Crafter_Blacksmith",
        portal = "TownPortal",
        jeweler = "TWN_Scos_Cerrigar_Vendor_Weapons",
        gizmo_paragon_glyph_upgrade = "Gizmo_Paragon_Glyph_Upgrade"
    },
    positions = {
        obelisk_position = vec3:new(-1659.1735839844, -613.06573486328, 37.2822265625)  ,
        blacksmith_position = vec3:new(-1685.5394287109, -596.86566162109, 37.6484375) ,
        portal_position = vec3:new(-1656.7141113281, -598.21716308594, 36.28515625),
        jeweler_position = vec3:new(-1658.699219, -620.020508, 37.888672),
        gambler_position = vec3:new(-1675.5198974609, -599.21429443359, 36.919921875)

    },
    waypoints = {
        CERRIGAR = 0x76D58,
        LIBRARY = 0x10D63D
    },
    shrines = {
        BLASTWAVE = "Shrine_DRLG_PBAoE",
        PROTECTION = "Shrine_DRLG_Protection",
        CRIT = "Shrine_DRLG_Crit",
        GOLD = "Shrine_DRLG_Gold",
        ARTILLERY = "Shrine_DRLG_Artillery",
        CHANNELING = "Shrine_DRLG_Channeling",
        WITCHPOWER = "S07_Witch_Bonus_Shrine",
        BELIALEYE = "S11_Pit_BetrayersEyeSwitch"
    }
}

return enums

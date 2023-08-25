-- Based on Malik's and Blue's animal shelters and vorp animal shelter, hunting/raising/tracking system added by HAL


Config = {}

Config.Locale = "fr"

Config.Framework = "vorp" -- IMPORTANT: Put either "redem" or "vorp" depending on your framework. VORP users need to also change the Convar in .fxmanifest !!

Config.TriggerKeys = {
    OpenShop = 'E'
}

--The attack command sets your animal to attack a target
Config.AttackCommand = true -- Set true to be able to send your pet to attack a target you are locked on (holding right-click on them)

--<<Only have one of these 3 be true or all 3 false if you want the attack prompt on all targets
Config.AttackOnlyPlayers = false -- The attack command works on only player peds
Config.AttackOnlyAnimals = false -- The attack command works on animal types, not players/peds
Config.AttackOnlyNPC = true -- If this is enabled, you can attack NPC peds and animals but not people
-->>

--The track command sets your animal to follow the selected target 
Config.TrackCommand = true -- If this is enabled, you can send pets to track a target you are locked on

--<<Only have one of these 3 be true or all 3 false if you want the track prompt on all targets
Config.TrackOnlyPlayers = false -- The track command works on only player peds
Config.TrackkOnlyAnimals = false -- The track command works on animal types, not players/peds
Config.TrackOnlyNPC = false -- If this is enabled, you can track NPC peds and animals but not people
-->>


Config.DefensiveMode = false --If set to true, pets will become hostile to anything you are in combat with


Config.NoFear = true --Set this to true if you are using Bears/Wolves as pets so that your horses won't be in constant fear and wont get stuck on the eating dead body animation.

Config.SearchRadius = 100.0 -- How far the pet will search for a hunted animal. Always a float value i.e 50.0
Config.FeedInterval = 1200 -- How often in seconds the pet will want to be fed

Config.RaiseAnimal = true -- If this is enabled, you will have to feed your animal for it to gain XP and grow. Only full grown pets can use commands (halfway you get the Stay command)

Config.FullGrownXp = 500 -- The amount of XP that it is fully grown. At the halfway point the pet will grow to 50% of max size.
Config.XpPerFeed = 20 -- The amount of XP every feed gives
Config.NotifyWhenHungry = true -- Puts up a little notification letting you know your pet can be fed. 
Config.AnimalMaxDifficulty = 5  -- How harder can an animal be to farm
Config.AnimalCouplingDifficulty = 5 -- How rare is the animal coupling event

Config.Shops = {
    {
        Name = 'Ferme',
        Ring = false,
        ActiveDistance = 5.0,
        Coords = {
            vector3(-274.4, 658.75, 113.42)
        },
        Spawnanimal = vector4( -274.4, 658.75, 113.42, 234.45 ),
        Blip = { sprite = 423351566, x = -274.4, y = 658.75, z = 113.42 }
    }
}


Config.Volume = 0

Config.PetAttributes = {
    FollowDistance = 5,
    Invincible = true,
    SpawnLimiter = 1, -- Set this to limit how often a pet can be spawned or 0 to disable it
    DeathCooldown = 300 -- Time before a pet can be respawned after dying
}

-- Pets availability will only be limited if the object exists in the pet config.
Config.Pets = {
    {
        Text = "$200 - Porc",
        SubText = "Porc",
        Desc = "Un gros porc",
        Param = {
            Price = 200,
            Model = "A_C_Pig_01",           -- DON'T TOUCH OR IT DON'T GONNA WORK !
            Level = 1
        },
        Sex = {"Male", "Female"},            -- WRITE WHICH SEX YOU WANT FOR THAT ANIMAL
        CoupleWith = "Porc"
    },
    {
        Text = "$200 - Coq",
        SubText = "Coq",
        Desc = "Un petit coq",
        Param = {
            Price = 200,
            Model = "A_C_rooster_01",           -- DON'T TOUCH OR IT DON'T GONNA WORK !
            Level = 1
        },
        Sex = {"Male"},                       -- WRITE WHICH SEX YOU WANT FOR THAT ANIMAL
        CoupleWith = "Poule"                   -- ANIMAL TYPE WITH WHICH ONE ANIMAL CAN BE IN COUPLE
    },
    {
        Text = "$200 - Poule",
        SubText = "Poule",
        Desc = "Une petite poule",
        Param = {
            Price = 200,
            Model = "A_C_chicken_01",           -- DON'T TOUCH OR IT DON'T GONNA WORK !
            Level = 1
        },
        Sex = {"Female"},                    -- WRITE WHICH SEX YOU WANT FOR THAT ANIMAL
        CoupleWith = "Coq"
    },
}

Config.Keys = { ['G'] = 0x760A9C6F, ["B"] = 0x4CC0E2FE, ['S'] = 0xD27782E3, ['W'] = 0x8FD015D8, ['H'] = 0x24978A28, ['U'] = 0xD8F73058, ["R"] = 0x0D55A0F0, ["ENTER"] = 0xC7B5340A, ['E'] = 0xDFF812F9, ["J"] = 0xF3830D8E }
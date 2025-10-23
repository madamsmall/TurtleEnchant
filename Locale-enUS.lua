--Grab our Locale Library to define our translation
local AceLocale = AceLibrary("AceLocale-2.1")

AceLocale:RegisterTranslation("TurtleEnchant", "enUS", function() return {
	--Options
	Sort = "Sort",
	SortDesc = "Chooses how to sort the enchanting window: Armor or Bonus",

	--Grouping types
	Armor = true,
	Bonus = true,
	
	--Header values
	Unknown = true,
	ArmorBoots = "Boots",
	ArmorBracer = "Bracer",
	ArmorChest = "Chest",
	ArmorCloak = "Cloak",
	ArmorGloves = "Gloves",
	ArmorShield = "Shield",
	ArmorWeapon = "Weapon",
	ArmorOils = "Oils",
	ArmorWands = "Wands",
	ArmorProfs = "Reagents",
	ArmorRods = "Rods",
	ArmorOther = "Other",
	
	BonusAgility = "Agility",
	BonusIntellect = "Intellect",
	BonusSpirit = "Spirit",
	BonusStamina = "Stamina",
	BonusStrength = "Strength",
	BonusDefense = "Defense",
	BonusArmor = "Armor",
	BonusSpellPower = "Spell Power",
	BonusVamp = "Vampirism",
	BonusHealth = "Health",
	BonusMana = "Mana",
	BonusStats = "Stats",
	BonusResistance = "Resistance",
	BonusSpeed = "Speed",
	BonusDamage = "Damage",
	BonusSpecialty = "Specialty",
	BonusProc = "Proc",		
	BonusOils = "Oils",
	BonusWands = "Wands",
	BonusRods = "Rods",
	BonusProf = "Professions",
	BonusReag = "Reagents",
	BonusMisc = "Misc",
}
end)
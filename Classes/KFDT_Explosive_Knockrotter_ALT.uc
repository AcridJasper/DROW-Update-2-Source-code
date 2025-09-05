class KFDT_Explosive_Knockrotter_ALT extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	ObliterationHealthThreshold=-500
	ObliterationDamageThreshold=500

	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=10000
	KDeathUpKick=2000
	KDeathVel=500

	KnockdownPower=150
	StumblePower=350

	// Perks
	ModifierPerkList(0)=class'KFPerk_Gunslinger' // main perk
	ModifierPerkList(1)=class'KFPerk_Berserker'
	ModifierPerkList(2)=class'KFPerk_Commando'
	ModifierPerkList(3)=class'KFPerk_Demolitionist'
	ModifierPerkList(4)=class'KFPerk_FieldMedic'
	ModifierPerkList(5)=class'KFPerk_Firebug'
	ModifierPerkList(6)=class'KFPerk_Sharpshooter'
	ModifierPerkList(7)=class'KFPerk_Support'
	ModifierPerkList(8)=class'KFPerk_Survivalist'
	ModifierPerkList(9)=class'KFPerk_Swat'

	WeaponDef=class'KFWeapDef_Knockrotter'
}
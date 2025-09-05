class KFDT_Slashing_CrucibleET_Heavy extends KFDT_Slashing_ZweihanderHeavy
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=3600 //1600
	KDeathUpKick=400 //200
	KDeathVel=750 //500

	KnockdownPower=100 //150
	StunPower=100
	StumblePower=75
	MeleeHitPower=150

	// Obliteration
	GoreDamageGroup = DGT_Explosive
	RadialDamageImpulse = 8000.f // This controls how much impulse is applied to gibs when exploding
	bUseHitLocationForGibImpulses = true // This will make the impulse origin where the victim was hit for directional gibs
	bPointImpulseTowardsOrigin = true // This creates an impulse direction aligned along hitlocation and pawn location -- this will push all gibs in the same direction
	ImpulseOriginScale = 100.f // Higher means more directional gibbing, lower means more outward (and upward) gibbing
	ImpulseOriginLift = 150.f
	MaxObliterationGibs = 12 // Maximum number of gibs that can be spawned by obliteration, 0=MAX
	bCanGib = true
	bCanObliterate = true
	ObliterationHealthThreshold = 0
	ObliterationDamageThreshold = 100

	DamageModifierAP=0.5f //0.4
	ArmorDamageModifier=7.0f

	WeaponDef=class'KFWeapDef_CrucibleET'
	ModifierPerkList(0)=class'KFPerk_Berserker'
}
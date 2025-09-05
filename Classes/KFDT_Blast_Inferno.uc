class KFDT_Blast_Inferno extends KFDT_Explosive
	abstract
	hidedropdown;

DefaultProperties
{
	KDamageImpulse=3600 //1600
	KDeathUpKick=400 //200
	KDeathVel=750 //500

	// unreal physics momentum
	bExtraMomentumZ=True
	
	KnockdownPower=0
	StunPower=250
	StumblePower=0
	GunHitPower=0
	MeleeHitPower=0

	GoreDamageGroup=DGT_Explosive
	RadialDamageImpulse=8000.f
	ImpulseOriginScale=100.f
	ImpulseOriginLift=150.f
	MaxObliterationGibs=12
	bCanGib=true
	bCanObliterate=true
	ObliterationHealthThreshold=0
	ObliterationDamageThreshold=100

	WeaponDef=class'KFWeapDef_Inferno'
	ModifierPerkList(0)=class'KFPerk_Berserker'
}
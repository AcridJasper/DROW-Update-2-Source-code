class KFDT_Explosive_Healer6 extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	bShouldSpawnPersistentBlood=false

	RadialDamageImpulse=2500
	GibImpulseScale=0.15
	KDeathUpKick=1500
	KDeathVel=500

	KnockdownPower=50
	StumblePower=50

	bExtraMomentumZ=false

	bCanObliterate=false

	ModifierPerkList(0)=class'KFPerk_FieldMedic'

	WeaponDef=class'KFWeapDef_Healer6'
}
class KFDT_Ballistic_C3000 extends KFDT_Ballistic_Submachinegun
	abstract
	hidedropdown;

defaultproperties
{
    KDamageImpulse=900
	KDeathUpKick=-300
	KDeathVel=100

	StumblePower=15
	GunHitPower=30

	WeaponDef=class'KFWeapDef_C3000'
	ModifierPerkList(0)=class'KFPerk_Survivalist'
}
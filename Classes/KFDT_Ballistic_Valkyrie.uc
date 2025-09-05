class KFDT_Ballistic_Valkyrie extends KFDT_Ballistic_Submachinegun
	abstract
	hidedropdown;

defaultproperties
{

	KDamageImpulse=900
	KDeathUpKick=-300
	KDeathVel=100

	StumblePower=10 //15
	GunHitPower=20

	WeaponDef=class'KFWeapDef_Valkyrie'
	ModifierPerkList(0)=class'KFPerk_Survivalist'
}
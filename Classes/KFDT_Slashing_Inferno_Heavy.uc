class KFDT_Slashing_Inferno_Heavy extends KFDT_Slashing_Inferno_Light
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=1600
	KDeathUpKick=200
	KDeathVel=500

	KnockdownPower=0
	StunPower=80 //50
	StumblePower=150
	MeleeHitPower=200

	WeaponDef=class'KFWeapDef_Zweihander'
	ModifierPerkList(0)=class'KFPerk_Berserker'
}
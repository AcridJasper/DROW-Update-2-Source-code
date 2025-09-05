class KFDT_Piercing_Inferno_Stab extends KFDT_Piercing
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=200
	KDeathUpKick=250

	KnockdownPower=0
	StunPower=0
	StumblePower=50
	MeleeHitPower=120

	WeaponDef=class'KFWeapDef_Inferno'
	ModifierPerkList(0)=class'KFPerk_Berserker'
}
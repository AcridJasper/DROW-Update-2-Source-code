class KFDT_Piercing_CrucibleET_Stab extends KFDT_Piercing
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=200
	KDeathUpKick=250

	KnockdownPower=0
	StunPower=5
	StumblePower=50
	MeleeHitPower=100

	DamageModifierAP=0.5f //0.4
	ArmorDamageModifier=7.0f

	WeaponDef=class'KFWeapDef_CrucibleET'
	ModifierPerkList(0)=class'KFPerk_Berserker'
}
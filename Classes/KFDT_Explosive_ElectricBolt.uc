class KFDT_Explosive_ElectricBolt extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=2000//3000
	GibImpulseScale=0.15
	KDeathUpKick=1000
	KDeathVel=300

	KnockdownPower=0
	StumblePower=2

	EMPPower=8 //6
	GoreDamageGroup=DGT_EMP
	// EffectGroup=FXG_Electricity
	
	ModifierPerkList(0)=class'KFPerk_Survivalist'
	WeaponDef=class'KFWeapDef_Nihilanth'
}
class KFDT_Explosive_C3000 extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=3000 //5000 //20000
	GibImpulseScale=0.15
	KDeathUpKick=1000
	KDeathVel=300

	KnockdownPower=8
	StumblePower=25

	WeaponDef=class'KFWeapDef_C3000'
	ModifierPerkList(0)=class'KFPerk_Survivalist'	
}
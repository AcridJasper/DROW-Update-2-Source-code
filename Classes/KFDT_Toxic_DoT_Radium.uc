class KFDT_Toxic_DoT_Radium extends KFDT_Toxic
	abstract
	hidedropdown;

defaultproperties
{
	WeaponDef=class'KFWeapDef_Radium'
	
	//DoT
	DoT_Duration=5.0
	DoT_Interval=1.0
	DoT_DamageScale=0.2

	PoisonPower=35.f
}
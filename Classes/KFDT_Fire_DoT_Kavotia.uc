class KFDT_Fire_DoT_Kavotia extends KFDT_Fire
	abstract
	hidedropdown;

defaultproperties
{
	WeaponDef=class'KFWeapDef_Kavotia'

	DoT_Type=DOT_Fire
	DoT_Duration=5.0
	DoT_Interval=0.5
	DoT_DamageScale=0.4

	BurnPower=25
}
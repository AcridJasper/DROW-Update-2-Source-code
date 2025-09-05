class KFDT_Fire_DoT_Radium extends KFDT_Fire
	abstract
	hidedropdown;

defaultproperties
{
	WeaponDef=class'KFWeapDef_Radium'

	DoT_Type=DOT_Fire
	DoT_Duration=3.0
	DoT_Interval=0.5
	DoT_DamageScale=0.5

	BurnPower=10
}
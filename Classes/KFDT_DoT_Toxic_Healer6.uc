class KFDT_DoT_Toxic_Healer6 extends KFDT_Toxic
	abstract
	hidedropdown;

defaultproperties
{
	DoT_Type=DOT_Toxic
	DoT_Duration=4.0
	DoT_Interval=1.0
	DoT_DamageScale=0.2

	PoisonPower=60 //100
	
	ModifierPerkList(0)=class'KFPerk_FieldMedic'

	WeaponDef=class'KFWeapDef_Healer6'
}
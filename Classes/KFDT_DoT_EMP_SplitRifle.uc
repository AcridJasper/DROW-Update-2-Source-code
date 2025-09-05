class KFDT_DoT_EMP_SplitRifle extends KFDT_EMP
	abstract; //KFDT_Toxic

// static function bool AlwaysPoisons()
// {
// 	return true;
// }

defaultproperties
{
	KDamageImpulse=0

	DoT_Type=DOT_Fire
	DoT_Duration=4.0 //5.0
	DoT_Interval=1.0
	DoT_DamageScale=0.5 //2.0

	// PoisonPower=15 //33
	EMPPower=55
}
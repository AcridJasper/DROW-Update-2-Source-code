class KFDT_Ballistic_Knockrotter_ALT extends KFDT_Ballistic_Rifle
	abstract
	hidedropdown;

static simulated function bool CanDismemberHitZone( name InHitZoneName )
{
	if( super.CanDismemberHitZone( InHitZoneName ) )
	{
		return true;
	}

    switch ( InHitZoneName )
	{
		case 'lupperarm':
		case 'rupperarm':
		case 'chest':
		case 'heart':
	 		return true;
	}

	return false;
}

defaultproperties
{
	KDamageImpulse=2250
	KDeathUpKick=-400
	KDeathVel=250

    KnockdownPower=20
	StunPower=90
	StumblePower=250
	GunHitPower=300

	WeaponDef=class'KFWeapDef_Knockrotter'

	// Perks
	ModifierPerkList(0)=class'KFPerk_Gunslinger' // main perk
	ModifierPerkList(1)=class'KFPerk_Berserker'
	ModifierPerkList(2)=class'KFPerk_Commando'
	ModifierPerkList(3)=class'KFPerk_Demolitionist'
	ModifierPerkList(4)=class'KFPerk_FieldMedic'
	ModifierPerkList(5)=class'KFPerk_Firebug'
	ModifierPerkList(6)=class'KFPerk_Sharpshooter'
	ModifierPerkList(7)=class'KFPerk_Support'
	ModifierPerkList(8)=class'KFPerk_Survivalist'
	ModifierPerkList(9)=class'KFPerk_Swat'
}
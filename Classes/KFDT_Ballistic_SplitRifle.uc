class KFDT_Ballistic_SplitRifle extends KFDT_Ballistic
	abstract
	hidedropdown;

// Damage type to use for the burning damage over time
// var class<KFDamageType> BurnDamageType;

/*
var class<KFDamageType> DoTDamageType;

// Called when damage is dealt to apply additional damage type (e.g. Damage Over Time)
static function ApplySecondaryDamage( KFPawn Victim, int DamageTaken, optional Controller InstigatedBy )
{
    if (default.DoTDamageType.default.DoT_Type != DOT_None)
    {
        Victim.ApplyDamageOverTime(DamageTaken, InstigatedBy, default.DoTDamageType);
    }
}
*/


// Allows the damage type to customize exactly which hit zones it can dismember
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
	 		return true;
	}

	return false;
}

/*
// Play damage type specific impact effects when taking damage
static function PlayImpactHitEffects(KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator)
{
	// Play burn effect when dead
	if (P.bPlayedDeath && P.WorldInfo.TimeSeconds > P.TimeOfDeath)
	{
		default.BurnDamageType.static.PlayImpactHitEffects(P, HitLocation, HitDirection, HitZoneIndex, HitInstigator);
		return;
	}

	super.PlayImpactHitEffects(P, HitLocation, HitDirection, HitZoneIndex, HitInstigator);
}

// Called when damage is dealt to apply additional damage type (e.g. Damage Over Time)
static function ApplySecondaryDamage(KFPawn Victim, int DamageTaken, optional Controller InstigatedBy)
{
	// Overriden to specific a different damage type to do the burn damage over
	// time. We do this so we don't get shotgun pellet impact sounds/fx during
	// the DOT burning.
	if (default.BurnDamageType.default.DoT_Type != DOT_None)
	{
		Victim.ApplyDamageOverTime(DamageTaken, InstigatedBy, default.BurnDamageType);
	}
}
*/

defaultproperties
{
	// EffectGroup=FXG_MicrowaveProj

	KDamageImpulse=550
	GibImpulseScale=0.85
	KDeathUpKick=-200
	KDeathVel=200

	// BurnPower=10
	// MicrowavePower=30

	// BurnDamageType=class'KFDT_Fire_MicrowaveRifleDoT'

	StumblePower=20
	GunHitPower=20

	EffectGroup=FXG_Electricity

	EMPPower=8 //10
    // DoTDamageType=class'KFDT_DoT_EMP_SplitRifle'

	WeaponDef=class'KFWeapDef_SplitRifle'
	ModifierPerkList(0)=class'KFPerk_FieldMedic'
}
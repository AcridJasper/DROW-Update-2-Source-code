class KFDT_Ballistic_Kavotia extends KFDT_Ballistic_Submachinegun
	abstract
	hidedropdown;

// Damage type to use for the burning damage over time
var class<KFDamageType> BurnDamageType;

var ParticleSystem ForceImpactEffect;
var AkEvent ForceImpactSound;

/** Allows the damage type to customize exactly which hit zones it can dismember */
static simulated function bool CanDismemberHitZone(name InHitZoneName)
{
	if (super.CanDismemberHitZone(InHitZoneName))
	{
		return true;
	}

	switch (InHitZoneName)
	{
	case 'lupperarm':
	case 'rupperarm':
	case 'chest':
	case 'heart':
		return true;
	}

	return false;
}

static function PlayImpactHitEffects( KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator )
{
	local KFSkinTypeEffects SkinType;

	if ( P.CharacterArch != None && default.EffectGroup < FXG_Max )
	{
		SkinType = P.GetHitZoneSkinTypeEffects( HitZoneIndex );

		if (SkinType != none)
		{
			SkinType.PlayImpactParticleEffect(P, HitLocation, HitDirection, HitZoneIndex, default.EffectGroup, default.ForceImpactEffect);
			SkinType.PlayTakeHitSound(P, HitLocation, HitInstigator, default.EffectGroup, default.ForceImpactSound);
		}
	}
}

/** Called when damage is dealt to apply additional damage type (e.g. Damage Over Time) */
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

defaultproperties
{
	// BurnPower=12
	GunHitPower=25

	KnockdownPower=0
	StumblePower=25

	BurnDamageType=class'KFDT_Fire_DoT_Kavotia'

	ForceImpactEffect=ParticleSystem'DTest_EMIT.FX_Kavotia_Impact_ZED'
	ForceImpactSound=AkEvent'WW_WEP_HRG_Teslauncher.Play_WEP_HRG_Teslauncher_Shoot_3P'

	WeaponDef=class'KFWeapDef_Kavotia'
	ModifierPerkList(0)=class'KFPerk_Survivalist'
	ModifierPerkList(1)=class'KFPerk_Commando'
}
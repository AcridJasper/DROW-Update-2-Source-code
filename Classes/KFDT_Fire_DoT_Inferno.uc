class KFDT_Fire_DoT_Inferno extends KFDT_Fire
	abstract
	hidedropdown;

var ParticleSystem ForceImpactEffect;

static function PlayImpactHitEffects( KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator )
{
	local KFSkinTypeEffects SkinType;

	if ( P.CharacterArch != None && default.EffectGroup < FXG_Max )
	{
		SkinType = P.GetHitZoneSkinTypeEffects( HitZoneIndex );

		if (SkinType != none)
		{
			SkinType.PlayImpactParticleEffect(P, HitLocation, HitDirection, HitZoneIndex, default.EffectGroup, default.ForceImpactEffect);
		}
	}
}

defaultproperties
{
	WeaponDef=class'KFWeapDef_Inferno'

	DoT_Type=DOT_Fire
	DoT_Duration=3.0
	DoT_Interval=0.5
	DoT_DamageScale=0.4

	BurnPower=40

	ForceImpactEffect=ParticleSystem'DTest_EMIT.FX_Inferno_DoT'
}
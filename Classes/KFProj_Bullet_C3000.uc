class KFProj_Bullet_C3000 extends KFProj_BallisticExplosive
	hidedropdown;

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	ExplosionTemplate.bIgnoreInstigator = true;
}

simulated function bool AllowNuke()
{
    return false;
}

defaultproperties
{
	MaxSpeed=22500
	Speed=22500

	DamageRadius=0

    ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_MuzzleFlash_Null'
    ProjFlightTemplateZedTime=ParticleSystem'DTest_EMIT.FX_SplitRifle_Tracer_ZedTime'

    bCanDisintegrate=false

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=0.5f
		Radius=400.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=60
		DamageRadius=200
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_C3000'

		MomentumTransferScale=10000
		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=150
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionSound=AkEvent'ww_wep_hrg_boomy.Play_WEP_HRG_Boomy_ProjExplosion'
		ExplosionEffects=KFImpactEffectInfo'WEP_C3000_ARCH.C3000_Impacts'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.3

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=300
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}
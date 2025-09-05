class KFProj_Blast_Inferno extends KFProj_Grenade
	hidedropdown;

simulated function bool AllowNuke()
{
    return false;
}

defaultproperties
{
	Physics=PHYS_Falling
	Speed=0
	MaxSpeed=0
	TossZ=0

	FuseTime=0.1

	ProjFlightTemplate=none
	ProjFlightTemplateZedTime=none
    ProjDisintegrateTemplate=none

	// Grenade explosion light
	Begin Object Name=ExplosionPointLight
	    LightColor=(R=245,G=190,B=140,A=255)
		Brightness=3.f
		Radius=1000.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=FALSE
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=200
		DamageRadius=600
		DamageFalloffExponent=2.0f
		DamageDelay=0.f
		MyDamageType=Class'KFDT_Blast_Inferno'

		MomentumTransferScale=0
		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=0.0
		FracturePartVel=0.0
		ExplosionSound=AkEvent'WW_ENV_HellmarkStation.Play_KFTrigger_Activation'
		ExplosionEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Explosions.FragGrenade_Explosion'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.3

		// Camera Shake
		CamShake=KFCameraShake'FX_CameraShake_Arch.Grenades.Molotov'
		CamShakeInnerRadius=250
		CamShakeOuterRadius=400
		CamShakeFalloff=1.f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}
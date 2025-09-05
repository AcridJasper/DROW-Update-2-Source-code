class KFProj_Bullet_Knockrotter_ALT extends KFProj_BallisticExplosive;

defaultproperties
{
	Physics=PHYS_Projectile
	MaxSpeed=23000 //18000
	Speed=23000

	ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_MuzzleFlash_Null'
	ProjFlightTemplateZedTime=ParticleSystem'DTest_EMIT.FX_Healer6_Tracer_ZedTime'

	bCanDisintegrate=false
    // ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	Begin Object Name=CollisionCylinder
		CollisionRadius=6
		CollisionHeight=6
	End Object
	ExtraLineCollisionOffsets.Add((Y=-4))
	ExtraLineCollisionOffsets.Add((Y=4))
	ExtraLineCollisionOffsets.Add((Z=-4))
	ExtraLineCollisionOffsets.Add((Z=4))
	// Since we're still using an extent cylinder, we need a line at 0
	ExtraLineCollisionOffsets.Add(())

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=1.0f
		Radius=850.f
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
		Damage=100
		DamageRadius=500 //300
		DamageFalloffExponent=2
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_Knockrotter_ALT'

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_ZEDMKIII_ARCH.FX_ZEDMKIII_Explosion'
		ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=500
		CamShakeFalloff=3.f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}

/*

class KFProj_Bullet_Knockrotter_ALT extends KFProj_Bullet;

// Explosion actor class to use for ground fire
var const protected class<KFExplosionActor> HitExplosionActorClass;
// Explosion template to use for ground fire
var KFGameExplosion HitExplosionTemplate;

var bool bSpawnOnHitExplosion;

replication
{
	if (bNetInitial)
		bSpawnOnHitExplosion;
}

simulated function PostBeginPlay()
{
	local KFWeap_Knockrotter Cannon;

	if(Role == ROLE_Authority)
	{
		Cannon = KFWeap_Knockrotter(Owner);
		if (Cannon != none)
		{
			bSpawnOnHitExplosion = true;
		}
	}

	super.PostBeginPlay();
}

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local KFExplosionActor GFExplosionActor;
	local vector OnHitExplosionHitNormal;

	if (bSpawnOnHitExplosion)
	{
		OnHitExplosionHitNormal = HitNormal;

		// Spawn our explosion and set up its parameters
		GFExplosionActor = Spawn(HitExplosionActorClass, self, , HitLocation + (HitNormal * 20.f), rotator(HitNormal)); //1
		if (GFExplosionActor != None)
		{
			GFExplosionActor.Instigator = Instigator;
			GFExplosionActor.InstigatorController = InstigatorController;

			// These are needed for the decal tracing later in GameExplosionActor.Explode()
			HitExplosionTemplate.HitLocation = HitLocation;
			HitExplosionTemplate.HitNormal = OnHitExplosionHitNormal;

			// Apply explosion direction
			if (HitExplosionTemplate.bDirectionalExplosion)
			{
				OnHitExplosionHitNormal = GetExplosionDirection(OnHitExplosionHitNormal);
			}

			GFExplosionActor.Explode(HitExplosionTemplate, OnHitExplosionHitNormal);
		}
	}
}

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	local KFExplosionActor GFExplosionActor;
	local vector OnHitExplosionHitNormal;

	if (bSpawnOnHitExplosion)
	{
		OnHitExplosionHitNormal = HitNormal;

		// Spawn our explosion and set up its parameters
		GFExplosionActor = Spawn(HitExplosionActorClass, self, , HitLocation + (HitNormal * 20.f), rotator(HitNormal)); //1
		if (GFExplosionActor != None)
		{
			GFExplosionActor.Instigator = Instigator;
			GFExplosionActor.InstigatorController = InstigatorController;

			// These are needed for the decal tracing later in GameExplosionActor.Explode()
			HitExplosionTemplate.HitLocation = HitLocation;
			HitExplosionTemplate.HitNormal = OnHitExplosionHitNormal;

			// Apply explosion direction
			if (HitExplosionTemplate.bDirectionalExplosion)
			{
				OnHitExplosionHitNormal = GetExplosionDirection(OnHitExplosionHitNormal);
			}

			GFExplosionActor.Explode(HitExplosionTemplate, OnHitExplosionHitNormal);
		}
	}
	
	Super.ProcessTouch(Other, HitLocation, HitNormal);
}

defaultproperties
{
	MaxSpeed=23000 //18000
	Speed=23000

    DamageRadius=0

	ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_MuzzleFlash_Null'
	ProjFlightTemplateZedTime=ParticleSystem'DTest_EMIT.FX_Healer6_Tracer_ZedTime'

	ImpactEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Heavy_bullet_impact'

	Begin Object Name=CollisionCylinder
		CollisionRadius=6
		CollisionHeight=6
	End Object
	ExtraLineCollisionOffsets.Add((Y=-4))
	ExtraLineCollisionOffsets.Add((Y=4))
	ExtraLineCollisionOffsets.Add((Z=-4))
	ExtraLineCollisionOffsets.Add((Z=4))
	// Since we're still using an extent cylinder, we need a line at 0
	ExtraLineCollisionOffsets.Add(())

	HitExplosionActorClass=class'KFExplosionActor'

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=HitExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=1.0f
		Radius=850.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object
	
	// Ground effect
	Begin Object Class=KFGameExplosion Name=ExploTemplate1
		Damage=100
		DamageRadius=500 //300
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_ZedMKIII'

		MomentumTransferScale=10000
		// bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=150
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_ZEDMKIII_ARCH.FX_ZEDMKIII_Explosion'
		ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'

        // Dynamic Light
        ExploLight=HitExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.3

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=300
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	HitExplosionTemplate=ExploTemplate1
}

*/
class KFProj_Rocket_Healer6 extends KFProj_BallisticExplosive
	hidedropdown;

/*
// Our intended target actor
var private KFPawn LockedTarget;
// How much 'stickyness' when seeking toward our target. Determines how accurate rocket is
var const float SeekStrength;

replication
{
	if( bNetInitial )
		LockedTarget;
}

function SetLockedTarget( KFPawn NewTarget )
{
	LockedTarget = NewTarget;
}

simulated event Tick( float DeltaTime )
{
	local vector TargetImpactPos, DirToTarget;

	super.Tick( DeltaTime );

	// Skip the first frame, then start seeking
	if( !bHasExploded
		&& LockedTarget != none
		&& Physics == PHYS_Projectile
		&& Velocity != vect(0,0,0)
		&& LockedTarget.IsAliveAndWell()
		&& `TimeSince(CreationTime) > 0.03f )
	{
		// Grab our desired relative impact location from the weapon class
		TargetImpactPos = class'KFWeap_Healer6'.static.GetLockedTargetLoc( LockedTarget );

		// Seek towards target
		Speed = VSize( Velocity );
		DirToTarget = Normal( TargetImpactPos - Location );
		Velocity = Normal( Velocity + (DirToTarget * (SeekStrength * DeltaTime)) ) * Speed;

		// Aim rotation towards velocity every frame
		SetRotation( rotator(Velocity) );
	}
}
*/

simulated protected function PrepareExplosionTemplate()
{
	local Weapon OwnerWeapon;
	local Pawn OwnerPawn;
	local KFPerk_Survivalist Perk;
	
	super(KFProjectile).PrepareExplosionTemplate();

	// ExplosionTemplate.bIgnoreInstigator = true;

	OwnerWeapon = Weapon(Owner);
	if (OwnerWeapon != none)
	{
		OwnerPawn = Pawn(OwnerWeapon.Owner);
		if (OwnerPawn != none)
		{
			Perk = KFPerk_Survivalist(KFPawn(OwnerPawn).GetPerk());
			if (Perk != none)
			{
				ExplosionTemplate.DamageRadius *= KFPawn(OwnerPawn).GetPerk().GetAoERadiusModifier();
			}
		}
	}
}

simulated function bool AllowNuke()
{
    return false;
}

simulated function bool AllowDemolitionistConcussive()
{
	return false;
}

simulated function bool AllowDemolitionistExplosionChangeRadius()
{
	return false;
}

defaultproperties
{
	Physics=PHYS_Projectile
	Speed=5000 //4000
	MaxSpeed=5000
	TossZ=0
	GravityScale=1.0
    MomentumTransfer=50000.0f
	ArmDistSquared=0

    // SeekStrength=928000.0f  // 128000.0f

	bCollideWithTeammates=true

	bWarnAIWhenFired=true

	ProjFlightTemplate=ParticleSystem'WEP_HRG_Locust_EMIT.FX_HRG_Locust_Projectile'
	ProjFlightTemplateZedTime=ParticleSystem'WEP_HRG_Locust_EMIT.FX_HRG_Locust_Projectile'

	bCanDisintegrate=false
    // ProjDisintegrateTemplate=ParticleSystem'WEP_HRG_Locust_EMIT.FX_Flying_Bugs_dispersion'

	AmbientSoundPlayEvent=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Projectile'
  	AmbientSoundStopEvent=AkEvent'WW_WEP_Seeker_6.Stop_WEP_Seeker_6_Projectile'

	// AltExploEffects=KFImpactEffectInfo'WEP_HRG_MedicMissile_ARCH.HRG_MedicMissile_Explosion'

	ExplosionActorClass=class'KFExplosion_Healer6'

	bCanApplyDemolitionistPerks=false

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=60,G=200,B=255,A=255)
		Brightness=2.f
		Radius=1500.f
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
		Damage=78 //90
		DamageRadius=400
		DamageFalloffExponent=1.5
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_Healer6'

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=0.0
		FracturePartVel=0.0
		ExplosionEffects=KFImpactEffectInfo'WEP_Healer6_ARCH.FX_Healer6_Explosion'
		ExplosionSound=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Explosion'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=200
		CamShakeOuterRadius=900
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}
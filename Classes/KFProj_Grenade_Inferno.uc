class KFProj_Grenade_Inferno extends KFProj_Grenade
	hidedropdown;

var class<KFProjectile> ResidualFlameProjClass;

// Number of lingering fires/fireballs to spawn
var() int NumResidualFlames;

// Sound to play on throw
var AkEvent ThrowAkEvent;

simulated function SpawnFlightEffects()
{
	super.SpawnFlightEffects();

	PlaySoundBase( ThrowAkEvent );
}

// Blow up on impact
simulated event HitWall(vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
	if( StaticMeshComponent(WallComp) != none && StaticMeshComponent(WallComp).CanBecomeDynamic() )
	{
		// pass through meshes that can move (like those little coffee tables in biotics)
		return;
	}

	Explode( Location, HitNormal );
}

// Blow up on impact
simulated function ProcessTouch( Actor Other, Vector HitLocation, Vector HitNormal )
{
	if( Other.bBlockActors )
	{
		// don't explode on players
		if ( Pawn(Other) != None && Pawn(Other).GetTeamNum() == GetTeamNum() )
		{
           return;
		}

		// don't explode on client-side-only destructibles
		if( KFDestructibleActor(Other) != none && KFDestructibleActor(Other).ReplicationMode == RT_ClientSide )
		{
			return;
		}

		Explode( Location, HitNormal );
	}
}

// Overridden to spawn residual flames
simulated function Explode(vector HitLocation, vector HitNormal)
{
	local vector HitVelocity;
	local KFPerk InstigatorPerk;

	local rotator FlareRot;
	
	// velocity is set to 0 in Explode, so cache it here
	HitVelocity = Velocity;

    super.Explode( HitLocation, HitNormal );

    if( Role < Role_Authority )
    {
    	return;
    }

    SpawnResidualFlames( HitLocation, HitNormal, HitVelocity );

    // spawn flare for flarotov
    if( Instigator != none && Instigator.Controller != none )
    {
    	InstigatorPerk = KFPlayerController(Instigator.Controller).GetPerk();
    	if( InstigatorPerk.IsFlarotovActive() )
    	{
    		FlareRot = rotator( HitVelocity );
    		FlareRot.Pitch = 0;
    		Spawn( class'KFProj_MolotovFlare', self,, HitLocation + HitNormal * 20, FlareRot );
    	}
    }
}

// Spawn several projectiles that explode and linger on impact
function SpawnResidualFlames( vector HitLocation, vector HitNormal, vector HitVelocity )
{
	local int i;
	local vector HitVelDir;
	local float HitVelMag;
	local vector SpawnLoc, SpawnVel;

	HitVelMag = VSize( HitVelocity );
	HitVelDir = Normal( HitVelocity );

	SpawnLoc = HitLocation + (HitNormal * 10.f);

	// spawn random lingering fires (rather, projectiles that cause little fires)
	for( i = 0; i < NumResidualFlames; ++i )
	{
		SpawnVel = CalculateResidualFlameVelocity( HitNormal, HitVelDir, HitVelMag );
		SpawnResidualFlame( ResidualFlameProjClass, SpawnLoc, SpawnVel );
	}

	// spawn one where we hit to a flame
	// (we don't give this class a lingering flame because it can hit zeds, and if they die the lingering flame could be left floating)
	SpawnResidualFlame( ResidualFlameProjClass, HitLocation, HitVelocity/3.f );
}

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	ExplosionTemplate.bIgnoreInstigator = true;
}

defaultproperties
{
	bWarnAIWhenFired=true

	FuseTime=10 // orb should only explode on contact, but it's probably good to have a fallback

	Speed=1500 //2000
	TerminalVelocity=1500
	// TossZ=650

	ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_Inferno_Grenade'

	bCanDisintegrate=false
	// ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	ResidualFlameProjClass=class'KFProj_MolotovSplash'
	NumResidualFlames=4

	ThrowAkEvent=AkEvent'WW_Emotes.Play_Emote_Deluxe_SpiritFingers_Shots'

	WeaponSelectTexture=Texture2D'wep_ui_molotov_tex.UI_WeaponSelect_MolotovCocktail'
	// AssociatedPerkClass=class'KFPerk_Firebug'

	ExplosionActorClass=class'KFExplosionActor'

	// dynamic light while airborne
	Begin Object Class=PointLightComponent Name=FlightPointLight
	    LightColor=(R=245,G=190,B=140,A=255)
		Brightness=2.f
		Radius=300.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=FALSE
		bCastPerObjectShadows=false
		bEnabled=TRUE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object
	Components.Add(FlightPointLight)

	Begin Object Class=PointLightComponent Name=FlamePointLight
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
		Damage=150 //120
		DamageRadius=800
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Fire_MolotovGrenade'

		MomentumTransferScale=0
		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'wep_molotov_arch.Molotov_Explosion'
		ExplosionSound=AkEvent'WW_Emotes.Play_Emote_Deluxe_SpiritFingers_Energy_Explosion'

        // Dynamic Light
        ExploLight=FlamePointLight
        ExploLightStartFadeOutTime=0.4
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=KFCameraShake'FX_CameraShake_Arch.Grenades.Molotov'
		CamShakeInnerRadius=250
		CamShakeOuterRadius=400
		CamShakeFalloff=1.f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}
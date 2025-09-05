class KFDT_Explosive_Radium extends KFDT_Explosive
	abstract
	hidedropdown;

/** Custom override that bypasses skin type system for one-off damage types. */
// var ParticleSystem AdditiveEffect;

//Visual class to attach to the victim when impact occurs
// var class<Actor> ParticleAttachClass;

// Damage type to use for the burning damage over time
var class<KFDamageType> BurnDamageType;

// Play damage type specific impact effects when taking damage
static function PlayImpactHitEffects(KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator)
{
/*
	local Actor ParticleAttachment;
    local Vector StickLocation;
    local Rotator StickRotation;
    local name BoneName;
    local WorldInfo WI;
    local KFPawn RetracePawn;
    local Vector RetraceLocation;
    local Vector RetraceNormal;
    local TraceHitInfo HitInfo;

    WI = class'WorldInfo'.static.GetWorldInfo();
    if (P != none && HitZoneIndex > 0 && HitZoneIndex < P.HitZones.Length && WI != none && WI.NetMode != NM_DedicatedServer)
    {
        //Don't play additional FX here if we aren't attaching a new Particle
        //super.PlayImpactHitEffects(P, HitLocation, HitDirection, HitZoneIndex, HitInstigator);

        //Retrace to get valid hit normal
        foreach WI.TraceActors(class'KFPawn', RetracePawn, RetraceLocation, RetraceNormal, HitLocation + HitDirection * 50, HitLocation - HitDirection * 50, vect(0, 0, 0), HitInfo, 1) //TRACEFLAG_Bullet
        {
            if (P == RetracePawn)
            {
                HitLocation = RetraceLocation;
                HitDirection = -RetraceNormal;
                break;
            }
        }

        ParticleAttachment = P.Spawn(default.ParticleAttachClass, P, , HitLocation, Rotator(HitDirection));
        if (ParticleAttachment != none)
        {
            BoneName = P.HitZones[HitZoneIndex].BoneName;
            P.Mesh.TransformToBoneSpace(BoneName, ParticleAttachment.Location, ParticleAttachment.Rotation, StickLocation, StickRotation);
            ParticleAttachment.SetBase(P, , P.Mesh, BoneName);
            ParticleAttachment.SetRelativeLocation(StickLocation);
            ParticleAttachment.SetRelativeRotation(StickRotation);
        }
    }
*/

	// local ParticleSystemComponent ParticleEffect;

	// if( default.AdditiveEffect != none )
	// {
	// 	ParticleEffect = P.WorldInfo.MyEmitterPool.SpawnEmitter( default.AdditiveEffect, HitLocation, rotator(-HitDirection), P );
	// 	ParticleEffect.SetAbsolute(false, true, true);
	// }

	// Play burn effect when dead
	if (P.bPlayedDeath && P.WorldInfo.TimeSeconds > P.TimeOfDeath)
	{
		default.BurnDamageType.static.PlayImpactHitEffects(P, HitLocation, HitDirection, HitZoneIndex, HitInstigator);
		return;
	}

	super.PlayImpactHitEffects(P, HitLocation, HitDirection, HitZoneIndex, HitInstigator);
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
	ObliterationHealthThreshold=-500
	ObliterationDamageThreshold=500

	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=2500//10000
	GibImpulseScale=0.15
	KDeathUpKick=1500//2000
	KDeathVel=500

    // ParticleAttachClass=class'KFWeapActor_ParticleAttach_Radium'
	// OverrideImpactEffect=ParticleSystem'DROW_EMIT.FX_Heat_Orb'

	// AdditiveEffect=ParticleSystem'DTest_EMIT.FX_SuperShield'

	KnockdownPower=225
	StumblePower=400

	BurnDamageType=class'KFDT_Fire_DoT_Radium'

	WeaponDef=class'KFWeapDef_Radium'
}
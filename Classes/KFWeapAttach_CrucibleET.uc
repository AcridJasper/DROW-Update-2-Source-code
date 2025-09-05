class KFWeapAttach_CrucibleET extends KFWeapAttach_SprayBase;

// Particle system
var transient ParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleEffect;

var AkEvent AmbientSoundPlayEvent;
var AkEvent	AmbientSoundStopEvent;

var transient bool bIsMur; 
var const float MurAttackAnimRate;

// Starts playing looping ambient sound
simulated function StartAmbientSound()
{
	if( Instigator != none && !Instigator.IsFirstPerson() )
	{
		if ( AmbientSoundPlayEvent != None )
		{
        	Instigator.PlaySoundBase(AmbientSoundPlayEvent, true, true, true,, true);
		}
    }
}

// Stops playing looping ambient sound
simulated function StopAmbientSound()
{
	if ( AmbientSoundStopEvent != None )
	{
    	Instigator.PlaySoundBase(AmbientSoundStopEvent, true, true, true,, true);
    }
}

simulated function float PlayCharacterMeshAnim(KFPawn P, name AnimName, optional bool bPlaySynchedWeaponAnim, optional bool bLooping)
{
	local float AnimRate;
	local float Duration;
	local EAnimSlotStance Stance;
	local string AnimStr;

	// skip weapon anims while in a special move
	if( P.IsDoingSpecialMove() && !P.SpecialMoves[P.SpecialMove].bAllowThirdPersonWeaponAnims )
	{
		return 0.f;
	}

	Stance = (!P.bIsCrouched) ? EAS_UpperBody : EAS_CH_UpperBody;

	AnimRate = ThirdPersonAnimRate;
	AnimStr = Caps(string(AnimName));

  	if (!bIsMur && (InStr(AnimStr, "ATK") != INDEX_NONE || InStr(AnimName, "COMB") != INDEX_NONE))
	{
		AnimRate *= MurAttackAnimRate;
	}

	Duration = P.PlayBodyAnim(AnimName, Stance, AnimRate, DefaultBlendInTime, DefaultBlendOutTime, bLooping);

	if ( Duration > 0 && bPlaySynchedWeaponAnim )
	{
		PlayWeaponMeshAnim(AnimName, P.BodyStanceNodes[Stance], bLooping);
	}

	`log(GetFuncName()@"called on:"$P@"Anim:"$AnimName@"Duration:"$Duration, bDebug);

	return Duration;
}

// Attach weapon to owner's skeletal mesh
simulated function AttachTo(KFPawn P)
{
    Super.AttachTo(P);

    StartAmbientSound();

	// setup and play the beam charge particle system
	if (ParticlePSC == none)
	{
		ParticlePSC = new(self) class'ParticleSystemComponent';

		if (WeapMesh != none)
		{
			WeapMesh.AttachComponentToSocket(ParticlePSC, 'ParticleFX');
		}
		else
		{
			AttachComponent(ParticlePSC);
		}
	}
	else
	{
		ParticlePSC.ActivateSystem();
	}

	if (ParticlePSC != none)
	{
		ParticlePSC.SetTemplate(ParticleEffect);
		// ParticlePSC.SetAbsolute(false, false, false);
	}
}

simulated function DetachFrom(KFPawn P)
{
    StopAmbientSound();

	if (ParticlePSC != none)
	{
		ParticlePSC.DeactivateSystem();
	}

    Super.DetachFrom(P);
}

simulated function Destroyed()
{
	StopAmbientSound();

	super.Destroyed();
}

defaultproperties
{
	ParticleEffect=ParticleSystem'DTest_EMIT.FX_CrucibleET_ParticleFX'

	AmbientSoundPlayEvent=AkEvent'WW_ENV_BurningParis.Play_ENV_Paris_Underground_LP_01'
	AmbientSoundStopEvent=AkEvent'WW_ENV_BurningParis.Stop_ENV_Paris_Underground_LP_01'

	Begin Object Class=PointLightComponent Name=PilotPointLight0
		LightColor=(R=250,G=0,B=0,A=255)
		Brightness=0.125f
		FalloffExponent=4.f
		Radius=250.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		bEnabled=true
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	PilotLights(0)=(Light=PilotPointLight0,LightAttachBone=LightSource)

	bIsMur=true;
	MurAttackAnimRate=2.2f;
}
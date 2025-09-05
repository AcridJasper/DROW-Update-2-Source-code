class KFWeapAttach_Kavotia extends KFWeapAttach_SprayBase; //KFWeaponAttachment

var AkEvent AmbientSoundPlayEvent;
var AkEvent	AmbientSoundStopEvent;

// Particle system
var transient ParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleEffect;

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
			WeapMesh.AttachComponentToSocket(ParticlePSC, 'MuzzleFlash');
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

// Detach weapon from owner's skeletal mesh
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

// Spawn tracer effects for this weapon
simulated function SpawnTracer(vector EffectLocation, vector HitLocation)
{
	local ParticleSystemComponent PSC;
	local vector Dir;
	local float DistSQ;
	local float TracerDuration;
	local KFTracerInfo TracerInfo;

	if (Instigator == None || Instigator.FiringMode >= TracerInfos.Length)
	{
		return;
	}

	TracerInfo = TracerInfos[Instigator.FiringMode];
	if (((`NotInZedTime(self) && TracerInfo.bDoTracerDuringNormalTime)
		|| (`IsInZedTime(self) && TracerInfo.bDoTracerDuringZedTime))
		&& TracerInfo.TracerTemplate != none )
	{
		Dir = HitLocation - EffectLocation;
		DistSQ = VSizeSq(Dir);
		if (DistSQ > TracerInfo.MinTracerEffectDistanceSquared)
		{
			// Lifetime scales based on the distance from the impact point. Subtract a frame so it doesn't clip.
			TracerDuration = fMin((Sqrt(DistSQ) - 100.f) / TracerInfo.TracerVelocity, 1.f);
			if (TracerDuration > 0.f)
			{
				PSC = WorldInfo.MyEmitterPool.SpawnEmitter(TracerInfo.TracerTemplate, EffectLocation, rotator(Dir));
				PSC.SetFloatParameter('Tracer_Lifetime', TracerDuration);
				PSC.SetVectorParameter('Shotend', HitLocation);
			}
		}
	}
}

defaultproperties
{
	ParticleEffect=ParticleSystem'DTest_EMIT.FX_Kavotia_ParticleFX'

	Begin Object Class=PointLightComponent Name=PilotPointLight0
		LightColor=(R=204,G=0,B=204,A=255)
		Brightness=0.125f
		FalloffExponent=4.f
		Radius=50.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		bEnabled=true
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	PilotLights(0)=(Light=PilotPointLight0,LightAttachBone=LightSource)

	AmbientSoundPlayEvent=AkEvent'WEP_Kavotia_SND.Play_Kavotia_Loop_3P'
	AmbientSoundStopEvent=AkEvent'WEP_Kavotia_SND.Stop_Kavotia_Loop_3P'
}
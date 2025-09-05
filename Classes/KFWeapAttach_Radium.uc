class KFWeapAttach_Radium extends KFWeaponAttachment;

// Effect that happens while charging up the beam
var transient ParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleEffect;

// Attach weapon to owner's skeletal mesh
simulated function AttachTo(KFPawn P)
{
    Super.AttachTo(P);
    
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
		// ParticlePSC.SetTemplate(ParticleEffect);
	}
}

simulated function DetachFrom(KFPawn P)
{
	if (ParticlePSC != none)
	{
		ParticlePSC.DeactivateSystem();
	}

    Super.DetachFrom(P);
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
	ParticleEffect=ParticleSystem'DTest_EMIT.FX_Radium_ParticleFX'
}
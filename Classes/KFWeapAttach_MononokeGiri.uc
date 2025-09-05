class KFWeapAttach_MononokeGiri extends KFWeapAttach_SprayBase; //KFWeaponAttachment;

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

defaultproperties
{
	ParticleEffect=ParticleSystem'DTest_EMIT.FX_MononokeGiri_ParticleFX'

	Begin Object Class=PointLightComponent Name=PilotPointLight0
		LightColor=(R=250,G=150,B=250,A=255)
		Brightness=1.5f
		FalloffExponent=4.f
		Radius=250.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		bEnabled=true
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	PilotLights(0)=(Light=PilotPointLight0,LightAttachBone=ParticleFX)
}
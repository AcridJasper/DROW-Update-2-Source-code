class KFWeapAttach_Valkyrie extends KFWeaponAttachment;

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

defaultproperties
{
	ParticleEffect=ParticleSystem'DTest_EMIT.FX_Valkyrie_ParticleFX'
}
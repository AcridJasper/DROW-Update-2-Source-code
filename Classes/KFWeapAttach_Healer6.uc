class KFWeapAttach_Healer6 extends KFWeaponAttachment;

// Spawn tracer effects for this weapon
simulated function SpawnTracer(vector EffectLocation, vector HitLocation)
{
	local ParticleSystemComponent E;
	local vector Dir;
	local float DistSQ;
	local float TracerDuration;
	local KFTracerInfo TracerInfo;

	if ( Instigator == None || Instigator.FiringMode >= TracerInfos.Length )
	{
		return;
	}

	// only show tracers for ALTFIRE_FIREMODE
	if (Instigator.FiringMode != 1)
	{
		return;
	}

	TracerInfo = TracerInfos[Instigator.FiringMode];
    if( ((`NotInZedTime(self) && TracerInfo.bDoTracerDuringNormalTime)
        || (`IsInZedTime(self) && TracerInfo.bDoTracerDuringZedTime))
        && TracerInfo.TracerTemplate != none )
    {
        Dir = HitLocation - EffectLocation;
		DistSQ = VSizeSq(Dir);
    	if ( DistSQ > TracerInfo.MinTracerEffectDistanceSquared )
    	{
    		// Lifetime scales based on the distance from the impact point. Subtract a frame so it doesn't clip.
			TracerDuration = fMin( (Sqrt(DistSQ) - 100.f) / TracerInfo.TracerVelocity, 1.f );
			if( TracerDuration > 0.f )
			{
	    		E = WorldInfo.MyEmitterPool.SpawnEmitter( TracerInfo.TracerTemplate, EffectLocation, rotator(Dir) );
				E.SetVectorParameter('Shotend', HitLocation);
	 			E.SetFloatParameter( 'Tracer_Lifetime', TracerDuration );
	 		}
    	}
	}
}

defaultproperties
{

}
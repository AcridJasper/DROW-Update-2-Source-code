class KFProj_Bullet_SplitRifle extends KFProj_Bullet
    hidedropdown;

defaultproperties
{
    MaxSpeed=30000
    Speed=30000

    DamageRadius=0

    ProjFlightTemplate=ParticleSystem'DTest_EMIT.FX_MuzzleFlash_Null'
    ProjFlightTemplateZedTime=ParticleSystem'DTest_EMIT.FX_SplitRifle_Tracer_ZedTime'

    ImpactEffects=KFImpactEffectInfo'WEP_Laser_Cutter_ARCH.Laser_Cutter_bullet_impact'
}
return {
    player = {
        -- general
        width = 100,
        height = 150,

        moveDeadzone = 0.25,

        groundProbeWidthFactor = 0.9,
        groundProbeHeight = 0.1,
        groundProbeOffsetY = 0.1,

        interactDistance = 100,
        interactHeightFactor = 0.8,

        animationScale = 0.45,

        animationFrames = {
            run = {{{1, 8}, 1}},
            sneak = {{{1, 6}, 2}},
            idle = {{{7, 8}, 2}},
            attack_side = {{3, 4}},
            attack_up = {{4, 4}},
            attack_down = {{5, 4}},
            dodge = {{6, 4}},
            jumpsquat = {{7, 4}},
            jump = {{8, 4}},
            fall = {{{1, 2}, 4}},
            land = {{1, 5}},
            climbV = {{{5, 8}, 3}},
            climbH = {{{1, 4}, 3}},
            climbVstop = {{5, 3}},
            climbHstop = {{{1, 2}, 3}},
            dash = {{2, 5}},
        },

        animationDurations = {
            idle = 0.8,
            run = 0.7,
            sneak = 0.9,
            fall = 0.6,
        },

        teamColors = {
            attackers = {255, 0, 0},
            defenders = {0, 0, 255},
        },

        -- Wait
        waitFriction = 1000.0, -- units/sec/sec

        -- Run
        walkAccelDur = 0.3, -- sec
        maxWalkSpeed = 300.0, -- units/sec
        sprintAccelDur = 0.7,
        maxSprintSpeedFactor = 3.0,
        runEndSpeed = 10.0,
        runFriction = 2500.0,
        stepInterval = 0.4,

        -- Fall
        fallAccelDur = 0.5,
        maxFallSpeed = 1200.0,
        fastFallThresh = 0.85,
        fastFallFactor = 1.7,
        fallImpactSoundThreshFactor = 0.95,

        airMaxMoveSpeed = 450.0,
        airAcceleration = 400.0,
        airAccelerationMin = 50.0,
        airMaxMoveSpeedFactor = 0.7,
        airFriction = 500.0,

        -- JumpSquat
        jumpSquatFrictionFactor = 2.0,
        jumpSquatDuration = 5/60.0,

        jumpSquatFriction = 800.0,
        jumpStartSpeed = 1500.0,
        shorthopFactor = 0.5,
        jumpMaxMoveSpeed = 1000.0,
        groundToJumpMoveSpeedFactor = 0.5,
        jumpMoveDirSpeed = 150,

        -- Dash
        dashDistance = 600.0,
        dashStartSpeedRemainder = 0.0,
        dashGroundFrictionFactor = 5.0,
        dashDuration = 0.3,
        dashSoundDelay = 0.05,

        -- Parry
        parryDuration = 0.5,
        parryInvinc = 0.2,

        -- Cling
        clingProbeMargin = 5.0,
        clingSpeed = 250.0,
        clingSprintSpeed = 500.0,
        clingDeadzone = 0.5,
        clingWalljumpVel = {500, -1000},
        clingStepInterval = 0.4,

        -- Wavedash
        wavedashFrictionFactor = 12.0,
        wavedashDuration = 0.35,
        wavedashRunoffVelFactor = 0.25,

        -- Attack
        attackGfxInnerRadX = 150,
        attackGfxInnerRadY = 100,
        attackGfxOuterRadX = 200,
        attackGfxOuterRadY = 100,

        attackStartup = 4/60.0,
        attackActive = 4/60.0,
        attackCooldown = 0.25,

        attackImpulse = {
            side = 600,
            up = 300,
            down = 600,
        },

        attackHitbox = {
            0, -100,
            90, -90,
            130, -70,
            180, 0,
            130, 70,
            90, 90,
            0, 100,
        },

        attackData = {
            ground = {
                side = {

                },
                up = {

                },
                down = {

                },
            },
            air = {
                side = {

                },
                up = {

                },
                down = {

                },
            },
        }
    }
}

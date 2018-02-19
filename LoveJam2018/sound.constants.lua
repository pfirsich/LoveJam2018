return {
    sound = {
        occlusionVolumeFactor = 0.6,

        inverseAttenFactor = 0.02,
        logAttenFactor = 0.25,

        masterVolume = 0.7,

        baseVolume = {
            parry = 0.5,
            wavedash = 0.5,
        },

        attenData = {
            default = {
                atten = "log",
                min = 100,
                max = 2000,
            },

            step = {
                min = 0, max = 350,
            },
            shorthop = {
                min = 0, max = 350,
            },
            wavedash = {
                min = 0, max = 300,
            }
        },
    }
}

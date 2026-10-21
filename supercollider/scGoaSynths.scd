
(
SynthDef(\goabass, { |out=0, pan=0, freq=55, sustain=0.5, amp=0.5, cutoff=400, res=2.5, envmod=4|
    var sig, env, filterEnv;

    // Amp env
    env = EnvGen.kr(Env.perc(0.01, sustain), doneAction: 2);
    // Filter env
    filterEnv = EnvGen.kr(Env.perc(0.01, sustain * 0.6));

    // Saw and pulse mix
    sig = Mix([Saw.ar(freq), Pulse.ar(freq * 0.99, 0.4)]) * 0.5;
    // Resonant filter
    sig = MoogFF.ar(sig, (cutoff + (filterEnv * cutoff * envmod)).clip(20, 20000), 0);

    sig = sig * env * amp;
    Out.ar(out, DirtPan.ar(sig, 2, pan));
}).add;
)

(
SynthDef(\goa, { |out = 0, freq = 110, sustain = 0.3, pan = 0, amp = 0.5, cutoff = 200, res = 0.1, envmod = 5000|
    var osc = Saw.ar(freq) + Pulse.ar(freq + 0.5, 0.5);
    var env = EnvGen.ar(Env.perc(0.01, sustain), doneAction: 2);
    var filterEnv = EnvGen.ar(Env.perc(0.01, sustain * 0.4, 1, -5));
    var filter = RLPF.ar(osc, (cutoff + (filterEnv * envmod)).clip(20, 20000), res);

    Out.ar(out, Pan2.ar(filter * env * amp, pan));
}).add;
)

(
SynthDef(\goakick, { |out=0, pan=0, amp=0.8|
    var sig, env, freqEnv;

    env = EnvGen.ar(Env.perc(0.001, 0.25, curve: -2), doneAction: 2);
    freqEnv = EnvGen.ar(Env([3000, 220, 50], [0.005, 0.1], curve: \exp));

    sig = SinOsc.ar(freqEnv);
    sig = (sig * 1.5).clip2(1.0) * env * amp;

    Out.ar(out, DirtPan.ar(sig, 2, pan));
}).add;
)


(
s.options.numBuffers = 1024 * 256;
s.options.memSize = 8192 * 32;
s.waitForBoot {
    ~dirt = SuperDirt(2, s);
    ~dirt.loadSoundFiles;
    s.sync;
    ~dirt.start(57120, 0 ! 12);
}
)
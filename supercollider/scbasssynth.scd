(
Server.default.options.numBuffers = 1024 * 256;
Server.default.options.memSize = 8192 * 32;
Server.default.options.numWireBufs = 64;
Server.default.options.maxNodes = 1024 * 32;
Server.default.options.numOutputBusChannels = 2;
Server.default.options.numInputBusChannels = 2;
)

(
SynthDef(\ysaw, {
    |out, freq=440, sustain=1, pan=0, amp=0.5,
     cutoff=1500, res=0.2, detune=0.015, atk=0.01, rel=0.1,
     drive=1.2, subamp=0.5|

    var sig, env, fenv;

    // Envelopes
    env = EnvGen.ar(Env.linen(atk, sustain, rel), doneAction: 2);
    fenv = EnvGen.kr(Env.perc(atk, sustai÷÷n + rel)) * cutoff + 100;

    // 2 detuned saws + 1 sub oscillator
    sig = Mix([
        Saw.ar(freq * (1.0 - detune)),
        Saw.ar(freq * (1.0 + detune)),
        Pulse.ar(freq * 0.5, 0.5, subamp)
    ]);

    // Moog-style filter
    sig = MoogFF.ar(sig, fenv.clip(20, 18000), 3.5 - (res * 3.5));

    // Analog saturation
    sig = (sig * drive).tanh;

    sig = sig * env * amp * 0.5;
    OffsetOut.ar(out, DirtPan.ar(sig, ~dirt.numChannels, pan));
}).add;
)

(
s.waitForBoot {
    ~dirt = SuperDirt(2, s);
    ~dirt.loadSoundFiles;
	~dirt.loadSoundFiles("/Users/eayavas/Music/Samples/eaykit/*");

    s.sync;
    ~dirt.start(57120, 0 ! 12);
};
)
(
SynthDef(\eay_bass, { |out=0, freq=55, gate=1, cutoff=800, res=0.6, amp=0.5, drive=1.8|
    var drift = LFNoise2.kr(0.5).range(0.997, 1.003);
    var osc1 = Saw.ar(freq * drift);
    var osc2 = Saw.ar(freq * 1.01 * drift);
    var sub = SinOsc.ar(freq * 0.5) * 0.4;

    var mix = ((osc1 + osc2 + sub) * 0.5 * drive).tanh;

    var envF = EnvGen.kr(Env.adsr(0.01, 0.3, 0.2, 0.1), gate);
    var filter = MoogFF.ar(mix, cutoff * (1 + (envF * 2)), res * 4);

    var envA = EnvGen.kr(Env.adsr(0.01, 0.3, 0.8, 0.1), gate, doneAction: 2);
    var sig = (filter * envA * amp * 1.2).softclip;

    Out.ar(out, Pan2.ar(sig, 0));
}).add;
)

(
SynthDef(\eay_bd, { |out=0, freq=50, amp=0.8, attack=0.005, release=0.8, drive=1.5, click=0.05|
    var pitchEnv = EnvGen.ar(Env.new([freq * 6, freq, freq * 0.5], [click, release], -4));
    var sig = SinOsc.ar(pitchEnv);

    var noiseEnv = EnvGen.ar(Env.perc(0.001, click * 2));
    var noise = WhiteNoise.ar(0.03) * noiseEnv;

    var envA = EnvGen.ar(Env.perc(attack, release, 1, -4), doneAction: 2);

    sig = ((sig + noise) * drive).tanh;
    sig = LPF.ar(sig, 800);

    Out.ar(out, Pan2.ar(sig * envA * amp, 0));
}).add;
)

(
SynthDef(\eay_sin, { |out=0, freq=440, attack=0, release=0, amp=0.5, gate=1, wobble=0.8|
    var drift = LFNoise2.kr([0.1, 0.12]).range(0.997, 1.003);
    var phaseMod = SinOsc.kr([wobble, wobble * 1.1]).range(0, 2pi);
    var fm = SinOsc.ar(freq * 0.2) * (freq * 0.05);
    var sig = SinOsc.ar((freq * drift) + fm, phaseMod);
    var env = EnvGen.kr(Env.asr(attack, 1, release), gate, doneAction: 2);

    sig = (sig + (WhiteNoise.ar(0.005) * SinOsc.kr(0.2))) * 1.4;
    sig = sig.softclip;

    Out.ar(out, sig * env * amp);
}).add;
)

(
SynthDef(\microclick, { |out, freq = 440, pan = 0, amp = 1, release = 0.05|
    var sig, env;
    env = EnvGen.ar(Env.perc(0.001, release), doneAction: 2);
    sig = SinOsc.ar(freq) * env;
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;
)

(
SynthDef(\sc_comp, { |out=0, in, ctrl_bus|
    var sig = In.ar(in, 2);
    var ctrl = In.ar(ctrl_bus, 2);

    // threshold: 0.1, slopeAbove: 0.1, clampTime: 0.01, relaxTime: 0.1
    var ducked = Compander.ar(sig, ctrl, 0.1, 1.0, 0.1, 0.01, 0.1);

    ReplaceOut.ar(out, ducked);
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
    ~dirt.soundLibrary.addSynth(\mySaw);
}
)

(
s.waitForBoot({
    var win, view, leftAmp = 0.0, rightAmp = 0.0;
    var numPoints = 80;
    var angles = Array.fill(numPoints, { rrand(0, 2pi) });
    var radii = Array.fill(numPoints, { rrand(20, 150) });
    var speeds = Array.fill(numPoints, { rrand(-0.03, 0.03) });

    win = Window("Generative", Rect(100, 100, 500, 500)).front;
    win.alwaysOnTop = true;
    win.background = Color.black;÷

    view = UserView(win, win.view.bounds);
    view.frameRate = 40;
    view.clearOnRefresh = true;

    view.drawFunc = {
        var center = view.bounds.center;

        Pen.translate(center.x, center.y);

        numPoints.do { |i|
            var r = radii[i] + (leftAmp * 400) + (rightAmp * 400);
            var a = angles[i];
            var x = cos(a) * r;
            var y = sin(a) * r;

            Pen.strokeColor = Color.new255(0, rrand(150, 255), rrand(50, 100), rrand(100, 200));
            Pen.width = rrand(0.5, 2.5);

            Pen.moveTo(0@0);
            Pen.lineTo(x@y);
            Pen.stroke;

            Pen.fillColor = Color.new255(0, 255, 100, rrand(150, 255));
            Pen.addArc(x@y, rrand(1, 4) * (leftAmp + 0.5) * 5, 0, 2pi);
            Pen.fill;

            angles[i] = angles[i] + speeds[i] + ((leftAmp + rightAmp) * 0.05);
        };
    };

    SynthDef(\tidal_art_analyzer, {
        var input = In.ar(0, 2);
        var amp = Amplitude.kr(input, 0.02, 0.15);
        SendReply.kr(Impulse.kr(40), '/tidal_art', amp);
    }).add;

    s.sync;

    OSCdef(\tidal_osc, { |msg|
        leftAmp = msg[3];
        rightAmp = msg[4];
        { view.refresh }.defer;
    }, '/tidal_art');

    win.onClose = {
        OSCdef(\tidal_osc).free;
        ~analyzer.free;
    };

    ~analyzer = Synth(\tidal_art_analyzer, addAction: \addToTail);
});
)

Quarks.folder
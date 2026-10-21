(
// 1. Server Memory Settings
Server.default.options.numBuffers = 1024 * 256;
Server.default.options.memSize = 8192 * 32;
Server.default.options.numWireBufs = 2048;
Server.default.options.maxNodes = 1024 * 32;
Server.default.options.numOutputBusChannels = 2;
Server.default.options.numInputBusChannels = 2;

// 2. Main init block
s.waitForBoot {
    // --- A. INIT SUPERDIRT & LOAD SAMPLES ---
    ~dirt = SuperDirt(2, s);
    
    ~dirt.loadSoundFiles("/Users/eayavas/Music/Samples/eaykit/*");
    ~dirt.loadSoundFiles("/Users/eayavas/Music/Samples/sample/*");

    ~dirt.loadSoundFiles("/Users/eayavas/Music/Samples/DrumKits/*/*", namingFunction: { |path|
        var p = PathName(path);
        var subFolder = p.folderName;
        var parentFolder = PathName(p.parentPath).folderName;
        (parentFolder ++ subFolder).asSymbol;
    });
    
    s.sync; // Wait for samples to load
    ~dirt.start(57120, 0 ! 12);
    
    // --- B. VST HOST & SYNTHDEF ---
    SynthDef(\vstHost, { |out=0|
        var sig = VSTPlugin.ar(nil, 2);
        Out.ar(out, sig);
    }).add;

    s.sync;
	
    // --- C. INIT SURGE XT ---
    ~numInstances = 2;
    ~surgeVsts = Array.newClear(~numInstances);

    ~numInstances.do { |i|
        var synth = Synth(\vstHost); 
        ~surgeVsts[i] = VSTPluginController(synth);
    
        ~surgeVsts[i].open("Surge XT.vst3", action: { |vst|
            var presetPath = "~/Documents/scSynthPresets/surge" ++ i ++ ".vstpreset";
        
            // Load preset if exists, else warn
            if(File.exists(presetPath.standardizePath)) {
                vst.readProgram(presetPath);
                ("Channel " ++ i ++ " preset loaded: " ++ presetPath).postln;
            } {
                ("Preset NOT found (Starting with init): " ++ presetPath).warn;
            };
        });
    };
	
    // --- D. MIDI ROUTER SETUP ---
    MIDIClient.init;
    MIDIIn.connectAll;
    
    ~midiOut = MIDIOut.newByName("IAC Sürücüsü", "Yol 1");
    ~midiOut.latency = 0;
    ~dirt.soundLibrary.addMIDI(\midi, ~midiOut);

    // Route notes to instances
    MIDIdef.noteOn(\vstNoteOn, { |val, num, chan|
        if(chan < ~numInstances) { ~surgeVsts[chan].midi.noteOn(0, num, val) };
    });

    MIDIdef.noteOff(\vstNoteOff, { |val, num, chan|
        if(chan < ~numInstances) { ~surgeVsts[chan].midi.noteOff(0, num, val) };
    });

    // Route CC for FX control
    MIDIdef.cc(\vstCC, { |val, num, chan|
        if(chan < ~numInstances) { ~surgeVsts[chan].midi.control(0, num, val) };
    });
    
    "SuperDirt and Surge XT MIDI succesfully initialized.".postln;
};
)
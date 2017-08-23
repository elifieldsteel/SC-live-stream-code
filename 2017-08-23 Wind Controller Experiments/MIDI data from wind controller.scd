s.boot;

Ndef(\b, {BPF.ar(PinkNoise.ar(0.2!2), 60.midicps, 0.1, 2)}).fadeTime_(5).play

(
Ndef(\b, {
	var sig;
	sig = PinkNoise.ar(0.2!2);
	2.do{sig = BPF.ar(sig, ([50,62,65,67,72,74,86]-2).midicps, 0.03, 15)};
	sig = sig * LFSaw.kr({[2,3,4,6].choose}!6).exprange(0.01,1);
	sig = Splay.ar(sig.scramble);
	sig = sig.blend(FreeVerb.ar(sig, 1), 0.5);
}).fadeTime_(3)
)

Ndef(\b).clear(10);

//////////////////////////////////

MIDIClient.init;
MIDIIn.connectAll;

(
s.freeAll;
s.newBusAllocators;
~bus = Dictionary.new;
~bus.add(\delay -> Bus.audio(s, 2));
~bus.add(\reverb -> Bus.audio(s, 2));

s.waitForBoot({
	SynthDef(\varsawWX7, {
		arg freq=440, detune=0, width=0.5, amp=1, gate=1,
		atk=0.08, dec=0.2, sus=0.5, rel=0.1, out=0;
		var sig, env;
		env = Env.adsr(atk, dec, sus, rel).kr(2,gate);
		// sig = PinkNoise.ar(1!2);
		// 2.do{sig = BPF.ar(sig, (freq * detune.midiratio).lag(0.02), 0.03, 6)};
		sig = 10.collect({
			VarSaw.ar(
				freq * Rand(-0.25,0.25).midiratio,
				Rand(0.0,1.0),
				width.lag(0.02),
				0.5
			);
		});
		sig = Splay.ar(sig);
		sig = RLPF.ar(sig, 5000, 0.5);
		sig = sig * env * amp.lag(0.02);
		Out.ar(out, sig);
	}).add;

	SynthDef(\delay, {
		arg in=0, out=0, delay=0.3, decay=2, mix=0.5;
		var sig;
		sig = In.ar(in, 2);
		sig = XFade2.ar(
			sig,
			CombN.ar(sig, 1, delay, decay),
			mix*2-1
		);
		Out.ar(out, sig);
	}).add;

	SynthDef(\reverb, {
		arg in=0, out=0, revTime=2.5, mix=0.2;
		var sig;
		sig = In.ar(in, 2);
		sig = XFade2.ar(
			sig,
			GVerb.ar(sig, 99, revTime),
			mix*2-1
		);
		Out.ar(out, sig);
	}).add;

	s.sync;

	~sourceGroup = Group.new;
	~delayGroup = Group.after(~sourceGroup);
	~reverbGroup = Group.after(~delayGroup);
	~delaySynth = Synth(\delay, [\in, ~bus[\delay], \out, ~bus[\reverb]], ~delayGroup);
	~reverbSynth = Synth(\reverb, [\in, ~bus[\reverb], \out, 0], ~reverbGroup);

	/*
	x = Synth(\varsaw, [\freq, 60, \amp, 1])
	x.set(\width, 0.96);
	x.set(\amp, 1);
	x.set(\gate, 0);
	*/

	~notes = Array.newClear(128);

	MIDIdef.noteOn(\on, {
		arg vel, nn, chan, src;
		//("note on: "++[nn, vel]).postln;
		~notes[nn] = Synth(
			\varsaw,
			[
				\freq, nn.midicps,
				\amp, ~breath.linexp(0,127,0.1,0.4),
				\width, (~breath+1).explin(1,128,0.5,0.95),
				\out, ~bus[\delay],
			], ~sourceGroup
		);
	});

	MIDIdef.noteOff(\off, {
		arg vel, nn, chan, src;
		//("note off: "++[nn, vel]).postln;
		~notes[nn].set(\gate, 0);
		~notes[nn] = nil;
	});

	MIDIdef.cc(\cc, {
		arg val, num, chan, src;
		//("cc: "++[num, val]).postln;
		~breath = val; //0 to 127
		~notes.do({
			arg synth;
			if(synth.notNil, {
				synth.set(\width, (~breath+1).explin(1,128,0.5,0.98).postln);
				synth.set(\amp, ~breath.linexp(0,127,0.1,0.4));
			}
			);
		});
	}, 2);

	MIDIdef.bend(\bend, {
		arg val, chan, src;
		("bend: "++val).postln;
		~bend = val.linlin(0,14302,-12,12); //0 to 16384
		// ~notes.do({
		// 	arg synth, i;
		// 	if(synth.notNil, {synth.set(\detune, ~bend)});
		// });
	}).disable;
});
)

~delaySynth.set(\mix, 0.2);

~notes.do(_.free);
s.freeAll;







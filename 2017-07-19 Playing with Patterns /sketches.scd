(
Buffer.freeAll;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;

//busses
~bus = Dictionary.new;
~bus.add(\reverb -> Bus.audio(s, 2));

s.waitForBoot({

	//buffers
	b = PathName.new("/Users/eli/Sounds/scaudio/mandel/").makeBufDict;
	g = PathName("/Users/eli/Sounds/scaudio/glitch/").makeBufDict;

	s.sync;

	//synthdefs
	SynthDef(\reverb, {
		arg in=60, out=0, amp=1, mix=0.06, lpf=5000, revTime=2.5, preDel=0.05;
		var wet, dry, temp, sig;
		mix = mix.clip(0,1);
		dry = In.ar(in, 2);
		temp = In.ar(in, 2);
		wet = 0;
		temp = DelayN.ar(temp, preDel, preDel);
		16.do{
			temp = AllpassN.ar(temp, 0.06, {Rand(0.001,0.06)}!2, revTime);
			temp = LPF.ar(temp, lpf);
			wet = wet + temp;
		};
		sig = XFade2.ar(dry, wet, mix*2-1, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\k, {
		arg freqA=800, freqB=50, freqC=40, freqDur1=0.02, freqDur2=0.5, freqC1=(-3), freqC2=(-1),
		atk=0.02, rel=2, c1=1, c2=(-12), amp=1, pan=0, out=0;
		var sig, freqSweep, env;
		freqSweep = Env([freqA, freqB, freqC],[freqDur1,freqDur2],[freqC1,freqC2]).ar;
		env = Env([0,1,0],[atk,rel],[c1,c2]).kr(2);
		sig = SinOsc.ar(freqSweep, pi/2);
		sig = sig * env;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\beep, {
		arg freq=1000, atk=0.001, sus=0.06, rel=0.001, c1=1, c2=(-1),
		amp=1, pan=0, out=0;
		var sig, env;
		env = Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]).kr(2);
		sig = SinOsc.ar(freq);
		sig = sig * env;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\play, {
		arg atk=0.001, sus=0.2, rel=0.06, c1=1, c2=(-1),
		buf=0, rate=1, spos=0, amp=1, pan=0, out=0;
		var sig, env;
		env = Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]).kr(2);
		sig = PlayBuf.ar(1, buf, rate, startPos:spos);
		sig = sig * env;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\loopBuf, {
		arg buf, rate=1, start=0, freq=200,
		atk=2, sus=2, rel=2, c1=1, c2=(-1),
		cfLo=500, cfHi=1000, rqLo=0.15, rqHi=0.5,
		panDev=0.25, ampMin=0.4, pan=0, amp=0.5, out=0;
		var sig, phs, env, cf, rq, panCtrl, ampCtrl;
		env = Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]).kr(2);
		phs = Phasor.ar(0, rate, start, start + (SampleRate.ir/freq));
		sig = BufRd.ar(1, buf, phs);
		cf = LFDNoise1.kr(LFNoise1.kr(8).exprange(0.1,0.8)).exprange(cfLo, cfHi);
		rq = LFDNoise1.kr(LFNoise1.kr(8).exprange(0.1,0.8)).exprange(rqLo, rqHi);
		sig = RLPF.ar(sig, cf, rq);
		sig = sig * env;
		panCtrl = LFDNoise1.kr(LFNoise1.kr(12).exprange(0.5,1.5)).bipolar(panDev);
		sig = Pan2.ar(sig, pan + panCtrl, amp);
		ampCtrl = LFDNoise1.kr(LFNoise1.kr(12).exprange(0.1,0.5)).exprange(ampMin,1);
		sig = sig * ampCtrl;
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\varsawSus, {
		arg	freq=40, detune=0.2, atk=0.05, rel=1, cAtk=1, cRel=(-4), gate=1,
		dutyLo=0.001, dutyHi=0.999, freqRandLo=0.1, freqRandHi=0.3, rq=0.2,
		lpfA=5000, lpfB=200, lpfC=100, lpfAtk=0.05, lpfRel=1, lpfC1=(-3), lpfC2=(-2),
		lpfMul=1, lpfAdd=0, amp=1, pan=0, out=0, thresh=(-6), ratio=8;
		var	sig, temp, env;
		sig = 0;
		env = Env([0,1,1,0],[atk,0,rel],[cAtk,0,cRel],2).kr(2,gate);
		4.do{
			temp = VarSaw.ar(
				freq * LFNoise1.kr({Rand(freqRandLo,freqRandHi)}!2).bipolar(detune).midiratio,
				Rand(0.0, 1.0),
				ExpRand(dutyLo,dutyHi)
			);
			temp = RLPF.ar(
				temp,
				Env([lpfA,lpfB,lpfB,lpfC],[lpfAtk,0,lpfRel],[lpfC1,0,lpfC2],2).ar(0,gate,1,lpfMul,lpfAdd),
				rq
			);
			temp = temp * 0.1;
			sig = sig + temp;
		};
		sig = sig * env;
		sig = Balance2.ar(sig[0], sig[1], pan, amp);
		sig = Compander.ar(sig, sig, thresh.dbamp, 1, 1/ratio);
		sig = sig.tanh;
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\varsawPerc, {
		arg	freq=40, detune=0.2, atk=0.05, sus=0, rel=1, cAtk=1, cRel=(-4), gate=1,
		dutyLo=0.001, dutyHi=0.999, freqRandLo=0.1, freqRandHi=0.3, rq=0.25,
		lpfA=5000, lpfB=200, lpfC=100, lpfAtk=0.05, lpfSus=0, lpfRel=1, lpfC1=(-3), lpfC2=(-2),
		lpfMul=1, lpfAdd=0, amp=1, pan=0, out=0, thresh=(-6), ratio=8;
		var	sig, temp, env;
		sig = 0;
		env = Env([0,1,1,0],[atk,sus,rel],[cAtk,0,cRel]).kr(2);
		4.do{
			temp = VarSaw.ar(
				freq * LFNoise1.kr({Rand(freqRandLo,freqRandHi)}!2).bipolar(detune).midiratio,
				Rand(0.0, 1.0),
				ExpRand(dutyLo,dutyHi)
			);
			temp = RLPF.ar(
				temp,
				Env([lpfA,lpfB,lpfB,lpfC],[lpfAtk,lpfSus,lpfRel],[lpfC1,0,lpfC2]).ar(0,1,1,lpfMul,lpfAdd),
				rq
			);
			temp = temp * 0.1;
			sig = sig + temp;
		};
		sig = sig * env;
		sig = Balance2.ar(sig[0], sig[1], pan, amp);
		sig = Compander.ar(sig, sig, thresh.dbamp, 1, 1/ratio);
		sig = sig.tanh;
		Out.ar(out, sig);
	}).add;

	s.sync;

	//manual merge of two dictionaries
	//merge these in OS eventually to use only one makeBufDict method call
	b.add(\glitch -> g[\glitch]);
	ServerTree.add({~reverb = Synth(\reverb, [\in, ~bus[\reverb]])});
	s.freeAll;
});
)

//----------
//2017-07-19

~reverb.set(\mix, 0.05)

Synth(\k, []);
Synth(\beep, []);

Synth(\play, [\buf, b[\glitch].choose, \sus, 1, \amp, 0.2, \pan, rrand(-0.5,0.5)]);

Synth(\loopBuf, [\buf, b[\breath].choose, \start, 40000, \freq, 50]);

x = Synth(\varsawSus, [\freq, 100, \detune, 0.2, \lpfA, 5000, \lpfB, 100, \lpfC, 300, \lpfAtk, 0.2, \lpfRel, 1, \lpfC1, -10, \lpfC2, -1]);
x.set(\gate, 0);

Synth(\varsawPerc, []);

[ 49, 56, 59, 64 ].midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.5, \lpfMul, 0, \lpfAdd, exprand(300,600), \freq, n, \atk, 4, \rel, 4])}

[ 45, 59, 61, 68 ].midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.5, \lpfMul, 0, \lpfAdd, 400, \freq, n, \atk, 4, \rel, 4])}

[ 44, 59, 63, 66 ].midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.5, \lpfMul, 0, \lpfAdd, 400, \freq, n, \atk, 4, \rel, 4])}

[ 43, 55, 57, 59, 64 ].midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.5, \lpfMul, 0, \lpfAdd, 400, \freq, n, \atk, 4, \rel, 4])}

[ 42, 54, 59, 61, 63 ].midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.5, \lpfMul, 0, \lpfAdd, 400, \freq, n, \atk, 4, \rel, 4])}



~bpm = 110;
t = TempoClock.new(~bpm/60);
t.beatDur;
t.schedAbs(t.beats.ceil, {(((t.beats*(~bpm/60))%4)+1).postln; t.beatDur})
t.clear

t.beats2secs;

(
Pdef(\glitchBase, Pbind(
	\instrument, \play,
	#[dur,amp], Pwrand([
		Ptuple([
			Pseq([1/16], 16),
			Pseq([0.8, Pexprand(0.03,0.08,15)],1),
		], 1),
		Ptuple([
			Pseq([Pseq([1/24],3),Pseq([1/8],7)],1),
			Pseq([Pexprand(0.45,0.5,1), Pexprand(0.02,0.08,3), 0.9, Pexprand(0.02,0.2,5)],1),
		], 1),
		Ptuple([
			Pseq(({exprand(0.01,0.5)}!16).normalizeSum,1),
			Pseq([0.9, Pshuf([0.7]++({exprand(0.02,0.08)}!14),1)],1),
		],1),
	], [1,0,0], inf),
	/*
	\dur, Pwrand([
		Pseq([1/16],8) * Pseq([5/4,4/5],4),
		Pseq([Pseq([1/24],3), Pseq([1/16],6)],1),
	], [0.5,0.5], inf),
	*/
	\stretch, 2,
	\atk, 0,
	\sus, Pwhite(0.01,0.1,inf),
	\rel, Pexprand(0.001,0.2,inf),
	\c1, 1,
	\c2, -1,
	\buf, Pxrand(scramble(b[\glitch]).at([2]),inf),
	//\freq, Prand([1, \],inf),
	\rate, 1,
	\spos, Pwhite(0,100,inf),
	\pan, Pwhite(-0.25,0.25,inf),
	\out, Prand([~bus[\reverb], 0], inf),
)).quant_([1]);
)

({rrand(20,30.0)}!4).midicps.do{arg n; Synth(\varsawPerc, [\detune, 2, \amp, exprand(0.4,0.5), \lpfMul, 0, \lpfAdd, exprand(300,600), \dutyLo, 0.4, \dutyHi, 0.6, \freq, n, \atk, 8, \rel, rrand(6,15)])}

(
Pdef(\beepPat, Pbind(
	\instrument, \beep,
	\dur, Pseq([1/16],inf),
	\stretch, 2,
	\freq, Prand([
		Pseq([1000, 1000, Pseq([\],14)],1) * Prand([1,2],inf),
		Pseq([1000, Pseq([\],2), 1000, Pseq([\],12)],1),
		Pseq([\],16),
	],inf) * 1,
	\sus, Pwhite(0.015,0.025,inf),
	\rel, 0.0,
	\amp, Prand([0.1,0.2,0.25]*2,inf),
	\pan, Pwrand([0,-0.8,0.8,Pwhite(-1.0,1.0,1)],[0.3,0.1,0.1,0.5],inf),
)).quant_([1]);
)

Pdef(\glitchBase).stop;
Pdef.all.do(_.stop);


~reverb.set(\mix, 0.25)




















//----------
//2017-07-16
(
//edit for fixed-duration envelope
Pdef(\loopBuf0, Pbind(
	\instrument, \loopBuf,
	\dur, Pexprand(0.3,1,inf),
	\buf, Pxrand(b[\breath].collect(_.bufnum),inf),
	\start, Pexprand(10000,100000,inf),
	\freq, Pexprand(100,1200,inf).round(100)/2,
	\rate, Pwhite(-0.2,0.2,inf).midiratio,
	\atk, Pexprand(2,4,inf),
	\dec, 0,
	\slev, 1,
	\rel, Pexprand(6,10,inf),
	\cAtk, 1,
	\cDec, -1,
	\cRel, -1,
	\gate, 1,
	\sustain, 0.5,
	\cfLo, Pkey(\freq),
	\cfHi, Pkey(\freq)*4,
	\rqLo, 0.07,
	\rqHi, 0.1,
	\pan, 0,
	\panDev, 0.2,
	\amp, Pexprand(0.4,0.8,inf),
	\ampMin, 0.6,
	\out, 0
)).play;
)

(
Pdef(\loopBuf1, Pbind(
	\instrument, \loopBuf,
	\dur, Pseq([
		Pseq([0.001],5),
		Pwhite(6,9,1),
	],inf),
	\buf, Pxrand(b[\breath].collect(_.bufnum),inf),
	\start, Pexprand(10000,20000,inf),
	//\midinote, Prand(30+Scale.minor.degrees, inf) + Prand([-12,0,12,24],inf),
	\freq, Pexprand(20,80,inf),
	\ctranspose, 0,
	\rate, Pwhite(-0.1,0.1,inf).midiratio,
	\atk, Pexprand(3,6,inf),
	\sus, 0,
	\rel, Pexprand(6,10,inf),
	\cAtk, 4,
	\cRel, -1,
	\cfLo, Pkey(\freq),
	\cfHi, Pkey(\freq)*2,
	\rqLo, 0.1,
	\rqHi, 0.2,
	\pan, 0,
	\panDev, 0.8,
	\amp, Pexprand(0.2,0.5,inf),
	\ampMin, 0.6,
	\out, 0
)).play;
)

Pdef(\loopBuf1).stop;


s.defaultGroup.set(\rel, 10, \gate, 0);







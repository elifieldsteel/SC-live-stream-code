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

	SynthDef.new(\wn, {
		arg lpf=20000, hpf=20, lrq=1, hrq=1,
		atk=0.001, sus=0.02, rel=0.001, c1=0, c2=0,
		pan=0, amp=1, out=0;
		var sig, env;
		env = Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]).kr(2);
		sig = WhiteNoise.ar;
		sig = RLPF.ar(sig, lpf, lrq);
		sig = RHPF.ar(sig, hpf, hrq);
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
//2017-07-26
t = TempoClock.new(80/60).permanent_(true);
t.beats;
t.stop;
Pbindef.all.do(_.stop);

~postClockInfo = {};

(
~postClockInfo = {
	("beat :"+((t.beats.floor)%t.beatsPerBar + 1)).postln;
	("bar  :"+(t.bar)).postln;
	"".postln;
	1; //do this every beat
};

t.schedAbs(
	t.nextBar,
	{
		~postClockInfo.value;
	}
);
)

(
Pbindef(\glitchMetro,
	\instrument, \play,
	\dur, Pwrand([Pseq([1/8],8), Pseq([1/4],4), Pseq([1/2],2)],[0.96,0.03,0.01],inf),
	\buf, Pwrand([
		Pseq([b[\glitch][42]],32), //default 42
		Prand(b[\glitch],4)
	],[0.45,0.55],inf),
	\pan, Pwrand([Pseq([0],16),Pseq([-1,1],1),Pwhite(-1.0,1.0,8)],[0.8,0.1,0.1],inf),
	\amp, Pseq([Pexprand(0.1,0.4,1),Pexprand(0.001,0.08,1)],inf),
	\sus, Pexprand(0.003,0.06),
	\rel, 0.001,
	\spos, Pexprand(1,500)-1,
	\rate, Pwrand([
		Pwrand([1,Pwhite(2.5,4,1),Pwhite(0.5,0.9,1)],[0.96,0.02,0.02],32),
		Pseq([2],8),
		Pseq([4],8),
	],[0.9,0.05,0.05],inf),
	\out, ~bus[\reverb]
).play(t).quant_(4);
)

(
Pbindef(\doubleBeep,
	\instrument, \beep,
	\dur, 1/8,
	\freq, Pwrand([
		Pseq([
			Prand([
				Pseq([\,\,\,\,Pstutter(2,Prand([1000,2500,4500],1)),\,\],1),
				Pseq([Pstutter(2,Prand([1000,2500,4500],1)),\,\,\,\,\,\],1),
			],1),
			\,\,\,\,\,\,\,\,
			\,\,\,\,\,\,\,\,
			\,\,\,\,\,\,\,\,
		],1),
		Pseq([\],32),
	],
	[0.7,0.3],inf),
	\pan, Pwrand([Pseq([0],32),Pwhite(-1.0,1.0,4)],[0.7,0.3],inf),
	\amp, Pseq([Pwhite(0.1,0.15,1), Pwhite(0.03,0.07,1)],inf),
	\atk, Pwhite(0,0.002),
	\sus, Pwhite(0.015,0.03),
	\rel, 0.001,
	\out, ~bus[\reverb],
).play(t).quant_(4)
)

(
Pbindef(\wn0,
	\type, Pseq([
		Pseq([\rest],8),
		Pseq([\note],4),
		Pseq([\rest],4),
	],inf),
	\instrument, \wn,
	\dur, 1/4,
	\pan, Pwrand([0,-1,1,Pwhite(-0.5,0.5,1)],[0.9,0.02,0.02,0.06],inf),
	\amp, Pwrand([
		Pshuf([Pexprand(0.06,0.12,1),0,0,0],1),
		Pseq([0],4),
	],[0.9,0.1],inf),
	\hpf, Pexprand(50,15000,inf),
	\hrq, Pwhite(0.05,0.5,inf),
	\atk, 0,
	\sus, (t.beatDur)/(Prand([2,4,8,12,16],inf)),
	\rel, 0,
	\out, ~bus[\reverb],
).play(t).quant_(4)
)

(
Pbindef(\sub0,
	\instrument, \beep,
	\dur, 2,
	\freq, Pseq([
		Pwrand([Prand([35,40,45,50],1),\],[0.2,0.8],1),
		Pseq([\],3),
	],inf),
	\amp, 0.32,
	\atk, Pwhite(0,0.002),
	\sus, t.beatDur * Prand([3,2,2.5],inf),
	\rel, 0.001,
	\out, ~bus[\reverb],
).play(t).quant([4]);
)

(
Pbindef(\glitchRattle16,
	\type, Pwrand([
		Pseq([\note],16),
		Pseq([\rest],16),
	],[0.2,0.8],inf),
	\instrument, \play,
	\dur, 1/16,
	\buf, Pstutter(16,Prand([9,14,18].collect({arg n; b[\glitch][n]}),inf)),
	\pan, Pseq([-1,1],inf)*0.9,
	\amp, Pseq([Pgeom(0.8,0.75,16)],inf) * Pwhite(1.2,1.5,inf),
	\sus, 0.004,
	\rel, Pwhite(0.005,0.008),
	\spos, Pstutter(16, Pwhite(0,1000,inf)),
	\rate, Prand([0.5,1],inf),
	\out, ~bus[\reverb]
).play(t).quant_(1);
)

(
Pbindef(\glitchRattle8,
	\type, Pwrand([
		Pseq([\note],8),
		Pseq([\rest],8),
	],[0.15,0.85],inf),
	\instrument, \play,
	\dur, 1/8,
	\buf, Pstutter(8,Prand([20].collect({arg n; b[\glitch][n]}),inf)),
	\pan, Pwhite(-0.3,0.3),
	\amp, Pseq([Pgeom(0.9,0.5,8)],inf) * Pwhite(0.8,1.2,inf),
	\sus, 0.004,
	\rel, Pwhite(0.005,0.008),
	\spos, Pstutter(8, Pwhite(0,500,inf)),
	\rate, Prand([0.5,1],inf),
	\out, ~bus[\reverb],
).play(t).quant_(1);
)

(
Pbindef(\glitchSwitch,
	\instrument, \play,
	\dur, Prand([1/2,3/4],inf),
	\buf, Pseq({b[\glitch].choose.bufnum}!2,inf),
	\pan, Pwrand([
		Pseq([-0.7,0.7],1),
		Pseq([0],1),
	],[0.7,0.3],inf),
	\amp, 0.55,
	\atk, 0,
	\sus, 0.05,
	\rel, 0,
	\spos, 0,
	\rate, Pseq([1,1],inf),
	\out, ~bus[\reverb],
).play(t).quant_(1);
)

Pbindef(\glitchSwitch).stop;
Pbindef(\beepSwitch).stop;

(
Pbindef(\beepSwitch,
	\type, Pwrand([\note,\rest],[0.75,0.25],inf),
	\instrument, \beep,
	\dur, Prand([1/4,1/2,3/4],inf),
	\freq, Pseq([rrand(5000,9000),1100],inf),
	\pan, Pwrand([
		Pseq([-0.7,0.7],1),
		Pseq([0],1),
	],[0.7,0.3],inf),
	\amp, 0.2,
	\atk, 0.001,
	\sus, 0.05,
	\rel, 0.02,
	\out, ~bus[\reverb],
).play(t).quant_(4);
)

(
Pbindef(\k0,
	\instrument, \k,
	\dur, Pseq([3/8],12),
	\rel, 1,
	\freqA, 2000,
	\freqDur1, 0.01,
	\amp, Pgeom(0.5,0.6,12),
	\out, ~bus[\reverb],
).playOnce(t,quant:4);
)

(
Pbindef(\sawMel0,
	\instrument, \varsawPerc,
	\dur, Pwrand([
		Pseq([3/4],3),
		Pseq([1/4],3),
		Pseq([4],1),
	],[0.45,0.45,0.1],inf),
	\midinote, Prand([
		Pseq([50,53,55],1),
		Pseq([57,64,67],1),
	],inf)+Pwhite(-0.1,0.1,inf) + Pstutter(3, Prand([12,0,-12],inf)),

	\lpfA, Pkey(\midinote).midicps * 2,
	\lpfB, 300,//Pkey(\midinote).midicps * 1,
	\lpfAtk, Pexprand(0.02,2,inf),
	\lpfC1, Pwhite(-2,-1,inf),
	\amp, 0.2,
	\atk, 0,
	\sus, 0.2,
	\rel, Pseq([4,4,12],inf)*t.beatDur*0.5,
	\cRel, -2,
	\dutyLo, 0.5,
	\dutyHi, 0.5,
	\out, ~bus[\reverb]
).play(t).quant_(4)
)

Pbindef(\sawMel0).stop;
Pbindef(\wn0).stop;
Pbindef(\sub0).stop;
Pbindef(\doubleBeep).stop;
Pbindef(\glitchMetro).stop;
Pbindef(\glitchRattle16).stop;
Pbindef(\glitchRattle8).stop;

([30,30,30,30]-4).midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.2, \lpfMul, 0, \lpfAdd, 400, \freq, n, \atk, t.beatDur*4, \sus, t.beatDur*4, \rel, t.beatDur*4, \c2, -1, \c1, 1])}

Pbindef(\glitchRattle8).clear;
Pbindef.all.do(_.stop);

Pbindef(\glitchMetro).stop;
Pbindef(\glitchMetro).play(t).quant_(4);


//----------
//2017-07-19

~reverb.set(\mix, 0.05)

Synth(\k, []);
Synth(\beep, []);

Synth(\play, [\buf, b[\glitch].choose, \sus, 1, \amp, 0.2, \pan, rrand(-0.5,0.5)]);

Synth(\loopBuf, [\buf, b[\breath].choose, \start, 40000, \freq, 50]);

x = Synth(\varsawSus, [\freq, 100, \detune, 0.2, \lpfA, 5000, \lpfB, 100, \lpfC, 300, \lpfAtk, 0.2, \lpfRel, 1, \lpfC1, -10, \lpfC2, -1]);
x.set(\gate, 0);

Synth(\varsawPerc, [\freq, 50.midicps, \out, ~bus[\reverb]]);

[ 49, 56, 59, 64 ].midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.5, \lpfMul, 0, \lpfAdd, exprand(300,600), \freq, n, \atk, 4, \rel, 4])}

[ 45, 59, 61, 68 ].midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.5, \lpfMul, 0, \lpfAdd, 400, \freq, n, \atk, 4, \rel, 4])}

[ 44, 59, 63, 66 ].midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.1, \lpfMul, 0, \lpfAdd, 400, \freq, n, \atk, 4, \rel, 4])}

[ 43, 55, 57, 59, 64 ].midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.5, \lpfMul, 0, \lpfAdd, 400, \freq, n, \atk, 4, \rel, 4])}

[ 30, 42, 54, 59, 61, 63 ].midicps.do{arg n; Synth(\varsawPerc, [\detune, 0.1, \amp, 0.5, \lpfMul, 0, \lpfAdd, 400, \freq, n, \atk, 4, \rel, 4])}



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







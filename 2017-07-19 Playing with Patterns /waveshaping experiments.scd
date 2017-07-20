s.boot;

(
var signal, len=256; //must be power of 2
Window.closeAll;
Buffer.freeAll;
s.waitForBoot({
	~wavetableBuf = Buffer.alloc(s,len,1);
	~signalBuf = Buffer.alloc(s,len/2+1,1);

	s.sync;

	//identity transform function
	signal = Signal.newClear(len/2+1).waveFill({
		arg x,y,i;
		var val;
		val = i.linlin(0,len/2,-1,1);
		val = val + rrand(-1.0,1.0);
		val = val.fold(-1,1);
	},0,2pi);

	/*
	//eight lowest harmonics w random amplitudes and random initial phases
	signal = Signal.sineFill(len/2+1, [1]++({exprand(0.1,1)}!7), {rrand(0,2pi)}!8);
	*/

	/*
	//funky sin/cos wrapping function
	signal = Signal.newClear(len/2+1).waveFill({
	arg x,y,i;
	var val;
	val = sin(x) + cos(x*pi/2).wrap(x/2pi.neg,x/2pi);
	4.do(val = (val * val.sign).squared* val.sign);
	val.clip(-1,1);
	},0,2pi);
	*/

	~wavetableBuf.loadCollection(signal.asWavetableNoWrap);
	~signalBuf.loadCollection(signal);

	s.sync;

	~signalBuf.plot("signal");
	~wavetableBuf.plot("wavetable");

});
)

~signalBuf.numFrames;
~wavetableBuf.numFrames;

(
{
	var sig, index;
	index = LFSaw.ar(40);
	sig = Shaper.ar(~wavetableBuf.bufnum, index * MouseX.kr(0,1).poll)!2;
	sig = sig * 0.5
}.play
)

s.scope;
FreqScope.new;

(
{
	var sig;
	sig = Shaper.ar(b.bufnum, Saw.ar([30,60.5], LFNoise1.kr(0.2!2).exprange(0.1,2)));
	1.do{sig = Shaper.ar(b.bufnum, sig)};
	sig = LeakDC.ar(sig)*0.5;
	sig = Compander.ar(sig, sig, 0.2, 1, 1/8);
}.play
)

(-1,-0.9..1).collect({arg n; (n*n.sign).sqrt*n.sign})


(
Buffer.freeAll;
b = Buffer.alloc(s, 1024, 1, {
	arg buf;
	buf.setn(
		0, Array.fill(1024, {
			arg i;
			var val;
			val = i.linlin(0,1023,-1.0,1.0);
			rrand(val.neg,val);
		});
	);
});
)

(
Buffer.freeAll;
b = Buffer.alloc(s, 1024, 1).loadCollection(
	Array.fill(1024, {
		arg i;
		var val;
		val = i.linlin(0,1023,-1.0,1.0);
		(val.cubed/10) + rrand(val*0.1.neg,val*0.1);
	}), 0
).normalize(1,true);
)

(
{
	var sig;
	sig = Shaper.ar(b.bufnum, LFSaw.ar(MouseX.kr(1,100,1),0, MouseY.kr(0.01,1,1)))
}.play
)

s.scope


b.plot

b.plot


a.waveFill({ arg x, old, i; x.linlin(0,2pi,-1,1)}, 0, 2pi);
a.waveFill({ arg x, old, i; old.squared},0,2pi);
a.waveFill({ arg x, old, i; old * (x % 4) }, 0, 3pi);
a.plot;

(
a = Signal.fill(1024, { |i|
	sin(i.linlin(0,1023,0,2pi));
});
b.asWavetable(
)


b = Buffer.alloc(s, 1024, 1);

b.sendCollection(a.asWavetableNoWrap);
b.plot
(
{Shaper.ar(b, SinOsc.ar(440, 0, Line.kr(0,1,7)))}.scope
)

b = Buffer.alloc(s, 1024, 1);
e = Env.new([0]++({rrand(-1.0,1.0)}!31)++[0],{rrand(0.01,0.1)}!32, {rrand(-2,2.0)}!32).asSignal(512);
b.sendCollection(e.asWavetableNoWrap);
b.plot;
e.plot;
(
{LeakDC.ar(Shaper.ar(b, Saw.ar(LFPulse.kr(1/4,0,0.5).range(7,14), MouseX.kr(0.01,1,1)!2)))*0.7}.scope
)


{LFSaw.ar(1,-1)}.scope
FreqScope.new;

{SinOsc.ar(10000,0,XLine.kr(0.8,0.01,0.05,doneAction:2))}.play(fadeTime:0);

s.record;
s.stopRecording
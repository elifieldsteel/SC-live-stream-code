//----------
//2017-08-02

s.boot;

//start with a zero-filled Signal instance
~sig = Signal.newClear(513);

(
//post values, return existing signal values (no change to signal)
~sig.waveFill({
	arg x, y, i;
	[x,y,i].postln;
	y
}, 0, 1);
)

~sig.plot; //take a look

(
//fill signal with linear ramp from -1 to 1
~sig.waveFill({
	arg x, y, i;
	i.linlin(0,512,-1,1);
}, 0, 1);
)

~sig.plot;

(
//inverted linear ramp
~sig.waveFill({
	arg x, y, i;
	i.linlin(0,512,1,-1);
}, 0, 1);
)

~sig.plot;

(
//linear ramp from -1 to 1, then cube each value twice
~sig.waveFill({
	arg x, y, i;
	i.linlin(0,512,1,-1).cubed.cubed;
}, 0, 1);
)

~sig.plot;

(
//trigonometric stuff - simple sine wave transfer function
~sig.waveFill({
	arg x, y, i;
	sin(x)
}, 0, 2pi) //note the new domain
)

~sig.plot;

(
//more complex trigonometric expression
~sig.waveFill({
	arg x, y, i;
	sin(x.squared) + cos(x.sqrt);
}, 0, 2pi)
)

~sig.plot;

(
//generate a signal using the sineFill method
~sig = Signal.sineFill(
	513,
	1/[1,2,3,4,5,6,7,8].scramble, //random order of fractional amplitudes
	{rrand(0,2pi)}!8 //random initial phases for all eight harmonics
);
)

~sig.plot;

(
//add random value to 10% of existing signal values
~sig.waveFill({
	arg x, y, i;
	if(0.1.coin, {(y + rrand(-0.5,0.5)).fold(-1,1)}, {y});
});
)

~sig.plot;

(
//generate a Signal from an Env
~env = Env.new(
	{rrand(-1.0,1.0)}!11,
	{exprand(0.01,2)}!10,
	{rrand(-5.0,5.0)}!10
);
)

~env.plot;

~sig = ~env.asSignal(513); //discretize Env into 513 values, convert to signal

//signals need to be converted to wavetable format to be used by Shaper UGen:

~w = ~sig.asWavetableNoWrap; //make sure to use "noWrap" method

~w.plot; //looks different, but this is normal

//can fill a Wavetable directly with a sum of chebyshev polynomials
~w = Wavetable.chebyFill(513, 1/[1,2,3,4,5].scramble);

~w.plot;

//wavetables must be loaded into Buffers to be used on the audio server:
~b = Buffer.loadCollection(s, ~w);
~b.plot;

(
~synth = {
	var sig, index;
	index = LFSaw.ar(500);
	//index = LFTri.ar(500);
	//index = SinOsc.ar(500);
	//try other indices if you like

	//horizontal mouse position = index amplitude control = portion of wavetable that is indexed and output by Shaper
	index = index * MouseX.kr(0.001,1,1);

	sig = Shaper.ar(~b.bufnum, index);

	//waveshaping in sequence
	//2.do{sig = Shaper.ar(~b.bufnum, sig)};

	//remove DC offset
	sig = LeakDC.ar(sig);

	Out.ar(0, sig * 0.1);

	//visualize index (need s.options.numOutputBusChannels = 4; and reboot)
	//if using s.scope;
	//Out.ar(2, index*0.05);
}.play;
)

s.scope;

~synth.free;

//----------
//2017-07-26

~wt = Dictionary.new;

~sig = Signal.newClear(513);
~sig.plot;

(
~sig.waveFill({
	arg x, y, i;
	[x,y,i].postln;
	i.linlin(1,513,-1,5).fold(-1,1);
}, 0, 1);
)

(
~sig.waveFill({
	arg x, y, i;
	[x,y,i].postln;
	sin(x.squared) - (2*tanh(x.sqrt));
}, 0, 2pi);
~sig = ~sig[0..256]++~sig[0..255].reverse;
)

~sig.plot;
~w = ~sig.asWavetableNoWrap;
~w.plot;
b = Buffer.loadCollection(Server.local, ~w);
b.plot

(
x = {
	var index, sig, amp, freq;
	amp = MouseX.kr(0.001,5,1).poll;
	//freq = MouseY.kr(395,405).poll;
	freq = [70,70];
	index = LFSaw.ar(freq,0,amp);
	//index = index * LFSaw.kr([2,2.5]).exprange(0.3,1);
	Out.ar(2, index);
	sig = Shaper.ar(b.bufnum, index, 0.5);
	sig = LeakDC.ar(sig);
}.play;
)

s.scope;

(
SynthDef(\shape, {
	arg freq=70, amp=1;
	var index, sig;
	index = LFSaw.ar(freq, 0, amp);
	sig = Shaper.ar(b.bufnum, index)*0.5;
	sig = LeakDC.ar(sig);
	Out.ar(0, sig!2);
}).add;
)

(
p = Pmono(\shape,
	\dur, Pexprand(0.01,0.4),
	\freq, Pexprand(20,1000),
	\amp, Pexprand(0.3,5),
).play
)


(
//20 segment random
Window.closeAll;
~wt.add(\0 -> Buffer.loadCollection(s,
	{
		var sig;
		sig = Env.new(
			{rrand(-1.0,1.0)}!21,//levels
			{exprand(0.01,2)}!20,//times
			{rrand(-5,0.5)}!20//curves
		).asSignal(513);
		/*
		//averaging function?
		sig.waveFill({
		arg x, old, i;
		var new;
		new = sig[i];
		20.do({
		arg n;
		new = (new + sig[(i+n+1)%512])/2;
		});
		new;
		});
		sig = sig.rotate(20);
		*/
		sig = sig.normalize;
		sig;
	}.value.asWavetableNoWrap;
));
)

(
//few low harmonics with noise bursts
Window.closeAll;
~wt.add(\1 -> Buffer.loadCollection(s,
	{
		var sig, mod;
		sig = Signal.sineFill(513,([1]++({rrand(0.001,0.05)}!15).sort), [0]++({rrand(0,2pi)}!15));
		mod = Array.fill(rrand(2,5),Array.fill(exprand(4,40).round, 1));
		mod = mod++Array.fill(513-mod.size, 0);
		mod = mod.scramble.flat;
		sig.waveFill({
			arg x, old, i;
			if(mod[i] == 1, {(old + rrand(-0.5,0.5)).fold(-1,1)}, {old})
		});
		sig = sig.normalize;
		sig;
	}.value.asWavetableNoWrap;
));
)


(
~wt[\1].plot;
s.scope;
{
	var sig, index;
	index = LFSaw.ar([40,41]);
	sig = Shaper.ar(~wt[\1].bufnum, index * MouseX.kr(0,1).poll);
	sig = sig.lag(20/SampleRate.ir);
	sig = sig * 0.5
}.play
)

[0,1,2,3,4,5,6,7,8,9]

e.plot;

[0,1,2,3,4,5,6,7].collect({arg n, i;

	a.waveFill({ arg x, old, i; x.linlin(0,2pi,-1,1)}, 0, 2pi);
	(
		var signal, len=512; //must be power of 2
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
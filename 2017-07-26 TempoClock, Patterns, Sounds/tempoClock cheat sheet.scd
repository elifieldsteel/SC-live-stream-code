t = TempoClock.new; //create new tempoclock, default tempo = 1 beat per sec

t.beats; //check current beat

t.stop; //stop and destroy the instance
t.beats; //error message if previously stopped

//permanence
t = TempoClock.new;
t.permanent; //command period will stop/destroy the clock
t.beats; //error

t = TempoClock.new;
t.permanent_(true); //command period will have no effect on the clock
t.beats; //still counting
t.stop;

//permanence can be set on creation
t = TempoClock.new.permanent_(true);
t.stop;

//scheduling
t = TempoClock.new;

//schedule an event (function) some number of beats in the future
t.sched(5, {"relative schedule time".postln});

//schedule an event (function) at a specific future beat
t.schedAbs(175, {"absolute scheduled time".postln});
t.beats;

//if the scheduled function returns a number, it will be rescheduled that many beats later
t.sched(5, {"relative".postln; 2});
t.clear;

//unscheduling a specific recurring scheduled function
~f = {"hello".postln;1};
t.sched(5, ~f);
~f = {}; //doesn't work, ~f as the scheduled function was evaluated by the interpreted
t.clear;

~f = {"hello".postln;1};
t.sched(5, {~f.value}); //instead, a function which evaluates a user-defined function
~f = {}; //works

//first argument of new sets tempo in bps
t = TempoClock.new(2); //2 beats per sec, or 120 bpm
t.beats;
t = TempoClock.new(108/60); //108 bpm
t.beats;

//printing beat/bar info for TempoClock:
t.beats; //current beat
t.beats.floor; //most recent beat
t.beats.ceil; //next beat
t.beatInBar.postln; //current beat within an arbitrary bar
(t.beats - t.beatInBar).postln; //most recent downbeat
t.bar; //most recent bar number
(t.bar*4).postln; //most recent bar in beats
t.nextBar.postln; //next bar in beats

//easy way to use the post window as a beat/bar counter:
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

//sixteenth notes
~postClockInfo = {
	("beat :"+(round((t.beats)%t.beatsPerBar + 1,0.25))).postln;
	("bar  :"+(t.bar)).postln;
	"".postln;
	0.25; //do this every beat
};

~postClockInfo = {}; //unschedule

t.clear;
t.nextBar;

//instantaneously change tempo
t.tempo_(108/60);

//scheduled tempo change
(
t.schedAbs(
	t.nextBar, //next bar
	{t.tempo_(108/60)}
);
)

//nextTimeOnGrid
t.clear;

//default args give next beat
(
("beats:"+t.beats).postln;
("next beat:"+t.nextTimeOnGrid).postln;
""
)

//quant:beatsPerBar gives next downbeat
(
("beats:"+t.beats).postln;
("next beat:"+t.nextTimeOnGrid(t.beatsPerBar)).postln;
""
)

//quant:beatsPerBar, phase:1 gives next beat 2nd beat of a measure
(
("beats:"+t.beats).postln;
("next beat:"+t.nextTimeOnGrid(t.beatsPerBar, 1)).postln;
""
)

//patterns

(
Pbindef(\wn,
	\instrument, \wn,
	\dur, Pseq([1/8],8),
	\amp, 0.1,
	\hpf, Pgeom(10000,0.7,8),
	\hrq, 0.2,
	\out, ~bus[\reverb],
).playOnce(t, quant:[4,0]);
)

(
Pbindef(\wn2,
	\instrument, \wn,
	\dur, Pseq([1/4],inf),
	\amp, Pexprand(0.05,0.2),
	\sus, 0.005,
	\hpf, Phprand(20,10000),
	\hrq, Pexprand(0.1,1),
	\out, ~bus[\reverb],
).quant_(0);
)

(
t.schedAbs(
	t.nextBar+4,
	{
		Pbindef(\wn2).play(t);
	}
)
)

(
t.schedAbs(
	t.nextBar+4,
	{
		Pbindef(\wn2).stop;
		Synth(\wn, [\amp, 0.005, \rel, 0.1, \c2, -10, \lpf, 20000, \lrq, 0.5,\out, ~bus[\reverb]]);
	}
)
)

~reverb.set(\mix, 0)
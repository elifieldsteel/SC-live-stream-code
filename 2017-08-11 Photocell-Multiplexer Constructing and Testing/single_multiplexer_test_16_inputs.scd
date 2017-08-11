(
Tdef.all.do(_.stop);
SerialPort.closeAll;
SerialPort.devices;
~port = SerialPort.new("/dev/tty.usbmodem1421", 115200);
~arduinoData = [];
~values = [];
CmdPeriod.doOnce({Tdef(\getData).stop;SerialPort.closeAll;});
)

(
Tdef(\getData, {
	~arduinoData = [];
	~values = [];
	loop{
		var data;
		data = ~port.read;
		case

		//do nothing if no data yet
		{data == nil} {nil}

		//if Arduino sends ascii integer corresponding to a number or comma
		{(data.asAscii.isAlpha.not) && (data.asAscii.isPrint)}

		//add it to this array as a string
		{~arduinoData = ~arduinoData.add(data.asAscii.asString)}

		//if a letter is received
		{(data.asAscii.isAlpha)}
		{
			//convert to a usable array of integers and reset the raw array
			~values = ("[".catList(~arduinoData)++"]").interpret;
			~arduinoData = [];
		}

		{true}{nil};
	}
}).play;
)

~arduinoData; //raw data
~values; //processed data, converted to array of integers

(
Window.closeAll;
w = Window.new(bounds:Rect(380,1580,420,60)).front;
~views = 16.collect{
	arg n;
	CompositeView(w, Rect(10+(n*25),10,25,25))
	.background_(Color.gray(0.5));
};
)

s.boot;

(
//bus to reverb synth
~bus = Bus.audio(s, 2);

//16 synths with settable gate/freq args
~synths = [48,50,52,55,57,60,62,64,67,69,72,74,76,79,81,84].collect{
	arg n;
	{
		arg gate=0, freq;
		var sig, env;
		//freq = n.midicps;
		sig = LFTri.ar(freq);
		env = Env.perc(0.02,0.5).kr(0, gate);
		sig = sig * env * 0.1!2;
		Out.ar(~bus, sig);
	}.play(args:[\freq, n.midicps]);
};

~reverb = {
	var sig;
	sig = In.ar(~bus, 2);
	sig = sig.blend(GVerb.ar(sig, 99, 5)*0.5, 0.1);
	sig = sig * 0.5;
	Out.ar(0, sig);
}.play(target:s, addAction:'addToTail');
)

(
Tdef(\control, {
	loop{
		~views.do{
			arg view, index;
			var grayVal, trig;

			//convert photocell values to grayscale values (0-1) and synth triggers (0||1)
			grayVal = ~values.collect({arg i; i.linlin(100,950,0,1)});
			trig = ~values.collect({arg i; if(i<770,{1},{0})});

			//adjust color of CompositeViews and set synths
			view.background_(Color.gray(grayVal[index]));
			~synths[index].set(\gate, trig[index]);
		};
		0.005.wait;
	}
}).play(AppClock);
)

(
([48,50,52,55,57,60,62,64,67,69,72,74,76,79,81,84]+1).do{
	arg n, i;
	~synths[i].set(\freq, n.midicps);
}
)
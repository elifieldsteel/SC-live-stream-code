Tdef.all.do(_.stop);
SerialPort.closeAll;
SerialPort.devices;
~port = SerialPort.new("/dev/tty.usbmodem1421", 115200);

(
~intArray = [ ];
Tdef(\readValues, {
	loop{
		~ascii = ~port.read;
		case

		{~ascii == nil} {nil}

		//if arduino sends a digit, add it to array
		{~ascii.asAscii.isDecDigit}
		{~intArray = ~intArray.add(~ascii.asAscii.digit)}

		//'a' means we just received photocell data;
		//convert digits and clear array
		{~ascii.asAscii == $a}
		{
			~photocellVal = ~intArray.convertDigits;
			~intArray = [ ];
		}

		//'b' means we just received button data
		{~ascii.asAscii == $b}
		{
			~buttonVal = ~intArray.convertDigits;
			~intArray = [ ];
		}

		{true} {nil};
	};
}).play
)

(
Tdef(\postValues, {
	{
		~photocellVal.postln;
		~buttonVal.postln;
		"".postln;
		0.1.wait;
	}.loop;
}).play
)

Tdef(\postValues).stop;

s.boot;

(
~synth = {
	arg freq=60, cf=4000, gate=0;
	var sig, env;
	cf = cf.lag(0.08);
	sig = Saw.ar([freq, freq+1],0.2!2);
	sig = RLPF.ar(sig, cf, 0.1);
	env = Env.adsr.kr(0, gate);
	sig = sig * env;
}.play.register;
)

//register allows us to check whether Synth is playing
~synth.isPlaying;

(
//frequency pattern, converted to stream
~freq = Pxrand(
	([30,33,35,37,40,42,45,47,49,52,54,57,59,61, 64]).midicps.mirror,
	inf
).asStream;

//track button state to avoid duplicate triggers
//i.e. only do something when the button state is *first* changed
//rather than repeating it while the new state remains unchanged
~buttonDown = false;

Tdef(\synthControl, {
	{
		if(
			~synth.isPlaying, {
				//update synth args with sensor values
				~synth.set(
					\gate, ~buttonVal,
					\cf, ~photocellVal.linexp(150,1010,50,4000),
				);

				case

				//if the button is down and was previously up
				{(~buttonVal == 1) && (~buttonDown.not)}

				{
					//change frequency and update state
					~buttonDown = true;
					~synth.set(\freq, ~freq.next)
				}

				//if the button is up and was previously down
				{(~buttonVal == 0) && (~buttonDown)}

				//update state
				{~buttonDown = false}

				{true}{nil};

			}
		);
		0.001.wait;
	}.loop
}).play
)

Tdef(\synthControl).isPlaying;
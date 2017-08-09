Tdef.all.do(_.stop);
SerialPort.closeAll;
SerialPort.devices;
~port = SerialPort.new("/dev/tty.usbmodem1421", 115200);

(
Tdef(\test, {
	{
		"hello".postln;
		1.wait;
	}.loop;
}).play;
)

Tdef(\test).stop;

(
~intArray = [ ];
Tdef(\readValues, {
	{
		~ascii = ~port.read;
		case

		{~ascii == nil} {nil}

		//if arduino sends a digit, add it to the array
		{~ascii.asAscii.isDecDigit}
		{~intArray = ~intArray.add(~ascii.asAscii.digit)}

		//if arduino sends an alphabetic character, convert the array
		//digits to an integer and then clear the array
		{~ascii.asAscii.isAlpha}
		{
			~val = ~intArray.convertDigits;
			~intArray = [ ];
		}

		{true} {nil};
	}.loop;
}).play;
)

(
Tdef(\postValues, {
	{
		~val.postln;
		0.05.wait;
	}.loop;
}).play
)

s.boot;

(
~synth = {
	arg freq=3000;
	var sig;
	sig = WhiteNoise.ar(1!2);
	sig = LPF.ar(sig, freq, 0.05);
}.play;
)

(
Tdef(\filterSweep, {
	{
		//make sure to set appropriate min/max values here
		~synth.set(\freq, ~val.linexp(150,1010,200,3500));
		0.001.wait;
	}.loop;
}).play
)

Tdef(\filterSweep).stop;
~synth.free;
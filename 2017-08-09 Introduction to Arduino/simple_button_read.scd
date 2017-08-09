Tdef.all.do(_.stop);
SerialPort.closeAll;
SerialPort.devices;
~port = SerialPort.new("/dev/tty.usbmodem1421", 115200);

(
Tdef(\readValues, {
	{
		//read the value
		~buttonVal = ~port.read;

		//might make sense to do the ascii conversion/boolean logic here
	}.loop;
}).play;
)

(
//track previous state as well as current state
~lastButtonVal = ~buttonVal;

//frequency value pattern, converted to stream
~freq = Pseq(
	(12+[ 30, 33, 35, 37, 40, 42, 45, 47, 49, 52, 54, 57, 59, 61, 64 ]).midicps.mirror,
	inf
).asStream;


Tdef(\postValues, {
	{
		if(
			~lastButtonVal != ~buttonVal,
			{
				//only update synth if value has changed
				~lastButtonVal = ~buttonVal;
				~lastButtonVal.asAscii.digit.postln;
				~synth.set(
					\gate, ~lastButtonVal.asAscii.digit,
				);
				if(
					//if the button has been pressed down,
					//go to the next frequency
					~lastButtonVal.asAscii.digit == 1,
					{~synth.set(\freq, ~freq.next)}
				);
			}
		);
		0.01.wait;
	}.loop;
}).play
)

s.boot;

(
~synth = {
	arg gate=0, freq=60;
	var sig, env;
	sig = Saw.ar([freq, freq+1],0.05);
	sig = LPF.ar(sig, 2000);
	env = Env.adsr.kr(0, gate);
	sig = sig * env;
}.play;
)

~synth.set(\gate, 0);
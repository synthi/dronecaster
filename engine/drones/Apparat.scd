/* Retrieved from
http://sccode.org/1-5aD
Original by Zé Craum
Crude simulation of old sinusoidal generators - with random vibrato and a high noise floor.
50hz mains hum emulation and slightly distorted sine (a clipped triangle wave) added by Josh Mitchell.
Modified by Bruno Ruviaro and Josh Mitchell 8/19.
Edited by Josue Arias for Dronecaster synthdef
*/

{
	arg
	//Standard Definitions
	amp = 0.2, freq = 440, pan = 0,
	//Noise Arguments (mainsDepth is 0 to 1)
	noiseAmp = 0.06, mainsDepth = 0.1, mainsHz = 50,
	//Sine Arguments
	vrate = 2, vdepth = 0.005, sineClip = 0.825;

	var noise, snd, vibrato;


	noise = PinkNoise.ar(noiseAmp * LFPar.ar(mainsHz * 2).range((1 - mainsDepth), 1));
	noise = noise + LFPar.ar(freq: mainsHz, mul: noiseAmp/8);

	vibrato = freq * LFNoise2.ar(vrate).range(1/(1 + vdepth), (1 + vdepth));

	snd = Clip.ar(LFTri.ar(vibrato), -1 * sineClip, sineClip).softclip;
	snd = ((snd * amp) + noise) * env;
	Out.ar(out, Pan2.ar(snd, pan));

},
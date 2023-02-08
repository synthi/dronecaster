/* Retrieved from
http://sccode.org/1-5aD
Original by Zé Craum
Crude simulation of old sinusoidal generators - with random vibrato and a high noise floor.
50hz mains hum emulation and slightly distorted sine (a clipped triangle wave) added by Josh Mitchell.
Modified by Bruno Ruviaro and Josh Mitchell 8/19.
Edited by Josue Arias for Dronecaster synthdef
*/

{
	arg hz = 128, amp = 0.5, out = 0,
	//Noise Arguments (mainsDepth is 0 to 1)
	noiseAmp = 0.05, mainsDepth = 0.2, mainsHz = 50,
	//Sine Arguments
	vrate = 2, vrate2 = 0.3, vdepth = 0.02, vdepth2 = 0.01, sineClip = 0.825;

	var noise, snd, snd2, vibrato, vibrato2, mix, wet, sndall;

	noise = PinkNoise.ar(noiseAmp * LFPar.ar(mainsHz * 2).range((1 - mainsDepth), 1));
	noise = noise + LFPar.ar(hz: mainsHz, mul: noiseAmp/8);

	vibrato = hz * LFNoise2.ar(vrate).range(1/(1 + vdepth), (1 + vdepth));
	vibrato2 = (hz * 4) * LFNoise2.ar(vrate2).range(1/(1 + vdepth2), (1 + vdepth2));

	snd = Clip.ar(LFTri.ar(vibrato), -1 * sineClip, sineClip).softclip;
	snd = ((snd * amp) + noise);
	snd2 = Clip.ar(LFTri.ar(vibrato2), -1 * sineClip, sineClip).softclip;
	snd2 = (snd2 * (amp / 4));
	sndall = (snd + snd2);
	wet = (Dust2.ar(10, 1) + Crackle.ar(1.95, 0.2) + SinOsc.ar((PinkNoise.ar(0.5) * 7500) + 40, 0, 0.04));
	wet = HPF.ar(wet, 25);
	wet = BPF.ar(wet, hz, 0.4);
	
	wet = (wet * amp);
	mix = (sndall + wet);
	//mix = Mix.new(wet, sndall);
	mix = Pan2.ar(mix,0)

/*

Apparatus by Josue Arias
Original parts by Zé Craum
Crude simulation of old sinusoidal generators
Modified by Bruno Ruviaro and Josh Mitchell

*/

{
	arg hz = 128, amp = 0.5, out = 0,
	//Noise Arguments (mainsDepth is 0 to 1)
	noiseAmp = 0.07, mainsDepth = 0.2, mainsHz = 50,
	//Sine Arguments
	vrate = 2, vrate2 = 0.3, vdepth = 0.02, vdepth2 = 0.01, sineClip = 0.825;

	var noise, snd, snd2, vibrato, vibrato2, mix, wet, sndall;

	noise = PinkNoise.ar(noiseAmp * LFPar.ar(mainsHz * 2).range((1 - mainsDepth), 1));
	noise = noise + LFPar.ar(hz: hz, mul: noiseAmp/8);

	vibrato = hz * LFNoise2.ar(vrate).range(1/(1 + vdepth), (1 + vdepth));
	vibrato2 = (hz * 3) * LFNoise2.ar(vrate2).range(1/(0.9 + vdepth2), (0.9 + vdepth2));

	snd = Clip.ar(LFTri.ar(vibrato), -1 * sineClip, sineClip).softclip;
	//snd = ((snd * amp) + noise);
	snd = ((snd + noise) * amp);
	snd2 = Clip.ar(LFTri.ar(vibrato2), -1 * sineClip, 0.5).softclip;
	snd2 = (snd2 * (amp / 10));
	sndall = (snd + snd2);
	wet = (Dust2.ar(10, 1) + Crackle.ar(1.95, 0.2) + SinOsc.ar((PinkNoise.ar(0.5) * 7500) + 40, 0, 0.04));
	wet = HPF.ar(wet, 25);
	wet = BPF.ar(wet, hz, 0.9);
	
	wet = ((wet * 2) * amp);
	mix = (sndall + wet);
	//mix = Mix.new(wet, sndall);
	mix = Pan2.ar(mix,0)
	
}

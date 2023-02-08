/* Apparatus drone by Josue AriasO
Original by Zé Craum
Crude simulation of old sinusoidal generators with random vibrato and a high noise floor.
50hz mains hum emulation and slightly distorted sine (a clipped triangle wave) added by Josh Mitchell.
Modified by Bruno Ruviaro and Josh Mitchell 8/19.
*/

{
	arg hz = 128, amp = 0.5, out = 0,
	//Noise Arguments (mainsDepth is 0 to 1)
	noiseAmp = 0.05, mainsDepth = 0.2, mainsHz = 50,
	//Sine Arguments
	vrate = 2, vdepth = 0.01, sineClip = 0.825;

	var noise, snd, vibrato;

	//env = Env.asr(att, amp, rel, curve: \lin).kr(gate: gate, doneAction: 2);

	noise = PinkNoise.ar(noiseAmp * LFPar.ar(mainsHz * 2).range((1 - mainsDepth), 1));
	noise = noise + LFPar.ar(hz: mainsHz, mul: noiseAmp/8);

	vibrato = hz * LFNoise2.ar(vrate).range(1/(1 + vdepth), (1 + vdepth));

	snd = Clip.ar(LFTri.ar(vibrato), -1 * sineClip, sineClip).softclip;
	snd = ((snd * amp) + noise);
	snd=Pan2.ar(snd,0)
	//Out.ar(out, snd).dup;

}

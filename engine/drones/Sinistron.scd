// @asymmetriccut
// Sinistron.
// Simple drone maker based on Gristle by @infinitedigits
//

{
    arg hz=20, amp=0.05;
	  var edc = Mix.ar(
			LFPulse.ar(
			freq:hz*Array.fill(6,{arg i;
					2**i *
					LinExp.kr(PMOsc.kr(LFBrownNoise2.kr(1)),-1,2,0.99,1.09)
			}),
			mul:amp*Array.fill(6,{arg i;(1/2)**i}),
		)
	);
	edc = BRF.ar(edc,
			LinExp.kr(PMOsc.kr(LFBrownNoise2.kr(1,mul:0.1)),-1,1,90,2000)
	);
	edc = JPverb.ar(edc, t60: 2.0, damp: 0.9, size: 2.0, earlyDiff: 0.909, modDepth: 0.9, modFreq: 2.0, low: 1.0, mid: 2.0, high: 9.0, lowcut: 500.0, highcut: 2000.0);

}

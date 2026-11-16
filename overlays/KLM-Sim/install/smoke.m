addpath(fileparts(fileparts(mfilename('fullpath'))));
run('settings.m');
Et=ones(1,8); Pt=abs(Et).^2; W1=ones(1,8)*3.2e-5;
q1=1./(-ones(1,8)/0.03-1i*lambda./(pi*W1.^2));
qt=MLSpatial(delta,Et,Pt,q1,W1,Ikl,L,deltaPlane);
assert(all(isfinite(qt)));
l=NLloss(W1,Wp); g=SatGain(Et,W1,1.2,Is,Wp);
assert(all(l>0) && all(l<=1) && g>0 && g<=1.2);
fprintf('PASS KLM-Sim Octave %s: MLSpatial, NLloss, SatGain, settings\n',version);

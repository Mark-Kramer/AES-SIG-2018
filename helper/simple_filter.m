% Apply a finite impulse response filter to the data d, with time axis t,
% and passband Wn = [low freq, high freq].

function [d_filtered] = simple_filter(t,d,Wn)

  dt = t(2)-t(1);				%Define the sampling interval.
  Fs = 1/dt;					%Define the sampling frequency.
  fNQ = Fs/2;					%Define the Nyquist frequency.

  Wn = Wn/fNQ;                  %...set the passband,
  n  = 100;                     %...and filter order,
  b  = fir1(n,Wn);              %...build bandpass filter.
  
  d_filtered = filtfilt(b,1,d);	%...and apply filter.
  
end
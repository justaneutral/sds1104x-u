function coeffs = design_fir_coeffs(Fpass, Fstop, Fs, Astop)
% DESIGN_FIR_COEFFS Design a low-pass FIR filter using Kaiser window
%
% Inputs:
%   Fpass - passband edge frequency in Hz
%   Fstop - stopband edge frequency in Hz
%   Fs    - sampling frequency in Hz
%   Astop - desired stopband attenuation in dB
%
% Output:
%   coeffs - FIR filter coefficients (linear phase)

% Normalize frequencies to Nyquist (0..1)
Wp = Fpass / (Fs/2);  % normalized passband
Ws = Fstop / (Fs/2);  % normalized stopband

% Transition width
delta_f = Ws - Wp;

% Estimate filter order using Kaiser formula
% N = (Astop - 8) / (2.285 * 2*pi*delta_f_normalized)
% Normalized to 0..1 for MATLAB formula
N = ceil((Astop - 8) / (2.285 * 2*pi*delta_f));

% Ensure N is odd for symmetric FIR
if mod(N,2) == 0
    N = N + 1;
end

% Design Kaiser window
beta = 0.1102*(Astop-8.7);  % Kaiser beta for Astop > 50 dB
w = kaiser(N,beta);

% Design lowpass FIR filter
coeffs = fir1(N-1, Wp, w, 'noscale'); % 'noscale' avoids automatic normalization

end

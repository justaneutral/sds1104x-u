function [y,ag]= freq_conv(x, Fs, f_shift)
% COMPLEX_DOWNCONVERTER Downconverts a real signal to complex baseband
%
% Inputs:
%   x       - real input signal (scalar or vector per time step)
%   Fs      - sampling rate (Hz)
%   f_shift - frequency to shift down (Hz)
%
% Output:
%   y       - complex baseband signal

% Persistent time vector to maintain phase continuity
persistent mx
ag = 1.0j*2*pi*double(f_shift)/double(Fs);
if isempty(mx)
    % Initialize time vector for the current frame
    mx = 1.0+0.0j;
else
    % Increment time for continuity
    mx = mx * exp(ag);
end

% Multiply real signal by complex exponential
y = double(x) * mx;
end
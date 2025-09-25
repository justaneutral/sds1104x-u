function [y, coeffs] = complex_lowpass_filter(x, coeffs, decimation_factor)
% COMPLEX_LOWPASS_FILTER Filter a complex signal with FIR coefficients
%
% Inputs:
%   x                - complex input array
%   coeffs           - FIR filter coefficients (vector)
%   decimation_factor - optional, integer > 0; if >1, output is decimated
%
% Outputs:
%   y      - filtered (and optionally decimated) complex array
%   coeffs - returned filter coefficients (for reference)
%
% Example:
%   b = design_fir_coeffs(64, 0.2, 0.05, 60); % get coefficients from another function
%   y = complex_lowpass_filter(x, b, 4); % filter and decimate by 4

if nargin < 3
    decimation_factor = 1; % default: no decimation
end

% Apply FIR filter
y_filtered = filter(coeffs, 1, x);

% Decimate if requested
if decimation_factor > 1
    y = y_filtered(1:decimation_factor:end);
else
    y = y_filtered;
end

end

% Filter specifications
FS = 500000.0;       % Input sampling rate in Hz
F_PASS = 200.0;      % Passband edge frequency in Hz
F_STOP = 12500.0;    % Stopband edge frequency in Hz
ATTENUATION_DB = 80; % Stopband attenuation in dB

% Calculate the linear ripple values
passband_ripple = 10^(-0.1/20); % Small ripple, for example 0.1 dB
stopband_ripple = 10^(-ATTENUATION_DB / 20.0);

% Estimate the filter order (number of taps) using firpmord
% This function estimates the minimum order required for the given specs
f = [F_PASS, F_STOP];
a = [1, 0]; % Passband has amplitude 1, Stopband has amplitude 0
dev = [passband_ripple, stopband_ripple];
[n, fo, ao, w] = firpmord(f, a, dev, FS);
n = n + mod(n, 2); % Ensure the order is even for linear phase filters

% Design the filter coefficients using firpm (Parks-McClellan algorithm)
b = firpm(n, fo, ao, w, 'h');

% Display the results in a C-style format
fprintf('Designed complex low-pass FIR filter with %d taps.\n', length(b));
fprintf('// Passband: 0-200 Hz, Stopband: > 12500 Hz, Attenuation: 80 dB\n');
fprintf('#define COMPLEX_FILTER_TAPS %d\n', length(b));
fprintf('const double complex_filter_coeffs[COMPLEX_FILTER_TAPS] = {\n');
for i = 1:length(b)
    fprintf('    %.16f,', b(i));
    if mod(i, 4) == 0 && i < length(b)
        fprintf('\n');
    end
end
fprintf('\n};\n');

function plot_fir_response(coeffs, fig_num)
% PLOT_FIR_RESPONSE Plots impulse and frequency response of an FIR filter
%
% Inputs:
%   coeffs  - FIR filter coefficients
%   fig_num - figure number (creates or rewrites this figure)
%
% Example:
%   b = design_fir_coeffs(64, 100, 150, 1000, 60);
%   plot_fir_response(b, 1);

% Create or reuse figure
figure(fig_num);
clf; % clear existing figure

% Impulse response
subplot(3,1,1);
stem(0:length(coeffs)-1, coeffs, 'filled');
xlabel('n (samples)');
ylabel('Amplitude');
title('Impulse Response');
grid on;

% Frequency response
[H,f] = freqz(coeffs, 1, 1024, 'half'); % compute frequency response
% f = normalized frequency (Hz) if Fs not specified
mag = abs(H);
phase = unwrap(angle(H));

% Magnitude response
subplot(3,1,2);
plot(f/pi*0.5, mag); % normalized frequency to Nyquist
xlabel('Frequency (normalized to Fs/2)');
ylabel('Magnitude');
title('Magnitude Response');
grid on;

% Phase response
subplot(3,1,3);
plot(f/pi*0.5, phase);
xlabel('Frequency (normalized to Fs/2)');
ylabel('Phase (radians)');
title('Phase Response');
grid on;

end

figure(1)
hold off
max_angle_error = 0;
for observation_time = 1:9:10
%for bandwidth = 2:198:200
bandwidth = 200;
noise_levels = 20*log10(1./(0.15:-0.01:0.01));
angle_errors1 = 100/sqrt(bandwidth*observation_time)*exp(-0.05*noise_levels).^3;
angle_errors2 = 180/pi*atan(1/sqrt(bandwidth*observation_time)*exp(-0.05*noise_levels*exp(pi/3)));
plot(noise_levels,angle_errors1);
hold all
plot(noise_levels,angle_errors2);
max_angle_error = max(max_angle_error,angle_errors1(1));
max_angle_error = max(max_angle_error,angle_errors2(1));

end %integration time
%end %bandwidth

title(sprintf("Angle Error Upper Limit Estimation. BW=%dHz",bandwidth));
axis([floor(noise_levels(1)) ceil(noise_levels(end)) 0 (max_angle_error+0.1)]);
xlabel('SNR,dB');
ylabel('Max Error, deg.');
%legend('BW:2Hz Time:1s','BW:200Hz Time:1s','BW:2Hz Time:10s','BW:200Hz Time:10s')
legend('BW:200Hz Time:1s','BW:200Hz Time:1s atan','BW:200Hz Time:10s','BW:200Hz Time:10s atan');
hold off

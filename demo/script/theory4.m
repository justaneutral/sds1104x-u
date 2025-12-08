N = 500000;
fignum = 1;

max_angle_error = 0;


for observation_time = 1:9:10
%for bandwidth = 2:198:200
bandwidth = 200;

noise_levels = [];
angle_errors = [];

for noise_magnitude = 0.15:-0.01:0.01
    W = zeros(361,7);
    i = 1;
    for angle = -88:2:86
        W(i,1) = angle;
        [ant_a,ant_b,ant_c] = signal_generator(angle,noise_magnitude,fignum,observation_time,bandwidth);
        ant_a = fft(ant_a,N);
        ant_b = fft(ant_b,N);
        ant_c = fft(ant_c,N);
        
        % figure(fignum+1)
        % hold off
        % plot([1:N],abs(ant_a),'color','red')
        % hold all
        % plot([1:N],abs(ant_b),'color','green')
        % plot([1:N],abs(ant_c),'color','blue')
        % hold off
        noise_level = noise_magnitude;
        gain_a = 1;
        gain_b = 1;
        gain_c = 1;
        [W(i,2) W(i,3) W(i,4)] = measurement_correlational1( ...
            ant_a,ant_b,ant_c,noise_level,gain_a,gain_b,gain_c, ...
            angle,0);
        i = i+1;
    end
    i = i-1;
    figure(fignum+3)
    hold off
    plot(W(1:i,1),W(1:i,2),'color','black')
    hold all
    plot(W(1:i,1),W(1:i,3),'color','red')
    plot(W(1:i,1),W(1:i,4),'color','blue')
    title(fignum+3,sprintf('noise_magnitude = %d',noise_magnitude))
    legend('Measured anglek','Pxy','An')
    figure(fignum+4)
    hold off
    plot(W(1:i,1),W(1:i,2)-W(1:i,1),'color','black')
    hold all
    plot(W(1:i,1),W(1:i,3),'color','red')
    plot(W(1:i,1),W(1:i,4),'color','blue')
    title(fignum+4,'Measurement Error')
    legend('Angle error','Pxy','An')

    noise_levels = [noise_levels, 20*log10(1/noise_magnitude)];
    angle_errors = [angle_errors, max(abs(W(1:i,2)-W(1:i,1)))];

end % noise magnitude

figure(fignum+5)
plot(noise_levels(1:end),angle_errors(1:end))
hold all
plot(noise_levels,100/sqrt(bandwidth*observation_time)*exp(-0.05*noise_levels).^3,'color','black');
max_angle_error = max(max_angle_error,angle_errors(1));

end %integration time
%end %bandwidth

title(sprintf("Angle Error Upper Limit Estimation. BW=%dHz",bandwidth));
axis([floor(noise_levels(1)) ceil(noise_levels(end)) 0 ceil(max_angle_error)]);
xlabel('SNR,dB');
ylabel('Max Error, deg.');
legend('BW:2Hz Time:1s','BW:200Hz Time:1s','BW:2Hz Time:10s','BW:200Hz Time:10s')
legend('BW:200Hz Time:1s','BW:200Hz Time:10s')




function [ant_a,ant_b,ant_c] = signal_generator(angle,noise_magnitude,fignum,observation_time,bandwidth)
    %f = 24000;
    %df = 100;
    %fw = 2000;
    fs = bandwidth*2;
    T = observation_time;
    dt = 1/fs;
    t = [0:dt:T-dt];
    %signal = df/(2*fw)*exp(sqrt(-1)*2*pi*f*t);
    signal = complex((0.5-rand(1,floor(T/dt))),(0.5-rand(1,floor(T/dt))));
    noise_a = noise_magnitude*complex((0.5-rand(1,floor(T/dt))),(0.5-rand(1,floor(T/dt))));
    % noise_b = noise_magnitude*complex((0.5-rand(1,floor(T/dt))),(0.5-rand(1,floor(T/dt))));
    % noise_c = noise_magnitude*complex((0.5-rand(1,floor(T/dt))),(0.5-rand(1,floor(T/dt))));
    % for i = f-fw:df:f+fw
    %     %signal = signal + df/(2*fw)*exp(sqrt(-1)*2*pi*(i*t+pi/180*i));
    %     signal = signal + complex((0.5-rand(1,floor(T/dt))),(0.5-rand(1,floor(T/dt))));
    %     noise_a = noise_a + noise_magnitude*complex((0.5-rand(1,floor(T/dt))),(0.5-rand(1,floor(T/dt))));
    %     noise_b = noise_b + noise_magnitude*complex((0.5-rand(1,floor(T/dt))),(0.5-rand(1,floor(T/dt))));
    %     noise_c = noise_c + noise_magnitude*complex((0.5-rand(1,floor(T/dt))),(0.5-rand(1,floor(T/dt))));
    % end
    ant_a = cos(pi/180*angle)*(signal)+cos(90+pi/180*angle)*noise_a;
    ant_c = cos(pi/180*(angle+240))*(signal)+cos(240+90+pi/180*angle)*noise_a;
    ant_b = cos(pi/180*(angle+120))*(signal)+cos(120+90+pi/180*angle)*noise_a;
    if fignum > 0
        tt = [t,t+T,t+2*T,t+3*T,t+4*T];
        zz = zeros(1,floor(T/dt));
        figure(fignum)
        plot(tt,[real(signal),zz,zz,zz,zz],'color','black');
        hold all
        plot(tt,[zz,real(noise_a),zz,zz,zz],'color','yellow');
        plot(tt,[zz,zz,real(ant_a),zz,zz],'color','red');
        plot(tt,[zz,zz,zz,real(ant_b),zz],'color','green');
        plot(tt,[zz,zz,zz,zz,real(ant_c)],'color','blue');
        title('signal in antennas')
        legend('Signal','noise','ant_a','ant_b','ant_c');
        hold off
    end
end
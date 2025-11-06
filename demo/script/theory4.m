N = 70000;
fignum = 1;
noise_magnitude = 0.01;
for noise_phase = 0:10:360
    W = zeros(361,7);
    i = 1;
    for angle = -89:1:89
        noise_angle = angle - 00;
        W(i,1) = angle;
        [ant_a,ant_b,ant_c] = signal_generator(angle,noise_magnitude,noise_angle,noise_phase,0);
        ant_a = fft(ant_a,N);
        ant_b = fft(ant_b,N);
        ant_c = fft(ant_c,N);
        
        % figure(20)
        % hold off
        % plot([1:N],abs(ant_a),'color','red')
        % hold all
        % plot([1:N],abs(ant_b),'color','green')
        % plot([1:N],abs(ant_c),'color','blue')
        % hold off
        noise_level = 0;
        gain_a = 1;
        gain_b = 1;
        gain_c = 1;
        [W(i,2)] = measurement_correlational( ...
            ant_a,ant_b,ant_c,noise_level,gain_a,gain_b,gain_c, ...
            angle,fignum);
        i = i+1;
    end
    i = i-1;
    figure(fignum+1)
    hold off
    plot(W(1:i,1),W(1:i,2),'color','black')
    hold all
    title(fignum+1,sprintf('noise_angle = %d, noise_phase = %d',noise_angle, noise_phase))
    figure(fignum+2)
    plot(W(1:i,1),W(1:i,2)-W(1:i,1),'color','black')
    title(fignum+2,'Measurement Error')
end



function [ant_a,ant_b,ant_c] = signal_generator(angle,noise_magnitude,noise_angle,noise_phase,fignum)
    f = 24000;
    df = 100;
    fw = 2000;
    fs = 500000;
    T = 70000/fs;
    dt = 1/fs;
    t = [0:dt:T-dt];
    signal = df/(2*fw)*exp(sqrt(-1)*2*pi*f*t);
    noise = df/(2*fw)*noise_magnitude*exp(sqrt(-1)*2*pi*(f*t+pi/180*noise_phase));
    for i = f-fw:df:f+fw
        signal = signal + df/(2*fw)*exp(sqrt(-1)*2*pi*(i*t+pi/180*i));
        noise = noise + df/(2*fw)*noise_magnitude*exp(sqrt(-1)*2*pi*(i*t+pi/180*noise_phase));
    end
    ant_a = cos(pi/180*angle)*(signal)+cos(pi/180*noise_angle)*noise;
    ant_c = cos(pi/180*(angle+240))*(signal)+cos(pi/180*(noise_angle+240))*noise;
    ant_b = cos(pi/180*(angle+120))*(signal)+cos(pi/120*(noise_angle+240))*noise;
    if fignum > 0
        figure(fignum)
        plot([t,t+T,t+2*T,t+3*T],[imag(signal),0*ant_a,0*ant_b,0*ant_c],'color','black');
        hold all
        plot([t,t+T,t+2*T,t+3*T],[0*signal,real(ant_a),0*ant_b,0*ant_c],'color','red');
        plot([t,t+T,t+2*T,t+3*T],[0*signal,0*ant_a,real(ant_b),0*ant_c],'color','green');
        plot([t,t+T,t+2*T,t+3*T],[0*signal,0*ant_a,0*ant_b,real(ant_c)],'color','blue');
        title('signal in antennas a(rd),b(grn),c(blue)');
        hold off
    end
end
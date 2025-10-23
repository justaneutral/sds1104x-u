N = 70000;
noise_magnitude = 0.1;
for noise_phase = 0:10:360
    W = zeros(361,7);
    i = 1;
    for angle = -90:1:89
        noise_angle = angle + 90;
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

        [W(i,2), W(i,3), W(i,4), W(i,5)] = measurement_coherent(ant_a,ant_b,ant_c,1,angle);
        %W(i,3) = measurement_coherent(ant_b,ant_c,ant_a,2,angle);
        %W(i,4) = measurement_coherent(ant_c,ant_a,ant_b,3,angle);
        % W(i,5) = measurement_separable(ant_a,ant_b,ant_c,4,angle);
        % W(i,6) = measurement_separable(ant_b,ant_c,ant_a,5,angle);
        % W(i,7) = measurement_separable(ant_c,ant_a,ant_b,6,angle);
        i = i+1;
    end
    i = i-1;
    figure(7)
    hold off
    plot(W(1:i,1),W(1:i,2),'color','black')
    hold all
    plot(W(1:i,1),W(1:i,3),'color','red')
    plot(W(1:i,1),W(1:i,4),'color','green')
    plot(W(1:i,1),W(1:i,5),'color','blue')
    title(j,sprintf('noise_angle = %d, noise_phase = %d',noise_angle, noise_phase))
end



function [direction] = measurement_separable(ant_a,ant_b,ant_c,fignum,reference_angle)
    Q = 2*ant_a - ant_b - ant_c;
    I = sqrt(3)*(ant_b - ant_c);
    S = Q.*I;
    S = sign(real(S.*conj(S)));

    
    directionsRe = 180/pi*atan2(real(I),-1*real(Q));
    directionsIm = 180/pi*atan2(imag(I),-1*imag(Q));
    directionRe = mean(directionsRe);
    direction = directionRe;

    if fignum > 0
        x = real(Q) - 100;
        y = -1*real(I) + 100;        
        figure(fignum)
        hold off
        plot(x,y,'color','green');
        hold all
        x = 0.1*real(I) - 100;
        y = 0.1*real(Q) + 100;
        plot(x,y,'color','green');
        x = imag(Q) - 80;
        y = -1*imag(I) + 100;
        plot(x,y,'color','blue');
        x = 0.1*imag(I) - 80;
        y = 0.1*imag(Q) + 100;
        plot(x,y,'color','blue');
        x=(0:1:100)*cos(pi/180*reference_angle) + 100;
        y=(0:1:100)*sin(pi/180*reference_angle) + 100;
        plot(x,y,'color','red');
        x=100*cos(pi/180*directionsRe) - 80;
        y=100*sin(pi/180*directionsRe) - 100;
        plot(x,y,'color','cyan');
        x=100*cos(pi/180*directionsIm) - 100;
        y=100*sin(pi/180*directionsIm) - 100;
        plot(x,y,'color','black');      
        % x=[0:1:100]*cos(pi/180*direction) + 100;
        % y=[0:1:100]*sin(pi/180*direction) - 100;
        % plot(x,y,'color','yellow');
        axis([-200 200 -200 200])
        hold off
    end
end


function [direction, directiona, directionb, directionc] = measurement_coherent(ant_a,ant_b,ant_c,fignum,reference_angle)
    I = 2*ant_a - ant_b - ant_c;
    Q = sqrt(3)*(ant_c - ant_b);
    S = sign(real(Q*I'));
    Q = S*sqrt(Q*Q');
    I = sqrt(I*I');
    R = sqrt(Q^2+I^2);
    Ia = I/R;
    Qa = Q/R;

    I = 2*ant_b - ant_c - ant_a;
    Q = sqrt(3)*(ant_a - ant_c);
    S = sign(real(Q*I'));
    Q = S*sqrt(Q*Q');
    I = sqrt(I*I');
    R = sqrt(Q^2+I^2);
    V=complex(I/R,Q/R)*exp(sqrt(-1)*pi*(60)/180);
    Ib = abs(real(V));
    Qb = sign(real(V))*imag(V); 

    I = 2*ant_c - ant_a - ant_b;
    Q = sqrt(3)*(ant_b - ant_a);
    S = sign(real(Q*I'));
    Q = S*sqrt(Q*Q');
    I = sqrt(I*I');
    R = sqrt(Q^2+I^2);
    V=complex(I/R,Q/R)*exp(sqrt(-1)*pi*(120)/180);
    Ic = abs(real(V));
    Qc = sign(real(V))*imag(V);   

    directiona = 180/pi*atan2(Qa,Ia);
    directionb = 180/pi*atan2(Qb,Ib);
    directionc = 180/pi*atan2(Qc,Ic);
    direction = sort([directiona,directionb,directionc]);
    direction = direction(2);

    if fignum > 0
        figure(fignum)
        hold off
        x=(0:1:190)*cos(pi/180*reference_angle);
        y=(0:1:190)*sin(pi/180*reference_angle);
        plot(x,y,'color','black');
        hold all
        x=(0:1:180)*cos(pi/180*direction);
        y=(0:1:180)*sin(pi/180*direction);
        plot(x,y,'color','yellow');
        x=(0:1:150)*cos(pi/180*directiona);
        y=(0:1:150)*sin(pi/180*directiona);
        plot(x,y,'color','red');
        x=(0:1:130)*cos(pi/180*directionb);
        y=(0:1:130)*sin(pi/180*directionb);
        plot(x,y,'color','green');
        x=(0:1:100)*cos(pi/180*directionc);
        y=(0:1:100)*sin(pi/180*directionc);
        plot(x,y,'color','blue');          
        axis([-200 200 -200 200])
        hold off
    end
end

function [direction] = measurement_noncoherent(ant_a,ant_b,ant_c)
    u_a = sqrt(ant_a*ant_a');
    u_b = sqrt(ant_b*ant_b');
    u_c = sqrt(ant_c*ant_c');
    s_ab = sign(real(ant_a*ant_b'));
    s_ac = sign(real(ant_a*ant_c'));
    Q = 2*u_a - u_b*s_ab - u_c*s_ac;
    I = sqrt(3)*(u_b*s_ab - u_c*s_ac);
    S = sign(Q*I);
    R = sqrt(Q^2+I^2);
    I = I/R;
    Q = Q/R;
    direction = 180/pi*atan2(Q,I);
    if direction>90
        fprintf('noncoher:I=%f,Q=%f,atan2(I,Q)=%fdeg.\n', I,Q,direction);
        direction = direction - 90;
    end
    if direction<-90
        fprintf('noncoher:I=%f,Q=%f,atan2(I,Q)=%fdeg.\n', I,Q,direction);
        direction = direction + 90;
    end

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
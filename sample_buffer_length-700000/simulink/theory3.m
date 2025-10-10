a = [];
W = [];
for angle = 0:1:360
    [ant_a,ant_b,ant_c] = signal_generator(angle);
    [R, I, Q, direction] = measurement_coherent(ant_a,ant_b,ant_c);
    [R, I, Q, direction1] = measurement_noncoherent(ant_a,ant_b,ant_c);
    W = [W; angle, R, I, Q, direction, direction1];
    a = [a; angle];
    %direction = [direction measurement(angle)];
end

figure(2)
plot(a,W(:,5))
hold all
plot(a,W(:,6))

function [R, I, Q, direction] = measurement_coherent(ant_a,ant_b,ant_c)
    Q = 2*ant_a - ant_b - ant_c;
    I = sqrt(3)*(ant_b - ant_c);
    S = sign(real(Q*I'));
    x = real(Q);
    y = real(I);
    figure(3)
    plot(x,y,'color','red');
    x = imag(Q);
    y = imag(I);
    if S<0
        clr = 'blue';
    else
        clr = 'green';
    end
    plot(x,y,'color',clr);
    hold all
    Q = sqrt(Q*Q');
    I = sqrt(I*I');
    R = sqrt(Q^2+I^2);
    I = S*I/R;
    Q = Q/R;
    direction = -180/pi*atan2(I,Q);
end

function [R, I, Q, direction] = measurement_noncoherent(ant_a,ant_b,ant_c)
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
    direction = -180/pi*atan2(I,Q);
end

function [ant_a,ant_b,ant_c] = signal_generator(angle)
    f = 24000;
    fs = 500000;
    T = 0.0002;
    dt = 1/fs;
    t = [0:dt:T-dt];
    signal = exp(sqrt(-1)*2*pi*f*t);
    ant_a = cos(pi/180*angle)*(signal);
    ant_c = cos(pi/180*(angle+240))*(signal);
    ant_b = cos(pi/180*(angle+120))*(signal);
    figure(1)
    plot([t,t+T,t+2*T,t+3*T],[imag(signal),0*ant_a,0*ant_b,0*ant_c],'color','black');
    hold all
    plot([t,t+T,t+2*T,t+3*T],[0*signal,imag(ant_a),0*ant_b,0*ant_c],'color','red');
    plot([t,t+T,t+2*T,t+3*T],[0*signal,0*ant_a,imag(ant_b),0*ant_c],'color','green');
    plot([t,t+T,t+2*T,t+3*T],[0*signal,0*ant_a,0*ant_b,imag(ant_c)],'color','blue');
    title('signal in antennas a(rd),b(grn),c(blue)');
    hold off
end
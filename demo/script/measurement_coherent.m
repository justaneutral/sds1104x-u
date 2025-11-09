function [direction,dd] = measurement_coherent(ant_s_a,ant_s_b,ant_s_c,noise_level,gain_a,gain_b,gain_c,angle_offset_a,angle_offset_b,angle_offset_c,fignum)
    voltage_offset = noise_level*sqrt(ant_s_a*ant_s_a' + ant_s_b*ant_s_b' + ant_s_c*ant_s_c')/3.0;    
   
    ant_a = ant_s_a * gain_a - voltage_offset;    
    ant_b = ant_s_b * gain_b - voltage_offset;
    ant_c = ant_s_c * gain_c - voltage_offset;

    I = 2*ant_a - ant_b - ant_c;
    Q = sqrt(3)*(ant_c - ant_b);

    S = sign(real(Q*I'));
    Q = S*sqrt(Q*Q');
    I = sqrt(I*I');
    R = sqrt(Q^2+I^2);
    V=complex(I/R,Q/R)*exp(sqrt(-1)*pi*(angle_offset_a)/180);
    Ia = abs(real(V));
    Qa = sign(real(V))*imag(V);

    %correlation receiver
    Sq = real(Q*I')/real(Q*Q');
    Si = real(Q*I')/real(I*I');

    I = 2*ant_b - ant_c - ant_a;
    Q = sqrt(3)*(ant_a - ant_c);
    S = sign(real(Q*I'));
    Q = S*sqrt(Q*Q');
    I = sqrt(I*I');
    R = sqrt(Q^2+I^2);
    V=complex(I/R,Q/R)*exp(sqrt(-1)*pi*(angle_offset_b+60)/180);
    Ib = abs(real(V));
    Qb = sign(real(V))*imag(V); 

    I = 2*ant_c - ant_a - ant_b;
    Q = sqrt(3)*(ant_b - ant_a);
    S = sign(real(Q*I'));
    Q = S*sqrt(Q*Q');
    I = sqrt(I*I');
    R = sqrt(Q^2+I^2);
    V=complex(I/R,Q/R)*exp(sqrt(-1)*pi*(angle_offset_c+120)/180);
    Ic = abs(real(V));
    Qc = sign(real(V))*imag(V);   

    directiona = 180/pi*atan2(Qa,Ia);
    directionb = 180/pi*atan2(Qb,Ib);
    directionc = 180/pi*atan2(Qc,Ic);
    ddab = abs(directiona - directionb) > 90;
    ddbc = abs(directionb - directionc) > 90;
    ddac = abs(directionc - directiona) > 90;
    ddc = (~ddab)&ddac&ddbc;
    ddb = (~ddac)&ddab&ddbc;
    dda = (~ddbc)&ddab&ddac;
    % Ia = Ia*(1-2*dda);
    % Qa = Qa*(1-2*dda);
    % Ib = Ib*(1-2*ddb);
    % Qb = Qb*(1-2*ddb);
    % Ic = Ic*(1-2*ddc);
    % Qc = Qc*(1-2*ddc);
    directiona = directiona - sign(directiona)*180*dda;
    directionb = directionb - sign(directionb)*180*ddb;
    directionc = directionc - sign(directionc)*180*ddc;
    % directiona = mod(90 + directiona + 180*dda,180)-90;
    % directionb = mod(90 + directionb + 180*ddb,180)-90;
    % directionc = mod(90 + directionc + 180*ddc,180)-90;


    directions = sort([directiona,directionb,directionc]);
    %direction = mean(directions);
    direction = 180/pi*atan2(Sq,Si);
    dd = directions(3)-directions(1);
    %direction = direction(2);

    if fig_num > 0
        figure(fig_num);
        subplot(subplot_x,subplot_y,subplot_p);
        hold off
        x=(0:1:180)*cos(pi/180*direction);
        y=(0:1:180)*sin(pi/180*direction);
        plot(x,y,'color','black');
        hold all
        x=(0:1:110)*cos(pi/180*directiona);
        y=(0:1:110)*sin(pi/180*directiona);
        plot(x,y,'color','red');
        x=(0:1:110)*cos(pi/180*directionb);
        y=(0:1:110)*sin(pi/180*directionb);
        plot(x,y,'color','green');
        x=(0:1:110)*cos(pi/180*directionc);
        y=(0:1:110)*sin(pi/180*directionc);
        plot(x,y,'color','blue');          
        axis([-200 200 -200 200])
        titstr = sprintf('AoA = %+03.2f deg. dd=%f,\na=%+03.2f, b=%+03.2f, c=%+03.2f,\nnp=%f, ga=%f, gb=%f, gc=%f,\naa=%f, ab=%f, ac=%f', ...
            direction,dd,directiona,directionb,directionc, ...
            noise_level, gain_a,gain_b,gain_c,angle_offset_a,angle_offset_b,angle_offset_c);
        title(titstr);
        hold off
    end
end

function [direction] = measurement_coherent(ant_a,ant_b,ant_c,angle_offset,fignum)
    I = 2*ant_a - ant_b - ant_c;
    Q = sqrt(3)*(ant_c - ant_b);
    S = sign(real(Q*I'));
    Q = S*sqrt(Q*Q');
    I = sqrt(I*I');
    R = sqrt(Q^2+I^2);
    V=complex(I/R,Q/R)*exp(sqrt(-1)*pi*(angle_offset)/180);
    Ia = abs(real(V));
    Qa = sign(real(V))*imag(V); 

    I = 2*ant_b - ant_c - ant_a;
    Q = sqrt(3)*(ant_a - ant_c);
    S = sign(real(Q*I'));
    Q = S*sqrt(Q*Q');
    I = sqrt(I*I');
    R = sqrt(Q^2+I^2);
    V=complex(I/R,Q/R)*exp(sqrt(-1)*pi*(angle_offset+60)/180);
    Ib = abs(real(V));
    Qb = sign(real(V))*imag(V); 

    I = 2*ant_c - ant_a - ant_b;
    Q = sqrt(3)*(ant_b - ant_a);
    S = sign(real(Q*I'));
    Q = S*sqrt(Q*Q');
    I = sqrt(I*I');
    R = sqrt(Q^2+I^2);
    V=complex(I/R,Q/R)*exp(sqrt(-1)*pi*(angle_offset+120)/180);
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


    %direction = sort([directiona,directionb,directionc]);
    direction = mean([directiona,directionb,directionc]);
    %direction = direction(2);

    if fignum > 0
        figure(fignum)
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
        titstr = sprintf('AoA = %+03.2f deg.',direction);
        title(titstr);
        hold off
    end
end

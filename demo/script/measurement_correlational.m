function [direction,directiona,directionb,directionc] = measurement_correlational(ant_s_a,ant_s_b,ant_s_c,noise_level,gain_a,gain_b,gain_c,reference_angle,fignum)
    epsilon = 0.1;
    voltage_offset = noise_level*sqrt(ant_s_a*ant_s_a' + ant_s_b*ant_s_b' + ant_s_c*ant_s_c')/3.0;    
   
    ant_a = ant_s_a * gain_a - voltage_offset;    
    ant_b = ant_s_b * gain_b - voltage_offset;
    ant_c = ant_s_c * gain_c - voltage_offset;

    I = (2*ant_a - ant_b - ant_c);%.*exp(sqrt(-1)*pi*(angle_offset_a)/180);
    Q = sqrt(3)*(ant_c - ant_b);%.*exp(sqrt(-1)*pi*(angle_offset_a)/180);
    qq = real(Q*Q');
    ii = real(I*I');
    if min(abs(qq),abs(ii))/max(abs(qq),abs(ii)) < epsilon
        Ia = 0;
        Qa = 0;
        Pa = 0;
    else
        Ia = sqrt(abs(real(Q*I'))/real(Q*Q'));
        Qa = sign(real(Q*I'))*sqrt(abs(real(Q*I'))/real(I*I'));
        Pa = min(abs(Ia),abs(Qa))/max(abs(Ia),abs(Qa));
    end

    I = (2*ant_b - ant_c - ant_a);%.*exp(sqrt(-1)*pi*(angle_offset_b+60)/180);
    Q = sqrt(3)*(ant_a - ant_c);%.*exp(sqrt(-1)*pi*(angle_offset_b+60)/180);
    qq = real(Q*Q');
    ii = real(I*I');
    if min(abs(qq),abs(ii))/max(abs(qq),abs(ii)) < epsilon
        Ib = 0;
        Qb = 0;
        Pb = 0;
    else
        Ib = sqrt(abs(real(Q*I'))/qq);
        Qb = sign(real(Q*I'))*sqrt(abs(real(Q*I'))/ii);
        Pb = min(abs(Ib),abs(Qb))/max(abs(Ib),abs(Qb));
    end

    I = (2*ant_c - ant_a - ant_b);%.*exp(sqrt(-1)*pi*(angle_offset_c+120)/180);
    Q = sqrt(3)*(ant_b - ant_a);%.*exp(sqrt(-1)*pi*(angle_offset_c+120)/180);
    qq = real(Q*Q');
    ii = real(I*I');
    if min(abs(qq),abs(ii))/max(abs(qq),abs(ii)) < epsilon
        Ic = 0;
        Qc = 0;
        Pc = 0;
    else
        Ic = sqrt(abs(real(Q*I'))/real(Q*Q'));
        Qc = sign(real(Q*I'))*sqrt(abs(real(Q*I'))/real(I*I'));
        Pc = min(abs(Ic),abs(Qc))/max(abs(Ic),abs(Qc));
    end

    if Pa > Pb && Pa > Pc
       direction =  180/pi*atan2(Qa,Ia);
    else
        if Pb > Pa && Pb > Pc
            direction =  mod(90+180/pi*atan2(Qb,Ib)+60,180)-90;
        else
            if Pc > Pa && Pc > Pb
                direction =  mod(90+180/pi*atan2(Qc,Ic)-60,180)-90;
            else
                if Pa == Pb && Pb > Pc
                    direction_a =  180/pi*atan2(Qa,Ia);
                    direction_b =  mod(90+180/pi*atan2(Qb,Ib)+60,180)-90;
                    direction = (direction_a + direction_b)/2;
                else
                    if Pb == Pc && Pc > Pa
                        direction_b =  mod(90+180/pi*atan2(Qb,Ib)+60,180)-90;
                        direction_c =  mod(90+180/pi*atan2(Qc,Ic)-60,180)-90;
                        direction = (direction_b + direction_c)/2;
                    else
                        if Pa == Pc && Pc > Pb
                            direction_a =  180/pi*atan2(Qa,Ia);
                            direction_c =  mod(90+180/pi*atan2(Qc,Ic)-60,180)-90;
                            direction = (direction_a + direction_c)/2;
                        else
                            direction = 0;
                        end
                    end
                end
            end
        end
    end

    if fignum > 0
        figure(fignum)
        hold off
        x=(0:1:180)*cos(pi/180*direction);
        y=(0:1:180)*sin(pi/180*direction);
        plot(x,y,'color','black');
        hold all
        x=(0:1:160)*cos(pi/180*reference_angle);
        y=(0:1:160)*sin(pi/180*reference_angle);
        plot(x,y,'color','yellow');
        axis([-200 200 -200 200])
        titstr = sprintf('Ref.A = %+03.2f, AoA = %+03.2f deg.\na=%+03.2f, b=%+03.2f, c=%+03.2f,\nnp=%f, ga=%f, gb=%f, gc=%f', ...
            reference_angle,direction, ...
            sqrt(real(ant_s_a*ant_s_a')), sqrt(real(ant_s_b*ant_s_b')), sqrt(real(ant_s_c*ant_s_c')), ...
            noise_level, gain_a,gain_b,gain_c);
        title(titstr);
        hold off
    end
end

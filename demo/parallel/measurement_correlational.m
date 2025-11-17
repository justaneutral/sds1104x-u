function [direction,Pxy,An] = measurement_correlational(ant,squelsh_latch,modulation_mask,reference_angle,fig_num,fig_position,subplot_x,subplot_y,subplot_p)
if sum(squelsh_latch) > 0.47*size(squelsh_latch,1);
    epsilon = 0.01;
    ant_a = ant(1,:);
    ant_b = ant(2,:);
    ant_c = ant(3,:);

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

    if (Pa > Pb && Pa > Pc) || (Pa == Pc && Pc > Pb) || (Pa == Pb && Pb > Pc)
       direction =  180/pi*atan2(Qa,Ia);
       Pxy=Pa;
       An = 1;
    else
        if (Pb > Pa && Pb > Pc) || (Pb == Pc && Pc > Pa)
            direction =  mod(90+180/pi*atan2(Qb,Ib)+60,180)-90;
            Pxy=Pb;
            An = 2;
        else
            if Pc > Pa && Pc > Pb
                direction =  mod(90+180/pi*atan2(Qc,Ic)-60,180)-90;
                Pxy=Pc;
                An = 3;
            else
                direction = 0;
                Pxy = 0;
                An = 0;
            end
        end
    end

    if fig_num > 0
        set(0, 'DefaultFigurePosition', fig_position);
        figure(fig_num);
        subplot(subplot_x,subplot_y,subplot_p);
        hold off
        y=(0:1:180)*cos(pi/180*direction);
        x=(0:1:180)*sin(pi/180*direction);
        plot(x,y,'color','black');
        hold all
        y=(0:1:160)*cos(pi/180*reference_angle);
        x=(0:1:160)*sin(pi/180*reference_angle);
        plot(x,y,'color','yellow');
        axis([-200 200 -200 200]);
        %angle_text = sprintf('%d',cast(direction,'int32'));
        angle_text = sprintf('%3.1f',direction);
        text(-120,0,angle_text,'color','red');
        % titstr = sprintf('Ref.A = %+03.2f, AoA = %+03.2f deg.\nPxy=%f, An=%d\na=%+03.2f, b=%+03.2f, c=%+03.2f,\nnp=%f, ga=%f, gb=%f, gc=%f', ...
        %     reference_angle,direction, ...
        %     Pxy,An, ...
        %     sqrt(real(ant_s_a*ant_s_a')), sqrt(real(ant_s_b*ant_s_b')), sqrt(real(ant_s_c*ant_s_c')), ...
        %     noise_level, gain_a,gain_b,gain_c);
        % title(titstr);
        hold off
    end
else %signal not present
    direction = 0;
    Pxy = 0;
    An = 0;
    if fig_num > 0
        set(0, 'DefaultFigurePosition', fig_position);
        figure(fig_num);
        subplot(subplot_x,subplot_y,subplot_p);
        hold off
        y=(-180:1:180)*cos(pi/180*45);
        x=(-180:1:180)*sin(pi/180*45);
        plot(x,y,'color','black');
        hold all
        y=(-180:1:180)*cos(pi/180*135);
        x=(-180:1:180)*sin(pi/180*135);
        plot(x,y,'color','black');
        hold all
        axis([-200 200 -200 200]);
        text(-120,0,'No signal','color','black');
        hold off
    end
end
end

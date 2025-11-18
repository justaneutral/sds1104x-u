function [direction,Pxy,An,iq_accumulator,ant_color] = measurement_correlational(iq_accumulator,iq_relaxation_gain,ant,squelsh_latch,modulation_mask,reference_angle,fig_num,fig_position,subplot_x,subplot_y,subplot_p)
direction = 0;
Pxy = 0;
An = 0;

r = 1/real(ant(1,:)*ant(1,:)');
g = 1/real(ant(2,:)*ant(2,:)');
b = 1/real(ant(3,:)*ant(3,:)');
rn = min(min(r,g),b);
r = r - rn;
g = g - rn;
b = b - rn;
X = max(max(r,g),b);
r = r/X;
g = g/X;
b = b/X;
X = 1.2;
ant_color = floatsToHexColor(r, g, b, X);

if sum(squelsh_latch) > 0.47*size(squelsh_latch,1)
    epsilon = 0.01;
    ant_a = ant(1,:);
    ant_b = ant(2,:);
    ant_c = ant(3,:);

    I = (2*ant_a - ant_b - ant_c);
    Q = sqrt(3)*(ant_c - ant_b);
    qq = real(Q*Q');
    ii = real(I*I');
    iq = real(I*Q');
    iq_accumulator(1) = iq_accumulator(1)*(1-iq_relaxation_gain)+ii*iq_relaxation_gain;
    iq_accumulator(2) = iq_accumulator(2)*(1-iq_relaxation_gain)+qq*iq_relaxation_gain;
    iq_accumulator(3) = iq_accumulator(3)*(1-iq_relaxation_gain)+iq*iq_relaxation_gain;
    if min(abs(qq),abs(ii))/max(abs(qq),abs(ii)) < epsilon
        Ia = 0;
        Qa = 0;
        Pa = 0;
    else
        Ia = sqrt(abs(iq_accumulator(3))/iq_accumulator(2));
        Qa = sign(iq_accumulator(3))*sqrt(abs(iq_accumulator(3))/iq_accumulator(1));
        Pa = min(abs(Ia),abs(Qa))/max(abs(Ia),abs(Qa));
    end

    I = (2*ant_b - ant_c - ant_a);
    Q = sqrt(3)*(ant_a - ant_c);
    qq = real(Q*Q');
    ii = real(I*I');
    iq = real(I*Q');
    iq_accumulator(4) = iq_accumulator(4)*(1-iq_relaxation_gain)+ii*iq_relaxation_gain;
    iq_accumulator(5) = iq_accumulator(5)*(1-iq_relaxation_gain)+qq*iq_relaxation_gain;
    iq_accumulator(6) = iq_accumulator(6)*(1-iq_relaxation_gain)+iq*iq_relaxation_gain;
    if min(abs(qq),abs(ii))/max(abs(qq),abs(ii)) < epsilon
        Ib = 0;
        Qb = 0;
        Pb = 0;
    else
        Ib = sqrt(abs(iq_accumulator(6))/iq_accumulator(5));
        Qb = sign(iq_accumulator(6))*sqrt(abs(iq_accumulator(6))/iq_accumulator(4));
        Pb = min(abs(Ib),abs(Qb))/max(abs(Ib),abs(Qb));
    end

    I = (2*ant_c - ant_a - ant_b);
    Q = sqrt(3)*(ant_b - ant_a);
    qq = real(Q*Q');
    ii = real(I*I');
    iq = real(I*Q');
    iq_accumulator(7) = iq_accumulator(7)*(1-iq_relaxation_gain)+ii*iq_relaxation_gain;
    iq_accumulator(8) = iq_accumulator(8)*(1-iq_relaxation_gain)+qq*iq_relaxation_gain;
    iq_accumulator(9) = iq_accumulator(9)*(1-iq_relaxation_gain)+iq*iq_relaxation_gain;
    if min(abs(qq),abs(ii))/max(abs(qq),abs(ii)) < epsilon
        Ic = 0;
        Qc = 0;
        Pc = 0;
    else
        Ic = sqrt(abs(iq_accumulator(9))/iq_accumulator(8));
        Qc = sign(iq_accumulator(9))*sqrt(abs(iq_accumulator(9))/iq_accumulator(7));
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
        y=(-150:1:150)*cos(pi/180*direction);
        x=(-150:1:150)*sin(pi/180*direction);
        plot(x,y,'color',ant_color);
        hold all
        y=(50:1:150)*cos(pi/180*reference_angle);
        x=(50:1:150)*sin(pi/180*reference_angle);
        plot(x,y,'color','red');
        for mark = 10:10:350
            y=(110:1:120)*cos(pi/180*mark);
            x=(110:1:120)*sin(pi/180*mark);
            plot(x,y,'color','blue');
        end
        for mark = 30:30:330
            y=(90:1:110)*cos(pi/180*mark);
            x=(90:1:110)*sin(pi/180*mark);
            plot(x,y,'color','green');
        end
        y = (-90:90);
        plot(0*y,y,'color','yellow');
        plot(y,0*y,'color','yellow');
        angle_text = sprintf('%1.2f',r);
        text(-170,-150,angle_text,'color','red');
        angle_text = sprintf('%1.2f',g);
        text(-50,-150,angle_text,'color','green');
        angle_text = sprintf('%1.2f',b);
        text(70,-150,angle_text,'color','blue');
        angle_text = sprintf('%3.1f',direction);
        text(-160,160,angle_text,'color',ant_color);
        axis([-200 200 -200 200]);
        % titstr = sprintf('Ref.A = %+03.2f, AoA = %+03.2f deg.\nPxy=%f, An=%d\na=%+03.2f, b=%+03.2f, c=%+03.2f,\nnp=%f, ga=%f, gb=%f, gc=%f', ...
        %     reference_angle,direction, ...
        %     Pxy,An, ...
        %     sqrt(real(ant_s_a*ant_s_a')), sqrt(real(ant_s_b*ant_s_b')), sqrt(real(ant_s_c*ant_s_c')), ...
        %     noise_level, gain_a,gain_b,gain_c);
        % title(titstr);
        hold off
    end
else %signal not present
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

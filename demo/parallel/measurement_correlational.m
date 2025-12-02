function [direction,Pxy,An,iq_accumulator,ant_color] = measurement_correlational( ...
    min_correlation, ...
    max_peak_to_average, ...
    min_peak_to_average, ...
    max_power_level, ...
    min_power_level, ...
    insist_AoA_return, ...
    iq_accumulator,iq_relaxation_gain,ant,squelsh_latch,modulation_mask,reference_angle,fig_num,fig_position,subplot_x,subplot_y,subplot_p)
direction = 0;
Pxy = 0;
An = 0;
Power_level = -1000;
spawn_end = size(squelsh_latch,2);
r = real(ant(1,:).*conj(ant(1,:)));
g = real(ant(2,:).*conj(ant(2,:)));
b = real(ant(3,:).*conj(ant(3,:)));

e = r+g+b;
Peak_to_average = spawn_end*max(e)/sum(e);

r = spawn_end/sum(r);
g = spawn_end/sum(g);
b = spawn_end/sum(b);
rn = min(min(r,g),b);
r = r - rn;
g = g - rn;
b = b - rn;
X = max(max(r,g),b);
r = r/X;
g = g/X;
b = b/X;
X = 2;
ant_color = floatsToHexColor(r, g, b, X);

cc_channel = [1 2 3]*[floor([r g b])'];
cc_sig = real(ant(cc_channel,:).*conj(ant(cc_channel,:)));
cc_sig = cc_sig - mean(cc_sig);
cc_msk = modulation_mask - mean(modulation_mask);
cc_nrm = (cc_sig*cc_msk')/sqrt((cc_sig*cc_sig')*(cc_msk*cc_msk'));



epsilon = 0.01;
bgcolor = '#999999';
% ant_a = ant(1,:) .* modulation_mask;
% ant_b = ant(2,:) .* modulation_mask;
% ant_c = ant(3,:) .* modulation_mask;
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
if (min(abs(qq),abs(ii))/max(abs(qq),abs(ii)) < epsilon) && (insist_AoA_return == 0)
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
if (min(abs(qq),abs(ii))/max(abs(qq),abs(ii)) < epsilon) && (insist_AoA_return == 0)
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
if (min(abs(qq),abs(ii))/max(abs(qq),abs(ii)) < epsilon)  && (insist_AoA_return == 0)
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
   Power_level = floor(20*log(abs(Ia)+abs(Qa)));
else
    if (Pb > Pa && Pb > Pc) || (Pb == Pc && Pc > Pa)
        direction =  mod(90+180/pi*atan2(Qb,Ib)+60,180)-90;
        Pxy=Pb;
        An = 2;
        Power_level = floor(20*log(abs(Ib)+abs(Qb)));
    else
        if Pc > Pa && Pc > Pb
            direction =  mod(90+180/pi*atan2(Qc,Ic)-60,180)-90;
            Pxy=Pc;
            An = 3;
            Power_level = floor(20*log(abs(Ic)+abs(Qc)));
        else
            direction = 0;
            Pxy = 0;
            An = 0;
        end
    end
end


if cc_nrm < min_correlation
    if insist_AoA_return == 0
        An = 0;
    end
    cc_color = 'magenta';
else
    cc_color = 'black';
end

if Power_level < min_power_level || Power_level > max_power_level
    if insist_AoA_return == 0
        An = 0;
    end
    power_level_color = 'magenta';
else
    power_level_color = 'black';
end

if Peak_to_average < min_peak_to_average || Peak_to_average > max_peak_to_average
    if insist_AoA_return == 0
        An = 0;
    end
    Peak_to_average_color = 'magenta';
else
    Peak_to_average_color = 'black';
end

if fig_num > 0
    set(0, 'DefaultFigurePosition', fig_position);
    figure(fig_num);
    set(gcf, 'color', bgcolor);
    subplot(subplot_y,subplot_x,subplot_p);
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
    r_text = sprintf('%1.2f',r);
    text(-175,-150,r_text,'color','red');
    g_text = sprintf('%1.2f',g);
    text(-50,-150,g_text,'color','green');
    b_text = sprintf('%1.2f',b);
    text(65,-150,b_text,'color','blue');
    angle_text = sprintf('%3.1f',direction);
    text(-175,160,angle_text,'color',ant_color);
    power_level_text = sprintf('%d',Power_level);
    text(-50,160,power_level_text,'color',power_level_color);
    Peak_to_average_text = sprintf('%.1f',Peak_to_average);
    text(65,160,Peak_to_average_text,'color',Peak_to_average_color);
    cc_text = sprintf('%1.2f',cc_nrm);
    text(-197,99,cc_text,'color',cc_color);
    axis([-200 200 -200 200]);
    % titstr = sprintf('Ref.A = %+03.2f, AoA = %+03.2f deg.\nPxy=%f, An=%d\na=%+03.2f, b=%+03.2f, c=%+03.2f,\nnp=%f, ga=%f, gb=%f, gc=%f', ...
    %     reference_angle,direction, ...
    %     Pxy,An, ...
    %     sqrt(real(ant_s_a*ant_s_a')), sqrt(real(ant_s_b*ant_s_b')), sqrt(real(ant_s_c*ant_s_c')), ...
    %     noise_level, gain_a,gain_b,gain_c);
    % title(titstr);
    hold off
end
end

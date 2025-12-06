function [direction,Pxy,An,iq_accumulator,ant_color] = measurement_correlational( ...
    min_correlation, ...
    max_peak_to_average, ...
    min_peak_to_average, ...
    max_power_level, ...
    min_power_level, ...
    insist_AoA_return, ...
    iq_accumulator,iq_relaxation_gain_hz,ant,squelsh_latch,modulation_mask,reference_angle,fig_num,fig_hndl,fig_prm)
epsilon = 0.0000001;

direction = 0;
Pxy = 0;
An = 0;
Power_level = -1000;
spawn_end = size(squelsh_latch,2);
r = real(ant(1,:).*conj(ant(1,:)));
g = real(ant(2,:).*conj(ant(2,:)));
b = real(ant(3,:).*conj(ant(3,:)));

e = r+g+b;
sum_e = sum(e);
Peak_to_average = spawn_end*max(e)/sum_e;

sum_r = sum(r)/sum_e;
sum_g = sum(g)/sum_e;
sum_b = sum(b)/sum_e;

r = 0;
g = 0;
b = 0;
if sum_r<epsilon
    r = 1;
end
if sum_g<epsilon
    g = 1;
end
if sum_b<epsilon
    b = 1;
end
if(r+g+b == 0)
    r = spawn_end/sum_r;
    g = spawn_end/sum_g;
    b = spawn_end/sum_b;
end
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
cc_nrm = (cc_sig*cc_msk');
if abs(cc_nrm)>epsilon
    cc_nrm = cc_nrm/sqrt((cc_sig*cc_sig')*(cc_msk*cc_msk'));
end

iq_relaxation_gain = iq_relaxation_gain_hz * spawn_end;

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
    %set(0, 'DefaultFigurePosition', fig_position);
    %figure(fig_num);
    %set(gcf, 'color', bgcolor);
    %subplot(subplot_y,subplot_x,subplot_p);
    hold(fig_hndl,"off");
    y=(-150:1:150)*cos(pi/180*direction);
    x=(-150:1:150)*sin(pi/180*direction);
    plot(fig_hndl,x,y,'color',ant_color);
    hold(fig_hndl,"all");
    y=(50:1:150)*cos(pi/180*reference_angle);
    x=(50:1:150)*sin(pi/180*reference_angle);
    plot(fig_hndl,x,y,'color','red');
    for mark = 10:10:350
        y=(110:1:120)*cos(pi/180*mark);
        x=(110:1:120)*sin(pi/180*mark);
        plot(fig_hndl,x,y,'color','blue');
    end
    for mark = 30:30:330
        y=(90:1:110)*cos(pi/180*mark);
        x=(90:1:110)*sin(pi/180*mark);
        plot(fig_hndl,x,y,'color','green');
    end
    y = (-90:90);
    plot(fig_hndl,0*y,y,'color','yellow');
    plot(fig_hndl,y,0*y,'color','yellow');

    angle_text = sprintf('AoA = %3.1f deg.',mod(direction,360));
    y=160*cos(pi/180*direction);
    x=160*sin(pi/180*direction);
    text(fig_hndl,x+50*sign(x)-40,y+8*sign(y),angle_text,'color',ant_color);
    y=-y
    x=-x;
    angle_text = sprintf('AoA = %3.1f deg.',mod(direction+180,360));
    text(fig_hndl,x+50*sign(x)-40,y+8*sign(y),angle_text,'color',ant_color);

    y=180*cos(pi/180*reference_angle);
    x=180*sin(pi/180*reference_angle);
    reference_text = sprintf('Ref = %3.1f deg.',reference_angle);
    text(fig_hndl,x+50*sign(x)-40,y+8*sign(y),reference_text,'color','red');

    axis(fig_hndl,[-200 200 -200 200]);
    axis(fig_hndl, 'equal');
    % titstr = sprintf('Ref.A = %+03.2f, AoA = %+03.2f deg.\nPxy=%f, An=%d\na=%+03.2f, b=%+03.2f, c=%+03.2f,\nnp=%f, ga=%f, gb=%f, gc=%f', ...
    %     reference_angle,direction, ...
    %     Pxy,An, ...
    %     sqrt(real(ant_s_a*ant_s_a')), sqrt(real(ant_s_b*ant_s_b')), sqrt(real(ant_s_c*ant_s_c')), ...
    %     noise_level, gain_a,gain_b,gain_c);
    % title(titstr);

    title(fig_hndl,'Reference Angle and Angle of Arrival');
    AoAlbl = sprintf('Angle of Arrival: %3.1f deg.', mod(direction,360));
    Reflbl = sprintf('Reference Angle: %3.1f deg.', mod(reference_angle,360));
    legend(fig_hndl,AoAlbl,Reflbl);
    ylabel(fig_hndl,'Normalized Cosinusoidal Signal Projection Level');
    xlabel(fig_hndl,'Normalized Sinusoidal Signal Projection Level');
    xticks(fig_hndl,[]);
    yticks(fig_hndl,[]);
    hold(fig_hndl,"off");

    title(fig_prm,'Station Signal Detector Parameters');
    xticks(fig_prm,[]);
    yticks(fig_prm,[]);
    axis(fig_prm,[0 100 0 100]);
    hold(fig_prm,"off");
    plot(fig_prm,0,0);
    x = 5;
    y = 95;
    dy = -11;
    r_text = sprintf('Antenna A (0 deg.) relative energy: %1.2f',r);
    text(fig_prm,x,y,r_text,'color','red');
    y = y+dy;
    g_text = sprintf('Antenna B (+120 deg.) relative energy: %1.2f',g);
    text(fig_prm,x,y,g_text,'color','green');
    y = y+dy;
    b_text = sprintf('Antenna C (-120 deg.) relative energy: %1.2f',b);
    text(fig_prm,x,y,b_text,'color','blue');
    y = y+dy;
    power_level_text = sprintf('Estimated SNR: %d  [dB]',Power_level);
    text(fig_prm,x,y,power_level_text,'color',power_level_color);
    y = y+dy;
    Peak_to_average_text = sprintf('Estimated Peak to Average Ratio: %.1f',Peak_to_average);
    text(fig_prm,x,y,Peak_to_average_text,'color',Peak_to_average_color);
    y = y+dy;
    cc_text = sprintf('Signal to Mask Envelope Normalized Cross Correlation: %.1f',cc_nrm);
    text(fig_prm,x,y,cc_text,'color',cc_color);
    hold(fig_prm,"off");
end
%iq_accumulator %% <= dbg
end

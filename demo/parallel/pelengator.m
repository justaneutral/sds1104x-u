close all
%%%%==========parameters==========%%%%
station_center_frequency = [24000; 25200; 16000; 40750; 29350; 31900];
station_bandwidth =        [  300;   200;    20;   300;   500;   400];
station_mask_number =      [    1;     1;     1;     1;     1;     1];
Fs = 500000;
N = 700000;
N_start=1;
N_end=N;
panorama_start_frequency = 20000;
panorama_stop_frequency = 30000;
panorama_mask_file_name = ['panorama_mask_' date '.mat'];
panorama_floor_file_name  = ['panorama_floor_' date '.mat'];
panorama_ceil_file_name  = ['panorama_ceil_' date '.mat'];
squelsh_line_file_name = ['squelsh_line_' date '.mat'];
iq_relaxation_gain = 0.37;
relaxation_gain = 0.37;
squelsh_threshold = 2.0;
squalsh_separation_gain = 0.1;%1.05;
squelsh_band_width = 150;
squelsh_band_width_step = 1;
Num_iterations = 1000000;
num_keep = 100;
trigtreshold = 5;
panorama_gain = 5;
%%%%==========averages============%%%%
M = 2^(ceil(log2(N))-1)-1;
colors = ['#ff0000'; '#00ff00'; '#0000ff'; '#000000'];
dT = 1/Fs;
N_spawn = (N_start:N_end);
T_spawn = (N_spawn-N_start)*dT;
dF = Fs/(2*(M+1));
squelsh_step = floor(squelsh_band_width_step/dF);
squelsh_offset = squelsh_step * floor(floor(squelsh_band_width/(2*dF))/squelsh_step);
squalsh_gain = squelsh_threshold * squelsh_step / (1+2*squelsh_offset);
panorama_start=ceil(panorama_start_frequency/dF);
panorama_end=floor(panorama_stop_frequency/dF);
N_panorama = panorama_end - panorama_start + 1;
panorama_spawn = panorama_start:panorama_end;
panorama_fscale = panorama_spawn*Fs/(2*(M+1));
panorama_history = zeros(num_keep,N_panorama,3);
modulation_mask = zeros(3,N_panorama);
panorama_mask_n = zeros(1,N_panorama);
%load('wrightstown_panorama_mask_true_energy.mat',"wrightstown_panorama_mask_true_energy");
panorama_floor = 100000000000*ones(1,N_panorama); %wrightstown_panorama_mask_true_energy;
panorama_ceil = zeros(1,N_panorama);
squelsh_line = zeros(1,N_panorama);
squelsh_base_line = zeros(1,N_panorama);
num_stations = size(station_center_frequency,1);
directions = zeros(num_stations,num_keep);
Pxys = zeros(num_stations,num_keep);
Ans = zeros(num_stations,num_keep);
IQs = zeros(num_stations,9);
%%%===============screen===================%%%%
% Get the screen size
screenSize = get(0, 'ScreenSize');
screenWidth = screenSize(3);
screenHeight = screenSize(4);
topOffset = 50;
figWidth = (screenWidth-2*topOffset)/5;
figHeight = (screenHeight-2*topOffset)/4;
figWidth1 = screenWidth-2*topOffset;
figHeight1 = (screenHeight-2*topOffset)/2;
fig1position = [screenWidth-5*figWidth-topOffset, screenHeight-figHeight-2*topOffset, figWidth, figHeight];
fig3position = [screenWidth-4*figWidth, screenHeight-figHeight-2*topOffset, figWidth, figHeight];
fig4position = [screenWidth-3*figWidth+1*topOffset, screenHeight-figHeight-2*topOffset, figWidth, figHeight];
fig5position = [screenWidth-2*figWidth+2*topOffset, screenHeight-figHeight-2*topOffset, figWidth, figHeight];
fig2position = [screenWidth-1*figWidth1-topOffset, screenHeight-figHeight-figHeight1-4*topOffset, figWidth1, figHeight1];
%%%%========plotting angles=============%%%%
fig_num = 4;
subplot_x = ceil(sqrt(num_stations));
subplot_y = subplot_x;

%%%%======loop========%%%%
trigcounter = 0;
for i=1:Num_iterations
raw_buffer = read_file_helper(N)';
signal_buffer = [ ...
    [raw_buffer(1:N), zeros(1,2*(M+1)-N)]; ...
    [raw_buffer(N+1:2*N), zeros(1,2*(M+1)-N)]; ...
    [raw_buffer(2*N+1:3*N), zeros(1,2*(M+1)-N)]; ...
    [raw_buffer(3*N+1:4*N), zeros(1,2*(M+1)-N)]];
% signal_buffer = [ ...
%     sin(2*pi*(0000*i+50000)/500000*(1:2*(M+1))); ...
%     cos(2*pi*(-0000*i+100000)/500000*(1:2*(M+1))); ...
%     cos(2*pi*(0000*i+150000)/500000*(1:2*(M+1))); ...
%     sin(2*pi*(-0000*i+200000)/500000*(1:2*(M+1)))];

signal_spawn = signal_buffer(:,N_spawn);

signal_extremum = max(max(abs(signal_spawn)));
set(0, 'DefaultFigurePosition', fig1position);
figure(1)
for j=1:4
    subplot(4,2,2+2*(j-1));
    plot(T_spawn,signal_spawn(j,:),'color',colors(j,:));
    axis([T_spawn(1) T_spawn(end) -1*signal_extremum signal_extremum]);
end
% s = [ ...
%         [complex(signal_buffer(j,:),zeros(1,2*(M+1)))]; ...
%         [complex(zeros(1,2*(M+1)),signal_buffer(j+1,:))] ...
%     ];
fft_buffer = complex(zeros(4,M),zeros(4,M));

for j=1:2:3
    s = complex(signal_buffer(j,:),signal_buffer(j+1,:));
    ff = fft(s);
    a = ff(2:M+1);
    b = flip(ff(M+3:2*(M+1)));
    rp = a+b;
    rn = a-b;
    fft_buffer(j,:) = complex(real(rp),-1*imag(rn));
    fft_buffer(j+1,:) = complex(imag(rp),real(rn));
end

panorama = abs(fft_buffer(:,panorama_spawn));
max_panorama = max(panorama);
panorama_max = max(max_panorama);
max_panorama = panorama_gain*max_panorama/panorama_max;
r=1./panorama(1,:);
g=1./panorama(2,:);
b=1./panorama(3,:);
rgbmin=min(min(r,g),b);
r = r-rgbmin;
g = g-rgbmin;
b = b-rgbmin;
rgbmax = max(max(r,g),b);
r = r./rgbmax;
g = g./rgbmax;
b = b./rgbmax;
r = r.*max_panorama;
g = g.*max_panorama;
b = b.*max_panorama;

panorama_history(1+mod(i-1,num_keep),:,1) = r;
panorama_history(1+mod(i-1,num_keep),:,2) = g;
panorama_history(1+mod(i-1,num_keep),:,3) = b;

if relaxation_gain > 1 
    panorama_mask_n = panorama_mask_n + max(panorama(1:3,:));
    panorama_mask = panorama_mask_n/i;
    panorama_ceil = max(panorama_ceil,max(panorama(1:3,:)));
else
    panorama_mask_n = panorama_mask_n*(1-relaxation_gain) + max(panorama(1:3,:))*relaxation_gain;
    panorama_mask = panorama_mask_n;
    panorama_ceil = max(panorama_ceil*(1-relaxation_gain),max(panorama(1:3,:)));
end
panorama_floor = min(panorama_floor,min(panorama(1:3,:)));

squelsh_line = zeros(1,N_panorama);
for so = -1*squelsh_offset:squelsh_step:squelsh_offset
    squelsh_line(1+squelsh_offset:end-squelsh_offset) = squelsh_line(1+squelsh_offset:end-squelsh_offset) + panorama_mask(1+squelsh_offset+so:end-squelsh_offset+so);
end
squelsh_line(1:squelsh_offset) = squelsh_line(1+squelsh_offset)*ones(1,squelsh_offset);
squelsh_line(end-squelsh_offset+1:end) = squelsh_line(end-squelsh_offset)*ones(1,squelsh_offset);
squelsh_line = squalsh_gain * squelsh_line;
squelsh_base_line(squelsh_offset+1:end-squelsh_offset) = (squelsh_line(1:end-2*squelsh_offset)+squelsh_line(2*squelsh_offset+1:end))/2;
squelsh_base_line(1:squelsh_offset) = squelsh_base_line(squelsh_offset+1)*ones(1,squelsh_offset);
squelsh_base_line(end-squelsh_offset+1:end) = squelsh_base_line(end-squelsh_offset)*ones(1,squelsh_offset);
squelsh_detected = squelsh_base_line*squalsh_separation_gain<squelsh_line;
squelsh_latch = [zeros(1,panorama_start-1) squelsh_detected zeros(1,M-panorama_end)];
set(0, 'DefaultFigurePosition', fig1position);
figure(1)
for j=1:4
    subplot(4,2,1+2*(j-1));
    hold off
    plot(panorama_fscale,panorama(j,:),'color',colors(j,:));
    axis([panorama_fscale(1) panorama_fscale(end) 0 panorama_max]);
end

set(0, 'DefaultFigurePosition', fig2position);
figure(2);
subplot(2,1,1);
hold off
axis([panorama_fscale(1) panorama_fscale(end) 0 panorama_max]);
plot(panorama_fscale,panorama_ceil,'color','red');
hold all
plot(panorama_fscale,panorama,'color','green');
plot(panorama_fscale,panorama_mask,'color','blue');
plot(panorama_fscale,panorama_floor,'color','black');

plot(panorama_fscale,10+panorama_max-squelsh_line,'color','yellow');
plot(panorama_fscale,10+panorama_max-squelsh_base_line,'color','cyan');
plot(panorama_fscale,panorama_max*(1.1-0.2*squelsh_detected),'color','black');

trigcounter = trigcounter + 1;
if trigcounter >= trigtreshold
    trigcounter = 0;
    subplot(2,1,2);
    %hold all
    axis([panorama_fscale(1) panorama_fscale(end) 1 num_keep]);
    image(panorama_history);
    %save(panorama_mask_file_name,"panorama_mask");
    %save(panorama_floor_file_name,"panorama_floor");
    %save(panorama_ceil_file_name,"panorama_ceil");
end

%%%%=================================================%%%%
for j=1:size(station_center_frequency,1)
    station_start_frequency = station_center_frequency(j)-station_bandwidth(j)/2;
    station_stop_frequency = station_center_frequency(j)+station_bandwidth(j)/2;
    if(station_start_frequency > panorama_fscale(1) && station_start_frequency < panorama_fscale(end))
        s_start = ceil(station_start_frequency/dF);
        s_end = floor(station_stop_frequency/dF);
        s_mask = station_mask_number(j);
        s_spawn = s_start:s_end;
        s_fscale = s_spawn*Fs/(2*(M+1));
        s_sig = fft_buffer(:,s_spawn);
        s_latch = squelsh_latch(:,s_spawn);
        s_current = max(abs(s_sig));
        modulation_mask(s_mask,s_spawn-panorama_start+1) = modulation_mask(s_mask,s_spawn-panorama_start+1) + s_current;
        m_mask = modulation_mask(s_spawn-panorama_start+1);
        s_abs = modulation_mask(s_mask,s_spawn-panorama_start+1);
        s_max = max(s_abs);
        s_current = s_current*s_max/max(s_current);
        reference_angle = 0;
        subplot_p = j;
        [directions(j,i),Pxys(j,i),Ans(j,i),IQs(j,:),ant_color] = measurement_correlational(IQs(j,:),iq_relaxation_gain,s_sig,s_latch,m_mask,reference_angle,fig_num,fig4position,subplot_x,subplot_y,subplot_p);
        if i>1 && Pxys(j,i) == 0
            directions(j,i) = directions(j,i-1);
            %directions(j,i) = 361;
        end
        set(0, 'DefaultFigurePosition', fig3position);
        figure(3);
        subplot(subplot_y,subplot_x,subplot_p);
        hold off
        plot(s_fscale,s_abs,'color','yellow');
        hold all
        plot(s_fscale,s_current,'color',ant_color);
        plot(s_fscale,0.63*s_max*s_latch,'color','black');
        axis([s_fscale(1) s_fscale(end) 0 s_max]);
        if Ans(j,i) > 0
            set(0, 'DefaultFigurePosition', fig5position);
            figure(5);
            if i > num_keep
                plot(i-num_keep:i,directions(j,i-num_keep:i),'color',ant_color);
                axis([i-num_keep i -90.5 90.5]);
            else
                plot(1:i,directions(j,1:i),'color',ant_color);
                axis([1 num_keep -90.5 90.5]);
            end
            hold all;
        end
    end
end

end
close all
%%%%==========parameters==========%%%%
% station_center_frequency     = [16000; 24000; 24000; 25000; 25200; 40750; 29350; 31900; 33700];
% station_bandwidth            = [   20;   300;    10;   400;   200;   300;   500;   400;   600];
% station_min_correlation      = [  0.1;   0.1;   0.1;   0.1;   0.1;   0.1;   0.1;   0.1;   0.1];
% station_max_power_level      = [   15;    17;    50;    16;    18;    12;     4;     5;     5];
% station_min_power_level      = [    5;     7;    25;     6;     8;     3;    -5;    -4;    -4];
% station_max_peak_to_average  = [   28;    20;   500;    30;    500;    30;   200;   200;   200];
% station_min_peak_to_average  = [    8;     1;    50;    10;     1;     1;    16;    23;    23];
% station_mask_number          = [    1;     1;     2;     1;     1;     1;     1;     1;     1];
% station_insist_AoA_return    = [    1;     1;     1;     1;     1;     1;     1;     1;     1];
% station_allow_mask_save_flag = [    1;     1;     1;     1;     1;     1;     1;     1;     1];
% station_force_mask_update    = [    1;     1;     1;     1;     1;     1;     1;     1;     1];
% station_active_flag          = [    1;     1;     1;     1;     1;     1;     1;     1;     1];

station_center_frequency     = [10700; 16000; 24000; 24000; 25000; 25200; 40750; 29350; 31900; 33700; 47750; 60000; 77000];
station_bandwidth            = [   10;    19;   220;   220;   400;   200;   200;    50;    40;   300;    20;     3;     3];
station_min_correlation      = [ -0.3; -0.2;  -0.2;  -0.2;  -0.2;  -0.2;  -0.2;  -0.2;  -0.2;  -0.2; -0.2;   -0.3;   -0.3];
station_max_power_level      = [ 50;  15;    27;    70;    16;    18;    12;    24;    24;    24;    24;    50;    50];
station_min_power_level      = [ 0;   5;     4;     4;     6;     8;     3;     4;     4;     14;    4;     3;   3];
station_max_peak_to_average  = [ 300;  28;    20;   500;    30;    20;    30;   200;   200;   200;   200;  1000;   1000];
station_min_peak_to_average  = [ 1;   8;     1;   130;    10;     1;     1;    16;    23;    23;    23;     0;   0];
station_mask_number          = [ 1;   1;     1;     2;     1;     1;     1;     1;     1;     1;     1;     1;   1];
station_insist_AoA_return    = [ 0;   0;     0;     0;     0;     0;     0;     0;     0;     0;     0;     0;   0];
station_allow_mask_save_flag = [ 1;   1;     1;     1;     1;     1;     1;     1;     1;     1;     1;     1;   1];
station_force_mask_update    = [ 1;   1;     1;     1;     1;     1;     1;     1;     1;     1;     1;     1;    1];
%station_active_flag          = [ 0;   0;     1;     1;     0;     1;     0;     0;     0;     0;     0;    1;    1];
station_active_flag          = [ 1;   1;     1;     1;     0;     1;     1;     1;     1;     1;     1;     1;    1];


Fs = 500000;
N = 700000;
N_start=1;
N_end=N;

panorama_start_frequency = 15000; %59750; %39900; %59950; %23000; %47000;
panorama_stop_frequency =  66000; %60350; %42000; %60050; %26000; %49000;

panorama_mask_file_name = ['panorama_mask_' date '.mat'];
panorama_floor_file_name  = ['panorama_floor_' date '.mat'];
panorama_ceil_file_name  = ['panorama_ceil_' date '.mat'];
squelsh_line_file_name = ['squelsh_line_' date '.mat'];
modulation_mask_1_file_name = ['modulation_mask_1_' date '.mat'];
modulation_mask_2_file_name = ['modulation_mask_2_' date '.mat'];
modulation_mask_3_file_name = ['modulation_mask_3_' date '.mat'];
modulation_mask_1_in_file_name = 'modulation_mask_in_1.mat';
modulation_mask_2_in_file_name = 'modulation_mask_in_2.mat';
modulation_mask_3_in_file_name = 'modulation_mask_in_3.mat';
preload_modulation_mask_file = [0,0,0];
station_relaxation_gain = 0.1;  %0.37;
station_relaxation_gain_hz = station_relaxation_gain / max(station_bandwidth.*station_active_flag);
modulation_mask_gain = station_relaxation_gain;
squelsh_relaxation_gain = station_relaxation_gain*0.1; %0.17;
squelsh_threshold = 2.0;
squalsh_separation_gain = 1.01;
squelsh_band_width = 150;
squelsh_band_width_step = 3;

record_signal_flag        = 0;
playback_signal_flag      = 0;
signal_record_file_name_prefix = 'recorded_signal_va_112625';
Starting_Iteration_Number = 1;
Num_iterations            = 1000;
num_keep                  = 16;
trigtreshold              = 1;
panorama_gain             = 10; %40;

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
modulation_mask = ones(3,N_panorama);
if preload_modulation_mask_file(1) > 0
        load(modulation_mask_1_in_file_name,"sfmm");
        modulation_mask(1,:) = sfmm;
end
if preload_modulation_mask_file(2) > 0
        load(modulation_mask_2_in_file_name,"sfmm");
        modulation_mask(2,:) = sfmm;
end
if preload_modulation_mask_file(3) > 0
        load(modulation_mask_3_in_file_name,"sfmm");
        modulation_mask(3,:) = sfmm;
end
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
reference_angle_offsets = zeros(1,num_stations);
reference_angles = zeros(1,num_stations);
reference_angle_valids = zeros(1,num_stations);
%reference_angle_valids_num = zeros(1,3);
%reference_angle_main = zeros(1,3);
%%%===============screen===================%%%%
% Get the screen size
screenSize = get(0, 'ScreenSize');
screenWidth = screenSize(3);
screenHeight = screenSize(4);
topOffset = 50;
figWidth = (screenWidth-2*topOffset)/5;
figHeight = (screenHeight-2*topOffset)/4;
figWidth1 = screenWidth/2-2*topOffset;
figHeight1 = (screenHeight-2*topOffset)/2;
fig1position = [screenWidth-5*figWidth-topOffset, screenHeight-1.5*figHeight-2*topOffset, figWidth, figHeight*1.5];
fig3position = [screenWidth-4*figWidth, screenHeight-figHeight-2*topOffset, figWidth, figHeight];
fig4position = [screenWidth-3*figWidth+1*topOffset, screenHeight-figHeight-2*topOffset, figWidth, figHeight];
fig5position = [screenWidth-2*figWidth+2*topOffset, screenHeight-figHeight-2*topOffset, figWidth, figHeight];
fig2position = [screenWidth-1*figWidth1-topOffset, screenHeight-figHeight-figHeight1-4*topOffset, figWidth1, figHeight1];
controls_pos = [screenWidth-5*figWidth-topOffset, screenHeight-figHeight-figHeight1-5*topOffset, 0.9*figWidth, figHeight*1.8];
%%%%========plotting angles=============%%%%
fig_num = 4;
num_active_stations = 0;
for j=1:size(station_active_flag,1)
    num_active_stations = num_active_stations + ((station_active_flag(j) ~=0) && ((station_center_frequency(j)-station_bandwidth(j)) > panorama_fscale(1)) && ((station_center_frequency(j)+station_bandwidth(j)) < panorama_fscale(end)));
end
[subplot_y, subplot_x] = bestTableShape(num_active_stations);
bgcolor = '#999999';
%%%%==========controls============%%%%
% Shared variable to store button pressed status
% Create a UI figures
try
    delete(userinterfacefigure);
catch
    disp('userinterfacefigure will be createrd');
end
userinterfacefigure = uifigure('Name', 'Button Press Monitor', 'Position', controls_pos);
% Create a toggle switches
toggleswitch_mask_update_3 = uiswitch(userinterfacefigure,'toggle','Items',{'Off mask 3 update','On mask 3 update'},'Position',[100 100 45 20],'Value','Off mask 3 update');
toggleswitch_mask_reset_3 = uiswitch(userinterfacefigure,'toggle','Items',{'Off mask 3 reset','On mask 3 reset'},'Position',[300 100 45 20],'Value','Off mask 3 reset');
toggleswitch_mask_update_2 = uiswitch(userinterfacefigure,'toggle','Items',{'Off mask 2 update','On mask 2 update'},'Position',[100 200 45 20],'Value','On mask 2 update');
toggleswitch_mask_reset_2 = uiswitch(userinterfacefigure,'toggle','Items',{'Off mask 2 reset','On mask 2 reset'},'Position',[300 200 45 20],'Value','Off mask 2 reset');
toggleswitch_mask_update_1 = uiswitch(userinterfacefigure,'toggle','Items',{'Off mask 1 update','On mask 1 update'},'Position',[100 300 45 20],'Value','On mask 1 update');
toggleswitch_mask_reset_1 = uiswitch(userinterfacefigure,'toggle','Items',{'Off mask 1 reset','On mask 1 reset'},'Position',[300 300 45 20],'Value','Off mask 1 reset');
toggleswitch_reference_1 = uiswitch(userinterfacefigure,'toggle','Items',{'Ref1 Keep','Ref1 Set'},'Position',[100 400 45 20],'Value','Ref1 Set');
toggleswitch_reference_2 = uiswitch(userinterfacefigure,'toggle','Items',{'Ref2 Keep','Ref2 Set'},'Position',[200 400 45 20],'Value','Ref2 Set');
toggleswitch_reference_3 = uiswitch(userinterfacefigure,'toggle','Items',{'Ref3 Keep','Ref3 Set'},'Position',[300 400 45 20],'Value','Ref3 Set');
toggleswitch_run_stop = uiswitch(userinterfacefigure,'toggle','Items',{'STOP','RUN'},'Position',[200 500 45 20],'Value','RUN');

%%%%%=====CREATE THEODOLITE CONNECTION================%%%%%%
try
clear theodolite;
theodolite = serialport("COM4", 115200);
%configureTerminator(theodolite, "CR/LF");
configureTerminator(theodolite, "CR");
catch
    disp('theodolite not connected');
end
%%%%======loop========%%%%
trigcounter = 0;
iteration_number = Starting_Iteration_Number-1;
while iteration_number < Num_iterations && isvalid(userinterfacefigure) ...
         && isvalid(toggleswitch_run_stop) && toggleswitch_run_stop.Value(1)=='R' ...
         && isvalid(toggleswitch_reference_1) && isvalid(toggleswitch_reference_2) && isvalid(toggleswitch_reference_3) ...
         && isvalid(toggleswitch_mask_update_1) && isvalid(toggleswitch_mask_reset_1) ...
         && isvalid(toggleswitch_mask_update_2) && isvalid(toggleswitch_mask_reset_2) ...
         && isvalid(toggleswitch_mask_update_3) && isvalid(toggleswitch_mask_reset_3)
iteration_number = iteration_number+1;

%%%%======get/read/save signal====%%%%%
if (playback_signal_flag > 0) || (record_signal_flag > 0) 
    signal_record_file_name = [signal_record_file_name_prefix '_' sprintf('%d',iteration_number) '.mat'];
end
if playback_signal_flag > 0
    load(signal_record_file_name,"raw_buffer");
else
    try
    if theodolite.NumBytesAvailable > 0
        theodolite_angle = readline(theodolite);
        disp('theodolite_angle: ' + theodolite_angle);
    else
        disp('theodolite data not received');
    end
    writeline(theodolite, "A");
    catch
        disp('theodolite unavailable');
        try
            clear theodolite;
            theodolite = serialport("COM4", 115200);
            %configureTerminator(theodolite, "CR/LF");
            configureTerminator(theodolite, "CR");
            writeline(theodolite, "A");
        catch
            disp('theodolite not connected');
        end
    end
    raw_buffer = read_file_helper(N)';
    %raw_buffer = generate_and_write_file_helper(N)';
    if record_signal_flag > 0
        save(signal_record_file_name,"raw_buffer");
    end
end

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

% panorama_history(1+mod(iteration_number-1,num_keep),:,1) = r;
% panorama_history(1+mod(iteration_number-1,num_keep),:,2) = g;
% panorama_history(1+mod(iteration_number-1,num_keep),:,3) = b;

panorama_history(2:end,:,:) = panorama_history(1:end-1,:,:);
panorama_history(1,:,1) = r;%20*log10(r);
panorama_history(1,:,2) = g;%20*log10(g);
panorama_history(1,:,3) = b;%20*log10(b);

if squelsh_relaxation_gain > 1 
    panorama_mask_n = panorama_mask_n + max(panorama(1:3,:));
    panorama_mask = panorama_mask_n/iteration_number;
    panorama_ceil = max(panorama_ceil,max(panorama(1:3,:)));
else
    panorama_mask_n = panorama_mask_n*(1-squelsh_relaxation_gain) + max(panorama(1:3,:))*squelsh_relaxation_gain;
    panorama_mask = panorama_mask_n;
    panorama_ceil = max(panorama_ceil*(1-squelsh_relaxation_gain),max(panorama(1:3,:)));
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
set(gcf,'color',bgcolor);
for j=1:4
    subplot(4,2,1+2*(j-1));
    hold off
    plot(panorama_fscale,panorama(j,:),'color',colors(j,:));
    axis([panorama_fscale(1) panorama_fscale(end) 0 panorama_max]);
end

panorama_min_db = 20*log10(min(panorama_floor));
panorama_max_db = 20*log10(panorama_max);
set(0, 'DefaultFigurePosition', fig2position);
figure(2);
set(gcf,'color',bgcolor);
subplot(2,1,1);
hold off
plot(panorama_fscale,20*log10(panorama_mask/max(panorama_mask)),'color','yellow');
hold all;
plot(panorama_fscale,20*log10(panorama_ceil)-panorama_max_db,'color','red');
plot(panorama_fscale,20*log10((panorama(1,:)+panorama(2,:)+panorama(3,:))/3)-panorama_max_db,'color','black');
plot(panorama_fscale,20*log10(panorama_floor)-panorama_max_db,'color','white');

%plot(panorama_fscale,1.05*panorama_max+0.15*squelsh_line,'color','yellow');
%plot(panorama_fscale,1.05*panorama_max+0.15*squelsh_base_line,'color','green');
%plot(panorama_fscale,1.05*panorama_max*(1+0.05*squelsh_detected),'color','black');
axis([panorama_fscale(1) panorama_fscale(end) -0.5*(panorama_min_db+panorama_max_db) 0]);

trigcounter = trigcounter + 1;
if trigcounter >= trigtreshold
    trigcounter = 0;
    subplot(2,1,2);
    %hold all
    %axis([panorama_fscale(1) panorama_fscale(end) 1 num_keep]);
    image(panorama_history);
    %axis([panorama_fscale(1) panorama_fscale(end) 1 num_keep]);
    %save(panorama_mask_file_name,"panorama_mask");
    %save(panorama_floor_file_name,"panorama_floor");
    %save(panorama_ceil_file_name,"panorama_ceil");
end

%%%%=================================================%%%%
active_station_num = 0;
reference_angle_valids_num = zeros(1,3);
reference_angle_main = zeros(1,3);
reference_rotation_base = 0;
reference_rotation_rate = 0;
for j=1:num_stations
    station_start_frequency = station_center_frequency(j)-station_bandwidth(j)/2;
    station_stop_frequency = station_center_frequency(j)+station_bandwidth(j)/2;
    s_active = (station_active_flag(j) ~=0) && station_start_frequency > panorama_fscale(1) && station_start_frequency < panorama_fscale(end);
    if(s_active)
        active_station_num = active_station_num + 1;
        s_start = ceil(station_start_frequency/dF);
        s_end = floor(station_stop_frequency/dF);
        s_mask = station_mask_number(j);
        s_spawn = s_start:s_end;
        s_fscale = s_spawn*Fs/(2*(M+1));
        s_sig = fft_buffer(:,s_spawn);
        s_latch = squelsh_latch(:,s_spawn);
        s_current = sqrt(sum(s_sig(1:3,:).*conj(s_sig(1:3,:))));
        s_current = s_current/max(s_current);
        sfmm = modulation_mask(s_mask,:);
        s_modulation_mask = sfmm(s_spawn-panorama_start+1);
        s_max = max(s_modulation_mask);
        s_allow_mask_save_flag = station_allow_mask_save_flag(j);

        %reset mask if swith on
        if (toggleswitch_mask_reset_1.Value(2)=='n' && s_mask==1) || (toggleswitch_mask_reset_2.Value(2)=='n' && s_mask==2) ||(toggleswitch_mask_reset_3.Value(2)=='n' && s_mask==3)
            if (toggleswitch_mask_update_1.Value(2)=='f' && s_mask==1)
                if s_allow_mask_save_flag > 0
                    save(modulation_mask_1_file_name,"sfmm");
                end
                toggleswitch_mask_reset_1.Value = 'Off mask 1 reset';
            end
            if (toggleswitch_mask_update_2.Value(2)=='f' && s_mask==2)
                if s_allow_mask_save_flag > 0
                    save(modulation_mask_2_file_name,"sfmm");
                end
                toggleswitch_mask_reset_2.Value = 'Off mask 2 reset';
            end
            if (toggleswitch_mask_update_3.Value(2)=='f' && s_mask==3)
                if s_allow_mask_save_flag > 0
                    save(modulation_mask_3_file_name,"sfmm");
                end
                toggleswitch_mask_reset_3.Value = 'Off mask 3 reset';
            end

            modulation_mask(s_mask,s_spawn-panorama_start+1) = ones(1,s_end-s_start+1);
        end

        %reference_angle = 0;
        subplot_p = active_station_num;
        [directions(j,iteration_number),Pxys(j,iteration_number),Ans(j,iteration_number),IQs(j,:),ant_color] = measurement_correlational( ...
            station_min_correlation(j), ...
            station_max_peak_to_average(j), ...
            station_min_peak_to_average(j), ...
            station_max_power_level(j), ...
            station_min_power_level(j), ...
            station_insist_AoA_return(j), ...
            IQs(j,:),station_relaxation_gain_hz,s_sig,s_latch,s_modulation_mask,reference_angles(j),fig_num,fig4position,subplot_x,subplot_y,subplot_p);
        if iteration_number>1 && Pxys(j,iteration_number) == 0
            directions(j,iteration_number) = directions(j,iteration_number-1);
            %directions(j,i) = 361;
        end
        if Ans(j,iteration_number) > 0 && Pxys(j,iteration_number) > 0 % got a good measurenent
            reference_angle_valids_num(s_mask) = reference_angle_valids_num(s_mask) + station_bandwidth(j);
            reference_angle_valids(j) = 1;
            if (s_mask == 1 && toggleswitch_reference_1.Value(6) == 'S') ... % 'Ref Keep','Ref Set'
            || (s_mask == 2 && toggleswitch_reference_2.Value(6) == 'S') ...
            || (s_mask == 3 && toggleswitch_reference_3.Value(6) == 'S')
                reference_angle_offsets(j) = -1*directions(j,iteration_number);
                reference_angles(j) = 0;
                reference_angle_main(s_mask) = 0;
            else
                reference_angles(j) = directions(j,iteration_number) + reference_angle_offsets(j);
                if reference_angles(j) > 100
                    reference_angles(j) = reference_angles(j) - 180;
                else
                    if reference_angles(j) < -100
                        reference_angles(j) = reference_angles(j) + 180;
                    end
                end
                reference_angle_main(s_mask) = reference_angle_main(s_mask) + reference_angles(j)*station_bandwidth(j);
            end
        else
            reference_angle_valids(j) = 0;
        end
        set(0, 'DefaultFigurePosition', fig3position);
        figure(3);
        set(gcf,'color',bgcolor);
        subplot(subplot_y,subplot_x,subplot_p);
        hold off
        plot(s_fscale,0.63*s_max*s_latch,'color','black');
        hold all
        plot(s_fscale,s_current,'color',ant_color);
        plot(s_fscale,s_modulation_mask,'color','yellow');
        axis([s_fscale(1) s_fscale(end) 0 s_max]);
        if (Ans(j,iteration_number) > 0) || (station_force_mask_update(j) > 0)
            %update if signal was present and ipdate swith on
            if (toggleswitch_mask_update_1.Value(2)=='n' && s_mask==1) || (toggleswitch_mask_update_2.Value(2)=='n' && s_mask==2) ||(toggleswitch_mask_update_3.Value(2)=='n' && s_mask==3)  
                modulation_mask(s_mask,s_spawn-panorama_start+1) = modulation_mask(s_mask,s_spawn-panorama_start+1)*(1-modulation_mask_gain) + s_current*modulation_mask_gain;
            end
            set(0, 'DefaultFigurePosition', fig5position);
            figure(5);
            set(gcf,'color',bgcolor);
            subplot(subplot_y,subplot_x,subplot_p);
            if iteration_number > num_keep
                unwrapped_directions = unwrap_aoa(directions(j,iteration_number-num_keep:iteration_number));
                plot(iteration_number-num_keep:iteration_number,unwrapped_directions,'color',ant_color);
                axis([iteration_number-num_keep iteration_number -180 180]);
            else
                unwrapped_directions = unwrap_aoa(directions(j,1:iteration_number));
                plot(1:iteration_number,unwrapped_directions,'color',ant_color);
                axis([1 num_keep -180 180]);
            end
            hold all;
        end
    end
end

if toggleswitch_reference_1.Value(6) == 'S' % 'Ref1 Keep','Ref1 Set'
    toggleswitch_reference_1.Value = 'Ref1 Keep';
else
    if reference_angle_valids_num(1) > 0
        reference_angle_main(1) = reference_angle_main(1) / reference_angle_valids_num(1);
    end
end
if(reference_angle_valids_num(1) > 0)
    fprintf('\nreference_angle_main 1: %f\n', mod(360-reference_angle_main(1),360));
    fprintf('reference_angle_valids_num 1: %d\n', reference_angle_valids_num(1));
    for j=1:num_stations
        if reference_angle_valids(j) && station_mask_number(j) == 1
            fprintf('st: %d, f=%.2f kHz, msk#%d, ref ang: %f\n', j, (station_center_frequency(j)/1000), station_mask_number(j), mod(360-reference_angles(j),360));
        end
    end
else
    disp('signals of group 1 unavailable');
end

if toggleswitch_reference_2.Value(6) == 'S' % 'Ref2 Keep','Ref2 Set'
    toggleswitch_reference_2.Value = 'Ref2 Keep';
else
    if reference_angle_valids_num(2) > 0
        reference_angle_main(2) = reference_angle_main(2) / reference_angle_valids_num(2);
    end
end
if(reference_angle_valids_num(2) > 0)
    fprintf('\nreference_angle_main 2: %f\n', mod(reference_angle_main(2),360));
    fprintf('reference_angle_valids_num 2: %d\n', reference_angle_valids_num(2));
    for j=1:num_stations
        if reference_angle_valids(j) && station_mask_number(j) == 2
            fprintf('st: %d, f=%.2f kHz, msk#%d, ref ang: %f\n', j, (station_center_frequency(j)/1000), station_mask_number(j), mod(reference_angles(j),360));
        end
    end
else
    disp('signals of group 2 unavailable');
end

if toggleswitch_reference_3.Value(6) == 'S' % 'Ref3 Keep','Ref3 Set'
    toggleswitch_reference_3.Value = 'Ref3 Keep';
else
    if reference_angle_valids_num(3) > 0
        reference_angle_main(3) = reference_angle_main(3) / reference_angle_valids_num(3);
    end
end
if(reference_angle_valids_num(3) > 0)
    fprintf('\nreference_angle_main 3: %f\n', mod(reference_angle_main(3),360));
    fprintf('reference_angle_valids_num 3: %d\n', reference_angle_valids_num(3));
    for j=1:num_stations
        if reference_angle_valids(j) && station_mask_number(j) == 3
            fprintf('st: %d, f=%.2f kHz, msk#%d, ref ang: %f\n', j, (station_center_frequency(j)/1000), station_mask_number(j), mod(reference_angles(j),360));
        end
    end
else
    disp('signals of group 3 unavailable');
end

reference_rotation_base = sum(reference_angle_main) - reference_rotation_base;
reference_rotation_rate = reference_rotation_rate + reference_rotation_base;
reference_rotation_rate = reference_rotation_rate /(1 + abs(max(reference_angle_valids.*reference_angles) - min(reference_angle_valids.*reference_angles)));
IQs = IQs./(1+abs(reference_rotation_rate));
fprintf('reference_rotation_rate = %f\n', reference_rotation_rate);
% if abs(reference_rotation_rate) > 10
%     IQs = zeros(size(IQs));
%     reference_rotation_rate = 0;
% end

drawnow; % Allow UI updates
%pause(57.1);
end
try
    clear theodolite;
catch
    disp('theodolite was not present');
end
try
    delete(userinterfacefigure)
catch
    disp('userinterfacefigure was not present');
end




% Callback functions


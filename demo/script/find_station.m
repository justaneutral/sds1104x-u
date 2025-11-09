%The approximate coordinates for 826 Cherry Lane, Newtown, PA 18940 are:
%Latitude: 40.2485° N
%Longitude: 74.9367° W
%Heading from 826 Cherry Lane, Newtown, PA 18940

% calculate an angle between direction to north and to radiator from 40.2485° N 74.9367° W

% The GQD VLF station at Anthorn, Cumbria, UK
% 29.7 kHz and its coordinates are:
% Latitude: 54.911° N
% Longitude: 3.280° W
% Grid Reference: NY179581
% Locator: IO84iv
%Distance: ~5,400 km (3,355 mi)
%Heading from Newtown, PA: 54.6° true (northeast by east)

% The VLF station NAA Cutler, operated by the U.S. Navy.
% 24.0 kHz
% Call Sign: NAA
% Location: Cutler, Maine, USA
% Coordinates:
% Latitude: 44.644506° N
% Longitude: 67.284565° W
% Frequency: 24.0 kHz (also transmits on 17.8 kHz)
% Distance: ~800 km (500 mi)
% Heading from Newtown, PA: 58.2° true (northeast)

% The VLF station NML LaMoure, operated by the U.S. Navy.
% 25.2 kHz
% Call Sign: NML
% Location: LaMoure, North Dakota, USA
% Coordinates:
% Latitude: 46.365987° N
% Longitude: 98.335667° W
% Purpose: Submarine communications
% Distance: ~2,000 km (1,240 mi)
% Heading from Newtown, PA: 296.4° true (west-northwest)

% The VLF station NLK
% 24.8 kHz
% Call Sign: NLK
% Location: Jim Creek, Washington, at approximately 48.2037° N, 121.9167° W. 
% Distance: ~2,000 km (1,240 mi)
% Heading from Newtown, PA: 297.4° true (west-northwest)

%[b_mean,b_dev] = find_direction(f_shift,Fcap,Frezolution,threshild, expected_bearing_angle)

%control parameters
antenna_direction_angle_start =0;
antenna_direction_angle_stop = 350;
antenna_direction_angle_step = 10;
files_bunch_amount = 10;
take_new_files = 0;
new_file_prefix = 'day20251107';

%panorama parameters
fignum_panorama = 8;
create_panorama = 0;
show_panorama = 0;
show_life_panorama = 0;
f_shift = -50000;
Fcap = 20000;
Frezolution = 0.1;


%common parameters
find_directions = 0;
N = 700000;
Fs = 500000;

if take_new_files > 0
    %save to files
    for antenna_direction_angle = antenna_direction_angle_start:antenna_direction_angle_step:antenna_direction_angle_stop
        [~] = read_file_helper(N); % make sure no wrong angle penetrated
        [~] = read_file_helper(N);
        for file_index = 0:files_bunch_amount-1
            buf = read_file_helper(N);
            disp('buffer received');
            fname = sprintf('%s_signal_%01d_%03d_degree',new_file_prefix,file_index,antenna_direction_angle);
            save(fname,"buf");
            fprintf('written to file: %s\n',fname);
        end
        if (antenna_direction_angle+antenna_direction_angle_step) <= antenna_direction_angle_stop
            request = sprintf('change from %d to %d, hit a key\n>',antenna_direction_angle,(antenna_direction_angle+antenna_direction_angle_step));
            display(request);
            pause
        else
            disp('All signal files collected');
        end
    end
end


if create_panorama > 0
    [~] = accumulate_panorama(f_shift,Fcap,Frezolution,-1,0);
    for antenna_direction_angle = antenna_direction_angle_start:antenna_direction_angle_step:antenna_direction_angle_stop
        for file_index = 0:files_bunch_amount-1
            fname = sprintf('%s_signal_%01d_%03d_degree',new_file_prefix,file_index,antenna_direction_angle);
            load(fname,"buf");
            fprintf('read file: %s\n',fname);
            fbuf = accumulate_panorama(f_shift,Fcap,Frezolution,fignum_panorama,buf);
        end
    end
    panorama_name = sprintf('%s_panorama_f_shift_%d_Fcap_%d_Fresolution_%f.mat',new_file_prefix,f_shift,Fcap,Frezolution);
    save(panorama_name,"fbuf");
    fprintf('saved panorama file: %d\n',panorama_name);
end

if show_panorama > 0 && fignum_panorama > 0
    panorama_name = sprintf('%s_panorama_f_shift_%d_Fcap_%d_Fresolution_%f.mat',new_file_prefix,f_shift,Fcap,Frezolution);
    load(panorama_name,"fbuf");
    fprintf('loaded panorama file: %s\n',panorama_name);
    Ns = size(fbuf,2);
    Np = 2*Fcap/Frezolution;

    NumChannels = 3; % max 4
    Nfft = 2^ceil(log2(Fs/Frezolution));
    Ncap = [max(1,Nfft/2 - ceil(Nfft*Fcap/Fs)), min(Nfft,Nfft/2 + ceil(Nfft*Fcap/Fs))];
    Nextract = [Ncap(1)+Nfft/2, Nfft, 1, Ncap(2)-Nfft/2];
    Fscale = ([Ncap(1):Ncap(2)]'-Nfft/2)*Frezolution;
    FscaleTrue = Fscale - f_shift;

    fprintf('Fmin=%d,Fmax=%d\n', FscaleTrue(1), FscaleTrue(end))

    figure(fignum_panorama);
    hold off
    plot(FscaleTrue,fbuf,'color','black');
    titstr = sprintf('Avg.|FFT| Ncap(1)=%d Ncap(2)=%d Nfft/2=%d Frezolution=%f',Ncap(1),Ncap(2),Nfft/2,Frezolution);
    title(titstr);
end

if show_life_panorama > 0 && fignum_panorama > 0
    NumChannels = 3; % max 4
    Nfft = 2^ceil(log2(Fs/Frezolution));
    Ncap = [max(1,Nfft/2 - ceil(Nfft*Fcap/Fs)), min(Nfft,Nfft/2 + ceil(Nfft*Fcap/Fs))];
    Nextract = [Ncap(1)+Nfft/2, Nfft, 1, Ncap(2)-Nfft/2];
    Fscale = ([Ncap(1):Ncap(2)]'-Nfft/2)*Frezolution;
    FscaleTrue = Fscale - f_shift;

    fprintf('Fmin=%d,Fmax=%d\n', FscaleTrue(1), FscaleTrue(end))

    figure(fignum_panorama);
    hold off
    buf = read_file_helper(N);
    disp('buffer received');
    [fbuf, Na] = accumulate_panorama(f_shift,Fcap,Frezolution,-1,buf)
    buf = read_file_helper(N);
    [fbuf, Na] = accumulate_panorama(f_shift,Fcap,Frezolution,fignum_panorama,buf);
end





if find_directions > 0
    for antenna_direction_angle = antenna_direction_angle_start:antenna_direction_angle_step:antenna_direction_angle_stop
        for file_index = 0:files_bunch_amount-1
            fname = sprintf('%s_signal_%01d_%03d_degree',new_file_prefix,file_index,antenna_direction_angle);
            load(fname,"buf");
            fprintf('read file: %s\n',fname);
            find_direction(-11000,1000,1,0.0,0,buf) % 10-12 kHz
            find_direction(-13000,1000,1,0.0,10,buf) % 12-14 kHz
            find_direction(-15000,1000,1,0.0,20,buf) % 14-16 kHz
            find_direction(-17000,1000,1,0.0,30,buf) % 16-18 kHz
            find_direction(-19000,1000,1,0.0,40,buf) % 18-20 kHz
            find_direction(-21000,1000,1,0.0,50,buf) % 20-22 kHz
            find_direction(-23000,1000,1,0.0,60,buf) % 22-24 kHz
            find_direction(-25000,1000,1,0.0,70,buf) % 24-26 kHz
            find_direction(-27000,1000,1,0.0,80,buf) % 26-28 kHz
            find_direction(-29000,1000,1,0.0,90,buf) % 28-30 kHz
            find_direction(-31000,1000,1,0.0,100,buf) % 30-32 kHz
            find_direction(-33000,1000,1,0.0,110,buf) % 32-34 kHz
            find_direction(-35000,1000,1,0.0,120,buf) % 34-36 kHz
            find_direction(-37000,1000,1,0.0,130,buf) % 36-38 kHz
            find_direction(-39000,1000,1,0.0,140,buf) % 38-40 kHz
            find_direction(-41000,1000,1,0.0,150,buf) % 40-42 kHz
            find_direction(-43000,1000,1,0.0,160,buf) % 42-44 kHz
            find_direction(-45000,1000,1,0.0,170,buf) % 44-46 kHz
            find_direction(-47000,1000,1,0.0,180,buf) % 46-48 kHz
            find_direction(-49000,1000,1,0.0,190,buf) % 48-50 kHz
            find_direction(-51000,1000,1,0.0,200,buf) % 50-52 kHz
            find_direction(-53000,1000,1,0.0,210,buf) % 52-54 kHz
            find_direction(-55000,1000,1,0.0,220,buf) % 54-56 kHz
            find_direction(-57000,1000,1,0.0,230,buf) % 56-58 kHz
            find_direction(-59000,1000,1,0.0,240,buf) % 58-60 kHz
            find_direction(-61000,1000,1,0.0,250,buf) % 60-62 kHz
            find_direction(-63000,1000,1,0.0,260,buf) % 62-64 kHz
            find_direction(-65000,1000,1,0.0,270,buf) % 64-66 kHz
            find_direction(-67000,1000,1,0.0,280,buf) % 66-68 kHz
            find_direction(-69000,1000,1,0.0,290,buf) % 68-70 kHz
        end
    end
end

%found stations
fig_num = fignum_panorama + 10;
subplot_x = 2;
subplot_y = 2;
close all
for iterind = 1:200
    %buf = read_file_helper(N);
    accumulate_panorama(-30000,20000,1,-1,buf);
    accumulate_panorama(-30000,20000,1,fignum_panorama+1,buf);
    accumulate_panorama(-40000,20000,1,-1,buf);
    accumulate_panorama(-40000,20000,1,fignum_panorama+2,buf);
    % find_direction(-24050,400,1,0.0,0,buf,fig_num,subplot_x,subplot_y,1);
    % find_direction(-38250,200,1,0.0,64,buf,fig_num,subplot_x,subplot_y,2);
    % find_direction(-33700,300,1,0.0,-50,buf,fig_num,subplot_x,subplot_y,3); % Sitka, Ak
    % %find_direction(-24000,2,0.1,0.0,-6,buf,fig_num,subplot_x,subplot_y,3); % NAA? 24.0 kHz 2 Hz
    % find_direction(-24000,100,0.1,0.0,-34.8,buf,fig_num,subplot_x,subplot_y,4); % NAA? 24.0 kHz 100 Hz
end

%find_direction(-24000,200,0.1,0.00,58.2) % NAA 24.0 kHz 200 Hz
%find_direction(-24000,5,0.1,0.00,58.2) % NAA 24.0 kHz 200 Hz
%find_station_direction(-25200,150,0.1,0.001) % NML 25.2 kHz 100 Hz
%find_direction(-25200,150,0.1,0.0,-57) % NML 25.2 kHz 100 Hz
%find_direction(-29700,600,0.1,0.0, 54.6) % Hawaii, USA
%find_direction(-36000,6000,1,0.002) % North Dakota, USA
%find_direction(-60000,10,0.1,0.00) % WWVB, Colorado

%find_station_direction(-16025,50,0.1,0.1) % panorama around 37.5khz
%find_station_direction(-16000,1000,0.1,0.001) % panorama around 37.5khz

%find_station_direction(-12650,400,1,0.001)
%find_station_direction(-20900,1400,1,0.001)
%find_station_direction(-23400,1400,1,0.001)
%find_station_direction(-38000,200,1,0.01,'bearing_abc_values_38khz.txt');
%find_station_direction(-29725,460,1,0.2) % negev ? ISL +54.7, GQD +54.6

%find_station_direction(-24000,200,1,0.2)
%find_direction(-29760,20,1,0.02) % points to 0 at needle 45
%find_station_direction_noncoherent(-29700,360,1,0.05,'bearing_abc_values_gqd.txt'); % GQD needle 90
%find_station_direction_noncoherent(-24000,100,1,0.0,'bearing_abc_values_naa_90needle_tmp.txt') % NAA
%find_station_direction_noncoherent(-24000,100,1,0.0,'bearing_abc_values_naa_rotating_antenna.txt') % NAA
%find_station_direction(-24000,100,1,0.0) % NAA
%find_station_direction_noncoherent(-29700,360,1,0.05,'90gqd+00.txt') % GQD
%find_station_direction_noncoherent(-29700,360,1,0.05,'gqd+15.txt') % GQD
%find_station_direction_noncoherent(-29700,360,1,0.05,'gqd-15.txt') % GQD
%find_station_direction_noncoherent(-25200,100,1,0.05,'nml+00.txt') % NML
%find_station_direction_noncoherent(-25200,100,1,0.05,'nml-15.txt') % NML
%find_station_direction_noncoherent(-25200,100,1,0.05,'nml+15.txt') % NML
%find_station_direction_noncoherent(-24000,100,1,0.05,'naa+00.txt') % NAA
%find_station_direction_noncoherent(-24000,100,1,0.05,'naa-15.txt') % NAA
%find_station_direction_noncoherent(-24000,100,1,0.05,'naa+15.txt') % NAA
%find_station_direction(-25200,100,1,0.0) % NML
%find_station_direction(-24800,100,0.1,0.3); % NLK
%find_station_direction(-50002,6,1,0.003);
%find_station_direction(-77500,6000,1,0.003);
%find_station_direction(-86000,8000,0.1,0.000);
%find_station_direction_noncoherent(-86000,3,0.1,0.000,'bearing_abc_values_86khz.txt') % time,frequency?
%find_station_direction(-50000,30000,0.1,0.0001);
%find_station_direction_noncoherent(-76020,200,1,0.1);
%find_station_direction(-136750,1050,0.1,0.002) % amat 135.7–137.8
%find_station_direction(-139250,9250,0.1,0.002) % maritime location 130.0–148.5
%find_station_direction(-139997,5,0.1,0.002) % maritime location 130.0–148.5
%find_station_direction(-140001.5,2,0.1,0.002) % maritime location 130.0–148.5

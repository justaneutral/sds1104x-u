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

%[b_mean,b_dev] = find_station_direction(f_shift,Fcap,Frezolution,threshild)
%find_station_direction(-37600,10000,1,0.01) % panorama around 37.5khz
%find_station_direction(-24000,200,1,0.001) % panorama around 24khz
%find_station_direction(-12650,400,1,0.001)
%find_station_direction(-20900,1400,1,0.001)
%find_station_direction(-23400,1400,1,0.001)
%find_station_direction(-38000,200,1,0.01,'bearing_abc_values_38khz.txt');
%find_station_direction(-29725,460,1,0.2) % negev ? ISL +54.7, GQD +54.6
%find_station_direction(-29725,560,1,0.2)
find_station_direction(-24000,200,1,0.2)
%find_station_direction(-29760,20,1) % points to 0 at needle 45
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
%%find_station_direction(-25200,100,1,0.0) % NML
%find_station_direction(-24800,100,0.1,0.3); % NLK
%find_station_direction(-50002,6,1,0.003);
%find_station_direction(-77500,6000,1,0.003);
%find_station_direction(-86000,8000,0.1,0.000);
%find_station_direction_noncoherent(-86000,3,0.1,0.000,'bearing_abc_values_86khz.txt') % time,frequency?
%find_station_direction(-100000,150,0.1,0.3);
%find_station_direction_noncoherent(-76020,200,1,0.1);
%find_station_direction(-136750,1050,0.1,0.002) % amat 135.7–137.8
%find_station_direction(-139250,9250,0.1,0.002) % maritime location 130.0–148.5
%find_station_direction(-139997,5,0.1,0.002) % maritime location 130.0–148.5
%find_station_direction(-140001.5,2,0.1,0.002) % maritime location 130.0–148.5

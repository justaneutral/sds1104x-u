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
%find_station_direction(-29725,260,1,0.2) % negev ? ISL +54.7, GQD +54.6
%find_station_direction(-29725,560,1,0.2)
%find_station_direction(-29760,20,1) % points to 0 at needle 45
find_station_direction(-24000,100,1,000.3) % NAA
%find_station_direction(-25200,100,1,0.01) % points to 0 at needle 350
%find_station_direction(-24800,6000,1,0.003);
%find_station_direction(-50002,6,1,0.003);
%find_station_direction(-77500,6000,1,0.003);
%find_station_direction(-100000,150,0.1,0.3);
%find_station_direction_noncoherent(-76020,200,1,0.1);


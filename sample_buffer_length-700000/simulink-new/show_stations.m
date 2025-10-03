%The approximate coordinates for 826 Cherry Lane, Newtown, PA 18940 are:
%Latitude: 40.2485° N
%Longitude: 74.9367° W
%Heading from 826 Cherry Lane, Newtown, PA 18940

num_frames = 50

% The GQD VLF station at Anthorn, Cumbria, UK
% 29.7 kHz and its coordinates are:
% Latitude: 54.911° N
% Longitude: 3.280° W
% Grid Reference: NY179581
% Locator: IO84iv
%Distance: ~5,400 km (3,355 mi)
%Heading from Newtown, PA: 54.6° true (northeast by east)
gqd_reference = 54.6;
[gqd000mean,gqd000dev] = show_accumulated_station('GQD',-29700,800,1,'antenna_at_000_degree',num_frames)
[gqd050mean,gqd050dev] = show_accumulated_station('GQD',-29700,800,1,'antenna_at_050_degree',num_frames)
[gqd100mean,gqd100dev] = show_accumulated_station('GQD',-29700,800,1,'antenna_at_100_degree',num_frames)

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
naa_reference = 58.2;
[naa000mean,naa000dev] = show_accumulated_station('NAA',-24000,200,1,'antenna_at_000_degree',num_frames)
[naa050mean,naa050dev] = show_accumulated_station('NAA',-24000,200,1,'antenna_at_050_degree',num_frames)
[naa100mean,naa100dev] = show_accumulated_station('NAA',-24000,200,1,'antenna_at_100_degree',num_frames)

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
nml_reference = 296.4-180;
[nml000mean,nml000dev] = show_accumulated_station('NML',-25200,200,1,'antenna_at_000_degree',num_frames)
[nml050mean,nml050dev] = show_accumulated_station('NML',-25200,200,1,'antenna_at_050_degree',num_frames)
[nml100mean,nml100dev] = show_accumulated_station('NML',-25200,200,1,'antenna_at_100_degree',num_frames)


txt = sprintf([ ...
    'gqd_reference = %.6f\n' ...
    'gqd000mean    = %.6f\n' ...
    'gqd000dev     = %.6f\n' ...
    'gqd050mean    = %.6f\n' ...
    'gqd050dev     = %.6f\n' ...
    'gqd100mean    = %.6f\n' ...
    'gqd100dev     = %.6f\n' ...
    'naa_reference = %.6f\n' ...
    'naa000mean    = %.6f\n' ...
    'naa000dev     = %.6f\n' ...
    'naa050mean    = %.6f\n' ...
    'naa050dev     = %.6f\n' ...
    'naa100mean    = %.6f\n' ...
    'naa100dev     = %.6f\n' ...
    'nml_reference = %.6f\n' ...
    'nml000mean    = %.6f\n' ...
    'nml000dev     = %.6f\n' ...
    'nml050mean    = %.6f\n' ...
    'nml050dev     = %.6f\n' ...
    'nml100mean    = %.6f\n' ...
    'nml100dev     = %.6f\n'], ...
    gqd_reference, gqd000mean, gqd000dev, gqd050mean, gqd050dev, gqd100mean, gqd100dev, ...
    naa_reference, naa000mean, naa000dev, naa050mean, naa050dev, naa100mean, naa100dev, ...
    nml_reference, nml000mean, nml000dev, nml050mean, nml050dev, nml100mean, nml100dev);

% Write to file
fid = fopen('bearing_summary.txt','w');   % use 'a' to append instead of overwrite
assert(fid>0, 'Could not open bearing_summary.txt for writing.');
c = onCleanup(@() fclose(fid));           % ensure the file closes even on error
fprintf(fid, '%s', txt);

% Also print to terminal
fprintf('%s', txt);

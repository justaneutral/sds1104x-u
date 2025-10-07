
filename_gqd = 'bearing_abc_values_gqd.txt'
filename_naa = 'bearing_abc_values_naa.txt'
filename_nml = 'bearing_abc_values_nml.txt'
row_num_gqd = 1;
row_req_gqd = 2;
row_num_naa = 1;
row_req_naa = 2;
row_num_nml = 1;
row_req_nml = 2;
while row_num_gqd > 0 && row_num_nml > 0 && row_num_naa > 0
    [row_num_gqd, a2, b2, c2] = read_three_at_row(filename_gqd, row_req_gqd);
    [row_num_naa, a0, b0, c0] = read_three_at_row(filename_naa, row_req_naa);
    [row_num_nml, a1, b1, c1] = read_three_at_row(filename_nml, row_req_nml);
    if row_num_naa > 0 && row_num_nml > 0 % new set received
        values_NAA = [a0, b0, c0];
        values_NML = [a1, b1, c1];
        values_GQD = [a2, b2, c2];
        calibrate_naa_nml_gqd_locked(values_NAA,values_NML, values_GQD)
        %theta_deg_ = computeaoa(values);
        %fprintf("%d->%f:(%f,%f,%f)\n",row_req,theta_deg,a,b,c);
        row_req_naa = row_num_naa;
        row_req_nml = row_num_nml;
    end
end





function calibrate_naa_nml_gqd_locked(values_NAA,values_NML, values_GQD)
    % True azimuths to VLF stations (degrees)
    heading_NAA = 46.0;
    heading_NML = 296.0;
    heading_GQD = 54.6;

    % Raw antenna vectors (Ant1, Ant2, Ant3)
    %values_NAA = [802640.448319, 220417.174424, -902404.306957];
    %values_NML = [251566.292536, 290376.346016, -94049.318930];

    % --- Final sector corrections ---
    doa_NAA = resolve(values_NAA, 0);     % No correction
    doa_NML = resolve(values_NML, 240);   % +240° correction
    doa_GQD = resolve(values_GQD, 0);     %no correction

    % Compute signed offsets
    offset_NAA = wrap_signed(heading_NAA - doa_NAA);
    offset_NML = wrap_signed(heading_NML - doa_NML);
    offset_GQD = wrap_signed(heading_GQD - doa_GQD);

    % Display results
    fprintf('\n--- Final Calibration ---\n');
    fprintf('GQD → DoA: %7.2f°, Offset: %+7.2f°\n', doa_GQD, offset_GQD);
    fprintf('NAA → DoA: %7.2f°, Offset: %+7.2f°\n', doa_NAA, offset_NAA);
    fprintf('NML → DoA: %7.2f°, Offset: %+7.2f°\n', doa_NML, offset_NML);
end

function doa = resolve(values, sector_shift)
    % Normalize input vector
    values = values / norm(values);

    % Coil geometry: 3-sector layout at 120° intervals
    coil_angles_deg = [0, 120, 240];
    coil_angles_rad = deg2rad(coil_angles_deg);

    % Project onto unit circle
    x = sum(values .* cos(coil_angles_rad));
    y = sum(values .* sin(coil_angles_rad));

    % Compute wrapped angle and apply sector correction
    doa = mod(rad2deg(atan2(y, x)) + sector_shift, 360);
end

function signed = wrap_signed(angle)
    % Wrap angle to range [-180, +180]
    signed = mod(angle + 180, 360) - 180;
end

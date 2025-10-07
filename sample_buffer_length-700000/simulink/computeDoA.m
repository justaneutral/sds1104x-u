filename = 'bearing_abc_values_naa.txt'
row_num = 1;
row_req = 2;
while row_num > 0
    [row_num, a, b, c] = read_three_at_row(filename, row_req);
    if row_num > 0 % new set received
        values = [a, b, c];
        theta_deg = computeaoa(values);
        fprintf("%d->%f:(%f,%f,%f)\n",row_req,theta_deg,a,b,c);
        row_req = row_num;
    end
end


function theta_deg = computeaoa(values)
% function theta_deg = computeDoA(values)
%     angles_deg = [0, 120, 240];
%     values = values / norm(values);
%     angles_rad = deg2rad(angles_deg);
%     x = sum(values .* cos(angles_rad));
%     y = sum(values .* sin(angles_rad));
%     theta_deg = mod(rad2deg(atan2(y, x)), 360);
%     fprintf('Estimated source direction: %.2f°\n', theta_deg);
% end
    % values: 3-element vector of antenna outputs [a1, a2, a3]
    % Antenna angles in degrees
    angles_deg = [0, 120, 240];  % 240° = -120° mod 360

    % Normalize input values
    values = values / norm(values);

    % Convert angles to radians
    angles_rad = deg2rad(angles_deg);

    % Compute unit vectors for each antenna direction
    x = sum(values .* cos(angles_rad));
    y = sum(values .* sin(angles_rad));

    % Compute direction of arrival
    theta_rad = atan2(y, x);
    theta_deg = mod(rad2deg(theta_rad), 360);  % Wrap to [0, 360)

    % Display result
    fprintf('Estimated source direction: %.2f°\n', theta_deg);
end




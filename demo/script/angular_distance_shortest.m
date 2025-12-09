% --- Helper Function to calculate the shortest angular difference ---
function diff = angular_distance_shortest(angle1_norm, angle2_norm)
    % Calculates the shortest angular distance between two angles (0 to 360 range)
    delta_angle = angle2_norm - angle1_norm;
    % Modulo arithmetic to wrap difference into [-180, 180) range
    diff = mod(delta_angle + 180, 360) - 180;
end
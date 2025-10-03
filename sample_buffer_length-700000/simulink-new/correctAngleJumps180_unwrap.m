function ang_out = correctAngleJumps180_unwrap(ang_in)
    phi = deg2rad(2*ang_in);           % map 0..180 -> 0..360
    phi_u = unwrap(phi);               % remove 2π jumps
    ang_out = rad2deg(phi_u)/2;        % map back (continuous, ±180 fixes)
end


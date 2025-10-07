function ang = geoAnglesFourPoints(latlon)
% GEOANGLESFOURPOINTS  Signed angles (deg) from 4 geo points.
% INPUT:
%   latlon : 4x2 [lat lon] in degrees, rows = [pt1; pt2; pt3; pt4]
% OUTPUT (struct, degrees in (-180,180]):
%   ang.np_1_2, ang.np_1_3, ang.np_1_4   (North → pt1→ptk)
%   ang.p2_1_3, ang.p2_1_4, ang.p3_1_4   (pt1→pti → pt1→ptj)
%
% Convention: bearings are clockwise from North (0°..360°).
% The angle returned is the signed minimal difference b2 - b1,
% positive = clockwise turn at pt1.

    arguments
        latlon (4,2) double
    end

    % Unpack
    lat1 = latlon(1,1); lon1 = latlon(1,2);
    lat2 = latlon(2,1); lon2 = latlon(2,2);
    lat3 = latlon(3,1); lon3 = latlon(3,2);
    lat4 = latlon(4,1); lon4 = latlon(4,2);

    % Bearings from pt1 to others (deg, 0=N, clockwise)
    b12 = initial_bearing(lat1,lon1, lat2,lon2);
    b13 = initial_bearing(lat1,lon1, lat3,lon3);
    b14 = initial_bearing(lat1,lon1, lat4,lon4);

    % North (0°) vs bearings
    ang_np_1_2 = angle_diff_signed(0,  b12);
    ang_np_1_3 = angle_diff_signed(0,  b13);
    ang_np_1_4 = angle_diff_signed(0,  b14);

    % Pairwise at pt1
    ang_p2_1_3 = angle_diff_signed(b12, b13);
    ang_p2_1_4 = angle_diff_signed(b12, b14);
    ang_p3_1_4 = angle_diff_signed(b13, b14);

    ang = struct('np_1_2',ang_np_1_2, ...
                 'np_1_3',ang_np_1_3, ...
                 'np_1_4',ang_np_1_4, ...
                 'p2_1_3',ang_p2_1_3, ...
                 'p2_1_4',ang_p2_1_4, ...
                 'p3_1_4',ang_p3_1_4);
end

function b = initial_bearing(lat1,lon1, lat2,lon2)
% Great-circle initial azimuth from (lat1,lon1) to (lat2,lon2), deg [0,360)
    if isequal([lat1,lon1],[lat2,lon2])
        b = NaN; return;
    end
    Phy1 = deg2rad(lat1);  Lambda1 = deg2rad(lon1);
    Phy2 = deg2rad(lat2);  Lambda2 = deg2rad(lon2);
    dLambda = Lambda2 - Lambda1;
    y = sin(dLambda) * cos(Phy2);
    x = cos(Phy1)*sin(Phy2) - sin(Phy1)*cos(Phy2)*cos(dLambda);
    b = rad2deg(atan2(y, x));
    b = mod(b + 360, 360);
end

function a = angle_diff_signed(b1, b2)
% Signed minimal angle from b1 to b2, deg in (-180, 180], positive = clockwise
    if isnan(b1) || isnan(b2)
        a = NaN; return;
    end
    d = b2 - b1;
    a = mod(d + 180, 360) - 180;
    if a == -180, a = 180; end  % choose (−180,180] instead of [−180,180)
end

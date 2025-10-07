%Newtown 40.2485° N 74.9367° W
%GQD 54.911° N 3.280° W
%NAA 44.644506° N 67.284565° W
%NML 46.365987° N 98.335667° W
% pt1 (vertex), pt2, pt3, pt4: [lat lon] deg
latlon = [
    40.2485      -74.9367  % pt1: PA
    54.911          +3.28  % pt2: GQD
    44.644506  -67.284565  % pt3: NAA
    46.365987  -98.335667  % pt4: NML
];

ang = geoAnglesFourPoints(latlon)

% ang.np_1_2 is the angle at pt1 between North and direction to pt2, etc.

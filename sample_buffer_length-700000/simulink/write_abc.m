function write_abc(fid, a, b, c)
% WRITE_ABC Write three numeric values to an open file (single line).
%   WRITE_ABC(fid, a, b, c)
    validateattributes(fid, {'numeric'}, {'scalar','integer','nonnegative'});
    validateattributes(a, {'numeric'}, {'scalar'});
    validateattributes(b, {'numeric'}, {'scalar'});
    validateattributes(c, {'numeric'}, {'scalar'});
    fprintf(fid, '%f %f %f\n', a, b, c);
end

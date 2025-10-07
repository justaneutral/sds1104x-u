function fid = open_abclog(filename, mode)
% OPEN_ABCLOG Open a text file for writing formatted values.
%   fid = OPEN_ABCLOG(filename)          % append mode by default
%   fid = OPEN_ABCLOG(filename,'w')      % overwrite
%   fid = OPEN_ABCLOG(filename,'a')      % append
    if nargin < 2, mode = 'a'; end
    [fid,msg] = fopen(filename, mode, 'n', 'UTF-8');
    if fid < 0
        error('open_abclog:openFailed', 'Could not open %s: %s', filename, msg);
    end
end

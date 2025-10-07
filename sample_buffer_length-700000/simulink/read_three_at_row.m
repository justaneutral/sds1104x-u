function [row_num, a, b, c] = read_three_at_row(filename, row_req)
% READ_THREE_AT_ROW  Read three floats from a given text row.
%   [row_num, a, b, c] = read_three_at_row(filename, row_req)
%   - Input:
%       filename : text file with lines like "%f %f %f\n"
%       row_req  : 1-based row index to read on this call
%   - Output:
%       row_num  : NEXT row index to read (row_req+1). If EOF/not found/parse
%                  failure, returns 0.
%       a,b,c    : values read from that row (NaN if row_num==0)
%
%   Behavior:
%     * Opens the file (UTF-8), skips to row_req, reads that line,
%       parses three floats, closes the file.
%     * If row_req is beyond EOF or the line can’t be parsed into 3 floats,
%       returns row_num=0 and a=b=c=NaN.

    arguments
        filename (1,1) string
        row_req (1,1) double {mustBeInteger, mustBePositive}
    end

    a = NaN; b = NaN; c = NaN;    % defaults
    row_num = 0;                  % default to EOF/failure

    [fid, msg] = fopen(filename, 'r', 'n', 'UTF-8');
    if fid < 0
        warning('read_three_at_row:openFailed', 'Could not open %s: %s', filename, msg);
        return
    end
    cleaner = onCleanup(@() fclose(fid));

    % Skip to the requested row (1-based)
    for k = 1:row_req-1
        tline = fgets(fid);
        if ~ischar(tline) && tline == -1
            % Reached EOF before target row
            return
        end
    end

    % Read the target row
    tline = fgets(fid);
    if ~ischar(tline) && tline == -1
        % Target row doesn't exist
        return
    end

    % Parse three floats from the line (space/tab separated)
    vals = sscanf(tline, '%f %f %f');
    if numel(vals) < 3
        % Not enough numeric tokens on this line
        return
    end

    a = vals(1); b = vals(2); c = vals(3);
    row_num = row_req + 1;   % next row to read on the next call
end
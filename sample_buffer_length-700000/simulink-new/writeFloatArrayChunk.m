function meta = writeFloatArrayChunk(filename, data)
% Append a floating-point array to a binary log file with metadata.
% If the file doesn't exist, it's created and initialized.
% Returns a struct 'meta' with the written chunk's metadata.
%
% File/Chunk format:
%   File header (once): char[8] 'FARRAY01'
%   For each chunk:
%       uint64  chunk_index       (1-based)
%       uint64  length_n
%       int64   epoch_ms          (UTC, POSIX epoch milliseconds)
%       char[24] timestamp_iso    ('YYYY-MM-DDTHH:MM:SS.mmmZ')
%       double[length_n] data     (ieee-le)

    arguments
        filename (1,1) string
        data {mustBeFloat}        % accept single/double; will store as double
    end

    % Ensure row vector of doubles for consistent byte layout
    data = double(data(:).');          % 1-by-N
    n = uint64(numel(data));

    % Open (create if missing) for read/update in little-endian
    [fid,msg] = fopen(filename, 'a+b', 'ieee-le');
    assert(fid>0, "Failed to open file: %s", msg);
    c = onCleanup(@() fclose(fid));

    % If new/empty file, write file header
    fseek(fid, 0, 'eof');
    if ftell(fid) == 0
        fseek(fid, 0, 'bof');
        fwrite(fid, uint8('FARRAY01'), 'uint8');
    end

    % Determine next chunk index by scanning
    nextIdx = local_countChunks(fid) + 1;

    % Build timestamps (UTC)
    nowUtc = datetime('now','TimeZone','UTC');
    ts_iso = datestr(nowUtc, 'yyyy-mm-ddTHH:MM:SS.FFF');  % 23 chars
    ts_iso = string(ts_iso) + "Z";                        % -> 24 chars
    if strlength(ts_iso) ~= 24
        error('Unexpected ISO string length.');
    end
    epoch_ms = int64(floor(posixtime(nowUtc) * 1000));

    % Append chunk at EOF
    fseek(fid, 0, 'eof');
    fwrite(fid, uint64(nextIdx), 'uint64');
    fwrite(fid, n,               'uint64');
    fwrite(fid, epoch_ms,        'int64');
    fwrite(fid, uint8(char(ts_iso)), 'uint8');           % 24 bytes
    fwrite(fid, data, 'double');

    % Return metadata
    meta = struct( ...
        'index',        double(nextIdx), ...
        'length',       double(n), ...
        'epoch_ms',     epoch_ms, ...
        'timestamp_iso', char(ts_iso) ...
    );
end

function count = local_countChunks(fid)
% Count chunks by scanning from start.
    fseek(fid, 0, 'bof');
    % Validate header
    magic = fread(fid, 8, 'uint8=>char')';
    if isempty(magic)
        count = 0; return;
    end
    if ~strcmp(magic, 'FARRAY01')
        error('Invalid file header (magic mismatch).');
    end
    count = 0;
    while true
        % Attempt to read fixed-size chunk header
        hdr = fread(fid, 2, 'uint64');
        if numel(hdr) < 2
            break; % EOF reached cleanly
        end
        % Skip epoch_ms (int64) + timestamp (24 bytes)
        fseek(fid, 8 + 24, 'cof'); % 8 bytes int64 + 24 bytes char
        n = hdr(2);
        % Skip data payload (n doubles)
        ok = (fseek(fid, double(n)*8, 'cof') == 0);
        if ~ok
            % Truncated/incomplete tail
            break;
        end
        count = count + 1;
    end
end

function mustBeFloat(x)
    if ~isfloat(x)
        error('Input "data" must be single or double.');
    end
end

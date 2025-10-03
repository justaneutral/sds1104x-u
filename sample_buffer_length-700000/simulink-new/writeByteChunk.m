function meta = writeByteChunk(filename, bytes)
% Append a uint8 array to a binary file with chunk metadata.
% Creates the file if it does not exist.
% Returns metadata struct of the written chunk.
%
% Format:
%   Header (once): char[8] 'FARRAY01'
%   Chunk:
%       uint64   chunk_index
%       uint64   length_n
%       int64    epoch_ms (UTC)
%       char[24] timestamp_iso ('YYYY-MM-DDTHH:MM:SS.mmmZ')
%       uint8[n] data

    arguments
        filename (1,1) string
        bytes {mustBeUint8Vector}
    end

    % Ensure row vector uint8
    bytes = uint8(bytes(:).');
    n = uint64(numel(bytes));

    % Open/create file for append+read, little-endian
    [fid,msg] = fopen(filename, 'a+b', 'ieee-le');
    assert(fid>0, "Failed to open file: %s", msg);
    c = onCleanup(@() fclose(fid));

    % If empty file, write magic header
    fseek(fid, 0, 'eof');
    if ftell(fid) == 0
        fseek(fid, 0, 'bof');
        fwrite(fid, uint8('FARRAY01'), 'uint8');
    end

    % Determine next chunk index by scanning existing chunks
    nextIdx = local_countChunks(fid) + 1;

    % Timestamps (UTC)
    nowUtc   = datetime('now','TimeZone','UTC');
    ts_iso   = datestr(nowUtc, 'yyyy-mm-ddTHH:MM:SS.FFF'); % 23 chars
    ts_iso   = string(ts_iso) + "Z";                       % -> 24
    if strlength(ts_iso) ~= 24
        error('Unexpected ISO timestamp length.');
    end
    epoch_ms = int64(floor(posixtime(nowUtc) * 1000));

    % Append this chunk
    fseek(fid, 0, 'eof');
    fwrite(fid, uint64(nextIdx), 'uint64');
    fwrite(fid, n,               'uint64');
    fwrite(fid, epoch_ms,        'int64');
    fwrite(fid, uint8(char(ts_iso)), 'uint8');            % fixed 24 bytes
    fwrite(fid, bytes, 'uint8');

    % Return metadata
    meta = struct( ...
        'index',         double(nextIdx), ...
        'length_bytes',  double(n), ...
        'epoch_ms',      epoch_ms, ...
        'timestamp_iso', char(ts_iso) ...
    );
end

function count = local_countChunks(fid)
% Count chunks by scanning from BOF; stops cleanly at EOF or on truncation.
    fseek(fid, 0, 'bof');
    magic = fread(fid, 8, 'uint8=>char')';
    if isempty(magic)
        count = 0; return;
    end
    if ~strcmp(magic, 'FARRAY01')
        error('Invalid file header (magic mismatch).');
    end
    count = 0;
    while true
        % Read index and length
        hdr = fread(fid, 2, 'uint64');
        if numel(hdr) < 2
            break; % EOF
        end
        n = hdr(2);

        % Skip epoch_ms (8) + timestamp (24)
        if fseek(fid, 8 + 24, 'cof') ~= 0
            break; % truncated
        end
        % Skip payload bytes
        if fseek(fid, double(n), 'cof') ~= 0
            break; % truncated
        end

        count = count + 1;
    end
end

function mustBeUint8Vector(x)
    if ~(isa(x,'uint8') && (isvector(x) || isempty(x)))
        error('Input "bytes" must be a uint8 vector.');
    end
end

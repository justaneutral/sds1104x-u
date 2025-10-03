function [bytes, meta] = readByteChunk(filename, chunkIndex)
% Read the specified (1-based) chunk from the file written by writeByteChunk.
% Returns: bytes (uint8 row) and meta struct with fields:
%   index, length_bytes, epoch_ms, timestamp_iso

    arguments
        filename (1,1) string
        chunkIndex (1,1) double {mustBePositive, mustBeInteger}
    end

    [fid,msg] = fopen(filename, 'rb', 'ieee-le');
    assert(fid>0, "Failed to open file: %s", msg);
    c = onCleanup(@() fclose(fid));

    % Validate header
    magic = fread(fid, 8, 'uint8=>char')';
    if ~strcmp(magic, 'FARRAY01')
        error('Invalid file header (magic mismatch).');
    end

    % Scan to target chunk
    while true
        idx = fread(fid, 1, 'uint64');
        if isempty(idx)
            error('Chunk %d not found (EOF).', chunkIndex);
        end
        n = fread(fid, 1, 'uint64');
        if isempty(n)
            error('Truncated file while reading length for chunk %d.', chunkIndex);
        end
        epoch_ms = fread(fid, 1, 'int64');
        ts_bytes = fread(fid, 24, 'uint8=>char')';
        if numel(ts_bytes) ~= 24
            error('Truncated file while reading timestamp for chunk %d.', chunkIndex);
        end

        if double(idx) == chunkIndex
            % Read payload
            bytes = fread(fid, double(n), 'uint8')';
            if numel(bytes) ~= double(n)
                error('Truncated file while reading data for chunk %d.', chunkIndex);
            end
            meta = struct( ...
                'index',         double(idx), ...
                'length_bytes',  double(n), ...
                'epoch_ms',      epoch_ms, ...
                'timestamp_iso', string(ts_bytes) ...
            );
            return;
        else
            % Skip payload and continue
            if fseek(fid, double(n), 'cof') ~= 0
                error('Truncated file while skipping data for chunk %d.', double(idx));
            end
        end
    end
end

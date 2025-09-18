function byte_array = read_file_helper()
    % This helper function reads a 1024-byte file
    filename = 'temp_output.txt';
    fid = fopen(filename,'rb');
    if fid ~= -1
        data = fread(fid, 1024, '*uint8');
        fclose(fid);
        byte_array = data;
    else
        byte_array = zeros(1024,1,'uint8'); % fallback
    end
end
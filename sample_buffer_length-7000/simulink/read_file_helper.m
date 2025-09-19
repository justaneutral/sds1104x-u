function byte_array = read_file_helper(N)
    coder.extrinsic('delete');
    filename = 'temp_output.txt';
    fid = fopen(filename,'rb');
    while fid == -1
        pause(0.1); % sleep for 100 milliseconds
        fid = fopen(filename,'rb');
    end
    data = fread(fid, 4*N, '*uint8');
    while isempty(data)
       data = fread(fid, 4*N, '*uint8');
    end
    fclose(fid);
    delete(filename);
    byte_array = data;
end

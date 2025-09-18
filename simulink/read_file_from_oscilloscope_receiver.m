% this is for simulink matlab module
function buffer = read_file_from_oscilloscope_receiver()
    persistent buf
    if isempty(buf)
        buf = zeros(1024,1,'uint8');
    end
    buffer = zeros(1024,1,'uint8');
    % Call helper function to get latest data
    buf = read_file_helper();
    buffer(:) = buf(:);
end

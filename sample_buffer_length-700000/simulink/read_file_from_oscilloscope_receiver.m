% this is for simulink matlab module
function [ch0,ch1,ch2,ch3] = read_file_from_oscilloscope_receiver()
    persistent buf
    N = 7000;
    if isempty(buf)
        buf = zeros(4*N,1,'uint8');
    end
    % Call helper function to get latest data
    buf = read_file_helper(N);
    ch0 = buf(1:N);
    ch1 = buf(N+1:2*N);
    ch2 = buf(2*N+1:3*N);
    ch3 = buf(3*N+1:4*N);
end


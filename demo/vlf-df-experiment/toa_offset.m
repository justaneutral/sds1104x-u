function [rg,rb,gb] = toa_offset(fft_buffer,s_spawn)
persistent rgp rbp gbp
if isempty(rgp)
    rgp = 0;
    rbp = 0;
    gbp = 0;
end
alpha = 0.1;
b0 = fft_buffer;
b0(1,s_spawn) = zeros(size(s_spawn));
b0(2,s_spawn) = zeros(size(s_spawn));
b0(3,s_spawn) = zeros(size(s_spawn));
b0(4,s_spawn) = zeros(size(s_spawn));
b1 = fft_buffer-b0;
%b1 = fft_buffer(:,s_spawn);
%b0 = [b1 flipud(conj(b1(:,2:end)))];
b0r = [b1(1,:) flip(conj(b1(1,2:end)))];
b0g = [b1(2,:) flip(conj(b1(2,2:end)))];
b0b = [b1(3,:) flip(conj(b1(3,2:end)))];
ba = real(ifft(b0r.*conj(b0g)));
bb = real(ifft(b0r.*conj(b0b)));
bc = real(ifft(b0g.*conj(b0b)));

b1 = [ba(end-1:end) ba(1:3)] / (ba(1));
b2 = [bb(end-1:end) bb(1:3)] / (bb(1));
b3 = [bc(end-1:end) bc(1:3)] / (bc(1));

rgp = rgp *(1-alpha) + b1*alpha;
rbp = rbp *(1-alpha) + b2*alpha;
gbp = gbp *(1-alpha) + b3*alpha;

rg = b1*[-1 -1 0 1 1]';
rb = b2*[-1 -1 0 1 1]';
gb = b3*[-1 -1 0 1 1]';


figure(22)
plot(rgp,'color','blue');
hold all
plot(rbp,'color','green');
plot(gbp,'color','red');
hold off
end

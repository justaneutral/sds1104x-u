% https://www.mwlist.org/vlf.php

% Active VLF Transmitters and Their Azimuths from Newtown, PA
% Station Location                        Frequency (kHz) Coordinates             Power (kW)      Azimuth from Newtown (°)
% NAA     Cutler, ME, USA                 24.0            44.645° N, 67.282°  W   800             68.2°
% NLK     Jim Creek, WA, USA              24.8            48.203° N, 121.917° W   300             112.6°
% NPM     Lualualei, HI, USA              21.4            21.420° N, 158.151° W   424             190.1°
% NML     LaMoure, ND, USA                25.2            46.366° N, 98.336°  W   800             90.3°
% NAU     Aquada, PR, USA                 40.8            18.399° N, 67.178°  W   800             85.6°
% NWC     North West Cape, Australia      19.8            21.816° S, 114.166° E   1000            262.6°
% DHO38   Rhauderfehn, Germany            23.4            53.087° N, 7.609°   E   800             13.8°
% HWU     Rosnay, France  20.9            46.7            13°     N, 1.245°   E   800             19.6°
% ICV     Tavolara, Italy 20.27           40.9            23°     N, 9.731°   E   800             14.6°
% JXN     Gildeskål, Norway               16.4            66.983° N, 13.873°  E   800             7.3°

%f_shift = -7980; %
%Fcap = 150; % Hz one side BW
%Frezolution = 1; % Hz fft bin

% f_shift = -9012; % ???
% Fcap = 100; % Hz one side BW
% Frezolution = 0.1; % Hz fft bin

% JXN
f_shift = -16068; 
Fcap = 1.5; % Hz one side BW
Frezolution = 0.125; % Hz fft bin

% NAA
f_shift = -24000; 
Fcap = 100; % Hz one side BW
Frezolution = 1; % Hz fft bin

% NML
% f_shift = -25200;
% Fcap = 100; % Hz one side BW
% Frezolution = 1; % Hz fft bin

%test station 3
% f_shift = -29700;
% Fcap = 400; % Hz one side BW
% Frezolution = 1; % Hz fft bin

% test station 4
% f_shift = -38200;
% Fcap = 150; % Hz one side BW
% Frezolution = 1; % Hz fft bin

% panorama
% f_shift = -24000;
% Fcap = 12000; % Hz one side BW
% Frezolution = 10; % Hz fft bin

N = 700000;
Fs = 500000;

Station_ID = ['JXN' 'NAA' 'NML' '#3?' '#4?']
f_shift = [-16068, -24000, -25200, -29700, -38200]
Fcap = [1.5 100 100 400 150]
Fresolution = [0.125 1 1 1 1]

%Fpass = Fs/10; %Fcap;       % Filter passband Hz
%Fstop = Fpass*1.5;  % Filter stopband Hz
%Astop = 60;         % Stopband attenuation in dB
%filter_coefficients = design_fir_coeffs(Fpass, Fstop, Fs, Astop);
% Plot responses in figure 3
%plot_fir_response(b, 3);

NumRepetitions = 100;
NumChannels = 3; % max 4

%iterate through stations
for st = 1:5
    Nfft(st) = 2^ceil(log2(Fs(st)/Frezolution(st)));
    Ncap(st,:) = [max(1,Nfft(st)/2 - ceil(Nfft(st)*Fcap(st)/Fs)), min(Nfft(st),Nfft(st)/2 + ceil(Nfft(st)*Fcap(st)/Fs))];
    Nextract(st) = [Ncap(st,1)+Nfft(st)/2, Nfft(st), 1, Ncap(st,2)-Nfft(st)/2];
    Fscale(st) = ([Ncap(st,1):Ncap(st,2)]'-Nfft(st)/2)*Frezolution(st);
    ch = zeros(N,NumChannels);
    energy = zeros(NumChannels,1);
    energies = zeros(NumChannels,NumRepetitions);
    signum = zeros(NumChannels,1);
    signums = zeros(NumChannels,NumRepetitions);
    alpha_estimated = zeros(NumChannels,1);
    alphas = zeros(NumChannels,NumRepetitions);
    chcut = zeros(size(Fscale,1),NumChannels);
    chftsum = zeros(size(Fscale,1),NumChannels);
end

for i=1:1:NumRepetitions
    % Call helper function to get latest data
    buf = read_file_helper(N);
    %freq. conversion
    ag = 1.0j.*2.*pi.*double(f_shift)./double(Fs).*(0:1:N-1)';
    mx = exp(ag);
    for chnum = 1:NumChannels;
        ch(:,chnum) = double(int8(buf((chnum-1)*N+1:chnum*N))).*mx;
        chex = [zeros(Nfft-floor(N/2),1) ; ch(:,chnum); zeros(Nfft-N+floor(N/2),1)];
        chft = fft(chex,Nfft);
        chcut(:,chnum) = [chft(Nextract(1):Nextract(2)); chft((Nextract(3):Nextract(4)))];
        chcut_abs = abs(chcut(:,chnum));
        chftsum(:,chnum) = chcut_abs;
        figure(1);
        plot(Fscale,chftsum(:,chnum));
        hold all
        energy(chnum) = 0.*energy(chnum) + chcut(:,chnum)'*chcut(:,chnum);
        if chnum>1
            signum(chnum) = chcut(:,chnum-1)'*chcut(:,chnum);
        end
    end
    signum(1) = chcut(:,1)'*chcut(:,NumChannels);
    legend('ch1 min at 0/180, max at 90/270 deg.','ch2 min at 60/240, max at 150/330 deg','ch3 min at 120/300, max at 30/210')
    hold off
    for k=0:2
        a = energy(1+mod(k,3));
        b = energy(1+mod(k+1,3));
        c = energy(1+mod(k+2,3));
        sinalpha = (b-c) * sqrt(3.0);
        cosalpha = b + c -2*a;
        %alpha_estimated = mod(atan2(sinalpha,cosalpha)-k*2*pi/3,2*pi)
        alpha_estimated(k+1) = 90/pi*(mod(atan2(sinalpha,cosalpha)-2/3*pi*(k-1),2*pi))';
    end
    [alpha_estimated(1) alpha_estimated(2) alpha_estimated(3)]
    energies(:,i) = energy(:);
    alphas(:,i) = alpha_estimated;
    figure(2)
    alpha_median = sort(sort(alphas(:,1:i)));
    alpha_median = alpha_median(ceil(end/2));
    alpha_mean = sum(sum(alphas(:,1:i)))/(i*NumChannels);
    alpha_dispersion = sum(sum(alphas(:,1:i).^2-alpha_mean^2))/(i*NumChannels);
    alpha_deviation = sqrt(alpha_dispersion);
    fprintf('num=%d median=%5.1f mean=%5.1f(+/-%3.2f) dispersion=%5.2f\n',i,alpha_median,alpha_mean,alpha_deviation,alpha_dispersion)
    for chnum = 1:NumChannels
        %plot([1:NumRepetitions], alphas(chnum,:))
        plot([1:i], alphas(chnum,1:i))
        xlim([1 NumRepetitions])
        ylim([0 180])
        hold all
    end
    hold off
end
hold all
u = [];
for i=1:NumChannels
    u=sort(alphas(1,:));
    plot([1:NumRepetitions], u)
end


%hold all
% 
% %plot(ch1);
% 
% plot(ch2);
% ch3 = double(int8(buf(3*N+1:4*N))).*mx;
% e0i = e0i + 1.036*sum(real(ch0.*conj(ch0)))./N;
% e1i = e1i + 1.036/1.024*sum(real(ch1.*conj(ch1)))./N;
% e2i = e2i + sum(real(ch2.*conj(ch2)))./N;
% e3i = e3i + sum(real(ch3.*conj(ch3)))./N;
% a01i = a01i + sum(ch0.*conj(ch1))./N;
% a12i = a12i + sum(ch1.*conj(ch2))./N;
% a20i = a20i + sum(ch2.*conj(ch0))./N;
% e0 = e0i./frame_num_cnt;
% e1 = e1i./frame_num_cnt;
% e2 = e2i./frame_num_cnt;
% e3 = e3i./frame_num_cnt;
% a01 = abs(angle(a01i./frame_num_cnt))>pi/2;
% a12 = abs(angle(a12i./frame_num_cnt))>pi/2;
% a20 = abs(angle(a20i./frame_num_cnt))>pi/2;
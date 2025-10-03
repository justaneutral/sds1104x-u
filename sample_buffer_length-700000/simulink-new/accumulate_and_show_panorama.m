function [num_bytes,duration] = accumulate_and_show_panorama(file_name,num_frames)
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
    % filename = 'jxn.txt'
    % f_shift = -16068; 
    % Fcap = 1.5; % Hz one side BW
    % Frezolution = 0.125; % Hz fft bin
    
    % NAA
    % filename = 'naa000.txt'
    % f_shift = -24000; 
    % Fcap = 100; % Hz one side BW
    % Frezolution = 1; % Hz fft bin
    
    % NLK
    % filename = 'nlk000.txt'
    % f_shift = -25200;
    % Fcap = 100; % Hz one side BW
    % Frezolution = 1; % Hz fft bin
    
    %test station 3
    % filename = 'station3_000.txt'
    % f_shift = -29700;
    % Fcap = 400; % Hz one side BW
    % Frezolution = 1; % Hz fft bin
    
    % test station 4
    %filename = 'station4.txt'
    % f_shift = -38200;
    % Fcap = 150; % Hz one side BW
    % Frezolution = 1; % Hz fft bin
    
    % panorama
    filename = 'panorama.txt'
    f_shift = -40000;
    Fcap = 25000; % Hz one side BW
    Frezolution = 1; % Hz fft bin
    
    N = 700000;
    Fs = 500000;
    
    if num_frames<=0
        num_frames = 1;
    end
    NumRepetitions = num_frames;
    NumChannels = 3; % max 4
    Nfft = 2^ceil(log2(Fs/Frezolution));
    Ncap = [max(1,Nfft/2 - ceil(Nfft*Fcap/Fs)), min(Nfft,Nfft/2 + ceil(Nfft*Fcap/Fs))];
    Nextract = [Ncap(1)+Nfft/2, Nfft, 1, Ncap(2)-Nfft/2];
    Fscale = ([Ncap(1):Ncap(2)]'-Nfft/2)*Frezolution;
    ch = zeros(N,NumChannels);
    energy = zeros(NumChannels,1);
    energies = zeros(NumChannels,NumRepetitions);
    signum = zeros(NumChannels,1);
    signums = zeros(NumChannels,NumRepetitions);
    alpha_estimated = zeros(NumChannels,1);
    alphas = zeros(NumChannels,NumRepetitions);
    chcut = zeros(size(Fscale,1),NumChannels);
    chftsum = zeros(size(Fscale,1),NumChannels);
    num_bytes = 0;
    duration = 0;
    for i=1:1:NumRepetitions
        % Call helper function to get latest data
        buf = read_file_helper(N);
        meta1 = writeByteChunk([file_name '.bytes'], uint8(buf));
        num_bytes = num_bytes + meta1.length_bytes;
        if i==1
            duration = meta1.epoch_ms;
        end 
        if i==NumRepetitions
            duration = meta1.epoch_ms - duration;
        end
        %freq. conversion
        ag = 1.0j.*2.*pi.*double(f_shift)./double(Fs).*(0:1:N-1)';
        mx = exp(ag);
        for chnum = 1:NumChannels
            ch(:,chnum) = double(int8(buf((chnum-1)*N+1:chnum*N))).*mx;
            chex = [zeros(Nfft-floor(N/2),1) ; ch(:,chnum); zeros(Nfft-N+floor(N/2),1)];
            chft = fft(chex,Nfft);
            chcut(:,chnum) = [chft(Nextract(1):Nextract(2)); chft((Nextract(3):Nextract(4)))];
            chcut_abs = abs(chcut(:,chnum));
            chftsum(:,chnum) = chcut_abs;
            fftf = figure(1);
            if chnum == 1 
                subplot(3,1,1); plot(Fscale,chftsum(:,chnum),'color','red'); title('Ch1');
            end
            if chnum == 2
                subplot(3,1,2); plot(Fscale,chftsum(:,chnum),'color','green'); title('Ch2');
            end
            if chnum == 3
                subplot(3,1,3); plot(Fscale,chftsum(:,chnum),'color','blue'); title('Ch3');
            end
            if i==1
                if(chnum == 3)
                    set(fftf, 'PaperOrientation','landscape', ...
                        'PaperUnits','inches', ...
                        'PaperPosition',[0 0 12 9]);   % width x height on page
                    print(fftf, '-dpdf', '-r300', [file_name '_fft_panorama.pdf']);  % 300 DPI
                end
            end
            hold off
            energy(chnum) = 0.*energy(chnum) + chcut(:,chnum)'*chcut(:,chnum);
            if chnum>1
                signum(chnum) = chcut(:,chnum-1)'*chcut(:,chnum);
            end
        end
        signum(1) = chcut(:,1)'*chcut(:,NumChannels);
        %legend('ch1 min at 0/180, max at 90/270 deg.','ch2 min at 60/240, max at 150/330 deg','ch3 min at 120/300, max at 30/210')
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
    
    fid = fopen(filename,'w');
    fprintf(fid,'%f\n',alphas);
    fclose(fid);
end


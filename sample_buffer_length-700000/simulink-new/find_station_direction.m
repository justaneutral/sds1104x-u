function [b_mean,b_dev] = find_station_direction(f_shift,Fcap,Frezolution)
    N = 700000;
    Fs = 500000;
    
    NumRepetitions = 1000000;
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
    %num_bytes = 0;
    %duration = 0;
    for i=1:1:NumRepetitions
        % Call helper function to get latest data
        buf = read_file_helper(N);
        %meta1 = writeByteChunk([file_name '.bytes'], uint8(buf));
        %[bytes, meta] = readByteChunk([file_name '.bytes'], i);
        %buf = int8(bytes');
        %num_bytes = num_bytes + meta1.length_bytes;
        %if i==1
        %    duration = meta1.epoch_ms;
        %end 
        % if i==NumRepetitions
        %     duration = meta1.epoch_ms - duration;
        % end
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
                %subplot(3,1,1); 
                plot(Fscale,chftsum(:,chnum),'color','red'); title('Ch1');
                hold all
            end
            if chnum == 2
                %subplot(3,1,2); 
                plot(Fscale,chftsum(:,chnum),'color','green'); title('Ch2');
            end
            if chnum == 3
                %subplot(3,1,3); 
                plot(Fscale,chftsum(:,chnum),'color','blue'); title('Ch3');
                hold off
            end
            % if i==1
            %     if(chnum == 3)
            %         set(fftf, 'PaperOrientation','landscape', ...
            %             'PaperUnits','inches', ...
            %             'PaperPosition',[0 0 12 9]);   % width x height on page
            %         print(fftf, '-dpdf', '-r300', [file_name '_' st_id '_fft_spectrum.pdf']);  % 300 DPI
            %     end
            % end
            %hold off
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
            b = energy(1+mod(k+1,3)); %orig b
            c = energy(1+mod(k+2,3)); %orig c
            sinalpha = (b-c) * sqrt(3.0);
            cosalpha = b + c -2*a;
            %alpha_estimated = mod(atan2(sinalpha,cosalpha)-k*2*pi/3,2*pi)
            alpha_estimated(k+1) = 90/pi*(mod(atan2(sinalpha,cosalpha)-2/3*pi*(k-1),2*pi))';
        end
        %[alpha_estimated(1) alpha_estimated(2) alpha_estimated(3)]
        fprintf('ang=%5.1f\n',mean(alpha_estimated))
    end
end


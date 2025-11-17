function [fbuf, Na] = accumulate_panorama(f_shift,Fcap,Frezolution,fignum,buf)
    persistent num_accumulated accumulated_max_fft accumulated_min_fft
    N = 700000;
    Fs = 500000;
    NumChannels = 3; % max 4
    Nfft = 2^ceil(log2(Fs/Frezolution));
    Ncap = [max(1,Nfft/2 - ceil(Nfft*Fcap/Fs)), min(Nfft,Nfft/2 + ceil(Nfft*Fcap/Fs))];
    Nextract = [Ncap(1)+Nfft/2, Nfft, 1, Ncap(2)-Nfft/2];
    Fscale = ([Ncap(1):Ncap(2)]'-Nfft/2)*Frezolution;%*(1-2^-5);
    fcorrection = Fcap./Fscale(end);
    Fscale = Fscale * fcorrection;
    FscaleTrue = Fscale - f_shift;
    if isempty(num_accumulated) || fignum < 0
         num_accumulated = 0;
    end
    if isempty(accumulated_max_fft)  || fignum < 0
         accumulated_max_fft = zeros(3,size(Fscale,1));
    end
    if isempty(accumulated_min_fft)  || fignum < 0
         accumulated_min_fft = zeros(3,size(Fscale,1));
    end

    if fignum >= 0
        ch = zeros(N,NumChannels);
        chcut = zeros(size(Fscale,1),NumChannels);
        ag = 1.0j.*2.*pi.*double(f_shift)./double(Fs).*(0:1:N-1)';
        mx = exp(ag);
        %extract the antenna signals
        for chnum = 1:NumChannels
            ch(:,chnum) = double(int8(buf((chnum-1)*N+1:chnum*N))).*mx;
        end
        % ch(:,1) = exp(1.0j.*2.*pi.*double(5000-f_shift)./double(Fs).*(0:1:N-1)').*mx;
        % ch(:,2) = exp(1.0j.*2.*pi.*double(10000-f_shift)./double(Fs).*(0:1:N-1)').*mx;
        % ch(:,3) = exp(1.0j.*2.*pi.*double(15000-f_shift)./double(Fs).*(0:1:N-1)').*mx;
        %calculate ffts
        chcut_abs = zeros(3,size(Fscale,1));
        for chnum = 1:NumChannels
            chex = [zeros(Nfft-floor(N/2),1) ; ch(:,chnum); zeros(Nfft-N+floor(N/2),1)];
            chft = fft(chex,Nfft);
            chcut(:,chnum) = [chft(Nextract(1):Nextract(2)); chft((Nextract(3):Nextract(4)))];
            chcut_abs(chnum,:) = abs(chcut(:,chnum));
            accumulated_max_fft(chnum,:) = max(accumulated_max_fft(chnum,:),chcut_abs(chnum,:));
            accumulated_min_fft(chnum,:) = min(accumulated_min_fft(chnum,:),chcut_abs(chnum,:));
        end
        powerlevel = max(max(accumulated_max_fft));
        num_accumulated = num_accumulated + 1;
        fbuf = accumulated_max_fft;
        Na = num_accumulated;
        if fignum > 0
            figure(fignum);
            subplot(3,1,1)
            hold off
            plot(FscaleTrue,accumulated_max_fft(1,:),'color','magenta');
            hold all
            plot(FscaleTrue,chcut_abs(1,:),'color','red');
            plot(FscaleTrue,accumulated_min_fft(1,:),'color','black');
            axis([FscaleTrue(1) FscaleTrue(end) 0 powerlevel]);
            subplot(3,1,2)
            hold off
            plot(FscaleTrue,accumulated_max_fft(2,:),'color','yellow');
            hold all
            plot(FscaleTrue,chcut_abs(2,:),'color','green');
            plot(FscaleTrue,accumulated_min_fft(2,:),'color','black');
            axis([FscaleTrue(1) FscaleTrue(end) 0 powerlevel]);
            subplot(3,1,3)
            hold off
            plot(FscaleTrue,accumulated_max_fft(3,:),'color','cyan');
            hold all
            plot(FscaleTrue,chcut_abs(3,:),'color','blue');
            plot(FscaleTrue,accumulated_min_fft(3,:),'color','black');
            hold off
            axis([FscaleTrue(1) FscaleTrue(end) 0 powerlevel]);
            % titstr = sprintf('Avg.|FFT| Ncap(1)=%d Ncap(2)=%d Nfft/2=%d Frezolution=%f',Ncap(1),Ncap(2),Nfft/2,Frezolution);
            % title(titstr);
        end
    else
        fbuf = 0;
        Na = 0;
    end
end

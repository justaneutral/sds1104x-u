function [fbuf, Na] = accumulate_panorama(f_shift,Fcap,Frezolution,fignum,buf)
    persistent num_accumulated accumulated_abs_fft
    N = 700000;
    Fs = 500000;
    NumChannels = 3; % max 4
    Nfft = 2^ceil(log2(Fs/Frezolution));
    Ncap = [max(1,Nfft/2 - ceil(Nfft*Fcap/Fs)), min(Nfft,Nfft/2 + ceil(Nfft*Fcap/Fs))];
    Nextract = [Ncap(1)+Nfft/2, Nfft, 1, Ncap(2)-Nfft/2];
    Fscale = ([Ncap(1):Ncap(2)]'-Nfft/2)*Frezolution;%*(1-2^-5);
    fcorrection = Fcap./Fscale(end);
    Fscale = Fscale * fcorrection;
    FscaleTrue = Fscale;% - f_shift;
    if isempty(num_accumulated) || fignum < 0
         num_accumulated = 0;
    end
    if isempty(accumulated_abs_fft)  || fignum < 0
         accumulated_abs_fft = zeros(1,size(Fscale,1));
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
        ch(:,1) = exp(1.0j.*2.*pi.*double(5000-f_shift)./double(Fs).*(0:1:N-1)').*mx;
        ch(:,2) = exp(1.0j.*2.*pi.*double(10000-f_shift)./double(Fs).*(0:1:N-1)').*mx;
        ch(:,3) = exp(1.0j.*2.*pi.*double(15000-f_shift)./double(Fs).*(0:1:N-1)').*mx;
        %calculate ffts
        chcut_abs = zeros(size(Fscale,1),1);
        for chnum = 1:NumChannels
            chex = [zeros(Nfft-floor(N/2),1) ; ch(:,chnum); zeros(Nfft-N+floor(N/2),1)];
            chft = fft(chex,Nfft);
            chcut(:,chnum) = [chft(Nextract(1):Nextract(2)); chft((Nextract(3):Nextract(4)))];
            chcut_abs = chcut_abs + abs(chcut(:,chnum));
        end
        num_accumulated = num_accumulated + 1;
        accumulated_abs_fft = accumulated_abs_fft + chcut_abs';
        fbuf = accumulated_abs_fft;
        Na = num_accumulated;
        if fignum > 0
            figure(fignum);
            hold off
            plot(FscaleTrue,accumulated_abs_fft,'color','black');
            titstr = sprintf('Avg.|FFT| Ncap(1)=%d Ncap(2)=%d Nfft/2=%d Frezolution=%f',Ncap(1),Ncap(2),Nfft/2,Frezolution);
            title(titstr);
        end
    else
        fbuf = 0;
        Na = 0;
    end
end

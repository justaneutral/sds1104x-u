function [b_mean,b_dev] = find_direction(f_shift,Fcap,Frezolution,cutoff)
    N = 700000;
    Fs = 500000;
    collected_coherent = [];
    NumRepetitions = 1000;
    NumChannels = 3; % max 4
    Nfft = 2^ceil(log2(Fs/Frezolution));
    Ncap = [max(1,Nfft/2 - ceil(Nfft*Fcap/Fs)), min(Nfft,Nfft/2 + ceil(Nfft*Fcap/Fs))];
    Nextract = [Ncap(1)+Nfft/2, Nfft, 1, Ncap(2)-Nfft/2];
    Fscale = ([Ncap(1):Ncap(2)]'-Nfft/2)*Frezolution;
    ch = zeros(N,NumChannels);
    energy = zeros(NumChannels,1);
    signum = zeros(NumChannels,2);
    alpha_estimated = zeros(NumChannels,1);
    chcut = zeros(size(Fscale,1),NumChannels);
    chftsum = zeros(size(Fscale,1),NumChannels);
    systemangle = [];
    systemangle1 = [];
    [~] = read_file_helper(N);
    for i=1:1:NumRepetitions
        buf = read_file_helper(N);
        ag = 1.0j.*2.*pi.*double(f_shift)./double(Fs).*(0:1:N-1)';
        mx = exp(ag);
        %extract the antenna signals
        for chnum = 1:NumChannels
            ch(:,chnum) = double(int8(buf((chnum-1)*N+1:chnum*N))).*mx;
        end
        %calculate auto and cross correlation
        for chnum = 1:NumChannels
            chex = [zeros(Nfft-floor(N/2),1) ; ch(:,chnum); zeros(Nfft-N+floor(N/2),1)];
            chft = fft(chex,Nfft);
            chcut(:,chnum) = [chft(Nextract(1):Nextract(2)); chft((Nextract(3):Nextract(4)))];
            chcut_abs = abs(chcut(:,chnum));
            chftsum(:,chnum) = chcut_abs;
        end

        %apply threshold
        maxfft = max(max(chftsum));
        minfft = min(min(chftsum));
        ecutoff = minfft + (maxfft-minfft)*cutoff;
        for chnum = 1:NumChannels
            for j = 1:(Nextract(2)-Nextract(1)+Nextract(4)-Nextract(3)+2)
                if(chftsum(j,chnum)) < ecutoff
                    chftsum(j,chnum) = 0;
                end
            end
        end
        
        ant_a = chcut(:,1)';
        ant_b = chcut(:,2)';
        ant_c = chcut(:,3)';

        figure(1);
        hold off
        plot(Fscale,imag(ant_a),'color','magenta');
        hold all
        plot(Fscale,imag(ant_b),'color','yellow');
        plot(Fscale,imag(ant_c),'color','cyan');
        plot(Fscale,real(ant_c),'color','blue');
        plot(Fscale,real(ant_b),'color','green');
        plot(Fscale,real(ant_a),'color','red');
        titstr = sprintf("Signal in channels a(red,magenta), b(green,yellow), c(blue,cyan)");
        title(titstr);
        hold off
        
        [systemangle] = measurement_coherent(ant_a,ant_b,ant_c,0,2);
        [systemangle1] = measurement_coherent(ant_a+ant_b,ant_b+ant_c,ant_c+ant_a,-60,3);
        
        collected_coherent = [collected_coherent (systemangle+systemangle1)/2];

        figure(4)
        hold off
        plot([1:i],[collected_coherent],'color', 'black');
        axis([1 NumRepetitions -200 200]);
        title('measured angle of arrival');
    end
end


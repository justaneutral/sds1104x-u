function [b_mean,b_dev] = find_direction(f_shift,Fcap,Frezolution,cutoff)
    % persistent mp ma mb mc aa ab ac
    % if isempty(mp)
    %     mp = 0;
    % end
    % if isempty(ma)
    %     ma = 1;
    % end
    % if isempty(mb)
    %     mb = 1;
    % end
    % if isempty(mc)
    %     mc = 1;
    % end
    % if isempty(aa)
    %     aa = 0;
    % end
    % if isempty(ab)
    %     ab = 0;
    % end
    % if isempty(ac)
    %     ac = 0;
    % end    
        
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
    chcut = zeros(size(Fscale,1),NumChannels);
    chftsum = zeros(size(Fscale,1),NumChannels);
    systemangle = [];
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
                    chcut(j,1) = complex(0,0);
                    chcut(j,2) = complex(0,0);
                    chcut(j,3) = complex(0,0);
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
        
        ma = 1; mb = 1; mc = 1; aa = 0; ab = 0; ac = 0; mp = 0;
        dd = 100;
        [systemangle,dd] = measurement_coherent(ant_a,ant_b,ant_c,mp,ma,mb,mc,aa,ab,ac,2);
        while dd > 360
            [systemangle,dd] = measurement_coherent(ant_a,ant_b,ant_c,mp,ma,mb,mc,aa,ab,ac,2);
            [~,dmp] = measurement_coherent(ant_a,ant_b,ant_c,mp+0.01,ma,mb,mc,aa,ab,ac,0);
            % [~,dma] = measurement_coherent(ant_a,ant_b,ant_c,mp,ma*1.01,mb,mc,aa,ab,ac,0);
            [~,dmb] = measurement_coherent(ant_a,ant_b,ant_c,mp,ma,mb*1.01,mc,aa,ab,ac,0);
            [~,dmc] = measurement_coherent(ant_a,ant_b,ant_c,mp,ma,mb,mc*1.01,aa,ab,ac,0);
            % [~,daa] = measurement_coherent(ant_a,ant_b,ant_c,mp,ma,mb,mc,aa+0.01,ab,ac,0);
            % [~,dab] = measurement_coherent(ant_a,ant_b,ant_c,mp,ma,mb,mc,aa,ab+0.01,ac,0);
            % [~,dac] = measurement_coherent(ant_a,ant_b,ant_c,mp,ma,mb,mc,aa,ab,ac+0.01,0);
            mp = mp + 0.1*(dd-dmp);
            % ma = ma * (1.0 + 0.1*(dd-dma));
            mb = mb * (1.0 + 0.1*(dd-dmb));
            mc = mc * (1.0 + 0.1*(dd-dmc));
            % aa = aa + 0.01*(dd-daa);
            % ab = ab + 0.01*(dd-dab);
            % ac = ac + 0.01*(dd-dac);
            % if dmb>dmc && dmb>dab && dmb>dac
            %     mb = mb * (1.0 + 0.01*(dd-dmb));
            % else
            %     if dmc>dmb && dmc>dab && dmc>dac
            %         mc = mc * (1.0 + 0.01*(dd-dmc));
            %     else 
            %         if dab>dmb && dab>dmc && dab>dac
            %             ab = ab + 0.01*(dd-dab);
            %         else 
            %             if dac>dmb && dac>dmc && dac>dab
            %                 ac = ab + 0.01*(dd-dab);
            %             end
            %         end
            %     end
            % end
        end
        
        collected_coherent = [collected_coherent systemangle];

        figure(4)
        hold off
        plot([1:i],[collected_coherent],'color', 'black');
        axis([1 NumRepetitions -200 200]);
        title('measured angle of arrival');
    end
end


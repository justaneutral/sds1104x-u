function [b_mean,b_dev] = find_station_direction(f_shift,Fcap,Frezolution,cutoff)
    N = 700000;
    Fs = 500000;
    alphas = [];
    NumRepetitions = 1000000;
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
        
        % figure(1);
        % plot(Fscale,chftsum(:,1),'color','red');
        % hold all
        % plot(Fscale,chftsum(:,2),'color','green');
        % plot(Fscale,chftsum(:,3),'color','blue');
        % title('Received spectrum');
        % hold off
        al = chcut(:,1);
        bl = chcut(:,2);
        cl = chcut(:,3);
        energy(1) = sqrt(al'*al);
        energy(2) = sqrt(bl'*bl);
        energy(3) = sqrt(cl'*cl);
        %signum(1,1) = sign(real(chcut(:,1+mod((chnum+1),NumChannels))'*chcut(:,chnum)));
        %signum(chnum,2) = sign(real(chcut(:,1+mod((chnum-1),NumChannels))'*chcut(:,chnum)));

        for k=0:2
            anta = 1+mod(k,3);
            antb = 1+mod(k+1,3);
            antc = 1+mod(k+2,3);
            a = energy(anta);
            b = energy(antb);
            c = energy(antc);
            I = chcut(:,anta)-chcut(:,antb)-chcut(:,antc);
            Q = sqrt(3)*(chcut(:,antb)-chcut(:,antc));
            
            cosalpha = (I'*I);
            sinalpha = (Q'*Q);
            % cosalpha = sqrt(cosalpha);
            % sinalpha = sqrt(sinalpha);
            IQangle = real(I'*Q);
            IQangle = sign(IQangle); %/abs(IQangle);
            sinalpha = sinalpha * IQangle;

        figure(k+1);
        plot(Fscale,sqrt(I.*conj(I)),'color','red');
        hold all
        if(IQangle > 0)
            plot(Fscale,sqrt(Q.*conj(Q)),'color','green');
        else
            plot(Fscale,sqrt(Q.*conj(Q)),'color','blue');
        end
        title('Received spectrum');
        hold off

            systemangle = 180/pi*atan2(sinalpha,cosalpha);
            % range from -90 to 90 degree
            %at needle 60 shows 90, must show around 0
            correctedangle = mod(15 + 180 - systemangle - k*120, 180) - 90;
            alpha_estimated(k+1) = correctedangle;
            signal_power = 0.01*sqrt(sinalpha^2+cosalpha^2);
            cosal=cosalpha/signal_power;
            sinal=sinalpha/signal_power;
            fprintf('ch%1d,',k+1);
            fprintf('p%03.0f,',10*log(signal_power));
            %fprintf('a%03.0f,',a/signal_power);
            %fprintf('b%03.0f,',b/signal_power);
            %fprintf('c%03.0f,',c/signal_power);
            %fprintf('B%+01.0f,',B);
            %fprintf('C%+01.0f,',C);
            fprintf('I%+03.0f,',cosal);
            fprintf('Q%+03.0f,',sinal);
            fprintf('IQang%+03.0f,',IQangle);
            fprintf('ang=%+03.0f\n',alpha_estimated(k+1));

            %fprintf('ch=%1.0f p=%5.1f (a,b,c,B,C)=(%5.0f,%5.0f,%5.0f,%+1.0f,%+1.0f), %+5.0fI %+5.1Q ang=%5.1f\n\n',k+1,signal_power/1000000,a,b,c,B,C,cosal,sinal,alpha_estimated(k+1));
            %fprintf('ch%1.0fp%3.1fa%3.0fb%3.0fc%3.0fA%+0.0fB%+0.0f\n',k+1,signal_power/1000000,a,b,c,B,C);
            %fprintf('%+3.0f %+3.1 ang=%3.1f\n',cosal,sinal,alpha_estimated(k+1));
          
        end
        %[alpha_estimated(1) alpha_estimated(2) alpha_estimated(3)]
        fprintf('\n');
        
        alphas = [alphas, alpha_estimated(1)];
        [counts, edges] = arrayHistogram(alphas, 100);
        figure(4);
        bar(edges(1:end-1), counts, 1);
        title('Streaming Histogram with Auto-binning');
        xlabel('Value');
        ylabel('Count');
        hold off

    end
end


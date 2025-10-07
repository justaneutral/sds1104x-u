function [b_mean,b_dev] = find_station_direction_noncoherent(f_shift,Fcap,Frezolution,cutoff,logfilename)
    N = 700000;
    Fs = 500000;
    alphas = [];
    
    fabcs =  open_abclog(logfilename,'w');
    fprintf(fabcs,"Ant1 Ant2 Ant3\n");
    close_abclog(fabcs);

    NumRepetitions = 271;
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
        squelch_width = 3;
        nc = Fscale(end);
        squelch_val = sum(sum(chcut(nc-squelch_width:nc+squelch_width,:)))/(2+squelch_width+1);
        %squelch_val = (sum(sum(chcut(nc-squelch_width:nc+squelch_width,:)))/(2+squelch_width+1))/(sum(sum(chcut(1:nc-squelch_width-1,:) + chcut(nc+squelch_width+1:end,:)))/(Ncap(2)-Ncap(1)+1-(2+squelch_width+1)));
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


        %calculate auto and cross correlations
        for chnum = 1:NumChannels
            figure(1);
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

            %energy(chnum) = (real(chcut(:,chnum)'*chcut(:,chnum)));
            energy(chnum) = sqrt(real(chcut(:,chnum)'*chcut(:,chnum))); % added sqrt
            signum(chnum,1) = sign(real(chcut(:,1+mod((chnum+1),NumChannels))'*chcut(:,chnum)));
            signum(chnum,2) = sign(real(chcut(:,1+mod((chnum-1),NumChannels))'*chcut(:,chnum)));
            % chnum>1
            %    signum(chnum,2) = sign(real(chcut(:,chnum-1)'*chcut(:,chnum)));
            %end
            %if chnum>2
            %    signum(chnum,1) = sign(real(chcut(:,chnum-2)'*chcut(:,chnum)));
            %end
        end
        %signum(1,2) = sign(real(chcut(:,1)'*chcut(:,NumChannels)));
        %signum(1,1) = sign(real(chcut(:,1)'*chcut(:,NumChannels-1)));
        %signum(2,1) = sign(real(chcut(:,2)'*chcut(:,NumChannels)));
        %legend('ch1 min at 0/180, max at 90/270 deg.','ch2 min at 60/240, max at 150/330 deg','ch3 min at 120/300, max at 30/210')
        hold off

        apa = energy(1);
        apb = energy(2)*signum(1,2);
        apc = energy(3)*signum(1,1);
        fabcs = open_abclog(logfilename);
        write_abc(fabcs, apa, apb, apc);
        close_abclog(fabcs);

        AoA = compute_aoa([apa, apb, apc]);

        %for k=0:2
        k = 0;
            anta = 1+mod(k,3);
            antb = 1+mod(k+1,3);
            antc = 1+mod(k+2,3);
            a = energy(anta);
            b = energy(antb);
            c = energy(antc);

            B = signum(anta,2);
            C = signum(anta,1);

            % original sin/cos 
            % sinalpha = (b-c) * sqrt(3.0);
            % cosalpha = b + c -2*a;
            %alpha_estimated(k+1) = 90/pi*(mod(atan2(sinalpha,cosalpha)-2/3*pi*(k-1),2*pi))';
            
            sinalpha = (b-c) * sqrt(3.0);
            cosalpha = b + c - a;
            %alpha_estimated(k+1) = 180/pi*(mod(atan2(sinalpha,cosalpha)+pi*(2/3*(k)-1/2),pi))';
            alpha_estimated(k+1) = 180/pi*(atan2(sinalpha,cosalpha));
            
            signal_power = 0.01*sqrt(sinalpha^2+cosalpha^2);
            abcmax = 100/max(max(a,b),c);
            a = a * abcmax;
            b = b * abcmax;
            c = c * abcmax;
            cosal=cosalpha/signal_power;
            sinal=sinalpha/signal_power;
            fprintf('ch%1d,',k+1);
            fprintf('p%03.0f,',10*log(signal_power));
            fprintf('a%03.0f,',a);
            fprintf('b%03.0f,',b);
            fprintf('c%03.0f,',c);
            fprintf('B%+01.0f,',B);
            fprintf('C%+01.0f,',C);
            fprintf('I%+03.0f,',cosal);
            fprintf('Q%+03.0f,',sinal);
            fprintf('ang=%+03.0f,',alpha_estimated(k+1));
            fprintf('AoA=%+03.0f\n',AoA);

            %fprintf('ch=%1.0f p=%5.1f (a,b,c,B,C)=(%5.0f,%5.0f,%5.0f,%+1.0f,%+1.0f), %+5.0fI %+5.1Q ang=%5.1f\n\n',k+1,signal_power/1000000,a,b,c,B,C,cosal,sinal,alpha_estimated(k+1));
            %fprintf('ch%1.0fp%3.1fa%3.0fb%3.0fc%3.0fA%+0.0fB%+0.0f\n',k+1,signal_power/1000000,a,b,c,B,C);
            %fprintf('%+3.0f %+3.1 ang=%3.1f\n',cosal,sinal,alpha_estimated(k+1));
          
        %end
        %[alpha_estimated(1) alpha_estimated(2) alpha_estimated(3)]
        fprintf('\n');
        
        % if(AoA) < 100
        %     AoA = AoA - 120;
        % end
        %alphas = [alphas, alpha_estimated(1)];
        alphas = [alphas, AoA];
        [counts, edges] = arrayHistogram(alphas, 100);
        b_mean = mean(alphas);
        b_dev = std(alphas);
        fprintf("mean = %f, std = %f\n", b_mean,b_dev);
        figure(2);
        bar(edges(1:end-1), counts, 1);
        title('Streaming Histogram with Auto-binning');
        xlabel('Value');
        ylabel('Count');
        hold off
       
    end

end


function theta_deg = compute_aoa(values)
% function theta_deg = computeDoA(values)
%     angles_deg = [0, 120, 240];
%     values = values / norm(values);
%     angles_rad = deg2rad(angles_deg);
%     x = sum(values .* cos(angles_rad));
%     y = sum(values .* sin(angles_rad));
%     theta_deg = mod(rad2deg(atan2(y, x)), 360);
%     fprintf('Estimated source direction: %.2f°\n', theta_deg);
% end
    % values: 3-element vector of antenna outputs [a1, a2, a3]
    % Antenna angles in degrees
    angles_deg = [0, 120, 240];  % 240° = -120° mod 360

    % Normalize input values
    values = values / norm(values);

    % Convert angles to radians
    angles_rad = deg2rad(angles_deg);

    % Compute unit vectors for each antenna direction
    x = sum(values .* cos(angles_rad));
    y = sum(values .* sin(angles_rad));

    % Compute direction of arrival
    theta_rad = atan2(y, x);
    theta_deg = mod(rad2deg(theta_rad), 360);  % Wrap to [0, 360)

    % Display result
    fprintf('Estimated source direction: %.2f°\n', theta_deg);
end

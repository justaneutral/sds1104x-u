function plot_history(valids,fig_hndl,directions,iteration_number,num_keep)
    if sum(valids)
        axy1 = 400;
        axy2 = -400;
        colors = ["red","green","blue"];
        texts = ["Group 1 Reference Angle", "Group 2 Reference Angle", "Group 3 Reference Angle"];
        for j=1:size(valids,2)
            if valids(j) > 0
                if iteration_number > num_keep
                    unwrapped_directions = unwrap_aoa(-1*directions(j,:));
                    %unwrapped_directions = mod(-1*directions(j,:),360);
                    plot(fig_hndl,iteration_number-num_keep+1:iteration_number,unwrapped_directions,'color',colors(j));
                    axx1 = iteration_number-num_keep+1;
                    axx2 = iteration_number;
                    axy1 = min(axy1,min(unwrapped_directions)-5);
                    axy2 = max(axy2,max(unwrapped_directions)+5);
                else
                    unwrapped_directions = unwrap_aoa(-1*directions(j,1:iteration_number));
                    %unwrapped_directions = mod(-1*directions(j,1:iteration_number),360);
                    plot(fig_hndl,1:iteration_number,unwrapped_directions,'color',colors(j));
                    axx1 = 1;
                    axx2 = num_keep;
                    axy1 = min(axy1,min(unwrapped_directions(1:iteration_number))-5);
                    axy2 = max(axy2,max(unwrapped_directions(1:iteration_number))+5);
                end
                hold(fig_hndl,"all");
                p_text = sprintf('%s: %3.1f, Standart Deviation: %1.1f)',texts(j),mod(mean(unwrapped_directions),360),std(directions(j,:)));
                text(fig_hndl,axx1+2,(axy2+axy1)/2+2,p_text,'color',colors(j));
            end %% valids
        end %% j
        axis(fig_hndl,[axx1 axx2 axy1 axy2]);
        title(fig_hndl,'Reference Angle History');
        indicator = valids > 0;
        indicator = indicator*[4,2,1]';
        switch indicator
            case 1; legend(fig_hndl,texts(3));
            case 2; legend(fig_hndl,texts(2));
            case 4; legend(fig_hndl,texts(1));
            case 3; legend(fig_hndl,texts(2),texts(3));
            case 5; legend(fig_hndl,texts(1),texts(3));
            case 6; legend(fig_hndl,texts(1),texts(2));
            case 7; legend(fig_hndl,texts(1),texts(2),texts(3));
        end
        
        ylabel(fig_hndl,'Reference Angle [degrees]');
        xlabel(fig_hndl,'Measurement Iteration Number');
        hold(fig_hndl,"off");
        fontsize(fig_hndl,14,"points");
    end %% sum(valids)
end


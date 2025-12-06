function plot_parameters(fig_prm,title_str,texts,values,colors)
    title(fig_prm,title_str);
    xticks(fig_prm,[]);
    yticks(fig_prm,[]);
    axis(fig_prm,[0 100 0 100]);
    hold(fig_prm,"off");
    plot(fig_prm,0,0);
    x = 5;
    y = 95;
    dy = -11;
    paramsize = size(values,2);
    for j=1:paramsize
        if isnan(values(j))
            t = texts(j);
        else
            t = sprintf('%s: %1.2f',texts(j),values(j));
        end
        text(fig_prm,x,y,t,'color',colors(j));
        y = y+dy;
    end
    hold(fig_prm,"off");
end


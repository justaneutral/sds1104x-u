function plot_angles(fig_num,fig_hndl,title_text,angle_text,angle_value,angle_color)
    if fig_num > 0
        max_index = size(angle_value,2);
        hold(fig_hndl,"off");
        for j = max_index:-1:1 
            y=(50:1:150)*cos(pi/180*angle_value(j));
            x=(50:1:150)*sin(pi/180*angle_value(j));
            plot(fig_hndl,x,y,'color',angle_color(j));
            hold(fig_hndl,"all");
        end
        for mark = 10:10:360
            y=(110:1:120)*cos(pi/180*mark);
            x=(110:1:120)*sin(pi/180*mark);
            plot(fig_hndl,x,y,'color','blue');
        end
        for mark = 30:30:360
            y=(90:1:110)*cos(pi/180*mark);
            x=(90:1:110)*sin(pi/180*mark);
            plot(fig_hndl,x,y,'color','green');
        end
        y = (-90:90);
        plot(fig_hndl,0*y,y,'color','yellow');
        plot(fig_hndl,y,0*y,'color','yellow');
    
        for j =  max_index:-1:1 
            current_angle_text = sprintf('%s = %3.1f deg.',angle_text(j),mod(angle_value(j),360));
            y=160*cos(pi/180*angle_value(j)) - 10*j;
            x=160*sin(pi/180*angle_value(j)) + 10*j;
            text(fig_hndl,x+50*sign(x)-40,y+8*sign(y),current_angle_text,'color',angle_color(j));
        end
        axis(fig_hndl,[-200 200 -200 200]);
        axis(fig_hndl, 'equal');
        title(fig_hndl,title_text);
        ylabel(fig_hndl,'Normalized Cosinusoidal Projection');
        xlabel(fig_hndl,'Normalized Sinusoidal Projection');
        xticks(fig_hndl,[]);
        yticks(fig_hndl,[]);
        hold(fig_hndl,"off");
        fontsize(fig_hndl,14,"points");
    end
end



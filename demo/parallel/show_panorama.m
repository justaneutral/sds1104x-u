close all
panorama_mask_db = 10*log10(panorama_mask);
panorama_min_db = 10*log10(panorama_min);
panorama_db = 10*log10(panorama);
figure(2);
hold off
plot(panorama_fscale,panorama_db,'color','green');
hold all
plot(panorama_fscale,panorama_mask_db,'color','blue');
hold all
%plot(panorama_fscale,panorama_db,'color','green');
plot(panorama_fscale,panorama_min_db,'color','black');
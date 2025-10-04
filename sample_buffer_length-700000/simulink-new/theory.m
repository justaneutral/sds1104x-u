
%cos(alpha +/- 2π/3)=
% cos(alpha)cos(2π/3) −/+ sin(alpha)sin(2π/3) =
%-0.5cos(alpha) −/+ 0.5sqrt(3)sin(alpha)

%we receive:
% a = p*cos(alpha), b=p*cos(alpha+2π/3), c=p*cos(alpha-2π/3)  =>
% b+c = -p*cos(alpha) and b-c = sqrt(3)*p*sin(alpha) =>
% alpha = atan2((b-c)/sqrt(3),b+c)


alpha = (0:0.001*pi:1.999*pi);
sa = size(alpha);
sa = sa(2)
a=zeros(3,sa);
% for k=0:2
%    a(k+1,:) = sign(cos(alpha+k*2*pi/3).*cos(alpha+(k+1)*2*pi/3))
% end
%plot(alpha*180/pi,2.5+a(1,:).*a(2,:))
%hold all
%plot(alpha*180/pi,a(2,:).*a(3,:))
%plot(alpha*180/pi,-2.5+a(1,:).*a(3,:))

pa=zeros(3,sa);
sb=zeros(3,sa);
sc=zeros(3,sa);

for k=0:2
    pa(k+1,:) = abs(cos(alpha+k*2*pi/3));
    sb(k+1,:) = sign(cos(alpha+k*2*pi/3).*cos(alpha+(k+1)*2*pi/3));
    sc(k+1,:) = sign(cos(alpha+k*2*pi/3).*cos(alpha+(k+2)*2*pi/3));
    %plot(alpha*180/pi,2.5*(1-k)+p(k+1,:))
end

for k=0:2
    anta = 1+mod(k+0,3);
    antb = 1+mod(k+1,3);
    antc = 1+mod(k+2,3);
    a = pa(anta,:);
    b = pa(antb,:); C = sc(antb,:);
    c = pa(antc,:); B = sb(antc,:);
    sinalpha = (c.*B - b.*C);
    cosalpha = sqrt(3)*a;
    alpha_estimated = mod(atan2(sinalpha,cosalpha)-k*2*pi/3,pi);
    figure(k+1);
    plot(alpha*180/pi,alpha_estimated*180/pi); title(string(k+1));
    hold off
end

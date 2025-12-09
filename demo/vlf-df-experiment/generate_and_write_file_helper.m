function byte_array = generate_and_write_file_helper(N)
    persistent ang cnt;
    if isempty(ang) || isempty(cnt)
        ang = 10;
        cnt = 10;
    end
    cnt = cnt-1;
    if cnt <= 0
        ang = 10+mod(ang+20,60);
        cnt = 100;
    end

    fprintf('true ang = %f', ang);
    p = 0.005;
    toff = 2*rand(1,"double") - 1;
    foff = 2*rand(1,N,"double") - 1;
    aoff = 2*rand(1,N,"double") - 1;
    Fs = 500000; % 500 kHz sampling rate
    Fc = 60000+foff; %carrier frequency
    %ang = 1; %AoA in degrees
    ts = 1/Fs;
    T = ts*N;
    t = toff+(ts:ts:T);
    dph = 2*pi*Fc;
    ph = (dph.*t)';
    ss = p*sin(ph);
    sn = rand(N,1,"double")-p/2;
    ka = (aoff+127.0)*cos(ang*pi/180);
    kb = (aoff+127.0)*cos((ang+120)*pi/180);
    kc = (aoff+127.0)*cos((ang-120)*pi/180);
    kd = (aoff+1.0)*cos((ang-120)*pi/180);
    nang = 360.0*rand(1,"double");
    na = (aoff+127.0)*cos(nang*pi/180);
    nb = (aoff+127.0)*cos((nang+120)*pi/180);
    nc = (aoff+127.0)*cos((nang-120)*pi/180);
    nd = (aoff+1.0)*cos((ang-120)*pi/180);
    byte_array = int8([ka'.*ss + na'.*sn; kb'.*ss + nb'.*sn; kc'.*ss + nc'.*sn; kd'.*ss + nd'.*sn]);
end


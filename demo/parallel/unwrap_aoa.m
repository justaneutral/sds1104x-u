function ua = unwrap_aoa(ia)
na = max(size(ia));
if na <= 1
    ua = ia;
else
    sg = 0;
    if sum(ia) < 0 
        sg = 1;
    end
    sa = 0;
    a = ia;
    for i = 1:na-1
        for j = i+1:na
            d = a(j)-a(j-1);
            if d > 90
                a(j) = a(j) - 180;
                sa = sa - 1;
            else
                if d < -90
                    a(j) = a(j) + 180;
                    sa = sa + 1;
                end
            end
        end
    end
    ua = mod(180 + a - sign(sa)*sg, 360) - 180;
end
end
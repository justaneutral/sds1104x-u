function hexColor = floatsToHexColor(r, g, b, X)
    % Validate inputs
    if nargin ~= 4
        error('Usage: hexColor = floatsToHexColor(r, g, b, X)');
    end
    if any([r, g, b] < 0) || any([r, g, b] > X)
        error('RGB values must be between 0 and X.');
    end
    if X <= 0
        error('X must be a positive number.');
    end

    % Normalize to [0, 1]
    rgbNorm = [r, g, b] / X;

    % Clamp values to avoid rounding errors
    rgbNorm = max(0, min(1, rgbNorm));

    % Convert to 0–255 integers
    rgb255 = round(rgbNorm * 255);

    % Format as #RRGGBB
    hexColor = sprintf('#%02X%02X%02X', rgb255(1), rgb255(2), rgb255(3));
end

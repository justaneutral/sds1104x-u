function angle_double = theodoliteToDouble(input_str)
    % theodoliteToDouble Converts a theodolite string (A:DEG/MIN/SEC/) to a double angle value.
    %
    % The function expects the format 'A:DEG/MIN/SEC/...' 
    % It uses the first three numeric components for degrees, minutes, and seconds.
    % The sign of the degrees component determines the sign of the total angle.
    %
    % Example usage:
    % angle1 = theodoliteToDouble('A:41/21/55/-0/40/48/')
    % angle2 = theodoliteToDouble('A:-15/30/10/')

    % Remove the 'A:' prefix
    str_cleaned = strrep(input_str, 'A:', '');
    
    % Split the string by the '/' delimiter
    parts = split(str_cleaned, '/');
    
    % Filter out empty strings that result from the split (e.g. if string ends in /)
    numeric_parts = parts(~cellfun('isempty', parts));
    
    if length(numeric_parts) < 3
        error('Input string does not contain enough components (DEG/MIN/SEC).');
    end
    
    % Convert the relevant parts to numbers
    deg = str2double(numeric_parts{1});
    min_val = str2double(numeric_parts{2});
    sec_val = str2double(numeric_parts{3});
    
    if isnan(deg) || isnan(min_val) || isnan(sec_val)
        error('Invalid numeric components in the input string.');
    end
    
    % Calculate the double value.
    % The sign of the degrees value determines the sign of the entire angle.
    % Minutes and seconds should always be positive absolute values when summed.
    sign_val = sign(deg);
    if sign_val == 0
        % Handle the case where degree is '0' or '-0', default to positive if no clear negative sign
        % We can check if the original string for 'deg' contained a minus sign if needed,
        % but generally, the user should ensure consistency.
        if contains(numeric_parts{1}, '-')
            sign_val = -1;
        else
            sign_val = 1;
        end
    end

    % Sum the components with the correct sign applied to the whole value
    angle_double = sign_val * (abs(deg) + abs(min_val)/60 + abs(sec_val)/3600);
    
end

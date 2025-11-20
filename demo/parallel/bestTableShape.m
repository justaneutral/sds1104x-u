function [rows, cols] = bestTableShape(n)
% bestTableShape - Find optimal rows and columns for a table
%   [rows, cols] = bestTableShape(n) returns the number of rows and columns
%   that make the table as square as possible while minimizing empty cells.
%
%   Input:
%       n - Positive integer, number of items
%
%   Output:
%       rows - Number of rows
%       cols - Number of columns
%
%   Example:
%       [r, c] = bestTableShape(10)
%       % r = 3, c = 4
    % Validate input
    if ~isscalar(n) || n <= 0 || n ~= floor(n)
        error('Input must be a positive integer.');
    end

    % Start with square root approximation
    root = sqrt(n);
    rows = floor(root);
    cols = ceil(n / rows);

    % Check if adjusting rows gives a better (more square) shape
    bestDiff = abs(rows - cols);
    bestEmpty = rows * cols - n;

    for r = max(1, floor(root)-2) : ceil(root)+2
        c = ceil(n / r);
        diffRC = abs(r - c);
        emptyCells = r * c - n;

        % Choose better shape:
        % 1. Smaller difference between rows and cols
        % 2. If tie, fewer empty cells
        if diffRC < bestDiff || (diffRC == bestDiff && emptyCells < bestEmpty)
            rows = r;
            cols = c;
            bestDiff = diffRC;
            bestEmpty = emptyCells;
        end
    end
end

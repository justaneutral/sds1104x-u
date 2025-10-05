function [counts, edges] = arrayHistogram(input_array, num_bins)
% arrayHistogram builds a histogram from a data array.
%
%   [counts, edges] = arrayHistogram(input_array, num_bins)
%
%   Inputs:
%     input_array:  An array of data values.
%     num_bins:     The number of bins for the histogram.
%
%   Outputs:
%     counts: A vector containing the number of elements in each bin.
%     edges:  A vector specifying the edges of each bin.

    % Ensure the input is a numeric array
    if ~isnumeric(input_array)
        error('Input must be a numeric array.');
    end
    
    % Ensure num_bins is a positive integer
    if ~isscalar(num_bins) || num_bins <= 0 || num_bins ~= round(num_bins)
        error('Number of bins must be a positive integer.');
    end
    
    % Handle empty input array gracefully
    if isempty(input_array)
        counts = [];
        edges = [];
        return;
    end
    
    % Calculate histogram using histcounts
    % histcounts automatically determines bin edges to cover the data range
    [counts, edges] = histcounts(input_array, num_bins);
end

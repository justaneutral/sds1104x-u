function h = updateBivariateHistogram(h, x_new, y_new)
%UPDATEBIVARIATEHISTOGRAM Updates an existing bivariate histogram with new data.
%   h = updateBivariateHistogram(h, x_new, y_new) takes an existing
%   histogram2 object 'h' and adds a new (x_new, y_new) data point to it.
%   The function effectively reconstructs the histogram with the updated data.
%
%   Inputs:
%       h: An existing histogram2 object.
%       x_new: The new x-coordinate to add.
%       y_new: The new y-coordinate to add.
%
%   Output:
%       h: The updated histogram2 object.

    % Get the existing data from the histogram object
    existing_x = h.XData;
    existing_y = h.YData;

    % Append the new data point
    updated_x = [existing_x, x_new];
    updated_y = [existing_y, y_new];

    % Get bin information from the existing histogram to maintain consistency
    x_edges = h.XBinEdges;
    y_edges = h.YBinEdges;

    % Clear the existing histogram and create a new one with updated data
    % This approach re-computes the histogram with the combined dataset.
    % Alternatively, if performance is critical and binning is fixed,
    % one could manually update bin counts.
    delete(h); % Delete the old histogram object
    h = histogram2(updated_x, updated_y, x_edges, y_edges);

    % Optional: Customize the plot if desired
    title('Updated Bivariate Histogram');
    xlabel('X-axis');
    ylabel('Y-axis');
    colorbar; % Add a color bar to indicate counts
end
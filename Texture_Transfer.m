
clc,clear
% EE368/CS232 Digital Image Processing 
% Allison Card
% Final Project: Artistic Rendering of Digital Images
% Texture Transfer - transfer texture of input image to target image

% Source information (adjust for your use)
cd('')
input_image = im2double(imread('Input_Images/Starry_Night.jpg', 'jpg')); % Texture to be matched
target_image = im2double(imread('Target_Images/yosemite.jpg', 'jpg')); % Image to be transformed
old=imread('Target_Images/yosemite.jpg', 'jpg')

% Parameters (adjust for your use)
neighborhood = 3; % Considers a nxn neighborhood (e.g., 5x5)
p = 0.2 % Probability of considering a random pixel
m = 0.9; % Weighting on intesity matching between images
iterations = 1; % Number of times the algorithm runs over the image

% Step 1: Initialize output image
[i_height, i_width, i_depth] = size(input_image);
[o_height, o_width, o_depth] = size(target_image);
n_2 = floor(neighborhood/2);

input_image_gray = rgb2gray(input_image);
target_image_gray = rgb2gray(target_image);

% Create variables for output image and locations used in input image
output_image = zeros(o_height+n_2, o_width+n_2*2, o_depth);
used_heights = zeros(o_height+n_2, o_width+n_2*2);
used_widths = zeros(o_height+n_2, o_width+n_2*2);

% Randomly assign "used" pixel locations to borders
used_heights(1:n_2,:) = round(rand(n_2, o_width+n_2*2)*(i_height-1)+1);
used_widths(1:n_2,:) = round(rand(n_2, o_width+n_2*2)*(i_width-1)+1);
used_heights(:,1:n_2) = round(rand(o_height+n_2, n_2)*(i_height-1)+1);
used_widths(:,1:n_2) = round(rand(o_height+n_2, n_2)*(i_width-1)+1);
used_heights(:,n_2+o_width+1:n_2*2+o_width) = round(rand(o_height+n_2, n_2)*(i_height-1)+1);
used_widths(:,n_2+o_width+1:n_2*2+o_width) = round(rand(o_height+n_2, n_2)*(i_width-1)+1);

% Fill output image with appropriate color values
for h = 1:n_2
    for w = 1:(o_width+n_2*2)
        output_image(h,w,:) = input_image(used_heights(h,w),used_widths(h,w),:);
    end
end

for h = n_2:(o_height+n_2)
    for w = [1:n_2,n_2+o_width+1:n_2*2+o_width]
        output_image(h,w,:) = input_image(used_heights(h,w),used_widths(h,w),:);
    end
end

% Step 3: Repeat Step 2 for some number of iterations
% -More candidates considered
% -Slight change in the distance measurement
for iteration = 1:iterations
    iteration
    
    % Step 2: Recreate target image with source texture
    % -Find candidate pixels
    % -Add random pixel
    % -Choose best pixel
    % -Repeat
    for h = (n_2+1):(o_height+n_2)
        for w = (n_2+1):(o_width+n_2)

            % Find candidates
            candidate_locations = [];
            candidate_pixels = {};
            count = 1;
            
            search_height = 0:1:n_2;
            search_width = 0:1:neighborhood-1;
            
            % In the repeat use the full neighborhood to look at candidates
            if iteration > 1
                search_height = -n_2:1:n_2;
            end

            for c_h = search_height
                for c_w = search_width
                    c_w_adj = c_w-n_2;
                    if and(or(or(c_h > 0, and(c_h == 0, c_w_adj < 0)), iteration > 1), h-c_h <= o_height+n_2)
                        new_height = used_heights(h-c_h,w+c_w_adj)+c_h;
                        new_width = used_widths(h-c_h,w+c_w_adj)-c_w_adj;

                        % If we reach the edge of the image, choose a new pixel
                        while or(or(new_height < neighborhood, new_height > i_height-neighborhood), ...
                                  or(new_width < neighborhood, new_width > i_width-neighborhood))
                            new_height = round(rand(1)*(i_height-1)+1);
                            new_width = round(rand(1)*(i_width-1)+1);
                        end

                        candidate_locations = [candidate_locations; new_height,new_width];
                        candidate_pixels{count} = input_image(new_height, new_width, :);
                        count = count + 1;
                    end
                end
            end

            % Add random pixel with probability p
            if rand() < p
                new_height = round(rand(1)*(i_height-1)+1);
                new_width = round(rand(1)*(i_width-1)+1);

                % If this is the edge of the image, choose a new pixel
                while or(or(new_height < neighborhood, new_height > i_height-neighborhood), ...
                          or(new_width < neighborhood, new_width > i_width-neighborhood))
                    new_height = round(rand(1)*(i_height-1)+1);
                    new_width = round(rand(1)*(i_width-1)+1);
                end

                candidate_locations = [candidate_locations; new_height,new_width];
                candidate_pixels{count} = input_image(new_height, new_width, :);
            end

            % Remove duplicates
            [C, unique_indicies, ic] = unique(candidate_locations, 'rows');

            % Find best candidate
            best_dist = 10000;
            best_pixel = [];
            best_location = [];

            % Look through all candidates
            for i = unique_indicies.'
                c_h = candidate_locations(i,1);
                c_w = candidate_locations(i,2);
                
                % Measure distance
                if iteration > 1
                    % Distance between the target and the result
                    height = -n_2:1:min(n_2,o_height-(h-n_2));
                    width = -n_2:1:n_2;
                    n = (max(height)+n_2+1)*(max(width)+n_2+1);
                    
                    input_values = reshape(input_image(c_h+height,c_w+width, :),1,3*n);
                    result_values = reshape(output_image(h+height,w+width,:),1,3*n);
                    
                    input_result_distance = pdist2(input_values, result_values);

                    % Distance between the intesity of the neighborhood
                    height = max(-n_2, 1-(h-n_2)):1:min(n_2,o_height-(h-n_2));
                    width = max(-n_2, 1-(w-n_2)):1:min(n_2,o_width-(w-n_2));
                    input_values = input_image_gray(height+c_h, width+c_w);
                    target_values = target_image_gray((h-n_2)+height, (w-n_2)+width);
                    input_target_distance = (mean(input_values(:))-mean(target_values(:)))^2;

                    distance = m*input_target_distance + (1/n^2)*input_result_distance;
                else
                    % Distance between the target and the result
                    input_values = [reshape(input_image(c_h-n_2:c_h-1,c_w-n_2:c_w+n_2,:),1,3*neighborhood*n_2), ...
                                    reshape(input_image(c_h,c_w-n_2:c_w-1,:),1,3*n_2)];
                    result_values = [reshape(output_image(h-n_2:h-1,w-n_2:w+n_2,:),1,3*neighborhood*n_2), ...
                                     reshape(output_image(h,w-n_2:w-1,:),1,3*n_2)];
                    
                    input_result_distance = pdist2(input_values, result_values);
                    n = neighborhood*n_2 + n_2;

                    % Distance between the intesity of the neighborhood
                    height = max(-n_2, 1-(h-n_2)):1:min(n_2,o_height-(h-n_2));
                    width = max(-n_2, 1-(w-n_2)):1:min(n_2,o_width-(w-n_2));
                    
                    input_values = input_image_gray(height+c_h, width+c_w);
                    target_values = target_image_gray((h-n_2)+height, (w-n_2)+width);
                    
                    input_target_distance = (mean(input_values(:))-mean(target_values(:)))^2;

                    distance = m*input_target_distance + (1/n^2)*input_result_distance;
                end

                % Find best distance
                if distance < best_dist
                    best_pixel = candidate_pixels{i};
                    best_location = candidate_locations(i,:);
                    best_dist = distance;
                end
            end

            % Add the new pixel
            output_image(h,w,:) = best_pixel;
            used_heights(h,w) = best_location(1);
            used_widths(h,w) = best_location(2);
        end
    end
end

% Step 4: Remove initialized values
new_output = output_image(n_2+1:o_height+n_2, n_2+1:o_width+n_2, :);

subplot(221)
imshow(input_image)
subplot(222)
imshow(new_output)
subplot(223)
imshow(old)


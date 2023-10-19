%jpeg_image = imread('choice.jpg');
%gray_image = rgb2gray(jpeg_image);
load("Data/SampleImages/camera256.mat");
image = camera256;
[M, N] = size(image);
block_size = 8;
quality_level = 80;

Q_50 = [16 11 10 16 24 40 51 61;
    12 12 14 19 26 58 60 55;
    14 13 16 24 40 57 69 56;
    14 17 22 29 51 87 80 62;
    18 22 37 56 68 109 103 77;
    24 35 55 64 81 104 113 92;
    49 64 78 87 103 121 120 101;
    72 92 95 98 112 100 103 99];

% Quality factor
if quality_level > 50
    tau = (100 - quality_level)/50;
else
    tau = 50/quality_level;
end

% Quantization matrix
Q = tau*Q_50;
numZeros = 0;

display(Q);

compressed = zeros(M,N);
original = zeros(M,N);

for i = 1:block_size:M
    for j = 1:block_size:N
        % Dividing to 8x8 blocks
        B = image(i:i+7, j:j+7);
        display(B);
        % Level off by substracting 128 from each entry
        B_hat = B - 128;
        display(B_hat);
        % Apply DCT
        C = dct2(B_hat);
        display(C);
        % Perform quantization
        S = round(C ./ Q);
        display(S);
        numZeros = numZeros + sum(S(:) == 0);
        compressed(i:i+block_size-1, j:j+block_size-1) = S;
        
        % Decompression
        R = Q.*S;
        display(R);
        E = idct2(R);
        display(E);
        F = E + 128;
        display(F);
        
        %display(B);
        %display(F);
        break;
        original(i:i+block_size-1, j:j+block_size-1) = F;
    end
    break;
end
zeros = (numZeros/(M*N))*100;

% Ensure that the images have the same data type (e.g., uint8)
error_mat = original - image;
% Calculate the squared error matrix
squared_error = (error_mat).^2;

% Calculate the mean squared error (MSE)
mse = mean(squared_error(:));  % Take the mean over all elements

% Determine the maximum pixel intensity (ψmax) for 8-bit images
max_intensity = 255;

% Calculate the PSNR using the formula
psnr = 20 * log10(max_intensity / sqrt(mse));
display(psnr);
display(zeros);

figure;

% Define the number of rows and columns for the subplot
num_rows = 1;
num_cols = 2;

% Plot the first image in the first subplot
subplot(num_rows, num_cols, 1);
imshow(uint8(image));
title('Original Image');

% Plot the second image in the second subplot
combined_title = sprintf('Compressed - Quality Level: %d', quality_level);
subplot(num_rows, num_cols, 2);
imshow(uint8(original));
title(combined_title);
text(0.5, -0.05, sprintf('Zeros: %.2f', zeros), 'Units', 'normalized', 'HorizontalAlignment', 'center');
% Adjust the layout for better visualization
% Adjust as needed based on your image sizes
set(gcf, 'Position', [100, 100, 800, 400]);
clear;
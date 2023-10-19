load("Data/SampleImages/camera256.mat");
load("Data/SampleImages/boat512.mat");
load("Data/SampleImages/goldhill512.mat");

imageMatrix = imread("columbia.tif");
imageMatrix = double(imageMatrix);

quality_levels = [80, 40, 15];

psnr_cam = compression(camera256, quality_levels);
psnr_boat = compression(boat512, quality_levels);
psnr_ghill = compression(goldhill512, quality_levels);
psnr_choice = compression(imageMatrix, quality_levels);

display(psnr_cam);
display(psnr_boat);
display(psnr_ghill);
display(psnr_choice);

function psnr_values = compression(image, quality_levels)
    n = length(quality_levels);
    psnr_values = zeros(1,n);
    
    figure;
    % Plot the first image in the first subplot
    subaxis(2, 2, 1, 'Spacing', 0.1, 'Padding', 0.02, 'Margin', 0.01);
    imshow(uint8(image));
    title('Original Image');
    
    % Iterate with every quality level
    for k = 1:n
        quality_level = quality_levels(k);  % Take the quality level
        [M, N] = size(image);
        block_size = 8;             % Define the block size
        
        % Quantization matrix for quality level 50
        Q_50 = [16 11 10 16 24 40 51 61;
            12 12 14 19 26 58 60 55;
            14 13 16 24 40 57 69 56;
            14 17 22 29 51 87 80 62;
            18 22 37 56 68 109 103 77;
            24 35 55 64 81 104 113 92;
            49 64 78 87 103 121 120 101;
            72 92 95 98 112 100 103 99];

        % Calculate the quality factor
        if quality_level > 50
            tau = (100 - quality_level)/50;
        else
            tau = 50/quality_level;
        end

        % Quantization matrix
        Q = tau*Q_50;
        numZeros = 0;

        recon_image = zeros(M,N);   % Create a matrix to store reconstructed image

        for i = 1:block_size:M
            for j = 1:block_size:N
                % Dividing to 8x8 blocks
                B = image(i:i+7, j:j+7);
                % Level off by substracting 128 from each entry
                B_hat = B - 128;
                % Apply DCT
                C = dct2(B_hat);
                % Perform quantization
                S = round(C ./ Q);
                % Calculate number of zeros
                numZeros = numZeros + sum(S(:) == 0);
                % Decompression
                R = Q.*S;
                % Calculate inverse 2-D DCT
                E = idct2(R);
                F = E + 128;
                recon_image(i:i+block_size-1, j:j+block_size-1) = F;
            end
        end
        zero = (numZeros/(M*N))*100;
        % Calculate the error matrix
        error_mat = recon_image - image;
        % Calculate the squared error matrix
        squared_error = (error_mat).^2;
        % Calculate the mean squared error (MSE)
        mse = mean(squared_error(:));

        max_intensity = 255;

        % Calculate the PSNR value
        psnr = 20 * log10(max_intensity / sqrt(mse));
        psnr_values(:,k) = psnr;     
        
        % Plotting the images
        subaxis(2, 2, k + 1, 'Spacing', 0.1, 'Padding', 0.02, 'Margin', 0.01);
        combined_title = sprintf('Compressed - Quality Level: %d', quality_level);
        imshow(uint8(recon_image));
        title(combined_title);
        text(0.5, -0.05, sprintf('Zeros: %.2f%%', zero), 'Units', 'normalized', 'HorizontalAlignment', 'center');
    end
end

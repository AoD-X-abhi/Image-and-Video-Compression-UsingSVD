clear; clc; close all;

img = imread('Car1.png');   % <-- Path of your Image
if size(img, 3) == 3
    img = rgb2gray(img);
end
img = double(img);

figure(1);
subplot(2, 3, 1);
imshow(uint8(img));
title('Original Image');

[m, n] = size(img);
fprintf('Original Image Size: %d x %d\n', m, n);
original_size = m * n;

[U, S, V] = svd(img, 'econ');
sigma = diag(S);

k_values = [5, 10, 20, 50, 100];
compressed_imgs = cell(1, length(k_values));

figure(1);
for i = 1:length(k_values)
    k = k_values(i);
    img_compressed = U(:, 1:k) * S(1:k, 1:k) * V(:, 1:k)';
    img_compressed = max(0, min(255, img_compressed));
    compressed_imgs{i} = uint8(img_compressed);
    subplot(2, 3, i+1);
    imshow(compressed_imgs{i});
    title(sprintf('k = %d', k));
    compressed_size = k*(m + n + 1);
    compression_ratio = original_size / compressed_size;
    mse = mean((img(:) - img_compressed(:)).^2);
    psnr_val = 10*log10(255^2 / mse);
    fprintf('k = %3d | Storage: %6d | Ratio: %6.2f:1 | PSNR: %6.2f dB\n', ...
        k, compressed_size, compression_ratio, psnr_val);
end

figure(2);
semilogy(sigma, 'b-', 'LineWidth', 1.5);
grid on;
xlabel('Singular Value Index');
ylabel('Singular Value (log scale)');
title('Singular Values of the Image');
xlim([1, min(100, length(sigma))]);

cum_energy = cumsum(sigma.^2) / sum(sigma.^2);
figure(3);
plot(cum_energy, 'r-', 'LineWidth', 1.5);
grid on;
xlabel('Number of Singular Values (k)');
ylabel('Normalized Cumulative Energy');
title('Energy Retained vs. Number of Singular Values');
hold on;
plot([k_values; k_values], [0; 1], 'k--');
hold off;
xlim([1, min(200, length(sigma))]);

disp('SVD Image Compression Demo Complete!');

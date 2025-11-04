clear; clc; close all;

videoFile   = 'Life.mp4';   % <-- Change Path for your Image
k           = 20;
downFactor  = 0.5;
saveVideo   = true;

vidObj    = VideoReader(videoFile);
frameRate = vidObj.FrameRate;
numFrames = vidObj.NumFrames;

firstRGB  = read(vidObj,1);
firstGray = rgb2gray(firstRGB);
[h0, w0]  = size(firstGray);
h = round(h0 * downFactor);
w = round(w0 * downFactor);

fprintf('Input: %d×%d @ %.1f fps, %d frames\n', w0, h0, frameRate, numFrames);
fprintf('Working: %d×%d (k=%d)\n', w, h, k);

pixels = h * w;
U = zeros(pixels, k, 'single');
initialized = false;

if saveVideo
    outFile = sprintf('compressed_k%d.mp4', k);
    writer  = VideoWriter(outFile, 'MPEG-4');
    writer.FrameRate = frameRate;
    open(writer);
end

hWait = waitbar(0, 'Compressing video...');
for i = 1:numFrames
    rgb = read(vidObj, i);
    gray = imresize(rgb2gray(rgb), [h w], 'bilinear');
    x = single(gray(:));

    if ~initialized
        [U(:,1), ~] = eigs(@(v) v, pixels, 1, 'largestreal');
        U(:,1) = x / norm(x);
        initialized = true;
    end

    coeffs = U' * x;
    x_recon = U * coeffs;

    resid = x - x_recon;
    if norm(resid) > 1e-3 * norm(x) && size(U,2) < k
        U(:, end+1) = resid / norm(resid);
    end

    if mod(i, 10) == 0 || i == numFrames
        [U, ~] = qr(U, 0);
        U = U(:, 1:min(k, size(U,2)));
    end

    coeffs = U' * x;
    x_recon = U * coeffs;
    frame_out = reshape(x_recon, h, w);
    frame_out = max(0, min(255, frame_out));
    frame_uint8 = uint8(frame_out);

    if ismember(i, [1, round(numFrames*[0.25 0.5 0.75]), numFrames])
        figure(1); clf;
        subplot(1,2,1); imshow(gray);       title(sprintf('Original Frame %d', i));
        subplot(1,2,2); imshow(frame_uint8); title(sprintf('Compressed (k=%d)', k));
        drawnow;
    end

    if saveVideo
        writeVideo(writer, frame_uint8);
    end

    waitbar(i/numFrames, hWait);
end
close(hWait);

if saveVideo
    close(writer);
    fprintf('Saved: %s\n', outFile);
end

sampleIdx = unique(round(linspace(1, numFrames, min(30, numFrames))));
psnrVals = zeros(length(sampleIdx),1);
for j = 1:length(sampleIdx)
    i = sampleIdx(j);
    rgb = read(vidObj, i);
    gray = imresize(rgb2gray(rgb), [h w]);
    x = single(gray(:));
    coeffs = U' * x;
    x_recon = U * coeffs;
    mse = mean((double(x) - double(x_recon)).^2);
    psnrVals(j) = 10*log10(255^2 / mse);
end
fprintf('Average PSNR (on %d frames): %.2f dB\n', length(sampleIdx), mean(psnrVals));

disp('=== Compression complete! ===');

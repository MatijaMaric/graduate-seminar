clear all
close all

% Load the grid of images
slices = imread('vivoGlo_slicica.jpg');
slices = double(rgb2gray(slices));
slices = (slices - min(slices))./(max(slices) - min(slices));

R = 2; C = 4;

% Split per slices
slices_size = size(slices);
slices_size = slices_size - mod(slices_size, [R C]);

slices_w = slices_size(1);
slices_h = slices_size(2);

slices_size = round(slices_size ./ [R C]);

slice_w = slices_size(1);
slice_h = slices_size(2);

% Array of slices
slice3d = zeros(slice_w/2, slice_h, R*C);

areas1 = zeros(10, R*C);
areas2 = zeros(10, R*C);
areasFus = zeros(10, R*C);

slice_id = 1;
for i = 1:slice_w:slices_w
    for j = 1:slice_h:slices_h
        x1 = i;
        y1 = j;
        x2 = x1 + slice_w - 1;
        if x2 > slices_w
            x2 = slices_w
        end
        y2 = y1 + slice_h - 1;
        if y2 > slices_h
            y2 = slices_h
        end
        
        % Single slice
        slice = slices(x1:x2, y1:y2);
        %figure, imagesc(slice);
        % Split to T1 and T2 map
        T1 = slice(1:slice_w/2, 1:end);
        %fig = figure(); imagesc(T1);
        %[X, Y] = getpts(fig); X = round(X); Y = round(Y);
        for k = 1:10
            %reg1 = procregiongrow(T1);
            reg1 = regiongrowing(T1);
            area1 = sum(reg1(:));
            areas1(k, slice_id) = area1
        end
        
        T2 = slice(slice_w/2+1:end, 1:end);
        %fig = figure(); imagesc(T2);
        %[X, Y] = getpts(fig); X = round(X); Y = round(Y);
        for k = 1:10
            %reg2 = procregiongrow(T2);
            reg2 = regiongrowing(T2);
            area2 = sum(reg2(:));
            areas2(k, slice_id) = area2
        end
        
        %threshL = multithresh(T2, 7);
        %vals = [0 threshL(2:end) 1];
        %quantized = imquantize(T2, threshL, vals);
        %filled = regiongrowing(quantized, 150, 100, 0.15);
        
        
        % Fuse slices using PCA
        fused_slice = pca_fusion(T1, T2);
        
        % Fuse slices using wavelet transform
        wfused = wfusimg(T1, T2, 'sym4', 5, 'mean', 'mean');
        wfused2 = wfusimg(T1, T2, 'db2', 5, 'mean', 'mean'); 
        
        %fig = figure(); imagesc(wfused2);
        %[X, Y] = getpts(fig); X = round(X); Y = round(Y);
        for k = 1:10
            %regFus = procregiongrow(wfused2);
            regFus = regiongrowing(wfused2);
            areaFus = sum(regFus(:));
            areasFus(k, slice_id) = areaFus
        end
        
        
        close all;
        
        figure;
        imagesc(T1);
        colormap(gray);
        hold on;
        contour(reg1, '-r');
        hold off;
        
        figure;
        subplot(1, 3, 1);
        imagesc(T1);
        colormap(gray);
        hold on;
        contour(reg1, '-r');
        hold off
        
        subplot(1, 3, 2);
        imagesc(T2);
        colormap(gray);
        hold on;
        contour(reg2, '-r');
        hold off
        
        subplot(1, 3, 3);
        imagesc(wfused2);
        colormap(gray);
        hold on;
        contour(regFus, '-r');
        hold off
        
        %slice3d(:, :, slice_id) = fused_slice;
        %slice_id = slice_id + 1;
        %figure, imagesc(fused_slice);
        %colormap(gray);
        %figure, imagesc(wfused);
        %colormap(gray);
        figure;
        subplot(2,2,1);
        imagesc(T1);
        title('T1');
        colormap(gray);
        
        subplot(2,2,2);
        imagesc(wfused);
        title('wavelet(sym4)');
        
        subplot(2,2,3);
        imagesc(T2);
        title('T2');
        
        subplot(2,2,4);
        imagesc(wfused2);
        title('wavelet(db2)');
        
        slice_id = slice_id + 1;
    end
end

plotErrors(areas1, areas2, areasFus);

imagesc(slices);
close all
%% Prepare images
I1 = imread('27.jpg');
I2 = imread('28.jpg');
% Undistort them!
%I1 = undistortImage(I1, cameraParams);
%I2 = undistortImage(I2, cameraParams);
%figure 
%imshowpair(I1, I2, 'montage');
%title('Undistorted Images');

% Convert to grayscale.
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);

% red/cyan composed
%figure;
%imshow(stereoAnaglyph(I1,I2));
%title('Composite Image (Red - Left Image, Cyan - Right Image)');
%% Find Correspondence
% Hello twins!
blobs1 = detectSURFFeatures(I1gray, 'MetricThreshold', 50, ...
    'NumOctaves', 5, 'NumScaleLevels', 8);
blobs2 = detectSURFFeatures(I2gray, 'MetricThreshold', 50, ...
    'NumOctaves', 5, 'NumScaleLevels', 8);

[features1, validBlobs1] = extractFeatures(I1gray, blobs1);
[features2, validBlobs2] = extractFeatures(I2gray, blobs2);

indexPairs = matchFeatures(features1, features2, 'Metric', 'SAD', ...
  'MatchThreshold', 50);

matchedPoints1 = validBlobs1(indexPairs(:,1),:);
matchedPoints2 = validBlobs2(indexPairs(:,2),:);

% Cac diem chung ban dau
%figure;
%showMatchedFeatures(I1, I2, matchedPoints1, matchedPoints2);
%legend('Diem chung trong I1', 'Diem chung trong I2');

% Epipolar constraint
[fMatrix, epipolarInliers, status] = estimateFundamentalMatrix(...
  matchedPoints1, matchedPoints2, 'Method', 'MSAC', ...
  'NumTrials', 10000, 'DistanceThreshold', 0.1, 'Confidence', 99.99);

if status ~= 0 || isEpipoleInImage(fMatrix, size(I1)) ...
  || isEpipoleInImage(fMatrix', size(I2))
  error(['Either not enough matching points were found or '...
         'the epipoles are inside the images. You may need to '...
         'inspect and improve the quality of detected features ',...
         'and/or improve the quality of your images.']);
end
% Cac diem chung chinh xac
inlierPoints1 = matchedPoints1(epipolarInliers, :);
inlierPoints2 = matchedPoints2(epipolarInliers, :);

figure;
showMatchedFeatures(I1, I2, inlierPoints1, inlierPoints2);
legend('Inlier points in I1', 'Inlier points in I2');
%% Rectify images
% Tim phep hieu chinh anh
[t1, t2] = estimateUncalibratedRectification(fMatrix, ...
  inlierPoints1.Location, inlierPoints2.Location, size(I2));
tform1 = projective2d(t1);
tform2 = projective2d(t2);
% Hieu chinh anh
[I1Rect, I2Rect] = rectifyStereoImages(I1, I2, tform1, tform2);
% figure;
% imshow(stereoAnaglyph(I1Rect, I2Rect));
% title('Rectified Stereo Images (Red - Left Image, Cyan - Right Image)');

%% Disparity Map
I1Rectgray = rgb2gray(I1Rect);
I2Rectgray = rgb2gray(I2Rect);
disparityMap = disparitySGM(I1Rectgray, I2Rectgray);
figure;
imshow(disparityMap, [0, 64]);
title('Disparity Map');
colormap jet
colorbar

%% 3D Reconstruction
%Doan nay can thong tin tu Calibrating camera
%points3D = reconstructScene(disparityMap, stereoParams);

% Convert to meters and create a pointCloud object
%points3D = points3D ./ 1000;
%ptCloud = pointCloud(points3D, 'Color', I1Rect);

% Create a streaming point cloud viewer
%player3D = pcplayer([-3, 3], [-3, 3], [0, 8], 'VerticalAxis', 'y', ...
%    'VerticalAxisDir', 'down');

% Visualize the point cloud
%view(player3D, ptCloud);

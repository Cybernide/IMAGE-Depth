%% 3D point cloud generation using IMAGE outputs

filepath = "./RGB-D/plane/";

depth_image = imread(filepath + "plane_d.png");
rgb_image = imread(filepath + "plane.jpg");

% pc_image = cat(3,rgb_image,depth_image);

xPoints = 1:length(depth_image(1,:));
yPoints = transpose(1:length(depth_image(:,1)));

xPoints = xPoints/length(depth_image(1,:)) * 100;
yPoints = yPoints/length(depth_image(:,1)) * 100;
depth_image = double(depth_image) / 255 * 100;

for h = 1 : length(depth_image(:,1)) - 1
    xPoints = cat(1,xPoints,(1:length(depth_image(1,:)))/length(depth_image(1,:)) * 100);
end

for w = 1 : length(depth_image(1,:)) - 1
    yPoints = cat(2,yPoints,transpose(1:length(depth_image(:,1)))/length(depth_image(1,:)) * 100);
end

xyzPoints = double(cat(3,xPoints,yPoints,depth_image));

ptCloud = pointCloud(xyzPoints,"Color",rgb_image);
% ptCloud = pointCloud(xyzPoints);

pcshow(ptCloud)
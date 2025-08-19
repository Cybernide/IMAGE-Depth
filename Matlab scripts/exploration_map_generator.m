%% Read exploration trajectory file and output a line plot of exploration and exploration heatmap


filename = "exploration files/tt08_log.csv";

makemaps(filename)


function makemaps(filename)

% load data
M = readtable(filename);

x = M.x;
y = M.y;
time = M.time - M.time(1);

% Normalize X and Y axis trajectories
xnorm = normalize(M.x,"range");
ynorm = normalize(M.y,"range");

%% generate line plot of trajectory
figure(1)
plot(xnorm,-ynorm)
title(filename)
hold("on")

%loop to find all the different objects
unique_vals = unique(M.Object);
for i = 2 : length(unique_vals)
    ind = find(M.Object == unique_vals(i));
    plot(xnorm(ind),-ynorm(ind))
end

hold("off")

%% density map / heatmap

% define bin edges and find bin counts
edx = 0:0.05:1;
edy = 0:0.05:1;
counts = histcounts2(xnorm,ynorm,edx,edy).'; 

figure(2)
imagesc(counts)
title(filename)
colorbar

%% avg framerate 
pixelpermm = 1;     % CHANGE THIS TO MATCH WHAT IS ON THE PROCESSING APP

x_mm = x*pixelpermm;

y_mm = y*pixelpermm;

framerate = [0; diff(time)];

figure
histogram(framerate/1000000)
title("Distribution of period for the 2DIY")
ylabel("Counts")
xlabel("Time between 10 frames (ms)")

figure
plot(1:length(framerate),framerate/1000000)
title("period of 2DIY over time")


figure
histogram(1./(framerate/1000000000))
title("Distribution of framerate for the 2DIY")
ylabel("Counts")
xlabel("framerate for every 10 frames (fps)")

figure
plot(1:length(framerate),1./(framerate/1000000000))
title("framerate of 2DIY over time")


% debugging plot 

x = xnorm*100;
y = -ynorm*100;
z = zeros(size(x));
%z = zeros([length(x),length(x)]);
col = framerate/1000000;

figure
title("Trajectory with processing time")
surface([x(100:end,1)';x(100:end,1)'],[y(100:end,1)';y(100:end,1)'],[z(100:end,1)';z(100:end,1)'],[col(100:end,1)';col(100:end,1)'],...
        'facecol','no',...
        'edgecol','interp',...
        'linew',2);
colorbar

end
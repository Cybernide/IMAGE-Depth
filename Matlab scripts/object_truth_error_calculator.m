%% Depth Study: Calculate the error between objects and truth to find closest match

% Change variable to match participant
% input:    objectlist = perspective.scene_# 
%           struct which contains cell variable marked as "scene" 1-N each containing object coordinates within a scene
%           truth = scene_#
%           struct containing scenes with the truth position of objects
%           within each scene.

data = depth_p02;

[mse, indtruth ] = SortObjects(data.topdown,depth_truth);
data.truthIndex.topdown.index = indtruth;
data.truthIndex.topdown.mse = mse;

[mse, indtruth ] = SortObjects(data.frontfacing_h,depth_truth);
data.truthIndex.frontfacing_h.index = indtruth;
data.truthIndex.frontfacing_h.mse = mse;

[mse, indtruth ] = SortObjects(data.frontfacing_v,depth_truth);
data.truthIndex.frontfacing_v.index = indtruth;
data.truthIndex.frontfacing_v.mse = mse;

save("Depth_Study_P02_matched.mat","data");

function [errorlist, indexlist] = SortObjects(objeclist, truth)

scenes = fieldnames(objeclist);
scenes_truth = fieldnames(truth);

ind_find = find(contains(scenes_truth,scenes));

mse = zeros(length(ind_find));

errorlog = zeros([4,1]);

for i = 1 : length(ind_find) %loop through each scene
    indexlist.(scenes{i}) = zeros([4,1]); %iteratively generate/name the scene index variable 
    errorlist.(scenes{i}) = zeros([4,1]); 
    var = cell2mat(objeclist.(scenes{i}).position);
    var_t = cell2mat(truth.(scenes_truth{ind_find(i)}));
    for j = 1 : length(var(:,1)) %loop through each experimental object
        for s = 1 : length(var_t(:,1)) % loop through each truth object
            mse(j,s) = mean((var(j,:) - var_t(s,:)).^2);            
        end
    end
    truth_ind = ones(size(mse)) .* [1:length(mse(:,1))]';
    
    count = 1;
    for c1 = 1 : j
        for c2 = 1: j
            for c3 = 1 : j
                for c4 = 1 : j
                    mse_comb(count,1:length(mse(1,:))) = [mse(c1,1),mse(c2,2),mse(c3,3),mse(c4,4)];
                    truth_comb(count,1:1:length(mse(1,:))) = [truth_ind(c1,1),truth_ind(c2,2),truth_ind(c3,3),truth_ind(c4,4)];
                    unique_vals = unique(truth_comb(count,1:1:length(mse(1,:))));
                    if length(unique_vals) < length(mse(1,:))
                        valid_inds(count) = 0;
                    else
                        valid_inds(count) = 1;
                    end                    
                    count = count + 1;
                end
            end
        end
    end

    % error minimization
    mse_valid = mse_comb(find(valid_inds),:);
    truth_valid = truth_comb(find(valid_inds),:);

    [mse_min, mse_min_ind] = min(sum(mse_valid,2));

    errorlist.(scenes{i}) = mse_valid(mse_min_ind,:);
    indexlist.(scenes{i}) = truth_valid(mse_min_ind,:);

end
end 
%% Function that will generate Truth data structure for Depth analysis

% Struture title
var_title = "truth_data.mat";

% Truth values 
% VariableName.Scene# = {position x, position y, postion z; repeat for other objects}

scaling = 20;

depth_truth.scene_01 = {0.1,0.1,0.2;
                        0.4,0.3,0.55;
                        0.8,0.6,0.65;
                        0.65,0.9,0.38} * scaling;
depth_truth.scene_02 = {0.2,0.3,0.85;
                        0.6,0.5,0.28;
                        0.7,0.7,0.71;
                        0.3,0.9,0.45} * scaling;
depth_truth.scene_03 = {0.15,0.15,0.63;
                        0.7,0.4,0.48;
                        0.25,0.5,0.3;
                        0.5,0.7,0.85} * scaling;
depth_truth.scene_04 = {0.6,0.2,0.46;
                        0.18,0.4,0.32;
                        0.82,0.5,0.14;
                        0.47,0.8,0.78} * scaling;
depth_truth.scene_05 = {0.8,0.1,0.18;
                        0.6,0.2,0.5;
                        0.7,0.55,0.83;
                        0.23,0.68,0.63} * scaling;
depth_truth.scene_06 = {0.12,0.25,0.5;
                        0.72,0.4,0.72;
                        0.27,0.55,0.9;
                        0.62,0.65,0.32} * scaling;
depth_truth.scene_07 = {0.4,0.1,0.62;
                        0.5,0.55,0.21;
                        0.7,0.68,0.45;
                        0.46,0.68,0.55} * scaling;
depth_truth.scene_08 = {2,14,1;
                        4,5,2;
                        7,9,4;
                        3,12,3} * scaling;
depth_truth.scene_09 = {1,14,3;
                        7,2,1;
                        9,16,4;
                        16,6,2} * scaling;
depth_truth.scene_10 = {2,2,3;
                        9,8,1;
                        14,5,4;
                        16,16,2} * scaling;
depth_truth.scene_11 = {2,15,3;
                        6,5,1;
                        11,2,2;
                        14,10,4} * scaling;
depth_truth.scene_12 = {4,14,3;
                        6,5,4;
                        8,11,1;
                        11,2,2} * scaling;
depth_truth.scene_13 = {2,4,4;
                        4,12,2;
                        9,6,3;
                        14,10,1} * scaling;
depth_truth.scene_14 = {4,14,2;
                        7,2,4;
                        13,8,1;
                        15,16,3} * scaling;
depth_truth.scene_15 = {3,3,4;
                        5,8,2;
                        8,1,3;
                        11,10,1} * scaling;
depth_truth.scene_16 = {2,5,1;
                        5,3,2;
                        7,14,3;
                        11,8,4} * scaling;
depth_truth.scene_17 = {2,11,1;
                        12,9,4;
                        14,16,2;
                        16,3,3} * scaling;
depth_truth.scene_18 = {3,6,1;
                        6,14,3;
                        9,2,2;
                        13,8,4} * scaling;
depth_truth.scene_19 = {2,3,2;
                        4,16,4;
                        6,8,1;
                        11,6,3} * scaling;
depth_truth.scene_20 = {1,16,1;
                        3,2,2;
                        6,10,4;
                        10,8,3} * scaling;

save(var_title,"depth_truth")
%% Function that will generate experimental data structure for Depth analysis

% Struture title - INCLUDE PARTICIPANT # ex.Depth_Study_P01
var_title = "Depth_Study_P02.mat";

% Truth values 
% VariableName.Perspective.Scene# = {position x, position y, postion z; repeat for other objects}
% update variable name to match participant #
data.topdown.scene_01.position = {2,12,2;7,16,3;13,6,3;14,1,2};
data.topdown.scene_01.exploration = "sequential";
data.frontfacing_h.scene_02.position = {6,2,1;8,11,3;12,12,1;15,2,4};
data.frontfacing_h.scene_02.exploration = "parallel";
data.frontfacing_h.scene_03.position = {7,10,4;11,4,1;12,14,1;16,2,3};
data.frontfacing_h.scene_03.exploration = "sequential";
data.frontfacing_v.scene_04.position = {3,9,3;10,10,2;16,15,1;16,2,1};
data.frontfacing_v.scene_04.exploration = "parallel";
data.frontfacing_v.scene_08.position = {6,4,3;12,8,4;14,16,1;16,4,1};
data.frontfacing_v.scene_08.exploration = "sequential";
data.topdown.scene_09.position = {3,11,4;7,3,3;9,12,3;13,3,2};
data.topdown.scene_09.exploration = "parallel";

% data.truthIndex.topdown.scene_01 = zeros([4,1]);
% data.truthIndex.frontfacing_h.scene_02 = zeros([4,1]);
% data.truthIndex.frontfacing_h.scene_03 = zeros([4,1]);
% data.truthIndex.frontfacing_v.scene_04 = zeros([4,1]);
% data.truthIndex.frontfacing_v.scene_08 = zeros([4,1]);
% data.truthIndex.topdown.scene_09 = zeros([4,1]);

depth_p02 = data;

save(var_title,"depth_p02")
function [groundtruth_Scores_second,groundtruth_Scores,groundtruth_Volums_centers,groundtruth_relapositions,groundtruth_relaposition_remains,Volums_Scores,Volums_Scores_second,rotated_Volums_relapositions,rotated_Volums_relaposition_remains,rotated_Volums_centers] = translate_proposals(transpose_angles, model, voxel_size, label_num, groundtruth, Voxels_200, groupPixels_200, Edge_pair, proposal_200_4kinds, proposal_200_Scores, proposal_200_Scores_second)
graph_groundtruth = groundtruth(:, 1);
groundtruth_Scores=Score_On_Graphs(graph_groundtruth ,groundtruth,Voxels_200, label_num, groupPixels_200);
groundtruth_Scores_second=Score_On_Graphs_analogy_class(graph_groundtruth ,groundtruth,Voxels_200, label_num, groupPixels_200);

transpose_angles = transpose_angles';
transpose_angles = num2cell(transpose_angles);
[rotated_Volums_relapositions, rotated_Volums_relaposition_remains, rotated_Volums_centers] = cellfun(@(x) transpose_proposals_a_time(x, proposal_200_4kinds, model, voxel_size, size(Edge_pair, 1)), transpose_angles, 'UniformOutput', false);
[groundtruth_relapositions, groundtruth_relaposition_remains, groundtruth_Volums_centers] = cellfun(@(x) transpose_proposals_a_time(x, graph_groundtruth, model, voxel_size, size(Edge_pair, 1)), transpose_angles, 'UniformOutput', false);
rotated_Volums_relapositions = free_cells(rotated_Volums_relapositions);
rotated_Volums_relaposition_remains = free_cells(rotated_Volums_relaposition_remains);
rotated_Volums_centers = free_cells(rotated_Volums_centers);
groundtruth_relapositions = free_cells(groundtruth_relapositions);
groundtruth_relaposition_remains = free_cells(groundtruth_relaposition_remains);
groundtruth_Volums_centers = free_cells(groundtruth_Volums_centers);
Volums_Scores = repmat(proposal_200_Scores, length(transpose_angles), 1);
Volums_Scores_second = repmat(proposal_200_Scores_second, length(transpose_angles), 1);
groundtruth_Scores = repmat(groundtruth_Scores, length(transpose_angles), 1);
groundtruth_Scores_second = repmat(groundtruth_Scores_second, length(transpose_angles), 1);
end
function result = free_cells(x)
x = [x{:}];
result = x(:);
end

function [Volums_30_relaposition, Volums_30_relaposition_remain, Volums_30_center] = transpose_proposals_a_time(x, proposal_200_4kinds, model, voxel_size, component_num)
Rot_Matrix = RotAngle(x);
model.vertices = model.vertices * Rot_Matrix;

%voxelization
repmat_ele=mean(model.vertices,1);
Vertices_normal = model.vertices - repmat(repmat_ele,size(model.vertices,1),1);    
components_idxes = num2cell(1:component_num);
components_idxes = components_idxes';
changed_voxels_30 = cellfun(@(x)  polygon2voxel2(FV_all_components(x,model,Vertices_normal),[voxel_size voxel_size voxel_size],0,'au'),components_idxes, 'UniformOutput',false);
changed_voxels_30 = cellfun(@(x) find(x==1), changed_voxels_30, 'UniformOutput', false);

[Volums_30_relaposition,Volums_30_relaposition_remain]=Voxelize_Subgraph_relaposition1(voxel_size, changed_voxels_30, proposal_200_4kinds);
Volums_30_center=Voxelize_Subgraph_center1(model,proposal_200_4kinds, voxel_size);
end

function FV=FV_all_components(x,model,Vertices_normal)
      FV.vertices=Vertices_normal;      
      group_idx=x;
      face=model.groups(group_idx,1);
      FV.faces=cell2mat(face);
end
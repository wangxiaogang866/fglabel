function [rotated_Volums_relapositions,rotated_Volums_relaposition_remains,rotated_Volums_centers] = translate_proposals(model, voxel_size, Edge_pair, proposal_200_4kinds)
transpose_angles = 0;
transpose_angles = num2cell(transpose_angles);
[rotated_Volums_relapositions, rotated_Volums_relaposition_remains, rotated_Volums_centers] = cellfun(@(x) transpose_proposals_a_time(x, proposal_200_4kinds, model, voxel_size, size(Edge_pair, 1)), transpose_angles, 'UniformOutput', false);
rotated_Volums_relapositions = free_cells(rotated_Volums_relapositions);
rotated_Volums_relaposition_remains = free_cells(rotated_Volums_relaposition_remains);
rotated_Volums_centers = free_cells(rotated_Volums_centers);
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
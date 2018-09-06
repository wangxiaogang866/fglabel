function [every_morph_num,merge_proposals_200_Scores_second,merge_Volums_30_center,merge_Volums_30_relaposition_remain,merge_Volums_30_relaposition,merge_proposals_200_Scores,merge_proposals_200,statistical_data_200_before,statistical_data_200_after] = data_morphing(transpose_angles, model, label_num, GT_nums, groundtruth, proposal_200_Scores_second, Edge_pair, Voxels_200, groupPixels_200)
threshold=0.7;
disp('Morphing datas.....')
tic;
 %% generate datas for balance data sizes among different labels
 %static numbers of groundtruth and proposals for each label  
 statistical_data_200_before=zeros(4,label_num);
 groundtruth_idxes=cell2mat(groundtruth(:,3));
 
 for j=1:label_num
     statistical_data_200_before(1,j)=j;
     statistical_data_200_before(2,j)=length(find(groundtruth_idxes==j));
     statistical_data_200_before(3,j)=length(find(proposal_200_Scores_second(:,j)>threshold));
 end
 statistical_data_200_before(4,:)=statistical_data_200_before(3,:)./statistical_data_200_before(2,:);
 statistical_data_200_before(isnan(statistical_data_200_before)==1)=0;
 toc;
 disp('morphing...')
 tic;
  [merge_proposals_200, every_morph_num] = Data_augument1(groundtruth, statistical_data_200_before, Edge_pair, GT_nums);
  toc;
  merge_proposals_200=merge_proposals_200';
  merge_proposals_200=cellfun(@transpose, merge_proposals_200, 'UniformOutput',false);
  empty_cells=cellfun(@(x) isempty(x), merge_proposals_200);
  empty_idx=find(empty_cells==1);
  merge_proposals_200(empty_idx)=[];
  disp('morphing scores...')
  tic;
 if size(merge_proposals_200, 1)~=0
     merge_proposals_200_Scores=Score_On_Graphs(merge_proposals_200,groundtruth,Voxels_200, label_num, groupPixels_200);
     merge_proposals_200_Scores_second=Score_On_Graphs_analogy_class(merge_proposals_200,groundtruth,Voxels_200, label_num, groupPixels_200);
 else
     merge_proposals_200_Scores = [];
     merge_proposals_200_Scores_second = [];
 end
 toc;
 disp('Voxelize morphing datas.....')
%generate proposals should be voxelized in needed angle
transpose_angles = transpose_angles';
transpose_angles = num2cell(transpose_angles);
[merge_Volums_30_relaposition, merge_Volums_30_relaposition_remain, merge_Volums_30_center] = cellfun(@(x) transpose_proposals_a_time(x, merge_proposals_200, model, 30, size(Edge_pair, 1)), transpose_angles, 'UniformOutput', false);
merge_Volums_30_relaposition = free_cells(merge_Volums_30_relaposition);
merge_Volums_30_relaposition_remain = free_cells(merge_Volums_30_relaposition_remain);
merge_Volums_30_center = free_cells(merge_Volums_30_center);
merge_proposals_200_Scores = repmat(merge_proposals_200_Scores, length(transpose_angles), 1);
merge_proposals_200_Scores_second = repmat(merge_proposals_200_Scores_second, length(transpose_angles), 1);

 %static numbers of groundtruth and proposals for each label  after generation    
 statistical_data_200_after=zeros(4,label_num);
 groundtruth_idxes=cell2mat(groundtruth(:,3));
 scores_second_after_generation = [proposal_200_Scores_second; merge_proposals_200_Scores_second(1:size(merge_proposals_200_Scores_second, 1)/2, :)];
 for j=1:label_num
     statistical_data_200_after(1,j)=j;
     statistical_data_200_after(2,j)=length(find(groundtruth_idxes==j));
     statistical_data_200_after(3,j)=length(find(scores_second_after_generation(:,j)>threshold));
 end
 statistical_data_200_after(4,:)=statistical_data_200_after(3,:)./statistical_data_200_after(2,:);
 statistical_data_200_after(isnan(statistical_data_200_after)==1)=0;

end

function result = free_cells(x)
x = [x{:}];
result = x(:);
end

function [Volums_30_relaposition, Volums_30_relaposition_remain, Volums_30_center] = transpose_proposals_a_time(x, proposal_200_4kinds, model, voxel_size, component_num)
Rot_Matrix = RotAngle(x);
model.vertices = model.vertices * Rot_Matrix;

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

function [Volums_30_relaposition1,Volums_30_relaposition_remain1]=Voxelize_Subgraph_relaposition1(VolumeSize_ele, Voxels_30, proposal_200_4kinds)
disp('Voxeling Subgraphics.....relaposition and relaposition_remain....');
Voxel_model=zeros(VolumeSize_ele, VolumeSize_ele, VolumeSize_ele);
true_idx=unique(cell2mat(Voxels_30));
Voxel_model(true_idx)=1;
Voxel_model=logical(Voxel_model);

Volums_30_relaposition1=cellfun(@(x)  Voxel_relapostion(x,VolumeSize_ele,Voxels_30),proposal_200_4kinds,'UniformOutput',false);
Volums_30_relaposition_remain1=cellfun(@(x)  Voxel_model-x,Volums_30_relaposition1,'UniformOutput',false);

end


function Volum_30_relaposition=Voxel_relapostion(x, VolumeSize_ele,Voxels_30)
a=zeros(VolumeSize_ele, VolumeSize_ele, VolumeSize_ele);
true_idx=unique(cell2mat(Voxels_30(x)));
a(true_idx)=1;
Volum_30_relaposition=logical(a);
end



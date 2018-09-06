function Proposals_Volums_30_center=Voxelize_Subgraph_center1(model,proposal_200_4kinds, voxel_size)
%% voxelize proposal in [voxel_size voxel_size voxel_size] space.
  disp('Voxeling Subgraphics.....center....');
    repmat_ele=mean(model.vertices,1);
    Vertices_normal = model.vertices - repmat(repmat_ele,size(model.vertices,1),1);     
    Proposals_Volums_30_center=cellfun(@(x)  polygon2voxel2(FV_all_proposals(x,model,Vertices_normal),[voxel_size voxel_size voxel_size],0,'au'),proposal_200_4kinds, 'UniformOutput',false);
    
%  toc;
end


function FV=FV_all_proposals(x,model,Vertices_normal)
      FV.vertices=Vertices_normal;      
      group_idx=x;
      face=model.groups(group_idx,1);
      FV.faces=cell2mat(face);
      saved_vertices=unique(FV.faces);
      set_zero=mean(FV.vertices(saved_vertices,:),1);
      set_zero_idx=1:length(FV.vertices);
      set_zero_idx(saved_vertices)=[];
      FV.vertices(set_zero_idx,1)=set_zero(1);
      FV.vertices(set_zero_idx,2)=set_zero(2);
      FV.vertices(set_zero_idx,3)=set_zero(3); 
end

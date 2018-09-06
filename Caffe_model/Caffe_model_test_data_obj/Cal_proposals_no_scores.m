function [BinaryTree_200_1,BinaryTree_200_2,BinaryTree_200_3,proposal_200_1,proposal_200_2,proposal_200_3] = Cal_proposals_no_scores(model, Voxels, new_graph)
Voxels_200=Voxels;
graph = new_graph;
disp('Cal proposals....200....method 1....')
[proposal_200_1, merge1_200, ~, proposol_parts, BinaryTree_200_1]=Cal_perposol(model, graph, Voxels_200, 200, 1);
disp('Cal proposals....200....method 2....')
[proposal_200_2, merge2_200, ~, ~, BinaryTree_200_2]=Cal_perposol(model, graph, Voxels_200, 200, 2);
disp('Cal proposals....200....method 3....')
[proposal_200_3, merge3_200, ~, ~, BinaryTree_200_3]=Cal_perposol(model, graph, Voxels_200, 200, 3);

proposal_200_1 = cellfun(@transpose, proposal_200_1, 'UniformOutput',false);
proposal_200_1 = cellfun(@sort, proposal_200_1, 'UniformOutput',false);
proposal_200_2 = cellfun(@transpose, proposal_200_2, 'UniformOutput',false);
proposal_200_2 = cellfun(@sort, proposal_200_2, 'UniformOutput',false);
proposal_200_3 = cellfun(@transpose, proposal_200_3, 'UniformOutput',false);
proposal_200_3 = cellfun(@sort, proposal_200_3, 'UniformOutput',false);

 groupPixels_200=[];
for j=1:length(Voxels_200)
    groupPixels_200 =[groupPixels_200,size(Voxels_200{j},1)];
end
if size(Voxels_200{1}, 2)==3
    Voxels_200 = cellfun(@(x) sub2ind([200, 200, 200],x(:,1), x(:,2), x(:,3)), Voxels_200, 'UniformOutput', false);
end

end
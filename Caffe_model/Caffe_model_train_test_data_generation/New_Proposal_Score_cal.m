function [proposal_200_4kinds, proposal_200_Scores, proposal_200_Scores_second, Voxels_200, groupPixels_200] = New_Proposal_Score_cal(saved_nums, Voxels, BinaryTree_200_1, BinaryTree_200_2, BinaryTree_200_3, proposal_200_1, proposal_200_2, proposal_200_3, proposal_200_1_Scores, proposal_200_2_Scores, proposal_200_3_Scores, proposal_200_1_Scores_second, proposal_200_2_Scores_second, proposal_200_3_Scores_second)
Voxels_200=Voxels;
groupPixels_200=[];
for j=1:length(Voxels_200)
    groupPixels_200 =[groupPixels_200,size(Voxels_200{j},1)];
end
if size(Voxels_200{1}, 2)==3
    Voxels_200 = cellfun(@(x) sub2ind([200, 200, 200],x(:,1), x(:,2), x(:,3)), Voxels_200, 'UniformOutput', false);
end

every_total_size = size(BinaryTree_200_1, 1);
saved_nums_1 = min(saved_nums(1), size(BinaryTree_200_1, 1));
saved_nums_2 = min(saved_nums(2), size(BinaryTree_200_1, 1));
saved_nums_3 = min(saved_nums(3), size(BinaryTree_200_1, 1));

idxes_order_1 = BinaryTree_200_1(ceil(every_total_size/2)+1:every_total_size, 3:4);
idxes_order_1 = idxes_order_1';
idxes_order_1 = idxes_order_1(:);
idxes_order_1 = [idxes_order_1; every_total_size];
idxes_order_1 = flipud(idxes_order_1);
proposal_1_idxes = idxes_order_1(1:saved_nums_1);

idxes_order_2 = BinaryTree_200_2(ceil(every_total_size/2)+1:every_total_size, 3:4);
idxes_order_2 = idxes_order_2';
idxes_order_2 = idxes_order_2(:);
idxes_order_2 = [idxes_order_2; every_total_size];
idxes_order_2 = flipud(idxes_order_2);
proposal_2_idxes = idxes_order_2(1:saved_nums_2);

idxes_order_3 = BinaryTree_200_3(ceil(every_total_size/2)+1:every_total_size, 3:4);
idxes_order_3 = idxes_order_3';
idxes_order_3 = idxes_order_3(:);
idxes_order_3 = [idxes_order_3; every_total_size];
idxes_order_3 = flipud(idxes_order_3);
proposal_3_idxes = idxes_order_3(1:saved_nums_3);

proposal_200_4kinds_all = [proposal_200_1(proposal_1_idxes); proposal_200_2(proposal_2_idxes); proposal_200_3(proposal_3_idxes)];
proposal_200_Scores_all = [proposal_200_1_Scores(proposal_1_idxes, :); proposal_200_2_Scores(proposal_2_idxes, :); proposal_200_3_Scores(proposal_3_idxes, :)];
proposal_200_Scores_second_all = [proposal_200_1_Scores_second(proposal_1_idxes, :); proposal_200_2_Scores_second(proposal_2_idxes, :); proposal_200_3_Scores_second(proposal_3_idxes, :)];
%remove repetitive proposals
proposal_200_4kinds_all = cellfun(@sort, proposal_200_4kinds_all, 'UniformOutput',false);
[~,k] = unique(cellfun(@char,cellfun(@getByteStreamFromArray,proposal_200_4kinds_all,'un',0),'un',0));
proposal_200_4kinds = proposal_200_4kinds_all(k);
proposal_200_Scores = proposal_200_Scores_all(k, :);
proposal_200_Scores_second = proposal_200_Scores_second_all(k, :);

end

function MakeNetInput()
%This is the main function in this folder.
FindFiles = 'E:\_fang\experiment_data\label_transfer\chair_test_mat\';  % All .mat files are under this path.
SavePath = 'F:\Codes_labeling\2_MakeNetInput\chair_test\';              %path to save .h5 files
save_num = [inf inf inf];       %select proposal nums on each grouping tree
label_num = 12;                 %number of labels
GT_nums = ones(1, label_num);
Sel_Mode = 'train';     %'train' or 'valid'

begin_clock = fix(clock);
Files = dir(fullfile(FindFiles,'*.mat'));
filenames = {Files.name}';
Files1= cellfun(@(x) ['load ', FindFiles, x], filenames,'UniformOutput',false);


%Sel_Mode=='train' or Sel_Mode=='valid'
model_files = num2cell(1:length(Files1))';
[GTandAL_center, GTandAL_relaposition, GTandAL_rela_remain, GTandAL_scores, GTandAL_scores_class] = cellfun(@(x) cal_single_model_train(x, Files1, label_num, save_num, GT_nums, Sel_Mode), model_files, 'Unif', 0);
GTandAL_center = cell2mat(GTandAL_center);
GTandAL_relaposition = cell2mat(GTandAL_relaposition);
GTandAL_rela_remain = cell2mat(GTandAL_rela_remain);
GTandAL_scores = cell2mat(GTandAL_scores);
GTandAL_scores_class = cell2mat(GTandAL_scores_class);

all_proposal_nums = size(GTandAL_center, 1)/30;
file_nums = floor((all_proposal_nums+500)/1000);
proposal_nums = ones(1, file_nums-1)*1000;
last_num = all_proposal_nums - max(0, file_nums-1)*1000;
proposal_nums = [proposal_nums, last_num];
proposal_nums = proposal_nums*30;

GTandAL_center = mat2cell(GTandAL_center, proposal_nums, 30, 30);
GTandAL_center = cellfun(@(x) mat2cell(x, ones(1,size(x, 1)/30)*30, 30, 30), GTandAL_center, 'UniformOutput', false);
GTandAL_relaposition = mat2cell(GTandAL_relaposition, proposal_nums, 30, 30);
GTandAL_relaposition = cellfun(@(x) mat2cell(x, ones(1,size(x, 1)/30)*30, 30, 30), GTandAL_relaposition, 'UniformOutput', false);
GTandAL_rela_remain = mat2cell(GTandAL_rela_remain, proposal_nums, 30, 30);
GTandAL_rela_remain = cellfun(@(x) mat2cell(x, ones(1,size(x, 1)/30)*30, 30, 30), GTandAL_rela_remain, 'UniformOutput', false);
GTandAL_scores = mat2cell(GTandAL_scores, proposal_nums/30, size(GTandAL_scores, 2));
GTandAL_scores_class = mat2cell(GTandAL_scores_class, proposal_nums/30, size(GTandAL_scores_class, 2));
h5_files_create=Random_mat_files_creat_h5_files(GTandAL_center, GTandAL_relaposition, GTandAL_rela_remain, GTandAL_scores, GTandAL_scores_class,[SavePath, Sel_Mode], 10);



end_clock=fix(clock);
begin_clock
end_clock
end

function [GTandAL_center, GTandAL_relaposition, GTandAL_rela_remain, GTandAL_scores, GTandAL_scores_class] = cal_single_model_train(x, Files1, label_num, save_nums, GT_nums, Sel_Mode)
eval(Files1{x});% load model infos
voxel_size = 30;
transpose_angles = (0:3)*(pi/2);
new_graph = Dealing_with_processed_Edge_pairs(Edge_pair, model);
[BinaryTree_200_1,BinaryTree_200_2,BinaryTree_200_3,proposal_200_1,proposal_200_2,proposal_200_3,proposal_200_1_Scores,proposal_200_1_Scores_second,proposal_200_2_Scores,proposal_200_2_Scores_second,proposal_200_3_Scores,proposal_200_3_Scores_second] = Cal_proposals_and_scores(model, Voxels, new_graph, label_num, groundtruth);
[proposal_200_4kinds, proposal_200_Scores, proposal_200_Scores_second, Voxels_200, groupPixels_200] = New_Proposal_Score_cal(save_nums, Voxels, BinaryTree_200_1, BinaryTree_200_2, BinaryTree_200_3, proposal_200_1, proposal_200_2, proposal_200_3, proposal_200_1_Scores, proposal_200_2_Scores, proposal_200_3_Scores, proposal_200_1_Scores_second, proposal_200_2_Scores_second, proposal_200_3_Scores_second);
[groundtruth_Scores_second,groundtruth_Scores,groundtruth_Volums_centers,groundtruth_relapositions,groundtruth_relaposition_remains,Volums_Scores,Volums_Scores_second,rotated_Volums_relapositions,rotated_Volums_relaposition_remains,rotated_Volums_centers] = translate_proposals(transpose_angles, model, voxel_size, label_num, groundtruth, Voxels_200, groupPixels_200, Edge_pair, proposal_200_4kinds, proposal_200_Scores, proposal_200_Scores_second);
[every_morph_num,merge_proposals_200_Scores_second,merge_Volums_30_center,merge_Volums_30_relaposition_remain,merge_Volums_30_relaposition,merge_proposals_200_Scores,merge_proposals_200,statistical_data_200_before,statistical_data_200_after] = data_morphing(transpose_angles, model, label_num, GT_nums, groundtruth, proposal_200_Scores_second, Edge_pair, Voxels_200, groupPixels_200);
[GTandAL_center, GTandAL_relaposition, GTandAL_rela_remain, GTandAL_scores, GTandAL_scores_class] = auto_select_and_combine_mats(Sel_Mode, groundtruth_Volums_centers, rotated_Volums_centers, merge_Volums_30_center, groundtruth_relapositions, rotated_Volums_relapositions, merge_Volums_30_relaposition, groundtruth_relaposition_remains,rotated_Volums_relaposition_remains,merge_Volums_30_relaposition_remain, groundtruth_Scores,Volums_Scores,merge_proposals_200_Scores, groundtruth_Scores_second,Volums_Scores_second,merge_proposals_200_Scores_second);

end

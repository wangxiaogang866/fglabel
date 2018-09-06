function [GTandAL_center, GTandAL_relaposition, GTandAL_rela_remain, GTandAL_scores, GTandAL_scores_class] = auto_select_and_combine_mats(Sel_Mode, groundtruth_Volums_centers, rotated_Volums_centers, merge_Volums_30_center, groundtruth_relapositions, rotated_Volums_relapositions, merge_Volums_30_relaposition, groundtruth_relaposition_remains,rotated_Volums_relaposition_remains,merge_Volums_30_relaposition_remain, groundtruth_Scores,Volums_Scores,merge_proposals_200_Scores, groundtruth_Scores_second,Volums_Scores_second,merge_proposals_200_Scores_second)
%generate 5 matrixes for hdf5, each save as a matrix instead of cells
if strcmp(Sel_Mode,'train')
    GTandAL_center = cell2mat([groundtruth_Volums_centers; rotated_Volums_centers; merge_Volums_30_center]);
    GTandAL_relaposition = cell2mat([groundtruth_relapositions; rotated_Volums_relapositions; merge_Volums_30_relaposition]);
    GTandAL_rela_remain = cell2mat([groundtruth_relaposition_remains; rotated_Volums_relaposition_remains; merge_Volums_30_relaposition_remain]);
    GTandAL_scores = [groundtruth_Scores; Volums_Scores; merge_proposals_200_Scores];
    GTandAL_scores_class = [groundtruth_Scores_second; Volums_Scores_second; merge_proposals_200_Scores_second];
else    %Sel_Mode=='valid'
    GTandAL_center = cell2mat(rotated_Volums_centers);
    GTandAL_relaposition = cell2mat(rotated_Volums_relapositions);
    GTandAL_rela_remain = cell2mat(rotated_Volums_relaposition_remains);
    GTandAL_scores = Volums_Scores; 
    GTandAL_scores_class = Volums_Scores_second;
end
end
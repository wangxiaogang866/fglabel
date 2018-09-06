% %%2017.3.24 generate proposals based on groundtruth

function [Aug_proposals_add_dis_copy_1, every_morph_num] = Data_augument1(groundtruth, statistical_data_200, Edge_pair, GT_nums)

    GT_proposals=groundtruth(:,1);
    GT_labels=groundtruth(:,3);
    
    all_label_num = statistical_data_200(3,:);
    max_num_proposals = all_label_num./GT_nums;
    max_num_proposals(isnan(max_num_proposals)) = 0;
    max_num_proposals(max_num_proposals==Inf) = 0;
    max_num_proposals = max(max_num_proposals);
    max_num_proposals2 = max_num_proposals*GT_nums;
    this_labels =  statistical_data_200(2,:);
    max_num_proposals2(this_labels==0) = 0;
    max_num_proposals2 = floor(max_num_proposals2);
    
    all_morphed_num = max_num_proposals2;
    every_morph_num = all_morphed_num - statistical_data_200(3,:);
    every_morph_num(every_morph_num<0) = 0;
    
    max_num_proposals2 = max_num_proposals2./this_labels;
    max_num_proposals2(isnan(max_num_proposals2))=0;
    cur_num_proposals=statistical_data_200(4,:);
    
    
    
    
    
    % calculate proposals numbers for balance
    % threshold in case too many proposals
    threshold=1;
    aug_num_proposals=cellfun(@(x) max_num_proposals2(x)-cur_num_proposals(x),GT_labels,'UniformOutput',false);
    aug_num_proposals=cellfun(@(x) floor(threshold*x) ,aug_num_proposals,'UniformOutput',false);
    aug_num_proposals = cellfun(@(x) max(x, 0), aug_num_proposals, 'UniformOutput',false);
    
    
    Edges=Edge_pair;   % 1-ring neighbor£»
    GT_proposals_neibors=cellfun(@(x) find_neibors(x,Edges),GT_proposals,'UniformOutput',false);
    GT_proposals_neibors1=cellfun(@setdiff, GT_proposals_neibors,GT_proposals,'UniformOutput',false);  %delete proposals the same as that in GT
    
    
    
    %  No_2 distract
    Aug_proposals_dis=cellfun(@No_2_distract, GT_proposals,aug_num_proposals,'UniformOutput',false);
    % groundtruth proposal - generate proposal
    gt_num2=num2cell([1:length(GT_proposals)]');
    Aug_proposals_dis_gt_label=cellfun(@(x,y) num2cell(y*ones(1,length(x))),Aug_proposals_dis,gt_num2,'UniformOutput',false);
    Aug_proposals_dis_and_gt=cellfun(@(x,y) distract(GT_proposals,x,y),Aug_proposals_dis_gt_label,Aug_proposals_dis,'UniformOutput',false);
    idxes = num2cell(1:length(Aug_proposals_dis_and_gt));
    idxes = idxes';
    Aug_proposals_dis_and_gt = cellfun(@(x) [Aug_proposals_dis_and_gt{x}, groundtruth{x, 1}], idxes, 'UniformOutput', false);
    
    Aug_proposals_dis_and_gt = cellfun(@(x) remove_empty_proposal(x), Aug_proposals_dis_and_gt, 'UniformOutput', false);
        
    % update aug_num_proposals
    num_proposals_dis=cellfun(@(x) length(x),Aug_proposals_dis,'UniformOutput',false);
    aug_num_proposals1=cellfun(@(x,y) x-y,aug_num_proposals,num_proposals_dis,'UniformOutput',false);
   
    
    % the last generation£º No_3 Copy(Aug_proposals_add_and_dis,aug_num_proposals2)
    Aug_proposals_copy=cellfun(@(x,y) No_3_copy(x,y),Aug_proposals_dis_and_gt,aug_num_proposals1,'UniformOutput',false);
      
    % add them all
    Aug_proposals_add_dis_copy=cellfun(@(x,y) [x,y],Aug_proposals_dis_and_gt,Aug_proposals_copy,'UniformOutput',false);  
    
    
    Aug_proposals_add_dis_copy_1=[Aug_proposals_add_dis_copy{1:end}];   %cool
    
end

function gene_proposals = remove_empty_proposal(gene_proposals)
empty_cells=cellfun(@(x) isempty(x), gene_proposals);
empty_idx=find(empty_cells==1);
gene_proposals(empty_idx)=[];
end

function neibors=find_neibors(x,Edges)
   [~,neibors]=find(Edges(x,:)==1); %1-ring neighbor
   neibors=unique(neibors)';
end


function All_combine_proposals_combine=No_2_distract(GT_proposals,aug_num)
  if aug_num>0
     num_neibors=numel(GT_proposals);  % coponent number
     All_combine_num=num2cell(1:num_neibors);
     All_combine_num1=cellfun(@(x) nchoosek(num_neibors,x),All_combine_num,'UniformOutput',false);
     All_combine_num2=cell2mat(All_combine_num1);
     All_combine_num_cumsum=cumsum(cell2mat(All_combine_num1));
     All_combine_num_cumsum1=aug_num-All_combine_num_cumsum;  % >0: too less  =0:good ¡´0: too much  
     Distinguish=All_combine_num2+All_combine_num_cumsum1;     % >0: need generation£¬ ¡´0: do not need   
     All_combine_proposals=cellfun(@(x) gen_proposals(GT_proposals,Distinguish,x),All_combine_num,'UniformOutput',false);    
  else
     All_combine_proposals=cell(1,0);
  end
  
  if ~isempty(All_combine_proposals)
      All_combine_proposals_combine=[All_combine_proposals{1:end}];
  else
      All_combine_proposals_combine=cell(1,0);
  end
end


function All_combine_proposals_combine=No_3_copy(Aug_proposals_add_and_dis,aug_num_proposals2)
 if aug_num_proposals2>0 && ~isempty(Aug_proposals_add_and_dis)
   total_copy_num=floor(aug_num_proposals2/length(Aug_proposals_add_and_dis));
   remain_num=floor(aug_num_proposals2-total_copy_num*length(Aug_proposals_add_and_dis));

   All_combine_proposals_combine=repmat(Aug_proposals_add_and_dis,1,total_copy_num);
   All_combine_proposals_combine=[All_combine_proposals_combine,Aug_proposals_add_and_dis(1:remain_num)];
 else
   All_combine_proposals_combine=cell(1,0);
 end
end


function all_combine_i2=gen_proposals(neibors,Distinguish,x)
    if Distinguish(x)>=0
       all_combine_i=combnk(neibors,x); 
       all_combine_i1=mat2cell(all_combine_i,ones(size(all_combine_i,1),1),[size(all_combine_i,2),0]); %  size(,1) cell  :   proposals
       all_combine_i1(cellfun(@isempty,all_combine_i1))=[];
       all_combine_i2=all_combine_i1(1:min(Distinguish(x),length(all_combine_i1)));
    else
       all_combine_i2=cell(1,0); 
    end
end




function  distract_gt=distract(GT_proposals,x,y)
    distract_gt=cellfun(@(x1,y1)  setdiff(GT_proposals{x1},y1), x,y,'UniformOutput',false); 
end






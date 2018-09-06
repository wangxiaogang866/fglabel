%% Inference the probability distribution for each component based on the CNN prediction results for all part hypotheses
function [node_avr_all_2]=Inference_prob_dis(top_num,Scores,Class, Edge_pair, proposal_200_4kinds,groupPixels_200)

% All information of proposals
X=proposal_200_4kinds;

%Extracting scores and classifications from CNN predict results
X_scores=Scores;      
X_class=Class;         

% The num of proposal, labels, nodes
num_proposal=length(X);
num_label=size(X_class,2);
num_node=size(Edge_pair,2);

X_single_scores= repmat(max(X_scores,[],2),1,size(X_class,2)); 

node_proposal=cellfun(@(x) setA(x,num_node), X, 'UniformOutput',false);

% Calculate the volume of each component
X_volume=cellfun(@(x) sum(x.*groupPixels_200), node_proposal, 'UniformOutput',false);   % 每个Proposal的体积
X_volume=cell2mat(X_volume);

node_proposal1=cell2mat(node_proposal);
node_proposal2=mat2cell(node_proposal1,[num_proposal,0],ones(1,num_node));
node_proposal2(cellfun(@isempty,node_proposal2))=[];



%% Probability: each node of graph
% All proposals which all contains node i
node_proposal3=cellfun(@(x) find(x), node_proposal2, 'UniformOutput',false);

% The volume of each node
node_idx=num2cell(1:num_node);
node_volume=cellfun(@(x) groupPixels_200(x),node_idx,'Unif', 0);

% volume of proposals that contains node i
node_proposal3_volume=cellfun(@(x) X_volume(x),node_proposal3,'Unif', 0);

% The weight of each proposal for the node i
node_proposal3_weights=cellfun(@Weighted, node_volume,node_proposal3_volume,'Unif', 0);
node_proposal3_weights_labels=cellfun(@(x) repmat(x,1,num_label),node_proposal3_weights,'UniformOutput',false);  %把权重复制为num_label列，以方便点乘


%%Select the top N proposals for each node with the highest score
% Extract the regress scores of proposals that contains node i
node_proposal3_scores=cellfun(@(x) X_single_scores(x,:),node_proposal3, 'UniformOutput',false);
node_proposal3_scores_top_idx_rows=cellfun(@(x) Max_top_n(x,top_num),node_proposal3_scores, 'UniformOutput',false);
node_proposal3_scores_top=cellfun(@(x,y) x(y,:),node_proposal3_scores,node_proposal3_scores_top_idx_rows,'UniformOutput',false);

% Extract the class scores of proposals that contains node i
node_proposal3_class=cellfun(@(x) X_class(x,:),node_proposal3, 'UniformOutput',false);
node_proposal3_class_top=cellfun(@(x,y) x(y,:),node_proposal3_class,node_proposal3_scores_top_idx_rows,'UniformOutput',false);
node_proposal3_class_weights_top=cellfun(@(x,y) x(y,:),node_proposal3_weights_labels,node_proposal3_scores_top_idx_rows,'UniformOutput',false);

% Initial probability distribution of each node
node_proposal3_weights_class=cellfun(@Dot_Product ,node_proposal3_class_top,node_proposal3_class_weights_top,'UniformOutput',false);
node_proposal3_weights_class_single_scores=cellfun(@Dot_Product, node_proposal3_weights_class,node_proposal3_scores_top,'UniformOutput',false);

% normalization
node_avr_2=cellfun(@(x) sum(x,1),node_proposal3_weights_class_single_scores, 'UniformOutput',false);
node_avr_2_1=cellfun(@(x) exp(x),node_avr_2, 'UniformOutput',false);
node_avr_2_2=cellfun(@(x) x./sum(x),node_avr_2_1, 'UniformOutput',false);
node_avr_all_2=cell2mat(node_avr_2_2(:));

end

function a=setA(x,num)
   a=zeros(1,num);
   a(x)=1;
end

function weights=Weighted(x,y)
   weights=x./y;
end

function xy=Dot_Product(x,y)
    xy=x.*y;
end

function x1=Max_top_n(x,top_num)
    max_rows_score=max(x,[],2); 
    [~,idx]=sort(max_rows_score,'descend');    
    num=min(top_num,numel(max_rows_score)); 
    x1=idx(1:num);  
end




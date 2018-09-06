
%% Batch processing for all models
function Results=Batching_adjust_para()

clear all
cs = computer;
if ~isempty(strfind(cs,'64'))
    % 64-bit machine
    mex -O -DNDEBUG -largeArrayDims robustpn_mex.cpp 
else
    mex -O -DNDEBUG robustpn_mex.cpp
end
clear cs;
tic
warning off
begin_clock=fix(clock);


%% Path of prediction results
% model original file
FindFiles='Data_mat\Generation_of_part_hypotheses\';

% model prediction result from CNN
NEtwork_Score_path='Data_mat\CNN_predict\';  

%% parameter K^c: the num of top-ranked part hypotheses for the component c.  
% score_class_threshold_mix1={1,3,5,10,1000};   %  K^c=1,3,5,10,all;
score_class_threshold_mix1=1000;  % K^c=all; 


%% The path of network prediction result
Files = dir(fullfile(NEtwork_Score_path,'*.mat'));
Files1={Files.name}';
Files1_full=cellfun(@(x) ['load ',FindFiles, x],Files1,'UniformOutput',false);   % original model files
Files1_NetWork_score_full=cellfun(@(x) ['load ',NEtwork_Score_path, x],Files1,'UniformOutput',false);  % predicted results of network

%% Labeling result from composite inference
Results=cellfun(@(x,y) Composite_Inference(x,y,score_class_threshold_mix1), Files1_full, Files1_NetWork_score_full,'UniformOutput',false);
save Results Results

toc;
end



%% Composite Inference
function label_smooth_all=Composite_Inference(x,y,score_class_threshold_mix1)

   eval(x);
   eval(y);
   
   disp(x);
   fprintf('\n');
   
   % Extraction of classification probability distribution and regression score from the prediction result file for each proposal
    data1=test_gt_score(:,3);  %the predicted classification probability of each hypothesis h
    data1=cellfun(@(x) x',data1,'UniformOutput',false);    
    data1=cellfun(@(x) x(1:end-1),data1,'UniformOutput',false);  
    data1=cell2mat(data1);
	
    data2=cell2mat(test_gt_score(:,2));  % the predicted confidence score of each hypothesis h

  
   % Inference initial probability distribution for each component
	Initial_prob_dis=Inference_prob_dis(score_class_threshold_mix1,data2,data1,Edge_pair, proposal_200_4kinds,groupPixels_200);
    Prob_dis_log=Transform(Initial_prob_dis);   
	
	
   
   % Higher order constraints
    proposals1=proposal_200_4kinds;
    datax=data1;
    datax1=sum(datax,2);
    datax2=repmat(datax1,1,size(datax,2));
    data1_norml=datax./datax2;
    data1_norml=mat2cell(data1_norml,ones(size(data1_norml,1),1),size(data1_norml,2));
    data1_norml_entropy=cellfun(@(x) sum(-x.*log2(x),2),data1_norml, 'UniformOutput',false);   % the entropy of the classification probability
    Scores_2=cell2mat(data1_norml_entropy);
    Scores1=Scores_2;
    num_label=size(data1,2);
    
    sG=sparse(double(Edge_pair*1e-5));   %components contact graph
    Dc=Prob_dis_log';   
    
    % The final labeling result of the higher-order CRF
    label_smooth_all=Computer_High_order_CRF(sG,Dc,proposals1,Scores1,num_label);

end


function L=Computer_High_order_CRF(sG,Dc,proposals1,Scores1,num_label)
    % parameters setting
    Q_effi=0.2;    % 2*Q < |P|,¼´| C|     
    hop = make_hop(proposals1, Q_effi,num_label,Scores1);
    
    % energy minimization
    [L E] = robustpn_mex(sG, Dc, hop);
    L = double(L+1); 
    [uE pE hE tE] = energy(sG, Dc, hop, L);

    if (E~=tE)/E < 1e-5
        error('robustpn:test', 'wrong energy value');
    end
    clear hop
end

%----------------------------------------%
function    hop = make_hop(proposals,Q_effi,num_label,Scores)
%  hop - higher order potential array of structs with (#higher) entries, each entry:
%      .ind - indices of nodes belonging to this hop
%      .w - weights w_i for each participating node
%      .gamma - #labels + 1 entries for gamma_1..gamma_max
%      .Q - truncation value for this potential (assumes one Q for all labels)
    gamma(num_label+1) = 10; % gamma_max
    [hop(1:numel(proposals))] = deal(struct('ind',[],'w',[],...  
        'gamma',single(gamma),'Q',.1)); 
    for hi=1:numel(proposals)
        hop(hi).ind = proposals{hi};
        hop(hi).w = single(ones(size(hop(hi).ind,1),size(hop(hi).ind,2)));  % weights È«Îª1
        C = numel(hop(hi).ind);
        hop(hi).Q = single(Q_effi * C);   %single(.1 * C);   
        max_gamma=gamma_max(numel(hop(hi).ind),Scores(hi));
        hop(hi).gamma(end) = single(max_gamma);
    end
end

%----------------------------------------%
function y=gamma_max(num_components,score_p)
% score_p - the entropy of the classification probability of hypothesis h
% num_components - the number of components constituting part hypothesis h
   y= exp(-score_p/num_components);
end 


% Aux functions
function [uE, pE, hE ,E] = energy(sG, Dc, hop, labels)

    % given sG, Sc, hop and current labeling - return the energy
    [nl, nvar] = size(Dc);

    % unary term
    uE = sum(Dc( [1 nl]*( [labels(:)';1:nvar] -1) +1 ));

    % pair-wise term - use only upper tri of sparseG
    [rr, cc]=find(sG);
    low = rr>cc;
    rr(low)=[];
    cc(low)=[];
    neq = labels(rr) ~= labels(cc);
    pE = sum(single(full((sG( [1 size(sG,1)]*( [rr(neq(:))'; cc(neq(:))']-1 ) + 1 )))));

    % Higher-Order potentials energy
    hE = 0;
    for hi=1:numel(hop)

        P = sum(hop(hi).w);
        tk = (hop(hi).gamma(end) - hop(hi).gamma(1:end-1))./hop(hi).Q;
        fk = accumarray( [labels( hop(hi).ind(:) )' ; numel(tk)],...
            [hop(hi).w(:)' 0] )'; % make sure we have numrl(tk) elements
        hE = hE + min([(P-fk).*tk + hop(hi).gamma(1:end-1) hop(hi).gamma(end)]);

    end
    E = uE + pE + hE;
end

  
function Prob_dis_log=Transform(x)
    Prob_dis  = x; 
    Prob_dis_log=-log(Prob_dis);
    Prob_dis_log(Prob_dis_log==Inf)=-1;
    max_log=ceil(max(max(Prob_dis_log)));
    Prob_dis_log(Prob_dis_log==-1)=max_log;
    Prob_dis_log=single(Prob_dis_log);
end






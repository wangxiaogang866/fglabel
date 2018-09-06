%% 2 unconnected graph-> connect graph
function graphsets_edgepair_idxs_distance3=Construct_connected_graph_from_unconnected_graphsets_1(graphsets,model)
      node_center=cellfun(@(x) mean(x),model.groupVertex,'UniformOutput',false);
      node_center=cell2mat(node_center);


      graphsets_num=length(graphsets);
      graphsets_idx=1:graphsets_num;
      
      graphsets_graph_1=repmat(graphsets_idx,graphsets_num,1);
      graphsets_graph_1=num2cell(graphsets_graph_1);
      
      graphsets_graph_2=repmat(graphsets_idx',1,graphsets_num);
      graphsets_graph_2=num2cell(graphsets_graph_2);
     
      % initial graphsets_graph
      graphsets_graph=cellfun(@(x,y) [x,y],graphsets_graph_1,graphsets_graph_2,'UniformOutput',false);
      
      % reshape graphsets_graph as one column
      graphsets_graph_col=reshape(graphsets_graph,graphsets_num*graphsets_num,1);
      
      % delete cells with i>j
      graph_graph_remain=cellfun(@(x) judge_idx(x),graphsets_graph_col,'UniformOutput',false);
      
      % delete empty cells
      graph_graph_remain(cellfun(@isempty,graph_graph_remain))=[];
      
      %
      graphsets_graph_nodes_idx=cellfun(@(x)  [graphsets(x(1)),graphsets(x(2))], graph_graph_remain,'UniformOutput',false);
      
      %indexes of min distances between graph pairs and min distance.[row,col,distance]     
      graphsets_edgepair_idxs_distance=cellfun(@(x) Find_min_edgepair(x(1),x(2),node_center),graphsets_graph_nodes_idx,'UniformOutput',false);  
      graphsets_edgepair_idxs_distance1=cell2mat(graphsets_edgepair_idxs_distance);  % 3*graphset_num matrix [r,c,dist]  
      
      graph_graph_remain1=cell2mat(graph_graph_remain);
      graphsets_edgepair_idxs_distance1=[graph_graph_remain1,graphsets_edgepair_idxs_distance1];

      graph_edge_weight=[cell2mat(graph_graph_remain),graphsets_edgepair_idxs_distance1(:,5)];
      graph_edge_weight=graph_edge_weight';
         
      % Create a graph. Compute and highlight its minimum spanning tree        
       G = graph(graph_edge_weight(1,:),graph_edge_weight(2,:),graph_edge_weight(3,:));      %graph(s,t,weights);
       tree = minspantree(G);
       tree.Edges
      
      % find rows_idxs from tree
      edges_pair_graph_idx=tree.Edges.EndNodes;
      edges_num=size(edges_pair_graph_idx,1);
      edges_pair_graph_idx1=mat2cell(edges_pair_graph_idx,ones(edges_num,1),2);
      rows_idx=cellfun(@(x) find(ismember(graph_graph_remain1,x,'rows')==1),edges_pair_graph_idx1,'UniformOutput',false);
      rows_idx=cell2mat(rows_idx);     

      %
      graphsets_edgepair_idxs_distance3=graphsets_edgepair_idxs_distance1(rows_idx,3:5);
      
end

function x=judge_idx(x)
   if(x(1)>=x(2))
       x=[];
   end      
end

function y=Find_min_edgepair(x1,x2,node_center)   % x1,x2 --indexes of two unconnected subgraphs
     
     x1=x1{1};
     x2=x2{1};


     % row indexes
     num_x=numel(x1);
     num_y=numel(x2);
     
     graph_x=repmat(x1',1,num_y);
     graph_x=num2cell(graph_x);
     
     graph_y=repmat(x2,num_x,1);
     graph_y=num2cell(graph_y);
     
     graph_xy=cellfun(@(x,y) [x,y],graph_x,graph_y,'UniformOutput',false);    
     graph_dis=cellfun(@(x) norm(node_center(x(1),:)-node_center(x(2),:)),graph_xy,'UniformOutput',false);  
     graph_dis1=cell2mat(graph_dis);
     min_distance=min(graph_dis1(:));   % minimum distance
     [r,c]= find(graph_dis1==min_distance);
     
     sel_couple = graph_xy{r(1), c(1)};
     y = [sel_couple(1), sel_couple(2), min_distance];
end

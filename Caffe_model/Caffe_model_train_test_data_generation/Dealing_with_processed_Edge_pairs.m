function new_graph = Dealing_with_processed_Edge_pairs(Edge_pair, model)
find_independ_groups = sum(Edge_pair);
independ_group_idx = find(find_independ_groups==0);
graphsets = find_independed_graph_point_groups(Edge_pair);
graphsets = [num2cell(independ_group_idx), graphsets];
new_graph = Edge_pair;
if size(graphsets, 2)>1
    graphsets_edgepair_idxs_distance3=Construct_connected_graph_from_unconnected_graphsets_1(graphsets,model);
    independ_group_idx = graphsets_edgepair_idxs_distance3(:, 1:2);
    independ_group_idx = [independ_group_idx;independ_group_idx(:, 2), independ_group_idx(:, 1)];
    set_idxes = independ_group_idx(:, 1)+(independ_group_idx(:, 2)-1)*size(new_graph, 1);
    new_graph(set_idxes) = 1;
end
end
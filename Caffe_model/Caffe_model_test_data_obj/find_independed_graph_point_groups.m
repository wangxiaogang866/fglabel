function independed_graphs = find_independed_graph_point_groups(graph)
%find all closed subgraphs
independed_graphs = cell(0);
graph_for_use = graph;
while max(sum(graph_for_use))~=0
    find_begin = sum(graph_for_use);
    unused_idx = find(find_begin>0);
    begin_idx = unused_idx(1);
    this_graph_points = find_independed_graphs(graph_for_use, begin_idx);
    graph_for_use(this_graph_points, :) = 0;
    graph_for_use(:, this_graph_points) = 0;
    independed_graphs = [independed_graphs, {this_graph_points}];
end
end

function result = find_independed_graphs(graph, begin_idx)
result = begin_idx;
pre_length=0;
after_length = length(result);
while pre_length<after_length
    pre_length = after_length;
    used_idxes = num2cell(result);
    this_neighbors = cellfun(@(x) find(graph(x, :)==1), used_idxes, 'UniformOutput', false);
    this_neighbors = cell2mat(this_neighbors);
    result = unique([result, this_neighbors]);
    after_length = length(result);
end
end
function [proposal, merger, middle_points, foren_proposol, binary_tree]=Cal_perposol(model, graph, Voxels, Voxel_size, merge_kind)
%%In the begining, n components are regerded as n nodes. Then each time, we group two nodes as one node ,untill we have only one node
%4 grouping criteria in total
%merge_kind=1£¬group by center distance
%merge_kind=2, group by group size
%merge_kind=3, group by geometric contact
%nerge_kind=4, group by centroid distance
%output£ºproposal: 2n-1 proposals
%        merger: group couples in order
%        middle_points:status after each group operation
%        foren_proposol:save each single component as a proposal
%        binary_tree:2n-1 proposals shown as a binary tree. we can then select proposals from tree root

if nargin==4
    merge_kind=1;
end
% tic;
component_num=size(graph, 1);
merger=cell(size(graph, 1)-1,1);
foren_proposol=cell(size(graph, 1),1);
htbrid=cell(size(graph, 1),3);
middle_points=cell(0);
binary_tree=zeros(2*size(graph, 1)-1, 4);
binary_tree(1:(2*component_num-1), 1)=1:(2*component_num-1);

if size(Voxels{1}, 2)==3
    for k=1:size(Voxels, 1)
        Voxels{k}=sub2ind([Voxel_size, Voxel_size, Voxel_size],Voxels{k}(:,1), Voxels{k}(:,2), Voxels{k}(:,3));
    end
end


vertices=model.vertices;
FV.vertices = model.vertices - repmat(mean(vertices,1),size(vertices,1),1);
FV.faces=cell2mat(model.groups(1,1));
Volume=polygon2voxel(FV,[ Voxel_size Voxel_size Voxel_size],0,0,0,'au');


switch merge_kind
    case 1
        centers=[];
    case 2
        voxel_size=zeros(size(graph, 1), 1);
    case 3
        voxel_size=zeros(size(graph, 1), 1);
    case 4
        centers=[];
        voxel_size=zeros(size(graph, 1), 1);
end
for i=1:size(graph, 1)
    foren_proposol{i}=i;
    switch merge_kind
        case 1
            %Calculate centers
            if size(model.groupVertex{i}, 1)>1
                centers=[centers;mean(model.groupVertex{i})];
            else
                centers=[centers;model.groupVertex{i}];
            end
        case 2
            %Voxelize infos
            if size(Voxels{1}, 2)==3
                for k=1:size(Voxels, 1)
                    Voxels{k}=sub2ind([Voxel_size, Voxel_size, Voxel_size],Voxels{k}(:,1), Voxels{k}(:,2), Voxels{k}(:,3));
                end
            end
            voxel_size(i)=length(Voxels{i});
        case 3
            %Voxelize infos
            if size(Voxels{1}, 2)==3
                for k=1:size(Voxels, 1)
                    Voxels{k}=sub2ind([Voxel_size, Voxel_size, Voxel_size],Voxels{k}(:,1), Voxels{k}(:,2), Voxels{k}(:,3));
                end
            end
            voxel_size(i)=length(Voxels{i});
        case 4
            if size(Voxels{1}, 2)==1                
                [Voxels_r,Voxels_c,Voxels_l]=ind2sub(size(Volume),Voxels{i});  %convert voxels_i to (row, column, page)
                this_voxel_coord=[Voxels_r,Voxels_c,Voxels_l];
            else
                this_voxel_coord=Voxels{i};
                for k=1:size(Voxels, 1)
                    Voxels{k}=sub2ind([Voxel_size, Voxel_size, Voxel_size],Voxels{k}(:,1), Voxels{k}(:,2), Voxels{k}(:,3));
                end
            end
            
            %centroid 
            centers=[centers;sum(this_voxel_coord(:,1))/length(this_voxel_coord(:,1)), sum(this_voxel_coord(:,2))/length(this_voxel_coord(:,1)), sum(this_voxel_coord(:,3))/length(this_voxel_coord(:,1))];
    end
end
htbrid(:,1)=foren_proposol;
htbrid(:,2)=foren_proposol;     
htbrid(:,3)=foren_proposol;     %node color
middle_points=[middle_points; {htbrid}];

cell_length=size(graph, 1)-1;
for i=1:cell_length   
%     tic;
    if max(graph(:))~=0
        tri_graph=triu(graph);
        points=find(tri_graph==1);
        p_x=mod(points, size(graph, 1));
        p_x(p_x==0)=size(graph, 1);     %mark an edge from p_x to p_y. p_x stands for row number. If p_x==0, it stands for row n
        p_y=(points-p_x)/size(graph, 1);    %p_y+1 is the column number
        p_y=p_y+1;
        
        volumn_idx1=0;
        volumn_idx2=0;
       
        switch merge_kind
            case 1
                %calculate center distances
                coord_x=centers(p_x,:);
                coord_y=centers(p_y,:);
                dis=coord_y-coord_x;
                dis=dis.^2;
                dis=sum(dis');
                merge_idx=find(dis==min(dis));
                merge_idx1=p_x(merge_idx(1));
                merge_idx2=p_y(merge_idx(1));
                %update center coordinates    
                centers(merge_idx1, :)=mean([centers(merge_idx1, :); centers(merge_idx2, :)]);
                centers(merge_idx2, :)=[];
            case 2
                % voxel numbers of connected nodes
                voxel_x=voxel_size(p_x)/(Voxel_size*Voxel_size*Voxel_size);
                voxel_y=voxel_size(p_y)/(Voxel_size*Voxel_size*Voxel_size);
                volumns=voxel_x+voxel_y;
                merge_idx=find(volumns==min(volumns));
                merge_idx1=p_x(merge_idx(1));
                merge_idx2=p_y(merge_idx(1));
                %update voxel_size and Voxels                
                volumn_idx1=length(Voxels{merge_idx1});
                volumn_idx2=length(Voxels{merge_idx2});
                Voxels{merge_idx1}=unique([Voxels{merge_idx1};Voxels{merge_idx2}]);
                Voxels(merge_idx2)=[];
                voxel_size(merge_idx1)=length(Voxels{merge_idx1});
                voxel_size(merge_idx2)=[];
            case 3
                %percentage of intersect voxels
                voxel_x=Voxels(p_x);
                voxel_y=Voxels(p_y);
                inters=cellfun(@intersect,voxel_x,voxel_y,'UniformOutput', false);
                inter_nums=cellfun(@length, inters);
                    inter_persent=max((repmat(inter_nums, 1,2)./[voxel_size(p_x), voxel_size(p_y)])');
                    merge_idx=find(inter_persent==max(inter_persent));
                    merge_idx1=p_x(merge_idx(1));
                    merge_idx2=p_y(merge_idx(1));
%                 end                
                %update [voxel_size¡¢Voxels
                volumn_idx1=length(Voxels{merge_idx1});
                volumn_idx2=length(Voxels{merge_idx2});
                Voxels{merge_idx1}=unique([Voxels{merge_idx1};Voxels{merge_idx2}]);
                Voxels(merge_idx2)=[];
                voxel_size(merge_idx1)=length(Voxels{merge_idx1});
                voxel_size(merge_idx2)=[];
            case 4
                %calculate centroid  distances
                coord_x=centers(p_x,:);
                coord_y=centers(p_y,:);
                dis=coord_y-coord_x;
                dis=dis.^2;
                dis=sum(dis');
                merge_idx=find(dis==min(dis));
                merge_idx1=p_x(merge_idx(1));
                merge_idx2=p_y(merge_idx(1));
                %update centroid     
                centers(merge_idx1, :)=(centers(merge_idx1, :)*length(Voxels{merge_idx1})+centers(merge_idx2, :)*length(Voxels{merge_idx2}))/(length(Voxels{merge_idx1})+length(Voxels{merge_idx2}));
                centers(merge_idx2, :)=[];
                volumn_idx1=length(Voxels{merge_idx1});
                volumn_idx2=length(Voxels{merge_idx2});
                Voxels{merge_idx1}=unique([Voxels{merge_idx1};Voxels{merge_idx2}]);
                Voxels(merge_idx2)=[];
        end

        %% update binary_tree, merger
        %confirm chile node and parent node
        child_node1=htbrid{merge_idx1, 2};
        child_node2=htbrid{merge_idx2, 2};
        binary_tree(child_node1, 2)=i+component_num;
        binary_tree(child_node2, 2)=i+component_num;
        binary_tree(i+component_num, 3)=child_node1;
        binary_tree(i+component_num, 4)=child_node2;
        %update merger, htbrid and connect graph
        merger{i}=cell2mat([htbrid(merge_idx1, 1),htbrid( merge_idx2, 1)]);
        htbrid(merge_idx1, 1)=merger(i);
        htbrid{merge_idx1, 2}=i+component_num;
        if volumn_idx1 > volumn_idx2
            htbrid{merge_idx1, 3}=htbrid{merge_idx1, 3};
        else
            htbrid{merge_idx1, 3}=htbrid{merge_idx2, 3};
        end
        htbrid(merge_idx2, :)=[];
        middle_points=[middle_points; {htbrid}];
        graph(merge_idx1, :)=graph(merge_idx1, :)+graph(merge_idx2, :);
        graph(:, merge_idx1)=graph(:, merge_idx1)+graph(:, merge_idx2);
        graph(merge_idx1, merge_idx1)=0;
        graph(merge_idx2, :)=[];
        graph(:, merge_idx2)=[]; 
        graph(graph==2)=1;    
    else    %if nodes more than 1 and do not have connect relations among them, just group the last two nodes in htbrid    
        merge_idx1=size(htbrid, 1)-1;
        merge_idx2=size(htbrid, 1);
        volumn_idx1=length(Voxels{merge_idx1});
        volumn_idx2=length(Voxels{merge_idx2});
        Voxels{merge_idx1}=unique([Voxels{merge_idx1};Voxels{merge_idx2}]);
        Voxels(merge_idx2)=[];
        
        child_node1=htbrid{merge_idx1, 2};
        child_node2=htbrid{merge_idx2, 2};
        binary_tree(child_node1, 2)=i+component_num;
        binary_tree(child_node2, 2)=i+component_num;
        binary_tree(i+component_num, 3)=child_node1;
        binary_tree(i+component_num, 4)=child_node2;
        
        merger{i}=cell2mat([htbrid(merge_idx1),htbrid( merge_idx2)]);
        htbrid(merge_idx1, 1)=merger(i);
        htbrid{merge_idx1, 2}=i+component_num;
        if volumn_idx1 > volumn_idx2
            htbrid{merge_idx1, 3}=htbrid{merge_idx1, 3};
        else
            htbrid{merge_idx1, 3}=htbrid{merge_idx2, 3};
        end
        htbrid(merge_idx2, :)=[];
        middle_points=[middle_points; {htbrid}];
    end
%     toc;
end
proposal=[foren_proposol; merger];
% toc;
end
function MakeNetTest()
FindFiles = 'E:\_fang\experiment_data\label_transfer\chair_test_mat\';  % All .obj files are under this path. 
SavePath = 'F:\Codes_labeling\3_MakeNetTest\h5\';                          %path to save .h5 files
MatPath = 'F:\Codes_labeling\3_MakeNetTest\mat\';                               %path to save .mat files
save_nums = [inf inf inf]; 

if ~exist(SavePath, 'dir')
    mkdir(SavePath)
end
if ~exist(MatPath, 'dir')
    mkdir(MatPath)
end

Files = dir(fullfile(FindFiles, '*.obj'));
fnames = {Files.name}';

cellfun(@(x) SingleModel(FindFiles, x, SavePath, save_nums, MatPath), fnames, 'Unif', 0);
end

function SingleModel(FindFiles, fname, SavePath, save_nums, MatPath)
fprintf(1,'%s\n', fname);
[vertices, faces, group_idxes]= obj__read([FindFiles, fname]);

faces = faces';
group_idxes = mat2cell(group_idxes, ones(size(group_idxes, 1), 1), 2);
groups = cellfun(@(x) faces(x(1):x(2), :), group_idxes, 'Unif', 0);

vertices = vertices';

ver_center = (max(vertices, [], 1)+min(vertices, [], 1))/2;
vertices = vertices-repmat(ver_center, size(vertices, 1), 1);
scale_size = max(max(vertices, [], 1)-min(vertices, [], 1));
vertices = vertices/scale_size;

model.vertices = vertices;
model.groups = groups;
model.groupVertex=cell(size(groups, 1), 1);
for j=1:size(groups, 1)
    vertex_idx=unique(groups{j});
    vertex_coord=vertices(vertex_idx, :);
    model.groupVertex{j,1}=vertex_coord;
end
[Edge_pair, Voxels] = Model_infos(model);
cal_single_model_test(Edge_pair, model,Voxels, save_nums, SavePath, fname, MatPath)
end

function [Edge_pair, Voxels] = Model_infos(model)

disp('Voxelizaing all groups....200');
tic;
num_group = length(model.groups);
VolumeSize_ele=200;
vertices=model.vertices;
groups=model.groups;
repmat_ele=mean(vertices,1);
vertices = vertices - repmat(repmat_ele,size(vertices,1),1);

vertices=vertices(:,[2 1 3]);
VolumeSize=[VolumeSize_ele VolumeSize_ele VolumeSize_ele];
positive = min(vertices,[],1);
vertices=bsxfun(@minus, vertices, positive);
scaling=min((VolumeSize-1)./(max(vertices(:))));
vertices=vertices*scaling+1;
offset = VolumeSize ./ 2 - max(vertices) ./ 2 ;

FV.vertices = model.vertices - repmat(repmat_ele,size(vertices,1),1);

FV_s=cell(size(model.groups,1),1);
for j=1:num_group
    FV.faces=cell2mat(model.groups(j,1));
    FV_s{j}=FV;
end
Volume=polygon2voxel(FV_s{1},[VolumeSize_ele VolumeSize_ele VolumeSize_ele],scaling,positive,offset,'cu');
Voxels = cellfun(@(x)  polygon2voxel(x,[VolumeSize_ele VolumeSize_ele VolumeSize_ele],scaling,positive,offset,'cu'),FV_s, 'UniformOutput',false);
Voxels_idx = cellfun(@(x) find(x==1), Voxels, 'UniformOutput',false);
[Voxels_r,Voxels_c,Voxels_l] = cellfun(@(x) ind2sub(size(Volume),find(x==1)) ,Voxels, 'UniformOutput',false);
lengthes=cellfun(@length, Voxels_r);
Voxels = [Voxels_r,Voxels_c,Voxels_l];
Voxels = cell2mat(Voxels);
Voxels = mat2cell(Voxels, lengthes, 3);

Voxels_200=Voxels;
toc;

disp('Voxelizaing....30');
tic;
VolumeSize_ele=30;
vertices=model.vertices;
repmat_ele=mean(vertices,1);
vertices = vertices - repmat(repmat_ele,size(vertices,1),1);

vertices=vertices(:,[2 1 3]);
VolumeSize=[VolumeSize_ele VolumeSize_ele VolumeSize_ele];
positive = min(vertices,[],1);
vertices=bsxfun(@minus, vertices, positive);
scaling=min((VolumeSize-1)./(max(vertices(:))));
vertices=vertices*scaling+1;
offset = VolumeSize ./ 2 - max(vertices) ./ 2 ;

FV.vertices = model.vertices - repmat(repmat_ele,size(vertices,1),1);

FV_s=cell(size(model.groups,1),1);
for j=1:num_group
    FV.faces=cell2mat(model.groups(j,1));
    FV_s{j}=FV;
end

Volume=polygon2voxel(FV_s{1},[VolumeSize_ele VolumeSize_ele VolumeSize_ele],scaling,positive,offset,'cu');
Voxels_30 = cellfun(@(x)  polygon2voxel(x,[VolumeSize_ele VolumeSize_ele VolumeSize_ele],scaling,positive,offset,'cu'),FV_s, 'UniformOutput',false);
[Voxels_r,Voxels_c,Voxels_l] = cellfun(@(x) ind2sub(size(Volume),find(x==1)) ,Voxels_30, 'UniformOutput',false);
lengthes=cellfun(@length, Voxels_r);
Voxels_30 = [Voxels_r,Voxels_c,Voxels_l];
Voxels_30 = cell2mat(Voxels_30);
Voxels_30 = mat2cell(Voxels_30, lengthes, 3);
toc;

disp('Calculating component connect graph......');
     tic;
    %% Calculate volumn, center, minimum coordinate and L_W_H(length,width,height) of each Part
    num_group = length(model.groupVertex);
    Volume=zeros(num_group,1);
    Centre=zeros(num_group,3);
    P_min=zeros(num_group,3);
    L_W_H=zeros(num_group,3);
    for j=1:num_group
        [Volume(j),Centre(j,:),P_min(j,:),L_W_H(j,:)]=AABB(model.groupVertex{j});
    end

    %% Whether Points in Volume_i belong to Volume_j
    Points_pair= cell(num_group,num_group);
    Edge_pair=zeros(num_group,num_group);
    for k=1:num_group-1
        for j=k+1:num_group        
             C=Intersections(model.groupVertex{k} ,Centre(j,:), L_W_H(j,1), L_W_H(j,2), L_W_H(j,3) );
             C1=Intersections(model.groupVertex{j} ,Centre(k,:), L_W_H(k,1), L_W_H(k,2), L_W_H(k,3) );
             if (~isempty(C))||(~isempty(C1))
               Points_pair{k,j}=[Centre(k,:); Centre(j,:)];
               Edge_pair(k,j)=1;
             end    
        end
    end
    toc;
    
    backup_edge=Edge_pair;
    backup_edge=backup_edge+backup_edge';

    %% pruning
    disp('pruning.....');
    tic;
    bunches=find(Edge_pair==1);
    for j=1:size(bunches, 1)
        idx=bunches(j);
        column=floor(idx/size(Edge_pair, 1))+1;
        row=idx-(column-1)*size(Edge_pair, 1);
        find_i=Voxels_idx{column};
        find_j=Voxels_idx{row};
        overlap=find(ismember(find_i, find_j)==1);
        if(size(overlap, 1)==0)
            Edge_pair(idx)=0;
            Points_pair{row,column}=[];
        end
    end
    toc;
    Points_pair1=Points_pair;
    Points_pair1(cellfun(@isempty,Points_pair1))=[];
    Edge_pair=Edge_pair+Edge_pair';
    
    independent_points=find(all(Edge_pair==0,2));
    Edge_pair(:,independent_points)=backup_edge(:,independent_points);
    Edge_pair(independent_points,:)=backup_edge(independent_points, :);
end

function cal_single_model_test(Edge_pair, model,Voxels, save_nums, savepath, filename, MatPath)
voxel_size = 30;
new_graph = Dealing_with_processed_Edge_pairs(Edge_pair, model);
[BinaryTree_200_1,BinaryTree_200_2,BinaryTree_200_3,proposal_200_1,proposal_200_2,proposal_200_3] = Cal_proposals_no_scores(model, Voxels, new_graph);
[proposal_200_4kinds, Voxels_200, groupPixels_200] = New_Proposal_no_Score_cal(save_nums, Voxels, BinaryTree_200_1, BinaryTree_200_2, BinaryTree_200_3, proposal_200_1, proposal_200_2, proposal_200_3);
[rotated_Volums_relapositions,rotated_Volums_relaposition_remains,rotated_Volums_centers] = translate_proposals(model, voxel_size, Edge_pair, proposal_200_4kinds);
auto_sel_test_and_generate_h5(rotated_Volums_centers, rotated_Volums_relapositions, rotated_Volums_relaposition_remains, filename, savepath);
eval(['save ', MatPath, filename(1:length(filename)-4), '.mat Edge_pair groupPixels_200 model proposal_200_4kinds'])
end

%% AABB Bounding Box
function [Volume,Centre,P_min,L_W_H]=AABB(P)
if size(P,1)==1
    P_max=P;
    P_min=P;
else
   P_max=max(P);
   P_min=min(P);
end
   Centre=mean([P_max;P_min]);
   L_W_H=P_max-P_min;
   L_W_H(L_W_H==0)=1.0e-07;
   Volume= L_W_H(1)*L_W_H(2)*L_W_H(3);  
end

%% Matrix transforms
function C = Intersections(P_1 ,Centre_point, L, W, H )
   T=Centre_point;
   num=size(P_1,1);
   B = repmat(T,num,1);
   
   D=P_1-B;
   lamda=0.01;  %expand boxes
   
   X=find(D(:,1)>=-(L/2+lamda*L) & D(:,1)<=(L/2+lamda*L));
   Y=find(D(:,2)>=-(W/2+lamda*W) & D(:,2)<=(W/2+lamda*W));
   Z=find(D(:,3)>=-(H/2+lamda*H) & D(:,3)<=(H/2+lamda*H));
   
   C1=intersect(X,Y);
   C=intersect(Z,C1);
end
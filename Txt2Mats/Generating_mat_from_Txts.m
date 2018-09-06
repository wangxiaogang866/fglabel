%Load txts from folders under the folder"FindFiles" and save as .mat files.
%Each folder in path "FindFiles" should have txts named as "vertices.txt","faces.txt", "groups.txt", "parts.txt"
function Generating_mat_from_Txts()
FindFiles = 'G:\shilin\test\models\car\';
TheSavePATH = 'G:\shilin\test\mats\';
Files = dir(fullfile(FindFiles,'*.'));
LengthFiles = length(Files); 
 for i = 3:LengthFiles;         %The first two files named as "." and ".." are useless
     fprintf(2,'\nTransforming the %dth model in %d models....%s\n', i-2,LengthFiles-2,  Files(i).name);
     
     disp('Loading model information......');
     tic;
     %load vertices infomations
     vertex_txt=[FindFiles, Files(i).name,'\vertices.txt'];
     vertex=importdata(vertex_txt);
     
     %load faces infomations
     faces_txt=[FindFiles, Files(i).name,'\faces.txt'];
     faces=importdata(faces_txt);
     
     %load group infomations
     group=cell(0);
     group_txt=[FindFiles, Files(i).name,'\groups.txt'];
     fidin=fopen(group_txt, 'r'); 
     temp_group=[];
     group_idx=0;
     while ~feof(fidin)
         tline=fgetl(fidin);
         if double(tline(1))>=48&&double(tline(1))<=57       % if is a number
             temp_group=[temp_group, str2num(tline)];
         else
             if group_idx>0
                group=[group; {faces(temp_group,:)}];
             end;
             group_idx=group_idx+1;
             temp_group=[];
         end
     end
     group=[group; {faces(temp_group,:)}];
    
     %load part infomations
     groundtruth=cell(0);
     groundtruth_txt=[FindFiles, Files(i).name,'\parts.txt'];
     fidin=fopen(groundtruth_txt, 'r'); 
     temp_part=[];
     part_idx=0;
     while ~feof(fidin)
         tline=fgetl(fidin);
         if double(tline(1))>=48&&double(tline(1))<=57       % if is a number
             temp_part=[temp_part, str2num(tline)];
         else
             if part_idx>0
                 groundtruth=[groundtruth; {temp_part}, {PartName}, {getpartA(PartName)}];
                 temp_part=[];
             end
             PartName=tline;
             part_idx=part_idx+1;
         end
     end
     groundtruth=[groundtruth; {temp_part}, {PartName}, {getpartA(PartName)}];
     fclose('all');
     
     %% save infomations from txts to a structure name as "model"
     struct name model;
     model.vertices=vertex;
     model.groups=group;
     model.groupVertex=cell(size(group, 1), 1);
     for j=1:size(group, 1)
         vertex_idx=unique(group{j});
         vertex_coord=vertex(vertex_idx, :);
         model.groupVertex{j,1}=vertex_coord;
     end
     
     toc;    

     

 
    
    disp('Calculating relative positions and rela_scale about every groups....');
    tic;
    Vertices=model.vertices;  
    Ver_min=min(Vertices);
    Ver_max=max(Vertices);
    Centre_Ver=mean([Ver_min;Ver_max]);
    Scale_Ver=Ver_max-Ver_min;

    num=length(model.groups);
    temp_centre_ver=repmat(Centre_Ver,num,1);
    temp_scale_ver=repmat(Scale_Ver,num,1);

    rela_position=Centre(:,1:3)-temp_centre_ver;
    rela_scale=L_W_H./temp_scale_ver;
    toc;
    disp('Calculating relative positions and rela_scale about groundtruth....');
    tic;
    groundtruth_rela_position=zeros(size(groundtruth, 1),3);
    groundtruth_rela_scale=zeros(size(groundtruth, 1),3);
    for groundtruth_idx=1:size(groundtruth, 1)
        group_ii=groundtruth{groundtruth_idx,1};
        group_faces=cell2mat(model.groups(group_ii,1));
        ver_idxes=unique(group_faces(:));
        vers=model.vertices(ver_idxes,:);
        ver_min=min(vers);
        ver_max=max(vers);
        this_center=mean([ver_min;ver_max])-Centre_Ver;
        this_scale=(ver_max-ver_min)./Scale_Ver;
        groundtruth_rela_position(groundtruth_idx,:)=this_center;
        groundtruth_rela_scale(groundtruth_idx,:)=this_scale;
    end
    toc;
    
    disp('Voxelizaing all groups....200');
    tic;
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
    
    No_points=1:num_group;
    No_points=No_points';
    Centre=[Centre,No_points];
    
    %% save groundtruth¡¢groundtruth_rela_position¡¢groundtruth_rela_scale and so on
    savepath=['save ',TheSavePATH,Files(i).name,'.mat  model Voxels_200 Voxels_30 Edge_pair Voxels groundtruth rela_scale rela_position groundtruth_rela_position groundtruth_rela_scale ' ];

    eval(savepath);
 end
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
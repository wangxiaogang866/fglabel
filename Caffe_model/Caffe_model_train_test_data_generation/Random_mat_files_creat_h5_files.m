%%  Random Select batch_size cells ----create h5 files
function h5_files_create=Random_mat_files_creat_h5_files(GTandAL_center, GTandAL_relaposition, GTandAL_rela_remain, GTandAL_scores, GTandAL_scores_class, h5_file_title, batch_size)
mat_idx=randperm(length(GTandAL_center));   % random order

%% select batch_size cells for one h5 file
num_mat=numel(mat_idx);   %cell numbers
num_h5_files=ceil(num_mat/batch_size);  % number of h5 files

h5_files_idx=num2cell(1:num_h5_files);
h5_files_mat_idx=cellfun(@(x) (x-1)*batch_size+1:min(x*batch_size,num_mat),h5_files_idx,'UniformOutput',false);   % cell indexes in each h5 file
h5_files_mat_idx = cellfun(@(x) mat_idx(x), h5_files_mat_idx, 'UniformOutput',false);

h5_files_create=cellfun(@(x, y) Create_h5_files(x, y, h5_file_title, GTandAL_center, GTandAL_relaposition, GTandAL_rela_remain, GTandAL_scores, GTandAL_scores_class), h5_files_mat_idx, h5_files_idx, 'UniformOutput',false); 
disp('h5 file saved....')
end

%%  Create h5 files from mat files
function y=Create_h5_files(mat_idxes, index, h5_file_title, GTandAL_center, GTandAL_relaposition, GTandAL_rela_remain, GTandAL_scores, GTandAL_scores_class)
% Combine mat files from a set of index numbers
mat_files=cellfun(@(x) load_cells(GTandAL_center{x}, GTandAL_relaposition{x}, GTandAL_rela_remain{x}, GTandAL_scores{x}, GTandAL_scores_class{x}),num2cell(mat_idxes),'UniformOutput', false);
combine_mats=[mat_files{:}];


data1_center=combine_mats(1,:);
data1_center=[data1_center{:}]';  %exact data center
data2_relaposition=combine_mats(2,:);
data2_relaposition=[data2_relaposition{:}]';  %exact data relaposition
data3_rela_remain=combine_mats(3,:);
data3_rela_remain=[data3_rela_remain{:}]';  %exact data relaposition remain
labels=combine_mats(4,:);
labels=[labels{:}]'; % exact labels
combine_mats = [];

h5_file_name = [h5_file_title, num2str(index), '_volums_center_rela_remain_all.h5'];

y=create_h5(data1_center, data2_relaposition, data3_rela_remain,labels, h5_file_name); 
end


%% load mat file, and extract the data and labels
function  data_voxel_labels=load_cells(GTandAL_center, GTandAL_relaposition, GTandAL_rela_remain, GTandAL_scores, GTandAL_scores_class)
data1 = GTandAL_center';
data2 = GTandAL_relaposition';
data3 = GTandAL_rela_remain';

pre_X_class=Set_class(GTandAL_scores_class);
X_class = mat2cell(pre_X_class, ones(1, size(pre_X_class, 1)), size(pre_X_class, 2));
X_class = cellfun(@(x) find(x==1)-1, X_class, 'UniformOutput', false);
X_class = cell2mat(X_class);
labels_2=max(GTandAL_scores,[],2);
labels=[X_class,labels_2]';
data_voxel_labels={data1; data2; data3; labels};

end
function created_flag=create_h5(data1_center, data2_relaposition, data3_rela_remain,labels, filename)
%% WRITING TO HDF5
tic;
% filename='exacted_proposals_double_scores_train_volums_center_rela_remain_all.h5';
num_total_samples=length(data1_center);    % numbers of samples

batch_size=100;     %  size of batch
created_flag=false;
totalct=0;       % current location
score_dim=size(labels,2);   % label dimension (car=9)
Tot=size(labels,1);   %   numbers of saples

disp('data to mat...')
tic;
label2 = reshape(labels',[1 1 score_dim Tot]);
toc;
last_read = 0;
for batchno=1:num_total_samples/batch_size
    fprintf('batch no. %d\n', batchno);
    last_read=(batchno-1)*batch_size;     % current batch_data location
    
    
    batchdata(:,:,:,1,:)= single(cell2mat(reshape(data1_center(last_read+1:last_read+batch_size),[1 1 1 1 batch_size])));
    batchdata(:,:,:,2,:)= single(cell2mat(reshape(data2_relaposition(last_read+1:last_read+batch_size),[1 1 1 1 batch_size])));
    batchdata(:,:,:,3,:)= single(cell2mat(reshape(data3_rela_remain(last_read+1:last_read+batch_size),[1 1 1 1 batch_size])));
    
    batchlabs = label2(:,:,:,(last_read+1:last_read+batch_size));
    
    
    % store to hdf5
    startloc=struct('dat',[1,1,1,1,totalct+1], 'lab', [1,1,1,totalct+1]);
    curr_dat_sz=store2hdf5(filename, batchdata, batchlabs, ~created_flag, startloc, batch_size);
    created_flag=true;% flag set so that file is created only once
    totalct=curr_dat_sz(end);% updated dataset size (#samples)
    
end

remain_size =mod( num_total_samples,batch_size);    %if have remain proposals
if remain_size~=0
    batchno=batchno+1;
    fprintf('batch no. %d\n', batchno);
    last_read = size(data1_center, 1) - remain_size;% current batch_data location
        
    new_batchdata(:,:,:,1,:)= single(cell2mat(reshape(data1_center(last_read+1:size(data1_center, 1)),[1 1 1 1 remain_size])));
    new_batchdata(:,:,:,2,:)= single(cell2mat(reshape(data2_relaposition(last_read+1:size(data1_center, 1)),[1 1 1 1 remain_size])));
    new_batchdata(:,:,:,3,:)= single(cell2mat(reshape(data3_rela_remain(last_read+1:size(data1_center, 1)),[1 1 1 1 remain_size])));
    
    newbatchlabs = label2(:,:,:,(last_read+1:last_read+remain_size));
    if remain_size ==1
        new_batchdata = cat(5, new_batchdata, new_batchdata);
        newbatchlabs = cat(4, newbatchlabs, newbatchlabs);
    end
    startloc=struct('dat',[1,1,1,1,totalct+1], 'lab', [1,1,1,totalct+1]);
    curr_dat_sz=store2hdf5(filename, new_batchdata, newbatchlabs, ~created_flag, startloc, batch_size);
    
    created_flag=true;% flag set so that file is created only once
    totalct=curr_dat_sz(end);% updated dataset size (#samples)
end
%

toc;

% display structure of the stored HDF5 file
h5disp(filename);


end

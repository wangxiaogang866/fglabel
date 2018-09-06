function auto_sel_test_and_generate_h5(rotated_Volums_centers, rotated_Volums_relapositions, rotated_Volums_relaposition_remains, filename, savepath)
% Scores = Volums_Scores ;
% Scores = max(Scores, [], 2);
% Scores_second = Volums_Scores_second;
% Scores_second = [Scores_second, Scores];

Scores_second = zeros(length(rotated_Volums_centers), 2);

fn1 = [savepath, filename(1:length(filename)-4),'.h5'];

created_flag=create_h5(rotated_Volums_centers, rotated_Volums_relapositions, rotated_Volums_relaposition_remains,Scores_second, fn1);
end

function created_flag=create_h5(data1_center, data2_relaposition, data3_rela_remain,labels, filename)
  %% WRITING TO HDF5  
  tic; 
num_total_samples=size(data1_center, 1);    % numbers of samples
  
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
  
remain_size =mod( num_total_samples,batch_size);    %whether have unsaved proposals
if remain_size~=0
    batchno=batchno+1;
    fprintf('batch no. %d\n', batchno);  
  last_read = size(data1_center, 1) - remain_size;
    
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
toc;
  
% display structure of the stored HDF5 file  
h5disp(filename);  
  
  
end
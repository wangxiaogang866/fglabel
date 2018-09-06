
function  ExtractFeatureFromDataBatch(FindFiles,net, save_file_path)
warning off
begin_clock=fix(clock);
Files = dir(fullfile(FindFiles,'*.h5'));
if ~exist(save_file_path, 'dir')
    mkdir(save_file_path);
end

Files1={Files.name}';
Files1_full=cellfun(@(x) [FindFiles, x],Files1,'UniformOutput',false);

%% Calculate net scores
Features=cellfun(@(x) extract_feature(x,net, save_file_path), Files1_full,'UniformOutput',false);



end

function test_score=extract_feature(impath,net, save_file_path)
    h5data = h5read(impath,'/data');
    h5label = h5read(impath,'/label');
    h5data = single(h5data);
    dims_data = size(h5data);
    dims_label= size(h5label);
    
    test_gt=squeeze(h5label);
    test_gt=test_gt';
    test_gt1=mat2cell(test_gt,ones(size(test_gt,1),1),[9,1]);  %Different model categories have different number of labels. Motor is 9

    test_Data=mat2cell(h5data,dims_data(1),dims_data(2),dims_data(3),dims_data(4),ones(1,1,1,1,dims_data(5)));
    test_Data1=squeeze(test_Data);
    test_label = mat2cell(h5label,dims_label(1),dims_label(2),dims_label(3),ones(1,1,1,dims_label(4)));
    test_label1=squeeze(test_label);
    test_score=cellfun(@(x) ExtractFeatureWithBatch(x,net), test_Data1, 'UniformOutput',false);
    [~,name,~] = fileparts(impath);
    name
    test_score=[test_score{:}];
    test_score=test_score';
    
    test_gt_score=[test_score(:,1:2),test_gt1(:,2),test_score(:,3),test_gt1(:,1)];
    
    save([save_file_path, name],'test_gt_score');
end


function ExtractFeatureFromDataList(dirpath, deploy_name, caffemodel_name, save_file_path)
    phase = 'test';

    addpath(genpath('..\..\Build\x64\Debug'));      %caffe install folders
    caffe.reset_all();
    model_dir = './models';
    caffe_model_def = fullfile(model_dir,deploy_name); %prototxt file
    
    caffe_model_file = fullfile(model_dir,caffemodel_name); %caffemodel
    
    if ~exist(caffe_model_def,'file') || ~exist(caffe_model_file,'file')
        fprintf('Unable to extract feature from image without effecive Caffe model.\n');
        return;
    end
    
    net = caffe.Net(caffe_model_def, phase);
    net.copy_from(caffe_model_file);
    use_gpu = 1;
    if exist('use_gpu', 'var') && use_gpu % we will use the first gpu in this demo
        caffe.set_mode_gpu();
        gpu_id = 0; 
        caffe.set_device(gpu_id);
    else
        caffe.set_mode_cpu();
    end
    ExtractFeatureFromDataBatch(dirpath,net, save_file_path);
    caffe.reset_all();
end
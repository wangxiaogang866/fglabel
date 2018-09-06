function Test_CNN_demo()
    dirpath = 'G:\chair\test\';   %% All .h5 files for test are under this path. 
    %all prototxt files and caffemodel files are in the fold 'model'
    deploy_name = 'multitask_cls_chair_deploy.prototxt';
    caffemodel_name = 'chair_14000_2way.caffemodel';
    save_file_path = 'chair_2way\';
    ExtractFeatureFromDataList(dirpath, deploy_name, caffemodel_name, save_file_path); 
end
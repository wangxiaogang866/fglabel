# Learning to Group and Label Fine-Grained Shape Components

This is the code repository for "Learning to Group and Label Fine-Grained Shape Components”

Created by Xiaogang Wang, Bin Zhou, Haiyue Fang, Xiaowu Chen, Qinping Zhao, Kai Xu


## Prerequisites: 
     windows 7, 
     Visual Studio 2015, 
     OSG 3.0(Open Scene Graph),
     Matlab 2015b.
     
## Dataset 
You can download the data [here](http://www.zbuaa.com/sa2018/data.rar).


## 0, Flt2Txt: Process models (.flt) into '.txt' files. 
   cd .../Code/Flt2Txt/Flt2Txt\
   main_get_txts.cpp\
   And the output '.txt' files include the following:\
        points.txt:  all vertices of model\
        faces.txt: all faces of model\
        groups.txt: all components of model\
        parts.txt: all semantic parts of model (only for groundtruth model)

## 1, Txt2Mats:  Transform  '.txt' file into '.mat' file
   cd .../Code/Txt2Mats\
   Generating_mat_from_Txts.m\
   And the output .mat file include the following:\
        model.vertices: all vertices of input model\
        model.groups: all components of input model (faces of each component)\
        model.Vertex: all components of input model (vertices of each component)

## 2, Caffe Network Training: Training Network   

   ### 2-1, Training Caffe Model  
    cd .../Code/Caffe_model/Caffe_model_train
    motor_multitask_cls.prototxt
    motor_multitask_solver.prototxt 
  
   ### 2-2, Training Data Generation
    cd .../Code/Caffe_model/Caffe_model_train_test_data_generation
    MakeNetInput.m
    The output .mat file include the following:
        proposals_200_4kinds:  all part hypotheses of 3D model
        model: all vertices, groups(components faces), grouVertex(components vertices)
        groupPixels_200: The number of elements each component occupies in the voxel space (200 *200*200)
        Edge_pair: The connection relationship between components.
    And the output .h5 file include the following:
      data : 30*30*30*3*K (30 is voxel space; 3 is three branch; K is the number of part hypotheses of input model)   
      label: 1*1*2*K (2 represents 'semantic label' and 'confidence score' for each part hypotheses; K is the number of part hypotheses of input model)
              
## 3, Caffe Network Test：Test Network 
  
   ### 3-1, Caffe Test Model
      cd .../Code/Caffe_model/Caffe_model_test
      Test_CNN_demo.m
      The output .mat models include the following fields:
         column 1: 2048 feature vector by CNN,
         column 2: regression score,
         column 3: class probability distribution
     
   ### 3-2, Caffe Test Data Generation
       1), For .flt model format, step 0->step 1->step 2-2 can be used to generate network test data (.h5 file only have 'data' term).
       2), For .obj model format, 
           cd .../Code/Caffe_model/Caffe_model_test_data_obj
           MakeNetTest_obj.m
           The output .h5 file include the following:
           data : 30*30*30*3*K (30 is voxel space; 3 is three branch; K is the number of part hypotheses of input model)       

## 4, Composite_inference:  Higher-order CRF optimization
   cd .../Code/Composite_inference\
   Batching_adjust_para.m\
   The output .txt file model is the final labelling result, that assigning a semantic label for each component.


## 5, Labeling result visualization
   cd .../Code/Visualization/osg_renderbytxt\
   main.cpp\
   input: labeling result（step 4： .txt file）,  original model (.flt or .obj model)\
   output: image with different color for different labels.


## Citation

If you find our paper useful in your research, please cite:

 @article{wang_siga18,\
   title = {Learning to Group and Label Fine-Grained Shape Components},\
   author = {Xiaogang Wang and Bin Zhou and Haiyue Fang and Xiaowu Chen and Qinping Zhao and Kai Xu},\
   journal = {ACM Transactions on Graphics (SIGGRAPH Asia 2018)},\
   volume = {37},\
   number = {6},\
   pages = {to appear},\
   year = {2018}\
  }


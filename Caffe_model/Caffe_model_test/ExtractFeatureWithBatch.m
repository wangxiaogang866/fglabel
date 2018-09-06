function features = ExtractFeatureWithBatch(imageData,net)
    count = size(imageData,5);
    net.blobs('data').reshape([30 ,30 ,30 ,3, 1]);
    %in caffe is 1*3*30*30*30
    net.forward({imageData});
   
    %get data (fc5,fc61,fc62)from caffe
    feat1 = net.blobs('fc5').get_data();
    features1 = permute(feat1,[4,3,2,1]);
    feat2 = net.blobs('fc61').get_data();
    features2 = permute(feat2,[4,3,2,1]);
    
    feat3 = net.blobs('Softmax').get_data();
    features3 = permute(feat3,[4,3,2,1]);
    
    features={feat1,feat2,feat3}';
end
        
    
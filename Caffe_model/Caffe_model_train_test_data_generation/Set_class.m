function X_class=Set_class(GTandAL_scores_class)
    X_class1=mat2cell(GTandAL_scores_class,ones(size(GTandAL_scores_class,1),1),size(GTandAL_scores_class,2));
    X_class2=cellfun(@(x) [0*x,0],X_class1,'UniformOutput',false);
    X_class3=cellfun(@(x,y) SetX_class(x,y),X_class1,X_class2,'UniformOutput',false);
    X_class=cell2mat(X_class3);
    
    X_class(max(X_class,[],2)==0,size(GTandAL_scores_class, 2)+1)=1;
end

function y=SetX_class(x,y)
   [a,b]=max(x);
   if (a>=0.7)
       y(b)=1;
   end
end
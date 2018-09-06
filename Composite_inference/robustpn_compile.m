% compile robustpn mex 
cs = computer;
if ~isempty(strfind(cs,'64'))
    % 64-bit machine
    mex -O -DNDEBUG -largeArrayDims robustpn_mex.cpp 
else
    mex -O -DNDEBUG robustpn_mex.cpp
end
clear cs;
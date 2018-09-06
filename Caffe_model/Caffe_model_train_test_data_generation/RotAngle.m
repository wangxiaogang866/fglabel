function R_Matrix = RotAngle(angle)
%Rotate by z-axis
R_Matrix = [cos(angle)    sin(angle)	0;
             -sin(angle)	cos(angle)	0;
             0          0       1];
%%Rotate by y-axis
% Rot_Matrix = [cos(x)    0   sin(x);
%              0          1       0;
%              -sin(x)	0 	cos(x)];
end
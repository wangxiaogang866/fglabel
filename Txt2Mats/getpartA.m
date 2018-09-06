%partA-B,get A & B
function part_A = getpartA(str)

index = isstrprop(str,'digit');

str_A = str(1:end-2);
part_A = str_A(index(1:end-2));
part_A = str2num(part_A);
end
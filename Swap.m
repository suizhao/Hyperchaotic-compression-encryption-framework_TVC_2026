function [gp] = Swap(GP,N)
% GP is even element group and N is half of GP's length
i = 1;
while(i<=N)
    temp = GP(i);
    GP(i) = GP(i+N);
    GP(i+N) = temp;
    i=i+1;
end
gp = GP;
return;
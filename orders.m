function [od] = orders(temp)
    if temp==0
        od = [1,2,3,4];
    elseif temp==1
        od = [1,2,4,3];
    elseif temp==2
        od = [1,3,2,4];
    elseif temp==3
        od = [1,3,4,2];
    elseif temp==4
        od = [1,4,2,3];
    elseif temp==5
        od = [1,4,3,2];
    elseif temp==6
        od = [2,1,3,4];
    elseif temp==7
        od = [2,1,4,3];
    elseif temp==8
        od = [2,3,1,4];
    elseif temp==9
        od = [2,3,4,1];
    elseif temp==10
        od = [2,4,1,3];
    elseif temp==11
        od = [2,4,3,1];
    elseif temp==12
        od = [3,1,2,4];
    elseif temp==13
        od = [3,1,4,2];
    elseif temp==14
        od = [3,2,1,4];
    elseif temp==15
        od = [3,2,4,1];
    elseif temp==16
        od = [3,4,1,2];
    elseif temp==17
        od = [3,4,2,1];
    elseif temp==18
        od = [4,1,2,3];
    elseif temp==19
        od = [4,1,3,2];
    elseif temp==20
        od = [4,2,1,3];
    elseif temp==21
        od = [4,2,3,1];
    elseif temp==22
        od = [4,3,1,2];
    elseif temp==23
        od = [4,3,2,1];
    end
return;
function [energy_map,num_nonzero,last_nonzero] = energy_ac_coefficients_framework(plain_image,CW,QF,key_image,fig)
%% return current results
if fig==0
    energy_map = imread('.\Baboon_EAC.png');
    num_nonzero = imread('.\Baboon_NCC.png');
    last_nonzero = imread('.\Baboon_PLZ.png');
else
    energy_map = imread('.\Baboon_EAC_w.png');
    num_nonzero = imread('.\Baboon_NCC_w.png');
    last_nonzero = imread('.\Baboon_PLZ_w.png');
end
return
%% encryption process
[m,n]=size(plain_image);
plain_image = plain_image-128;
block16_num = n*m/256;
block16(16,16,block16_num)=0;
% Execute our encryption algorithm to obtain encrypted encoded stream
% Assume the encoded stream encryption process is cracked, so Huffman decoding can be performed
% Huffman decoding yields zigzag-processed frequency domain coefficient vector for each 8*8 block
%% unzigzag8
block16(16,16,block16_num)=0;
for bx=1:block16_num
    temp_bx = 4*bx-3;
    block16(1:8,1:8,bx) = unzigzag8(block8_zigzag(temp_bx,:));
    block16(1:8,9:16,bx) = unzigzag8(block8_zigzag(1+temp_bx,:));
    block16(9:16,1:8,bx) = unzigzag8(block8_zigzag(2+temp_bx,:));
    block16(9:16,9:16,bx) = unzigzag8(block8_zigzag(3+temp_bx,:));
end

%% reverse raster scan
img_restruct(m,n)=0;
k=1;
temp_r = 0; temp_c = 0;
for r=1:m/16
    temp_r = r*16-15; 
    for c=1:n/16
        temp_c = c*16-15;
        img_restruct(temp_r:temp_r+15,temp_c:temp_c+15)=block16(:,:,k);
        k=k+1;
    end
end

%% sketch attack
energy_map(m/8,n/8)=0;

for i=1:m/8
    for j=1:n/8
        temp = img_restruct(8*(i-1)+1:8*i,8*(j-1)+1:8*j);
        energy_map(i,j) = sum(abs(temp(:)));
    end
end

num_nonzero(m/8,n/8)=0;
for i=1:m/8
    for j=1:n/8
        temp = img_restruct(8*(i-1)+1:8*i,8*(j-1)+1:8*j);
        num_nonzero(i,j) = nnz(temp(:)~=0);
    end
end

last_nonzero(m/8,n/8)=0;
for i=1:m/8
    for j=1:n/8
        temp = zigzag8(img_restruct(8*(i-1)+1:8*i,8*(j-1)+1:8*j));
        for k=64:-1:2
            if temp(k)~=0
                last_nonzero(i,j)=k;
                break;
            end
        end
    end
end

return;
    


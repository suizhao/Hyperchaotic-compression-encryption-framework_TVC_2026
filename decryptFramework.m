function [img_restruct] = decryptFramework(seq_enc,key_image,ITE)
%% return current result
load('image_restruct.mat');
return
%% 
len_seq_enc = length(seq_enc);
key_initial = '66c782e8f95ba958f28adaae576c42a263c2449af416fb844499bef7fd41b2d0';
key_image = bitxor(double(key_image),double(key_initial),'int16');
key_image = char(key_image);
%% get compressed data bitstream
% Extract compressed data data_compressed from JPEG encoded stream,
% original image height height_img, width width_img, quantization table QT
img_restruct(height_img,width_img)=0;
block16_num = height_img*width_img/256;
block8_num = block16_num*4;
%% get chaotic stream
% Generate initial state values of chaotic system based on initial key key_image, 
% produce chaotic sequences k1, k2, k3, k4
%% reverse data_compressed complement and diffusion 
% Generate encryption keys key5 and key6 using chaotic sequence k4, and generate encryption key key7 using chaotic sequence k2
% Perform inverse process of selective complementation and diagonal diffusion on encoded stream based on key5, key6 and key7
%% huffman decode
block8_zigzag = zeros(block8_num,64);
% Perform Huffman decoding on data_compressed according to JPEG Huffman decoding rules 
% to obtain zigzag-scanned frequency domain coefficient data
%% Get s vector from AC coefficient and Decode them
% inverse embed oprate

% Generate encryption key key4 based on chaotic sequence k4
for bx=1:block16_num
    if key4(bx) == 1
        if s(bx)=='1'
            s(bx)='0';
        else
            s(bx)='1';
        end
    end
end
clear key4;

for i=1:block16_num
    if s(i)=='1'
        index_char1 = i;
    end
end
%% reverse group and swap DC coefficient
% Generate encryption key key3 with minimum length based on chaotic sequence k3 and characteristics of group scrambling
dcc = block8_zigzag(1:end,1);
temp_block8 = block8_num*0.5;
if(ITE<=temp_block8)
    j=ITE;
else
    j=floor(temp_block8+1);
end

k = numel(key3);
for j=j:-1:1
    temp = 2*j;
    for i=floor(block8_num/temp):-1:1
        if(key3(k)=='1')
            temp_i = temp*i;
            dcc((temp_i-temp+1):temp_i) = Swap(dcc((temp_i-temp+1):temp_i),j);
        end
        k=k-1;
    end
end
block8_zigzag(1:end,1) = dcc;
%% decode DC by reverse DPCM
for bx=2:block8_num
    block8_zigzag(bx,1) = block8_zigzag(bx,1)+block8_zigzag(bx-1,1);
end
%% decode DC by reverse XOR
for bx=block16_num:-1:1
   if(s(bx)=='0')
       bx_temp = 4*bx-3; % 4*(bx-1)+1
       block8_zigzag(3+bx_temp,1) = bitxor(block8_zigzag(3+bx_temp,1),block8_zigzag(2+bx_temp,1),'int16');
       block8_zigzag(2+bx_temp,1) = bitxor(block8_zigzag(2+bx_temp,1),block8_zigzag(1+bx_temp,1),'int16');
       block8_zigzag(1+bx_temp,1) = bitxor(block8_zigzag(1+bx_temp,1),block8_zigzag(bx_temp,1),'int16');
       temp1 = bx_temp;
       bx=bx-1;
       break; 
   end
end
for bx=bx:-1:1
   if(s(bx)=='0')
      bx_temp = 4*bx-3; % 4*(bx-1)+1
      block8_zigzag(temp1,1)=bitxor(block8_zigzag(temp1,1),block8_zigzag(3+bx_temp,1),'int16');
      block8_zigzag(3+bx_temp,1) = bitxor(block8_zigzag(3+bx_temp,1),block8_zigzag(2+bx_temp,1),'int16');
      block8_zigzag(2+bx_temp,1) = bitxor(block8_zigzag(2+bx_temp,1),block8_zigzag(1+bx_temp,1),'int16');
      block8_zigzag(1+bx_temp,1) = bitxor(block8_zigzag(1+bx_temp,1),block8_zigzag(bx_temp,1),'int16');
      temp1 = bx_temp;
   end
end
%% decode AC by reverse 8x8 block permutation
% Generate index vector key1 with length block16_num*4 based on k1. Generate integer vector s2 with length max(height_img/8,width_img/8)
% Reshape key1 into index matrix s1 of size height_img/8 * width_img/8
% Perform cyclic scrambling on index matrix based on s2 to get final index matrix s1
% Sort the 1D degraded vector of default 2D matrix in MATLAB to get index vector s11, which can restore to original block distribution
%% unzigzag8
block16(16,16,block16_num)=0;
for bx=1:block16_num
    temp_bx = 4*bx-3;
    block16(1:8,1:8,bx) = unzigzag8(block8_zigzag(temp_bx,:));
    block16(1:8,9:16,bx) = unzigzag8(block8_zigzag(1+temp_bx,:));
    block16(9:16,1:8,bx) = unzigzag8(block8_zigzag(2+temp_bx,:));
    block16(9:16,9:16,bx) = unzigzag8(block8_zigzag(3+temp_bx,:));
end
%% reverse QT
for bx=1:block16_num
    block16(1:8,1:8,bx) = block16(1:8,1:8,bx).*QT;
    block16(1:8,9:16,bx) = block16(1:8,9:16,bx).*QT;
    block16(9:16,1:8,bx) = block16(9:16,1:8,bx).*QT;
    block16(9:16,9:16,bx) = block16(9:16,9:16,bx).*QT;
end
%% reverse last_bit
if(any(any( QT==1 )))
    one_mtx = ones(8,8);
    for i=1:8
        for j=1:8
            if(QT(i,j)==1)  
                one_mtx(i,j)=2;  
            end
        end
    end
    k = 1;
    for bx=1:block16_num
        if(s(bx)=='1')
            block16(:,:,bx) = blkproc(block16(:,:,bx),[8 8],'round(x.*P1)',one_mtx);
        end
    end
end
%% reverse DCT
% Generate binary encryption key key2 based on chaotic sequence k2
key2 = char(mod(floor(k2(1:448+index_char1)*10^10),2)+ '0');
T8 = dctmtx(8);
T8_tm = T8';
T16 = dctmtx(16);
T16_tm = T16';
for bx=1:block16_num
    if(s(bx)=='1')
        % Perform inverse process of coefficient redistribution on block16(:,:,bx) based on key2, 
        % then perform 16*16 inverse DCT process
        block16(:,:,bx) = T16_tm* block16(:,:,bx) *T16;
    else
        block16(1:8,1:8,bx) = T8_tm*block16(1:8,1:8,bx)*T8;
        block16(1:8,9:16,bx) = T8_tm*block16(1:8,9:16,bx)*T8;
        block16(9:16,1:8,bx) = T8_tm*block16(9:16,1:8,bx)*T8;
        block16(9:16,9:16,bx) = T8_tm*block16(9:16,9:16,bx)*T8;
    end
end
%% reverse raster scan
k=1;
temp_r = 0; temp_c = 0;
for r=1:height_img/16
    temp_r = r*16-15; 
    for c=1:width_img/16
        temp_c = c*16-15; 
        img_restruct(temp_r:temp_r+15,temp_c:temp_c+15)=block16(:,:,k);
        k=k+1;
    end
end


return;



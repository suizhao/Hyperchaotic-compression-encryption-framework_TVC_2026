function [bitstream_enc,bit_seq,key_image,ite]=encryptFramework(I,CW,QF,ITE,key_image)
%% return current results
load('enc_stream.mat')
load('dc_ac.mat')
load('key_image.mat')
bitstream_enc = enc_stream;
bit_seq = dc_ac;
key_image = key_image;
ite = ITE;
return
%% preprocess
[m,n]=size(I);
% Intergrate External Key and Interference Key Based on Original Image
% This part is temporarily commented out to facilitate cloning and running, as it only affects the generation of initial parameter values for the chaotic system.
    % key_initial = SHA256('123412341234');
    % key_image = bitxor(double(key_image),double(key_initial),'int16');
    % key_image = char(key_image);
ite=ITE;
I = I-128;
block16_num = n*m/256;
block8_num = 4*block16_num;
block16(16,16,block16_num)=0;
k=1;
temp_r = 0; temp_c = 0;
for r=1:m/16
    temp_r = r*16-15; %(r-1)*16+1
    for c=1:n/16
        temp_c = c*16-15; %(c-1)*16+1
        block16(:,:,k) = I(temp_r:temp_r+15,temp_c:temp_c+15);
        k=k+1;
    end
end
%% block segmentation process
s(1:block16_num)='0';
for bx=1:block16_num  
    % Perform segmentation analysis on each 16*16 block,
    % return values d and e related to rate-distortion and bitstream length for segmentation decision
    cost = CW*(d-e)+e;
    if(cost<=0) 
        s(bx)='1';
        index_char1 = bx;
    end
end
%% generate key stream about plain image
% Generate initial state values of chaotic system based on initial key key_image, 
% produce chaotic sequences k1, k2, k3, k4
%% check s vector process
% Generate binary encryption key key2 based on chaotic sequence k2
T8 = dctmtx(8);
T8_tm = T8';
T16 = dctmtx(16);
T16_tm = T16';
for bx=1:block16_num
    if(s(bx)=='1')
        block16(:,:,bx) = T16*block16(:,:,bx)*T16_tm;
        % Perform coefficient redistribution process on block16(:,:,bx) based on key2
    else
        block16(1:8,1:8,bx) = T8*block16(1:8,1:8,bx)*T8_tm;
        block16(1:8,9:16,bx) = T8*block16(1:8,9:16,bx)*T8_tm;
        block16(9:16,1:8,bx) = T8*block16(9:16,1:8,bx)*T8_tm;
        block16(9:16,9:16,bx) = T8*block16(9:16,9:16,bx)*T8_tm;
    end
end
%% quantization process
QT = [16 11 10 16 24 40 51 61
    12 12 14 19 26 58 60 55
    14 13 16 24 40 57 69 56
    14 17 22 29 51 87 80 62
    18 22 37 56 68 109 103 77
    24 35 55 64 81 104 113 92
    49 64 78 87 103 121 120 101
    72 92 95 98 112 100 103 99];
if(QF<50)
    SF = 5000/QF;
else
    SF = 200-2*QF; 
end
if QF<91
    for i=1:8
        for j=1:8
            QT(i,j) = median([1,round((QT(i,j)*SF+50)/100),255]); 
        end
    end
else
    for i=1:8
        for j=1:8
            QT(i,j) = median([1,floor((QT(i,j)*SF)/100),255]);
        end
    end
end

if QF>=91
    one_mtx = ones(8,8);
    for i=1:8
        for j=1:8
            if(QT(i,j)==1)  
                one_mtx(i,j)=0.5;  
            end
        end
    end
    for bx=1:block16_num
        if(s(bx)=='1')
            block16(:,:,bx) = blkproc(block16(:,:,bx),[8 8],'round(x.*P1)',one_mtx);
        end
    end
end

for bx=1:block16_num
    block16(1:8,1:8,bx) = round(block16(1:8,1:8,bx)./QT);
    block16(1:8,9:16,bx) = round(block16(1:8,9:16,bx)./QT);
    block16(9:16,1:8,bx) = round(block16(9:16,1:8,bx)./QT);
    block16(9:16,9:16,bx) = round(block16(9:16,9:16,bx)./QT);
end
%% zigzag 8x8 matrix to obtain DC and AC
block8_zigzag(block8_num,64)=0;
for bx=1:block16_num
    temp_bx = 4*bx-3;
    block8_zigzag(temp_bx,:) = zigzag8(block16(1:8,1:8,bx));
    block8_zigzag(1+temp_bx,:) = zigzag8(block16(1:8,9:16,bx));
    block8_zigzag(2+temp_bx,:) = zigzag8(block16(9:16,1:8,bx));
    block8_zigzag(3+temp_bx,:) = zigzag8(block16(9:16,9:16,bx));
end
%% 8x8 block permutation excluding DC
% Generate index vector key1 with length block8_num based on k1. Generate integer vector s2 with length max(m/8,n/8)
% Reshape key1 into index matrix s1 of size m/8 * n/8
% Perform cyclic scrambling on index matrix based on s2 to get final index matrix s1
% Perform scrambling of block distribution based on 1D degraded vector of 2D matrix in default column-wise order in MATLAB
%% DC coefficient XOR
pre_dc8 = 0;
for bx=1:block16_num
   if(s(bx)=='0')
      bx_temp = 4*bx-3;
      block8_zigzag(bx_temp,1) = bitxor(pre_dc8,block8_zigzag(bx_temp,1),'int16');
      block8_zigzag(1+bx_temp,1) = bitxor(block8_zigzag(bx_temp,1),block8_zigzag(1+bx_temp,1),'int16');
      block8_zigzag(2+bx_temp,1) = bitxor(block8_zigzag(1+bx_temp,1),block8_zigzag(2+bx_temp,1),'int16');
      block8_zigzag(3+bx_temp,1) = bitxor(block8_zigzag(2+bx_temp,1),block8_zigzag(3+bx_temp,1),'int16');
      pre_dc8 = block8_zigzag(3+bx_temp,1);
   end
end
%% encode DC by DPCM
for bx=block8_num:-1:2
    block8_zigzag(bx,1) = block8_zigzag(bx,1)-block8_zigzag(bx-1,1);
end
%% complement s vector by key,then and enbed it as well as last_bit vector into AC coefficient
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
zero_ac(block8_num)=0;
for bx=1:block8_num
   zero_ac(bx)=sum(block8_zigzag(bx,2:end)==0); 
end
[zero_ac_sort,zero_index] = sort(zero_ac,'descend');
k=1;
for bi=1:block8_num
    if zero_ac_sort==63
        continue;
    end
    for bj=2:64
        if block8_zigzag(zero_index(bi),bj)==0
            continue;
        elseif block8_zigzag(zero_index(bi),bj)==1
            block8_zigzag(zero_index(bi),bj)=1+s(k)-'0';
            k=k+1;
            if k>block16_num
                break;
            end
        elseif block8_zigzag(zero_index(bi),bj)==-1
            block8_zigzag(zero_index(bi),bj)=-1-s(k)+'0';
            k=k+1;
            if k>block16_num
                break;
            end
        elseif block8_zigzag(zero_index(bi),bj)>1
            block8_zigzag(zero_index(bi),bj)=block8_zigzag(zero_index(bi),bj)+1;
        else
            block8_zigzag(zero_index(bi),bj)=block8_zigzag(zero_index(bi),bj)-1;
        end
    end
    if k>block16_num
        break;
    end
end
%% group and swap DC coefficient
% Generate encryption key key3 with minimum length based on chaotic sequence k3 and characteristics of group scrambling
dcc = block8_zigzag(1:end,1);
temp_block8 = block8_num*0.5;
if(ITE>temp_block8)
    ITE=floor(temp_block8+1);
end
k=1;
for j=1:ITE
    temp = 2*j;
    for i=1:floor(block8_num/temp)
        if(key3(k)=='1')
            temp_i = temp*i;
            dcc((temp_i-temp+1):temp_i) = Swap(dcc((temp_i-temp+1):temp_i),j);
        end
        k=k+1;
    end
end
block8_zigzag(1:end,1) = dcc;
%% encode DC and AC by huffman table
% Encode DC and AC coefficients according to JPEG huffman coding rules
%% bit_seq complement and diffusion
% Generate encryption keys key5 and key6 using chaotic sequence k4, and generate encryption key key7 using chaotic sequence k2
% Perform selective complementation and diagonal diffusion on encoded stream based on key5, key6 and key7
%% JPEG bitstream
% Add JPEG header file, current code only includes the following parts
% SOI
% APP0
% DQT only include one
% SOF0
% DHT only include one DHT for DC and AC
% SOS
% EOI
% no some unuseful FF
bitstream_enc=[SOI,APP0,DQT,SOF0,DHT_DC,DHT_AC,SOS,bit_seq,EOI];

return;

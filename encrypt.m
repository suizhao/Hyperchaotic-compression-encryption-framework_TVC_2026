function [bitstream_enc,bit_seq,key_image,ite]=encrypt(I,key_image)
%% preprocess
CW = 0.5;
QF = 70;
ITE = 15;
[m,n]=size(I);
key_initial = SHA256('202503041149');
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
    QTY = [16 11 10 16 24 40 51 61
    12 12 14 19 26 58 60 55
    14 13 16 24 40 57 69 56
    14 17 22 29 51 87 80 62
    18 22 37 56 68 109 103 77
    24 35 55 64 81 104 113 92
    49 64 78 87 103 121 120 101
    72 92 95 98 112 100 103 99];
for bx=1:block16_num  
    matrix16 = block16(:,:,bx);
    % no-seg
    T = dctmtx(16);
    matrix = matrix16;
    matrix = T*matrix*T';
    m1 = matrix(1:8,1:8);
    m2 = matrix(1:8,9:end);
    m3 = matrix(9:end,1:8);
    m4 = matrix(9:end,9:end);
    m1 = round(m1./QTY);
    m2 = round(m2./QTY);
    m3 = round(m3./QTY);
    m4 = round(m4./QTY);
    [~,m1bit_len] = EntropyCode(m1);
    [~,m2bit_len] = EntropyCode(m2);
    [~,m3bit_len] = EntropyCode(m3);
    [~,m4bit_len] = EntropyCode(m4);
    L_noseg = m1bit_len+m2bit_len+m3bit_len+m4bit_len;
    m1 = round(m1*QTY);
    m2 = round(m2*QTY);
    m3 = round(m3*QTY);
    m4 = round(m4*QTY);
    matrix = [m1,m2;m3,m4];
    matrix = T'*matrix*T;
    mse_noseg = std2(matrix-matrix16);
    
    % seg
    T = dctmtx(8);
    m1 = matrix16(1:8,1:8);
    m2 = matrix16(1:8,9:end);
    m3 = matrix16(9:end,1:8);
    m4 = matrix16(9:end,9:end);
    m1 = T*m1*T';
    m2 = T*m2*T';
    m3 = T*m3*T';
    m4 = T*m4*T';
    m1 = round(m1./QTY);
    m2 = round(m2./QTY);
    m3 = round(m3./QTY);
    m4 = round(m4./QTY);
    [~,m1bit_len] = EntropyCode(m1);
    [~,m2bit_len] = EntropyCode(m2);
    [~,m3bit_len] = EntropyCode(m3);
    [~,m4bit_len] = EntropyCode(m4);
    L_seg = m1bit_len+m2bit_len+m3bit_len+m4bit_len;
    m1 = round(m1*QTY);
    m2 = round(m2*QTY);
    m3 = round(m3*QTY);
    m4 = round(m4*QTY);
    m1 = T'*m1*T;
    m2 = T'*m2*T;
    m3 = T'*m3*T;
    m4 = T'*m4*T;
    matrix = [m1,m2;m3,m4];
    mse_seg = std2(matrix-matrix16);
    
    d = mse_noseg - mse_seg;
    e = L_noseg - L_seg;
    cost = CW*(d-e)+e;
    if(cost<=0) 
        s(bx)='1';
        index_char1 = bx;
    end
end
%% generate key stream about plain image
key = key_image;
C = zeros(32,1);
for i=1:32 % get bytes
   C(i) = hex2dec(key((2*(i-1)+1):2*i));
end
T = mod(sum(C),256);
g(8) = 0;
for i=1:8
   D =  key((8*(i-1)+1):8*i);
   for j=1:8
      E = D(j);
      F = mod(floor(T)+hex2dec(E),10);
      g(i) = g(i)+(F+1)/10^j;
   end
end
X = 8*[g(1)+g(3) g(5)+g(7)];
U = 10*[g(2) g(4) g(6) g(8)];

iteration = 151000;
a = X(1); b = X(2); inil = U;
k1 = zeros(iteration,1);
k2 = zeros(iteration,1);
k3 = zeros(iteration,1);
k4 = zeros(iteration,1);
k1(1) = ini1(1);
k2(1) = ini1(2);
k3(1) = ini1(3);
k4(1) = ini1(4);
for v=2:iteration
    Arg = -atan(cos(k4(v-1))/sin(k4(v-1)));
    k1(v) = a*Arg;
    k2(v) = b*k1(v-1)+k2(v-1)*cos(2*pi*k1(v-1))/2;
    k3(v) = -a*k2(v-1)*k1(v-1);
    k4(v) = b*k3(v-1)+k4(v-1)*cos(2*pi*k3(v-1))/2;
end 
%% check s vector process
key2 = char(mod(floor(k2(1:448+index_char1)*10^10),2)+ '0'); 
T8 = dctmtx(8);
T8_tm = T8';
T16 = dctmtx(16);
T16_tm = T16';
zigzag16 = [1,17,2,3,18,33,49,34,19,4,5,20,35,50,65,81,66,51,36,21,6,7,...
        22,37,52,67,82,97,113,98,83,68,53,38,23,8,9,24,39,54,69,84,99,114,129,...
        145,130,115,100,85,70,55,40,25,10,11,26,41,56,71,86,101,116,131,146,161,177,...
        162,147,132,117,102,87,72,57,42,27,12,13,28,43,58,73,88,103,118,133,148,163,178,193,...
        209,194,179,164,149,134,119,104,89,74,59,44,29,14,15,30,45,60,75,90,105,120,135,150,165,180,195,...
        210,225,241,226,211,196,181,166,151,136,121,106,91,76,61,46,31,16,32,47,62,77,92,107,122,137,152,...
        167,182,197,212,227,242,243,228,213,198,183,168,153,138,123,108,93,78,63,48,64,79,94,109,124,139,...
        154,169,184,199,214,229,244,245,230,215,200,185,170,155,140,125,110,95,80,96,111,126,141,156,171,...
        186,201,216,231,246,247,232,217,202,187,172,157,142,127,112,128,143,158,173,188,203,218,233,248,249,234,...
        219,204,189,174,159,144,160,175,190,205,220,235,250,251,236,221,206,191,176,192,207,222,237,252,253,...
        238,223,208,224,239,254,255,240,256];
zigzag88 = [1,9,2,3,10,17,25,18,11,4,5,12,19,26,33,41,34,27,20,13,6,7,...
        14,21,28,35,42,49,57,50,43,36,29,22,15,8,16,23,30,37,44,51,58,59,...
        52,45,38,31,24,32,39,46,53,60,61,54,47,40,48,55,62,63,56,64];
for bx=1:block16_num
    if(s(bx)=='1')
        matrix16 = T16*block16(:,:,bx)*T16_tm;
        z256 = matrix16(zigzag16);
        key_temp = [];
        key_temp = key2(1+bx:448+bx);
        coeIndex = 1;
        index = 1;
        B1(8,8)=0;B2(8,8)=0;B3(8,8)=0;B4(8,8)=0;
        k=1;
        while coeIndex<=256
            x = z256(coeIndex:coeIndex+3);
            temp = bin2dec(key_temp(index:index+6));
            od = orders(mod(temp,24));
            for i=1:4
                if od(i)==1
                    B1(zigzag88(k))=x(i);
                elseif od(i)==2
                    B2(zigzag88(k))=x(i);
                elseif od(i)==3
                    B3(zigzag88(k))=x(i);
                else
                    B4(zigzag88(k))=x(i);
                end
            end
            k=k+1;
            index = index+7;
            coeIndex = coeIndex+4;
        end
        block16(:,:,bx) = [B1,B2;B3,B4];
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
[~,key1] = sort(k1(1:block8_num));
s2 = floor(k1(1:max(m/8,n/8)));
s1 = reshape(key1,m/8,n/8);
for i=1:m/8
    if s2(i)>0
        temp = s1(i,:);
        s1(i,s2(i)+1:end) = temp(1:end-s2(i));
        s1(i,1:s2(i)) = temp(end-s2(i)+1:end);
    elseif s2(i)<0
        temp = s1(i,:);
        s1(i,1:end+s2(i)) = temp(1-s2(i):end);
        s1(i,end+s2(i)+1:end) = temp(1:-s2(i));
    end
end
for i=1:n/8
    if s2(i)>0
        temp = s1(:,i);
        s1(s2(i)+1:end,i) = temp(1:end-s2(i));
        s1(1:s2(i),i) = temp(end-s2(i)+1:end);
    elseif s2(i)<0
        temp = s1(:,i);
        s1(1:end+s2(i),i) = temp(1-s2(i):end);
        s1(end+s2(i)+1:end,i) = temp(1:-s2(i));
    end
end
block8_zigzag(1:end,2:end) = block8_zigzag(s1(:),2:end);
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
key4 = mod(floor(k4(1:block16_num)*10^10),2);
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
len_key3 = 0;
temp_block8 = block16_num*2; 
if(ITE<=temp_block8)
    for i=1:ITE
        len_key3 = len_key3+floor(temp_block8/i);
    end
else
    for i=1:temp_block8
        len_key3 = len_key3+floor(temp_block8/i);
    end
    len_key3 = len_key3+1;
end
key3 = char(mod(floor(k3(1:len_key3)*10^10),2)+'0');
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
%% encrypt key_image using key_initial
key_image = bitxor(double(key_image),double(key_initial),'int16');
key_image = char(key_image);
ite=ITE;
%% encode DC and AC by huffman table
EOB_seq=dec2bin(10,4);
zrl_seq=dec2bin(2041,11);
bit_seq=[];
dc_len=0;
for bx=1:block8_num
    [DC_seq,DC_len] = DCEncoding(block8_zigzag(bx,1));
    dc_len=dc_len+DC_len;
    acc = block8_zigzag(bx,2:end);
    w=0;
    for v=63:-1:1
         if acc(v) ~= 0
            w=v;
            break;
         end
    end
    AC_seq=[];
    zero_number=0;

    if w ~= 0
      for j=1:w
          if (acc(j)==0 && zero_number<16)
              zero_number=zero_number+1;
          elseif (acc(j)==0 && zero_number==16)
              zero_number=1;
              AC_seq=[AC_seq,zrl_seq];
          elseif (acc(j)~=0 &&zero_number==16)
              [trt_seq]=ACEncoding(0,acc(j));
              AC_seq=[AC_seq,zrl_seq,trt_seq];
              zero_number=0;
          else 
              [trt_seq]=ACEncoding(zero_number,acc(j));
              AC_seq=[AC_seq,trt_seq];
              zero_number=0;
          end
      end
    end
    
    if w~=63
        bit_seq=[bit_seq,DC_seq,AC_seq,EOB_seq];
    else
        bit_seq=[bit_seq,DC_seq,AC_seq];
    end
end
%% bit_seq complement and diffusion
len_bit_seq = length(bit_seq);
num_36bit = floor(len_bit_seq/256);
[~,key5] = sort(k4(1:num_36bit)); 
key6 = mod(floor(k4(1:num_36bit)*10^10),2);
block_9int(64,num_36bit)=0;
for i= 1:num_36bit
    temp_36bit = bit_seq(256*(i-1)+1:256*i);
    for j=1:64
        block_9int(j,i) = bin2dec(temp_36bit((j-1)*4+1:j*4));
    end
end
clear temp_36bit;clear len_bit_seq;
block_9int(:,1:end) = block_9int(:,key5);
for i=1:num_36bit
    if key6(i)==1
        block_9int(:,i) = 15-block_9int(:,i);
    end
end
block_9int = block_9int';
key7 = floor(k2(1:num_36bit)*10^10);
[block_9int(1,:),block_9int(2:end-1,1),block_9int(end,1:end),block_9int(2:end-1,end)]...
    = boundary_diffusion(block_9int(1,:),block_9int(2:end-1,1),block_9int(end,1:end),block_9int(2:end-1,end),key7);
for i=2:num_36bit-1
    for j=2:63
        if mod(i+j,2)==1
            block_9int(i,j) = mod(block_9int(i,j)+block_9int(i,j-1)+block_9int(i+1,j)+key7(i),16);
        else
            block_9int(i,j) = mod(block_9int(i,j)+block_9int(i,j+1)+block_9int(i-1,j)+key7(i),16);
        end
    end
end
block_9int = block_9int';

for i=1:num_36bit
    temp = dec2bin(block_9int(:,i),4);
    tempv = 256*(i-1);
    for j=1:64
        bit_seq(tempv+(j-1)*4+1:tempv+j*4) = temp(j,:);
    end
end
clear temp;clear tempv;
%% JPEG bitstream
% SOI
    SOI = '1111111111011000'; % 0xFFD8
% APP0
    APP0 = '111111111110000000000000000100000100101001000110010010010100011000000000000000010000000100000000000000010000000000000001000000000000000000000000';
% DQT only include one
    if QF>23
        info_QT = '00000000';
        len_seg = dec2bin(0x0043,16); 
        bit_QT(512)='0';
        for i = 1:64
            bit_QT(8*(i-1)+1:8*(i-1)+8) = dec2bin(QT(i),8);
        end
    else
        info_QT = '00010000'; 
        len_seg = dec2bin(0x0083,16);
        bit_QT(1024)='0'; % 64*16
        for i = 1:64
            bit_QT(16*(i-1)+1:16*(i-1)+16) = dec2bin(QT(i),16);
        end
    end
    DQT = [dec2bin(0xFFDB,16),len_seg,info_QT,bit_QT];
% SOF0
    SOF0 = ['1111111111000000000000000000101100001000',dec2bin(m,16),dec2bin(n,16),...
        '00000001000000010010001000000000']; 
% DHT only include one DHT for DC and AC
    DHT_DC = '111111111100010000000000000111110000000000000000000000010000010100000001000000010000000100000001000000010000000100000000000000000000000000000000000000000000000000000000000000000000000100000010000000110000010000000101000001100000011100001000000010010000101000001011';
    DHT_AC = '111111111100010000000000101101010000100000000000000000100000000100000011000000110000001000000100000000110000010100000101000001000000010000000000000000000000000110000000000000010000001000000011000000000000010000010001000001010001000000100001001100010100000100000110000100110101000101100010000000000010001001110001000101000011001010000001100100011010001000000000001000110100001010110001110000010001010101010010110100100000000000100100001100110110001001110010100000100000100100001010000000000001011100011000000110010001101000100101001001100010011100000000001010010010101000110100001101010011011000110111001110000000000000111010010000110100010001000101010001100100011101001000000000000100101001010011010101000101010101010110010101110101100000000000010110100110001101100100011001010110011001100111011010000000000001101010011100110111010001110101011101100111011101111000000000000111101010000011100001001000010110000110100001111000100000000000100010101001001010010011100101001001010110010110100110000000000010011001100110101010001010100011101001001010010110101000000000001010100010101001101010101011001010110011101101001011100000000000101101111011100010111001101110101100001011000011110010000000000011000110110001111100100011001001110010101101001011010000000000001101010111010110110101111101100011011001110110101110000000000000111000111110010011100101111001101110011111101000111010000000000011110001111100101111001111110100111101011111011011111000000000001111100111111010';
% SOS
    SOS = '11111111110110100000000000001000000000010000000100000000000000000011111100000000';
% EOI
    EOI = '1111111111011001'; 
% no some unuseful FF
bitstream_enc=[SOI,APP0,DQT,SOF0,DHT_DC,DHT_AC,SOS,bit_seq,EOI];
return;
clc;clear;close all;

I = rgb2gray(imread('.\Baboon.tiff'));
% To simplify, the initial key is not generated from the original image here.
key_image = '8f7e9d8c7b6a5f4e3d2c1b0a9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e';
CW = 0.5;
QF = 70;
ITE = 15;

%% visual safty
[enc_stream,dc_ac,key,ite] = encryptFramework(double(I),CW,QF,ITE,key_image);
% load standard JPEG decompression result without encoded bitstreams protection
load('I_without.mat');
[img_restruct] = decryptFramework(enc_stream,key,ite);
img_res = img_restruct+128;
PSNR = [psnr(uint8(img_res),I),psnr(uint8(I_without),I)]
SSIM = [ssim(uint8(img_res),I),ssim(uint8(I_without),I)]
figure;
subplot(1,3,1); imshow(I,[]);
subplot(1,3,2); imshow(I_without,[]); % standard JPEG decoded image(encrypted image) without encoded bitstreams protection
subplot(1,3,3); imshow(img_res,[]);% completely decrypted image

%% outline attack
[EAC,NCC,PLZ] = energy_ac_coefficients_framework(double(I),CW,QF,key_image,0);% with ac permutation
[EAC_w,NCC_w,PLZ_w] = energy_ac_coefficients_framework(double(I),CW,QF,key_image,1);% without ac permutation
figure;
subplot(3,3,4);
imshow(EAC, [],'InitialMagnification', 'fit');
title('EAC');
subplot(3,3,5);
imshow(NCC, [],'InitialMagnification', 'fit');
title('NCC');
subplot(3,3,6);
imshow(PLZ, [],'InitialMagnification', 'fit');
title('PLZ');
subplot(3,3,7);
imshow(EAC_w, [],'InitialMagnification', 'fit');
title('EAC_w');
subplot(3,3,8);
imshow(NCC_w, [],'InitialMagnification', 'fit');
title('NCC_w');
subplot(3,3,9);
imshow(PLZ_w, [],'InitialMagnification', 'fit');
title('PLZ_w');
subplot(3,3,2);
% figure
imshow(I, [],'InitialMagnification', 'fit');

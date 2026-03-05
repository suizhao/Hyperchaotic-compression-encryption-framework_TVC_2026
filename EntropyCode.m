function [blockbit_seq,blockbit_len] = EntropyCode(matrix88)
    % obtain zigzag sequence about 8*8 block
    k1=zigzag8(matrix88);

    % search index about last no-zero value
    % if 63 ACs is zeros,satisfy w = 1.
    w=1;
    v=64;
    while v ~= 0
         if k1(v) ~= 0
            w=v;
            break;
         end
         v=v-1;
    end
    
   % delete rear successive zero value
   e(w) = 0;
   for i=1:w
       e(i)=k1(i);
   end

   % coding DC using Huffman code
   [DC_seq]=DCEncoding(e(1));

   % coding AC using Huffman code
   % zerolen is numbers of successive zero
   % amplitude is adjacent no-zero value after zerolen zeros
   % end_seq = 1010 is EOB
   end_seq=dec2bin(10,4);
   AC_seq=[];
   blockbit_seq=[];
   zrl_seq=[];
   trt_seq=[];
   zerolen=0;
   zeronumber=0; % successive zero max is 15,min is 0.

   if numel(e) ~= 1
      for i=2:w
          if ( e(i)==0 && zeronumber<16)
              zeronumber=zeronumber+1;
          % cope with 16 succesive zeros
          elseif (e(i)==0 && zeronumber==16)
              bit_seq=dec2bin(2041,11);
              zeronumber=1;
              AC_seq=[AC_seq,bit_seq];
          elseif (e(i)~=0 &&zeronumber==16)
              zrl_seq=dec2bin(2041,11);
              amplitude=e(i);
              [trt_seq]=ACEncoding(0,amplitude);
              bit_seq=[zrl_seq,trt_seq];
              AC_seq=[AC_seq,bit_seq];
              zeronumber=0;
          elseif(e(i))
              zerolen=zeronumber;          
              amplitude=e(i);
              zeronumber=0;
              [bit_seq]=ACEncoding(zerolen,amplitude);
              AC_seq=[AC_seq,bit_seq];
          end
      end
   else
       AC_seq = [];
   end
   
   if w==64
       blockbit_seq=[DC_seq,AC_seq];
   else
       blockbit_seq=[DC_seq,AC_seq,end_seq];
   end
   blockbit_len=length(blockbit_seq);

return;
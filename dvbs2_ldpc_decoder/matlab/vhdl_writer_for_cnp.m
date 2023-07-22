clear;
clc;
close all;

z = 45;
codes = 1:10;
%% 
EdgeCnts = [];
nbs = [];
for code_sel = codes
    Hb = Convert2Hb(code_sel,z);
    EdgeCnts = [EdgeCnts sum(sum(sum(Hb > -1)))];
    
    [qwe nb asd] = size(Hb);
    nbs = [nbs nb];
end
MaxEdgeCnt = 2^ceil( log2(max(EdgeCnts) + max(nbs)) );
%% CNP edge memories
TotEdgeCntr = 0;

fidin = fopen('CNP_INPUT_Hb.vhd','wt');
fidout = fopen('CNP_OUTPUT_Hb.vhd','wt');
for code_sel = codes
    disp(code_sel)
    Hb = Convert2Hb(code_sel,z);
    %%
    [mb nb asd] = size(Hb);
    kb= nb-mb;
    %% Hbm matrisini satir satir tarayarak -1 olmayan rotasyonlari ve bunlarin
    % bagli oldugu node'lari vektor olarak kaydetme
    % FPGA belleginde edge llr'lari kaydedilirken de bu sira kullanilmistir
    H = [];

    edgeCntr = 0;
    for i = 1:mb
        for j = 1:nb
            for k = 1:3
                if Hb(i,j,k) ~= -1
                    edgeCntr = edgeCntr + 1;
                    H(edgeCntr,:) = [i j Hb(i,j,k)];
                end
            end
        end
    end
    EdgeCnt = edgeCntr;
    TotEdgeCntr = TotEdgeCntr + edgeCntr;
    %% Her bir CN'e kac adet edge bagli oldugunu bulma
    CN_EdgeCount = zeros(mb,1);
    for i=1:mb
        CN_EdgeCount(i) = sum(sum( Hb(i,:,:) > -1 ));
    end
    [asd CN_Index]= sort(CN_EdgeCount); % vhdldeki processing en az sayida edge'e sahip VN'den baslayacaktir
    %% CN processing icin kullanilacak input ConnectionMap
    for i = CN_Index'
        for k = 1:length(H)
            if H(k,1) == i
                fprintf(fidin, ',%4d',k-1);
                fprintf(fidout, '%4d*%4d+%4d, ', z-H(k,3), MaxEdgeCnt, k-1);
            end
        end
        fprintf(fidin, '+%4d', MaxEdgeCnt);
        fprintf(fidin, '\n');
        fprintf(fidout, '\n');
    end
    fprintf(fidin, '\n');
    fprintf(fidout, '\n');
    %%
end
fclose('all');
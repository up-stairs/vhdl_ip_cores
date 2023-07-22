clear;
clc;
close all;

z = 45;
codes = 1:10;
%% 
EdgeCnts = [];
nbs = [];
kbs = [];
vnp_start = [];
vnp_end = [];
cnp_start = [];
cnp_end = [];
vn_max_edge = [];
cn_max_edge = [];
for code_sel = codes
    Hb = Convert2Hb(code_sel,z);
    
    vn_max_edge = max( [vn_max_edge (sum(Hb(:,:,1) > -1)+sum(Hb(:,:,2) > -1)+sum(Hb(:,:,3) > -1))] );
    cn_max_edge = max( [cn_max_edge; (sum(Hb(:,:,1) > -1,2)+sum(Hb(:,:,2) > -1,2)+sum(Hb(:,:,3) > -1,2))] );
    
    vnp_start = [vnp_start sprintf('%4d, ', sum(EdgeCnts)+sum(nbs))];
    cnp_start = [cnp_start sprintf('%4d, ', sum(EdgeCnts))];
    EdgeCnts = [EdgeCnts sum(sum(sum(Hb > -1)))];
    
    [mb nb asd] = size(Hb);
    nbs = [nbs nb];
    kbs = [kbs nb-mb];
    
    vnp_end = [vnp_end sprintf('%4d, ', sum(EdgeCnts)+sum(nbs))];
    cnp_end = [cnp_end sprintf('%4d, ', sum(EdgeCnts))];
end
MaxEdgeCnt = 2^ceil( log2(max(EdgeCnts) + max(nbs)) );

fprintf('\nedge cnt ');
fprintf('%4d*360/z,',EdgeCnts/(360/z));
fprintf('\nkb ');
fprintf('%4d*360/z,',kbs/(360/z));
fprintf('\n');
fprintf('start_addr for vnp %s',vnp_start);
fprintf('\n');
fprintf('end_addr for vnp %s',vnp_end);
fprintf('\n');
fprintf('start_addr for cnp %s',cnp_start);
fprintf('\n');
fprintf('end_addr for cnp %s',cnp_end);
fprintf('\n');
%% VNP edge memories
SPECIAL_INDEX = [];
TotEdgeCntr = 0;

fidin = fopen('VNP_INPUT_Hb.vhd','wt');
fidout = fopen('VNP_OUTPUT_Hb.vhd','wt');
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
    TotEdgeCntr = TotEdgeCntr + edgeCntr + nb;
    %% Her bir VN'e kac adet edge bagli oldugunu bulma
    VN_EdgeCount = zeros(nb,1);
    for j=1:nb
        VN_EdgeCount(j) = sum(sum( Hb(:,j,:) > -1 ));
    end
    [asd VN_Index]= sort(VN_EdgeCount); % vhdldeki processing en az sayida edge'e sahip VN'den baslayacaktir
    %%
    for j = VN_Index'
        for k = 1:length(H)
            if H(k,2) == j
                if H(k,1) == 1 && H(k,2) == nb % this edge requires special treatment
                    SPECIAL_INDEX = [SPECIAL_INDEX k-1];
                end
                fprintf(fidin,'%4d, ',k-1);
                fprintf(fidout,'%4d*%4d+%4d, ', H(k,3), MaxEdgeCnt, k-1);
            end
        end
        fprintf(fidin,'%4d+%4d, ', MaxEdgeCnt, j-1+EdgeCnt);
        fprintf(fidin,'\n');
        fprintf(fidout,'%4d*%4d+%4d, ', 0, MaxEdgeCnt, j-1+EdgeCnt);
        fprintf(fidout,'\n');
    end
    fprintf(fidin,'\n');
    fprintf(fidout,'\n');
    %%
end
fclose('all');
fprintf('\nSPECIAL_INDEX');
fprintf('%4d,',SPECIAL_INDEX)
fprintf('\n');
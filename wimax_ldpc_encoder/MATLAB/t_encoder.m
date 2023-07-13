clear;
clc
%% delete the contents of the txt files
fid = fopen('u.txt','wt');
fid = fopen('c.txt','wt');
fclose('all');
%%
codes = round(rand(1,100)*5);
% codes = 0;
fid = fopen('codes.txt','wt');
fprintf(fid,'%d\n',codes);
fclose('all');
%%
z = 60;
for code_sel = codes
    switch code_sel
        case 0
            load H_r1_2
        case 1
            load H_r2_3A
        case 2
            load H_r2_3B
        case 3
            load H_r3_4A
        case 4
            load H_r3_4B
        case 5
            load H_r5_6
    end
    %%
    if code_sel ~= 1
        Hm = floor(Hbm*z/96);
    else
        Hm = Hbm;
        Hm(find(Hbm >= 0)) = mod(Hbm(find(Hbm >= 0)),z); % 2/3A matrisi bu sekilde hesaplaniyor
    end

    [mb nb] = size(Hbm);
    kb = rate * nb;
    mb = nb-kb;

    K = z*kb;
    N = z*nb;
    M = N-K;
    %% write the systematic bits to file
    u = round(rand(K,1));  
    fid = fopen('u.txt','at');
    fprintf(fid,'%d\n',u);
    fclose('all');
    %% encode
    c = bit_accurate_hdl_encoder(u,z,Hm);
    %% write the parity bits to file
    fid = fopen('c.txt','at');
    fprintf(fid,'%d\n',c(K+1:end));
    fclose('all');
    %% print the selected code to screen
    fprintf('%d \n',code_sel);
end
fclose('all');
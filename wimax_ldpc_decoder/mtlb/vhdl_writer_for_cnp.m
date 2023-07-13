clear;
clc;
close all;

%%
for code_sel = 0:5
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
    fprintf('%2d, ',sum(sum(Hbm > -1)))
end
%% CNP input memory    
clear;
clc;
close all;

fprintf('(\n')
for code_sel = 0:5
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
    [mb nb] = size(Hbm);
    kb= nb-mb;
    %% Hbm matrisini satir satir tarayarak -1 olmayan rotasyonlari ve bunlarin
    %% bagli oldugu node'lari vektor olarak kaydetme
    %% FPGA belleginde edge llr'lari kaydedilirken de bu sira kullanilmistir
    ConnectionMap = [];

    k = 1;
    for i = 1:mb
        for j = 1:nb
            if Hbm(i,j) ~= -1
                ConnectionMap(k,:) = [i j Hbm(i,j)];
                k = k + 1;
            end
        end
    end
    %% Her bir CN'e kac adet edge bagli oldugunu bulma
    CN_EdgeCount = zeros(mb,1);
    for i=1:mb
        Indices = find( Hbm(i,:) >=0 );
        CN_EdgeCount(i) = sum( Hbm(i,:) > -1 );
    end
    [CN_EdgeCount CN_Index]= sort(CN_EdgeCount); % vhdldeki processing en az sayida edge'e sahip VN'den baslayacaktir
    %% CN processing icin kullanilacak input ConnectionMap
    for i = CN_Index'
        for k = 1:length(ConnectionMap)
            if ConnectionMap(k,1) == i
                fprintf(', %2d',k-1)
            end
        end
        fprintf('+%3d',128) %104=128-24
        fprintf('\n');
    end
    for k = sum(sum(Hbm > -1))+1:128
        fprintf(',%d',0)
    end
    fprintf('\n');
    %%
end
%% CNP output memory   
clear;
clc;
close all;

fprintf('(\n')
for code_sel = 0:5
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
    [mb nb] = size(Hbm);
    kb= nb-mb;
    %% Hbm matrisini satir satir tarayarak -1 olmayan rotasyonlari ve bunlarin
    %% bagli oldugu node'lari vektor olarak kaydetme
    %% FPGA belleginde edge llr'lari kaydedilirken de bu sira kullanilmistir
    ConnectionMap = [];

    k = 1;
    for i = 1:mb
        for j = 1:nb
            if Hbm(i,j) ~= -1
                ConnectionMap(k,:) = [i j Hbm(i,j)];
                k = k + 1;
            end
        end
    end
    %% Her bir CN'e kac adet edge bagli oldugunu bulma
    CN_EdgeCount = zeros(mb,1);
    for i=1:mb
        Indices = find( Hbm(i,:) >=0 );
        CN_EdgeCount(i) = sum( Hbm(i,:) > -1 );
    end
    [CN_EdgeCount CN_Index]= sort(CN_EdgeCount); % vhdldeki processing en az sayida edge'e sahip VN'den baslayacaktir
    %% VN processing icin kullanilacak input ConnectionMap
    for i = CN_Index'
        for k = 1:length(ConnectionMap)
            if ConnectionMap(k,1) == i
                if code_sel ~= 1
                    fprintf('(z-(%2d*z/96))*128+%2d, ',ConnectionMap(k,3),k-1)
                else
                    fprintf('(z-(%2d mod z))*128+%2d, ',ConnectionMap(k,3),k-1)
                end
            end
        end
        fprintf('\n');
    end
    for k = sum(sum(Hbm > -1))+1:128
        fprintf('%d,',0)
    end
    fprintf('\n');
    %%
end
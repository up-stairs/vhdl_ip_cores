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
%% VNP input memory    
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
    %% Her bir VN'e kac adet edge bagli oldugunu bulma
    VN_EdgeCount = zeros(nb,1);
    for j=1:nb
        Indices = find( Hbm(:,j) >=0 );
        VN_EdgeCount(j) = sum( Hbm(:,j) > -1 );
    end
    [VN_EdgeCount VN_Index]= sort(VN_EdgeCount); % vhdldeki processing en az sayida edge'e sahip VN'den baslayacaktir
    %% VN processing icin kullanilacak input ConnectionMap
    for j = VN_Index'
        for k = 1:length(ConnectionMap)
            if ConnectionMap(k,2) == j
                fprintf('%2d, ',k-1)
    %             fprintf('%2d, ',ConnectionMap(k,3))
            end
        end
        fprintf('%2d+%3d, ',j-1+104,128) %104=128-24
        fprintf('\n');
    end
    for k = sum(sum(Hbm > -1))+24+1:128
        fprintf('%d,',0)
    end
    fprintf('\n');
    %%
end
%% VNP output memory   
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
    %% Her bir VN'e kac adet edge bagli oldugunu bulma
    VN_EdgeCount = zeros(nb,1);
    for j=1:nb
        Indices = find( Hbm(:,j) >=0 );
        VN_EdgeCount(j) = sum( Hbm(:,j) > -1 );
    end
    [VN_EdgeCount VN_Index]= sort(VN_EdgeCount); % vhdldeki processing en az sayida edge'e sahip VN'den baslayacaktir
    %% VN processing icin kullanilacak input ConnectionMap
    for j = VN_Index'
        for k = 1:length(ConnectionMap)
            if ConnectionMap(k,2) == j
                if code_sel ~= 1
                    fprintf('(%2d*z/96)*128+%2d, ',ConnectionMap(k,3),k-1)
                else
                    fprintf('(%2d mod z)*128+%2d, ',ConnectionMap(k,3),k-1) % 2/3 A kodu icin
                end
            end
        end
        if code_sel ~= 1
            fprintf('(%2d*z/96)*128+%2d, ',0,j-1+104)
        else
            fprintf('(%2d mod z)*128+%2d, ',0,j-1+104)
        end
        fprintf('\n');
    end
    for k = sum(sum(Hbm > -1))+24+1:128
        fprintf('%d,',0)
    end
    fprintf('\n');
    %%
end
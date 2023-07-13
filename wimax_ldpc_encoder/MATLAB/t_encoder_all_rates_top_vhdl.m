clear;
clc
fclose('all');

code_sel = 0;
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
z = 32;
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
%%
fid = fopen('iw.txt','rt');
U = fscanf(fid,'%d\n');
fid = fopen('cw.txt','rt');
C = fscanf(fid,'%d\n');

for i = 1:20
    u = U( (i-1)*K+1:i*K );
    c = C( (i-1)*M+1:i*M );
    
    cw = bit_accurate_hdl_encoder(u,z,Hm);
    
    fprintf('%d ',sum(c ~= cw(K+1:N)))
    locs{i} = find(c ~= cw(K+1:N));
end
fclose('all');
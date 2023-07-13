% VHDL kodunda kullanilan yonteme gore implement edildi
function [iw iter] = decoder_vhdl(cw,z,Hb,AbsMax)

nb = 24;
mb = length(Hb(:,1));
kb = nb - mb;

TotalEdges = length(find(Hb >= 0)); %find non-negative indices

y = reshape(cw,z,nb); %codeword matrix
%% Generate Edge Table for Check Node Processing
EdgeMap = [];

m = 1;
for i = 1:mb
    for j = 1:nb
        if Hb(i,j) ~= -1
            EdgeMap(m,:) = [i j Hb(i,j)];
            m = m + 1;
        end
    end
end
% Her bir CN'e kac adet edge bagli oldugunu bulma
CN_EdgeCount = zeros(mb,1);
for i=1:mb
    CN_EdgeCount(i) = sum( Hb(i,:) > -1 );
end
[CN_EdgeCount CN_Index]= sort(CN_EdgeCount); % vhdldeki processing en az sayida edge'e sahip VN'den baslayacaktir
% CN processing icin kullanilacak EdgeMap
CNP_EDGE_INDEX = zeros(TotalEdges,1);
CNP_RESTART = zeros(TotalEdges,1);
CNP_ROT = zeros(TotalEdges,1);

m = 1;
for i = CN_Index'
    for k = 1:length(EdgeMap)
        if EdgeMap(k,1) == i
            CNP_EDGE_INDEX(m) = k;
            CNP_ROT(m) = z-EdgeMap(k,3);
            m = m + 1;
        end
    end
    CNP_RESTART(m-1) = 1;
end
%% Generate Edge Table for Variable Node Processing
EdgeMap = [];

m = 1;
for i = 1:mb
    for j = 1:nb
        if Hb(i,j) ~= -1
            EdgeMap(m,:) = [i j Hb(i,j)];
            m = m + 1;
        end
    end
end
% Her bir VN'e kac adet edge bagli oldugunu bulma
VN_EdgeCount = zeros(nb,1);
for j=1:nb
    VN_EdgeCount(j) = sum( Hb(:,j) > -1 );
end
[VN_EdgeCount VN_Index]= sort(VN_EdgeCount); % vhdldeki processing en az sayida edge'e sahip VN'den baslayacaktir
% VN processing icin kullanilacak input EdgeMap
VNP_EDG_I = zeros(TotalEdges+nb,1);
VNP_RESTART = zeros(TotalEdges+nb,1);
VNP_ROT = zeros(TotalEdges,1);

m = 1;
for j = VN_Index'
    for k = 1:length(EdgeMap)
        if EdgeMap(k,2) == j
            VNP_EDG_I(m) = k;
            VNP_ROT(m) = EdgeMap(k,3);
            m = m + 1;
        end
    end
    VNP_EDG_I(m) = j+104;
    VNP_RESTART(m) = 1;
    m = m + 1;
end
%% Decoding
llr_mem = zeros( z , 128 ); % llr memory
hdd_mem = zeros( z , 128 ); % hard decision memory

llr_mem(:,105:128) = y;
for iter = 1:50
    %% variable node processing
    m1 = 0;
    p = 0;
    for n = 1:nb
        m2 = m1+1;
        while(1);
            m1 = m1 + 1;
            if VNP_RESTART(m1) == 1
                break;
            end
        end
        indices = VNP_EDG_I(m2:m1);

        llr_sum = sum( llr_mem(:,indices) , 2 );

        for l = indices(1:end-1)'
            p = p + 1;
            llr_mem( : , l ) = vec_rotate( llr_sum - llr_mem(:,l) , VNP_ROT(p) );
            hdd_mem( : , l ) = vec_rotate( llr_sum < 0 , VNP_ROT(p) );
        end
        p = p + 1;
        hdd_mem( : , indices(end) ) = 1*(llr_sum < 0);
    end
    llr_mem( llr_mem > +AbsMax ) = +AbsMax;
    llr_mem( llr_mem < -AbsMax ) = -AbsMax;
    
    iw = hdd_mem(:,104+(1:kb));
    iw = reshape(iw,1,kb*z);
    
    %% check node processing
    sign_mem = 1-2*(llr_mem < 0);
    
    m1 = 0;
    par = 0;
    p = 0;
    for m = 1:mb
        m2 = m1+1;
        while(1);
            m1 = m1 + 1;
            if CNP_RESTART(m1) == 1
                break;
            end
        end
        indices = CNP_EDGE_INDEX(m2:m1);

        min1_llr = zeros(z,1);
        min1_ind = zeros(z,1);
        min2_llr = zeros(z,1);
        for d = 1:z
            [B IX] = sort( abs(llr_mem(d,indices)) );
            min1_llr(d) = B(1);
            min1_ind(d) = indices(IX(1));
            min2_llr(d) = B(2);
        end
        
        sign_prod = prod(sign_mem(:,indices),2);

        for l = indices'
            Temp = zeros(z,1);
            for d = 1:z
                if min1_ind(d) ~= l
                    Temp(d) = min1_llr(d)*sign_prod(d)*sign_mem(d,l);
                else
                    Temp(d) = min2_llr(d)*sign_prod(d)*sign_mem(d,l);
                end
            end
            p = p + 1;
            llr_mem( : , l ) = vec_rotate( Temp-floor(Temp/4) , CNP_ROT(p) );
        end
        par = par + sum( mod( sum(hdd_mem(:,indices),2) , 2 ) );
    end
    llr_mem( llr_mem > +AbsMax ) = +AbsMax;
    llr_mem( llr_mem < -AbsMax ) = -AbsMax;
    if par == 0
        break
    end
end



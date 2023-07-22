
function [iw iter] = bit_accurate_hdl_decoder(cw,z,Hb,AbsMax)

nb = size(Hb(:,:,1),2);
mb = size(Hb(:,:,1),1);
kb = nb - mb;

%%
EdgeMap = [];

edgeCntr = 0;
for i = 1:mb
    for j = 1:nb
        for k = 1:3
            if Hb(i,j,k) ~= -1
                edgeCntr = edgeCntr + 1;
                EdgeMap(edgeCntr,:) = [i j Hb(i,j,k)];
            end
        end
    end
end
TotalEdges = edgeCntr;
%% Generate Edge Table for Check Node Processing
% Her bir CN'e kac adet edge bagli oldugunu bulma
CN_EdgeCount = zeros(mb,1);
for i=1:mb
    CN_EdgeCount(i) = sum( Hb(i,:,1) > -1 )+sum( Hb(i,:,2) > -1 )+sum( Hb(i,:,3) > -1 );
end
[CN_EdgeCount CN_Index]= sort(CN_EdgeCount); % vhdldeki processing en az sayida edge'e sahip VN'den baslayacaktir
% CN processing icin kullanilacak EdgeMap
CNP_EdgeMap = zeros(TotalEdges,3);
m = 1;
for i = CN_Index'
    for k = 1:length(EdgeMap)
        if EdgeMap(k,1) == i
            CNP_EdgeMap(m,1) = k;
            CNP_EdgeMap(m,2) = z-EdgeMap(k,3);
            if EdgeMap(k,1) == 1 && EdgeMap(k,2) == nb % this edge requires special treatment
                CNP_SpecialIndex = m;
            end
            m = m + 1;
        end
    end
    CNP_EdgeMap(m-1,3) = 1;
end
%% Generate Edge Table for Variable Node Processing
% Her bir VN'e kac adet edge bagli oldugunu bulma
VN_EdgeCount = zeros(nb,1);
for j=1:nb
    VN_EdgeCount(j) = sum( Hb(:,j,1) > -1 )+sum( Hb(:,j,2) > -1 )+sum( Hb(:,j,3) > -1 );
end
[VN_EdgeCount VN_Index]= sort(VN_EdgeCount); % vhdldeki processing en az sayida edge'e sahip VN'den baslayacaktir
% VN processing icin kullanilacak EdgeMap
VNP_EdgeMap = zeros(TotalEdges+nb,3);

m = 1;
for j = VN_Index'
    for k = 1:length(EdgeMap)
        if EdgeMap(k,2) == j
            VNP_EdgeMap(m,1) = k;
            VNP_EdgeMap(m,2) = EdgeMap(k,3);
            if EdgeMap(k,1) == 1 && EdgeMap(k,2) == nb % this edge requires special treatment
                VNP_SpecialIndex = m;
            end
            m = m + 1;
        end
    end
    VNP_EdgeMap(m,1) = j+TotalEdges;
    VNP_EdgeMap(m,3) = 1;
    m = m + 1;
end
%% Decoding
y = reshape(cw,z,nb); %codeword matrix

llr_mem = zeros( z , nb+TotalEdges ); % llr memory
hdd_mem = zeros( z , nb+TotalEdges ); % hard decision memory

llr_mem(:,TotalEdges+1:nb+TotalEdges) = y;
for iter = 1:20
    %% variable node processing
%     m1 = 0;
    p = 0;
%     for n = 1:nb
    for m = find(VNP_EdgeMap(:,3) == 1)'
%         m2 = m1+1;
%         while(1);
%             m1 = m1 + 1;
%             if VNP_EdgeMap(m1,3) == 1
%                 break;
%             end
%         end
%         indices = VNP_EdgeMap(m2:m1,1);
        indices = VNP_EdgeMap(p+1:m,1);

        llr_sum = sum( llr_mem(:,indices) , 2 );

        for l = indices(1:end-1)'
            p = p + 1;
            
            
            llr_mem( : , l ) = vec_rotate( llr_sum - llr_mem(:,l) , VNP_EdgeMap(p,2) );
            hdd_mem( : , l ) = vec_rotate( llr_sum < 0 , VNP_EdgeMap(p,2) );
            if p == VNP_SpecialIndex
                llr_mem( 1 , l ) = AbsMax;
                hdd_mem( 1 , l ) = 0;
            end
        end
        p = p + 1;
        hdd_mem( : , indices(end) ) = 1*(llr_sum < 0);
    end
    llr_mem( llr_mem > +AbsMax ) = +AbsMax;
    llr_mem( llr_mem < -AbsMax ) = -AbsMax;
    
    iw = hdd_mem(:,TotalEdges+1:TotalEdges+kb);
    iw = reshape(iw,1,kb*z);
    
    %% check node processing
    sign_mem = 1-2*(llr_mem < 0);
    
%     m1 = 0;
    par = 0;
    p = 0;
    for m = find(CNP_EdgeMap(:,3) == 1)'
%     for m = 1:mb
%         m2 = m1+1;
%         while(1);
%             m1 = m1 + 1;
%             if CNP_EdgeMap(m1,3) == 1
%                 break;
%             end
%         end
        indices = CNP_EdgeMap(p+1:m,1);

%         min1_llr = zeros(z,1);
%         min1_ind = zeros(z,1);
%         min2_llr = zeros(z,1);
%         for d = 1:z
%             [B IX] = sort( abs(llr_mem(d,indices)) );
%             min1_llr(d) = B(1);
%             min1_ind(d) = indices(IX(1));
%             min2_llr(d) = B(2);
%         end
        [B IX] = sort( abs(llr_mem(:,indices)), 2 );
        min1_llr = B(:,1);
        min1_ind = indices(IX(:,1));
        min2_llr = B(:,2);
        
        sign_prod = prod(sign_mem(:,indices),2);

        for l = indices'
            Temp = zeros(z,1);
%             for d = 1:z
%                 if min1_ind(d) ~= l
%                     Temp(d) = min1_llr(d)*sign_prod(d)*sign_mem(d,l);
%                 else
%                     Temp(d) = min2_llr(d)*sign_prod(d)*sign_mem(d,l);
%                 end
%             end
            ix = l ~= min1_ind;
            Temp(ix) = min1_llr(ix) .* sign_prod(ix) .* sign_mem(ix,l);
            ix = l == min1_ind;
            Temp(ix) = min2_llr(ix) .* sign_prod(ix) .* sign_mem(ix,l);
            
            p = p + 1;
            
            llr_mem( : , l ) = vec_rotate( Temp-floor(Temp/4) , CNP_EdgeMap(p,2) );
            if p == CNP_SpecialIndex
                llr_mem( z , l) = 0;
            end
        end
        par = par + sum( mod( sum(hdd_mem(:,indices),2) , 2 ) );
    end
    llr_mem( llr_mem > +AbsMax ) = +AbsMax;
    llr_mem( llr_mem < -AbsMax ) = -AbsMax;
    if par == 0
        break
    end
end



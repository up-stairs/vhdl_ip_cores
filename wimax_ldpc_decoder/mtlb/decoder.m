% VHDL kodunda kullanilan yonteme gore implement edildi
function [iw iter deb] = decoder(cw,z,Hbm)

nb = 24;
mb = length(Hbm(:,1));
kb = nb - mb;

cw = round( 127*cw / max(abs(cw)) );

y = reshape(cw,z,nb); %codeword matrix
%% create variable node control vector
d = 1;
for j = 1:nb
    indices = find( Hbm(:,j) >= 0 );
    rotation = Hbm(indices,j);
    
    L = length(indices);
    for l = 1:L
        vnc(d,[1 2 3]) = [j indices(l) rotation(l)];
        d = d + 1;
    end
end
%% Decoding
llr_mem = zeros( z , length(vnc(:,1)) ); % llr memory
hdd_mem = zeros( z , length(vnc(:,1)) ); % hard decision memory
for iter = 1:50
    iw = zeros(z,kb);
    %% variable node processing
    for n = 1:nb
        indices = find( vnc(:,1) == n );

        llr_sum = sum( llr_mem(:,indices) , 2 ) + y(:,n) ;

        for l = indices'
            llr_mem( : , l ) = vec_rotate( llr_sum - llr_mem(:,l) , vnc(l,3) );
            hdd_mem( : , l ) = vec_rotate( llr_sum < 0 , vnc(l,3) );
        end
        
        %% making decision
        if n <= kb
            iw(:,n) = (llr_sum < 0); %vec_rotate( (llr_sum < 0) , vnc(l,3) );
        end
    end
    if iter == 1
        deb = llr_mem;
    end
    %% check node processing
    sign_mem = 1-2*(llr_mem < 0);
    
    par = 0;
    for m = 1:mb
        indices = find( vnc(:,2) == m );

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
            llr_mem( : , l ) = 0.8*vec_rotate( Temp , z-vnc(l,3) );
        end
        par = par + sum( mod( sum(hdd_mem(:,indices),2) , 2 ) );
    end
    iw = reshape(iw,1,kb*z);
%     if sum(iw ~= DataIn) == 0
    if par == 0
        break
    end
end



% VHDL kodunda kullanilan yonteme gore implement edildi
function cw = bit_accurate_hdl_encoder(iw,z,Hb,hdl)

[mb nb] = size(Hb(:,:,1));
kb = nb-mb;
%%
if hdl == 0
    iw2 = iw;
    L = length(1:360/z:kb*z);
    for g = 0:360/z-1
        iw(g*L+(1:L)) = iw2(g+(1:360/z:kb*z));
    end
end
%%
U = reshape(iw,z,kb); %Information Matrix
P = zeros(z,mb); % parity vectors
p = zeros(z,1);
%% find the results of summation terms
for i = 1:mb
    for j = 1:kb
        if Hb(i,j,1) ~= -1
            rot = Hb(i,j,1);
            P(:,i) = mod( P(:,i) + vec_rotate(U(:,j) , rot) , 2 );
            p = mod( p + vec_rotate(U(:,j) , rot) , 2 );
        end
        if Hb(i,j,2) ~= -1
            rot = Hb(i,j,2);
            P(:,i) = mod( P(:,i) + vec_rotate(U(:,j) , rot) , 2 );
            p = mod( p + vec_rotate(U(:,j) , rot) , 2 );
        end
        if Hb(i,j,3) ~= -1
            rot = Hb(i,j,3);
            P(:,i) = mod( P(:,i) + vec_rotate(U(:,j) , rot) , 2 );
            p = mod( p + vec_rotate(U(:,j) , rot) , 2 );
        end
    end
end

%% find p0
for j = 2:z
    p(j) = mod( p(j)+p(j-1) , 2);
end
P(:,1) = mod( P(:,1)+[0; p(1:end-1)] , 2 );

%% parallel outputting
for i = 2:mb
    P(:,i) = mod( P(:,i) + P(:,i-1), 2 );
end


%% forming the codeword
if hdl == 0 
    cw = [iw2; reshape(P',mb*z,1)];
else % for comparing with the vhdl code
    cw = [iw; reshape(P,mb*z,1)];
end
% VHDL kodunda kullanilan yonteme gore implement edildi
function cw = bit_accurate_hdl_encoder(iw,z,Hbm)

[mb nb] = size(Hbm);
kb = nb-mb;
hb = Hbm(:,kb+1);
x = 1+find(hb(2:end-1) >= 0); %unpaired index
%%
u=reshape(iw,z,kb); %Information Matrix
v = zeros(z,mb); % parity vectors
%% find the results of summation terms
for i = 1:mb
    for j = 1:kb
        if Hbm(i,j) ~= -1
            v(:,1) = mod( v(:,1) + vec_rotate(u(:,j) , Hbm(i,j)) , 2 );
        end
    end
    if i ~= mb
        v(:,i+1) = v(:,1);
    end
end

% find v(0)
v(:,1) = mod( vec_rotate( v(:,1) , z-hb(x) ) , 2 );

%% find the rest of the parities
for i = 2:mb
    if i >= x+1
        v(:,i) = mod( v(:,i) + vec_rotate(v(:,1), hb(1)) + vec_rotate(v(:,1),hb(x)) , 2 );
    else
        v(:,i) = mod( v(:,i) + vec_rotate(v(:,1), hb(1)), 2 );
    end
end

%% forming the codeword
cw = [iw; reshape(v,mb*z,1)];
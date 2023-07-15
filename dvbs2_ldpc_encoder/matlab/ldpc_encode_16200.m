% DVB-S2 LDPC encoder
% Code length n=16200, information bits k=12600

function c = ldpc_encode_16200(info,A,V_DEG)
%load oa_parameters

N = 16200; % code block length
K = length(info);
p = zeros(N-K,1); % parity bits

M=360;
q = (N-K)/M;
num_of_groups = ceil(K/360);


% there are 35 groups of 360 information blocks.
% info(1),...info(360) -- first block, etc

for k=1:num_of_groups 
    for m=0:359
        for h=1:V_DEG(k)
            parity_index = 1+mod(A(k,h)+ mod(m,360)*q,N-K);
            data_index = 1+m+360*(k-1);
            p(parity_index) = mod(p(parity_index) + info(data_index),2);
        end
    end
end
for k=2:N-K
    p(k) = mod(p(k)+p(k-1),2);
end

c = [info; p];
return;


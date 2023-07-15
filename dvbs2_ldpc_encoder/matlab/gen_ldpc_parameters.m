% DVB-S2 LDPC encoder
% Code length n=16200 

function c = gen_ldpc_parameters(code)

if code==1
   rate=1/5;
elseif code==2
   rate=1/3;
elseif code==3
   rate=2/5;
elseif code==4
   rate=4/9;
elseif code==5
   rate=3/5;
elseif code==6
   rate=2/3;
elseif code==7
   rate=11/15;
elseif code==8
   rate=7/9;
elseif code==9
   rate=37/45;
elseif code==10
   rate=8/9;
end ;   
	

N = 16200;
K = round(N*rate);


p = zeros(N-K,1); % parity bits

coef_matrix_file=sprintf('coef_matrix_c%d.mat',code);
load( [coef_matrix_file]);

[kk mm]=size(A);

V_DEG=ones(kk,1)*mm;
for k=1:kk
    for m=1:mm
        if A(k,m)==-1
            V_DEG(k)=m-1;
            break
        end
    end
end

M=360;
q = (N-K)/M;
AA = A;
num_of_groups = ceil(K/M);

index=1;
for jj=1:num_of_groups
    for kk=1:V_DEG(jj)
        A2(index) = AA(jj,kk);
        index=index+1;
    end
 end 
A2=A2';

A1 = A2 ;
ROT = (floor(A1/q));
ADR = A1 - q*ROT;
ROT = mod(ROT,M);

par_start=numel(ROT)+1;

ROT(par_start:par_start + q*2-1) = 0;

for i=1:q
    ADR(par_start+i*2-2)=i-1;
    if i==q
        ADR(par_start+i*2-1)=0;
    else
        ADR(par_start+i*2-1)=i;
    end
end

CNU_ROM=[];
for i=1:q
    C_DEG(i) = size(find(ADR == i-1),1);                              
    CNU_ROM   = [CNU_ROM; sort(find(ADR ==i-1)  ,'ascend');  ];
end;

V_DEG(num_of_groups+1:num_of_groups+q)=2;



code_length = 16200;
info_length = K;

if code==1
    save params_1  rate code  info_length code_length AA V_DEG ADR ROT CNU_ROM C_DEG
elseif code==2
    save params_2  rate code  info_length code_length AA V_DEG ADR ROT CNU_ROM C_DEG
elseif code==3
    save params_3  rate code  info_length code_length AA V_DEG ADR ROT CNU_ROM C_DEG
elseif code==4
    save params_4  rate code  info_length code_length AA V_DEG ADR ROT CNU_ROM C_DEG
elseif code==5
    save params_5  rate code  info_length code_length AA V_DEG ADR ROT CNU_ROM C_DEG
elseif code==6
    save params_6  rate code  info_length code_length AA V_DEG ADR ROT CNU_ROM C_DEG
elseif code==7
    save params_7  rate code  info_length code_length AA V_DEG ADR ROT CNU_ROM C_DEG
elseif code==8
    save params_8  rate code  info_length code_length AA V_DEG ADR ROT CNU_ROM C_DEG
elseif code==9
    save params_9  rate code  info_length code_length AA V_DEG ADR ROT CNU_ROM C_DEG
elseif code==10
    save params_10 rate code  info_length code_length AA V_DEG ADR ROT CNU_ROM C_DEG
end;
    



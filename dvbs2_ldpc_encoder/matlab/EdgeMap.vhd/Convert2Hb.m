function [Hb EdgeCnt] = Convert2Hb(code,P)
% for rate 7/9 and 16200 code the order of messages in the memory for P=30
% is as follows
%%%%%%%%%%%%%%%%%%%
% 0         12          24          36          ..........      348      
% 360       372
% 720       732
% .
% .
% 12240     12252
% 1         13
% 361       373
% .
% .
% 12241     12253
% 2         14
% .
% .
% 12242     12254
% .
% .
% 11        23
% 371       383
% .
% .
% 12251     12263                   .............               12599
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Order of indices (0 throught 3599) for the LLR vector of parity digits 
% as they appear in the array RAM_p for m=12 (no_proc =30)
%%%%%%%%%%%
% p0    p120    .   .   .   p3480
% p1    p121                p3481
% p2    p122
% .     .
% .     .
% .     .
% p119  p239                p3599
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if code <= 10
    coef_matrix_file=sprintf('coef_matrix_c%d.mat',code);
    load( [coef_matrix_file]);
else
    coef_matrix_file=sprintf('coef_matrix_b%d.mat',code-10);
    load( [coef_matrix_file]);
end

if code <= 10
   N = 16200;
   R = size(A,1)/(N/360);
else
   N = 64800;
   R = size(A,1)/(N/360);
end ;
	
K = round(N*R);

nb = N/360;
kb = K/360;
q = (N-K)/360; % DVB'deki q = WiMAX'teki mb

S = (360/P); % serialization amount

% Hb = cell(q*S,nb*S);
Hb = -ones(q*S,nb*S,3);
EdgeCnt = 0;
for j = 1:kb
    for k = find(A(j,:) >= 0)
        for p = 0:S-1
            a = A(j,k)+p*q;

            rot = floor(a/(q*S));
            adr = 1+(a - rot*q*S);

            if Hb(adr,p*kb+j,1) == -1
                Hb(adr,p*kb+j,1) = rot;
            elseif Hb(adr,p*kb+j,2) == -1
                Hb(adr,p*kb+j,2) = rot;
            elseif Hb(adr,p*kb+j,3) == -1
                Hb(adr,p*kb+j,3) = rot;
            else
                disp('error:more than 3 connections')
            end

            EdgeCnt = EdgeCnt + 1;
        end
    end
end
for j = kb*S+1:nb*S
    Hb(j-kb*S,j,1) = 0;
    if j ~= nb*S
        Hb(j-kb*S+1,j,1) = 0;
    else
        Hb(1,j,1) = 1;
    end
%     EdgeCnt = EdgeCnt + 2;
end
clear
clc
%%
P = 30;
code = 12;

S = 360/P;
[Hb EdgeCnt] = Convert2Hb(code,P);

nb = size(Hb(:,:,1),2);
mb = size(Hb(:,:,1),1);
kb = nb-mb;

% writing systematic indices
for g = 0:S-1
    range = g:S:kb*P;
    for k = 0:kb/S-1;
        fprintf('(');
        
        temp = sprintf('%d, ',range(k*P+(1:P)));
        temp(end-1:end) = '';
        fprintf(temp);
           
        fprintf('),');
        fprintf('\n')
    end
end
% writing parity indices
for g = 0:mb-1
    fprintf('(');
    
    temp = sprintf('%d, ', g:mb:mb*P-1);
    temp(end-1:end) = '';
    fprintf(temp);
    
    fprintf('),');
    fprintf('\n')
end
%% check the hdl output
fid = fopen('p2s_hdl.txt','rt');
p2s_hdl = fscanf(fid,'%d\n');
fclose('all');

sum(p2s_hdl' ~= [0:kb*P-1 0:mb*P-1])
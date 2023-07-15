clear;
clc;
close all;

% stream = RandStream.getDefaultStream;
% reset(stream);

z = 180;
% delete the contents of the txt files
fid = fopen('u.txt','wt');
fid = fopen('c.txt','wt');
fid = fopen('y.txt','wt');
fclose('all');

codes = round(rand(1,40)*20)+1;
fid = fopen('codes.txt','wt');
fprintf(fid,'%d\n',codes);
fclose('all');
for code_sel = codes
    Hb = Convert2Hb(code_sel,z);
    
    rate = 1-size(Hb(:,:,1),1)/size(Hb(:,:,1),2);
    info_length = z*(size(Hb(:,:,1),2)-size(Hb(:,:,1),1));
    %% 
    u = round(rand(info_length,1));  
    fid = fopen('u.txt','at');
    fprintf(fid,'%d\n',u);
    
    c = bit_accurate_hdl_encoder(u,z,Hb,1);

    fid = fopen('c.txt','at');
    fprintf(fid,'%d\n',c(info_length+1:end));
    fclose('all');
    fprintf('%d \n',code_sel);


    % LastRandState = stream.State;
end
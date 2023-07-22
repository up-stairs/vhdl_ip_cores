clear;
clc;
close all;

stream = RandStream.getDefaultStream;
reset(stream);

z = 45;

% delete the contents of the txt files
fid = fopen('u.txt','wt');
fid = fopen('y.txt','wt');
fclose('all');

codes = round(rand(1,40)*9)+1;
% codes = [9 9 8 8];
fid = fopen('codes.txt','wt');
fprintf(fid,'%d\n',codes-1);
fclose('all');
for code_sel = codes
    Hb = Convert2Hb(code_sel,z);
    %%
    rate = 1-size(Hb(:,:,1),1)/size(Hb(:,:,1),2);
    info_length = z*(size(Hb(:,:,1),2)-size(Hb(:,:,1),1));
    %%
    M=8;%M-QAM
    modObj = modem.pskmod('M',M,'SymbolOrder','gray','InputType','Bit');

    modulatedsig = pskmod(0:M-1,M);
    Es=mean(abs(modulatedsig).^2);
    
    snr = 5.5 + 10*log10(rate)+ 10*log10(log2(M));
%     snr = 30;
    sigma   = sqrt(Es/(2*10^(snr/10)));        
    demodObj = modem.pskdemod(modObj,'DecisionType','LLR', 'NoiseVariance',sigma^2);
    %%
    u = round(rand(info_length,1));
    fid = fopen('u.txt','at');
    fprintf(fid,'%d\n',u);
    
    c = bit_accurate_hdl_encoder(u,z,Hb,1);
    %%
    x = modulate(modObj, c);

    y = x + sigma * (randn(length(x),1)+1i*randn(length(x),1)) ;

    llr = demodulate(demodObj, y);
    AbsMax = 2^(6-1)-1;
    llr( llr > +AbsMax ) = +AbsMax;
    llr( llr < -AbsMax ) = -AbsMax;
    
    fid = fopen('y.txt','at');
    fprintf(fid,'%d\n',round(llr));
    fclose('all');
    
    %%
    [iw iter] = bit_accurate_hdl_decoder(round(llr),z,Hb,AbsMax);
    
    %%
    fprintf('%2d %10g %2d %5d\n',code_sel, rate, iter, sum(iw~=u'));
end
clear;
clc;
close all;

stream = RandStream.getDefaultStream;
reset(stream);

z = 180;

    %%
    M=8;%M-QAM
    modObj = modem.pskmod('M',M,'SymbolOrder','gray','InputType','Bit');

    modulatedsig = pskmod(0:M-1,M);
    Es=mean(abs(modulatedsig).^2);
    
    rate = 0.5;
    snr = 7 + 10*log10(rate)+ 10*log10(log2(M));
    sigma   = sqrt(Es/(2*10^(snr/10)));        
    demodObj = modem.pskdemod(modObj,'DecisionType','LLR', 'NoiseVariance',sigma^2);
    %% create interleaver
    Intv = [];
    for k = 0:359
        Intv = [Intv k+(1:360:16200)];
    end
    %%
    
codes = round(rand(1,400)*9)+1;
for code_sel = codes
    Hb = Convert2Hb(code_sel,z);
    load(sprintf('params_%d.mat',code_sel))
    %%
    rate = 1-size(Hb(:,:,1),1)/size(Hb(:,:,1),2);
    info_length = z*(size(Hb(:,:,1),2)-size(Hb(:,:,1),1));
    code_length = z*size(Hb(:,:,1),2);
    %%
    u = round(rand(info_length,1));
    
    c0 = bit_accurate_hdl_encoder(u,z,Hb,0);
    c1 = bit_accurate_hdl_encoder(u,z,Hb,1);
    c1 = c1(Intv);
    %%
    x0 = modulate(modObj, c0);
    x1 = modulate(modObj, c1);

    w = sigma * (randn(length(x1),1)+1i*randn(length(x1),1)) ;
    
    y0 = x0 + w;
    y1 = x1 + w;

    llr0 = demodulate(demodObj, y0);
%     llr0(Intv) = llr0;
    llr1 = demodulate(demodObj, y1);
    llr1(Intv) = llr1;
    
    AbsMax = 2^(12-1)-1;
    %%
    [iw0 iter0,return_code] = ldpc_dec(ROT,ADR,V_DEG,C_DEG,CNU_ROM,llr0,50);
    iw0 = reshape(iw0',1,code_length);
    
    [iw1 iter1] = bit_accurate_hdl_decoder((llr1),z,Hb,AbsMax);
    
    %%
    fprintf('%d %10g %2d %2d %3d %3d\n',code_sel, rate, iter0, iter1, sum(iw0(1:info_length)~=u'), sum(iw1~=u'));
end
clear;
clc;
close all;

% stream = RandStream.getDefaultStream;
% reset(stream);

z = 36;

% delete the contents of the txt files
fid = fopen('u.txt','wt');
fid = fopen('y.txt','wt');
fclose('all');

codes = round(rand(1,40)*5);
fid = fopen('codes.txt','wt');
fprintf(fid,'%d\n',codes);
fclose('all');
for code_sel = codes
    switch code_sel
        case 0
            load H_r1_2
        case 1
            load H_r2_3A
        case 2
            load H_r2_3B
        case 3
            load H_r3_4A
        case 4
            load H_r3_4B
        case 5
            load H_r5_6
    end
    Hm = floor(Hbm*z/96);

    [mb nb] = size(Hbm);
    kb = nb - mb;
    info_length=nb*z*rate;

    unpaired_index = 1+find( Hm(2:mb-1,kb+1) >= 0 );
    unpaired_rotation = Hm(unpaired_index,kb+1);
    %%
    M=16;%M-QAM
    modObj = modem.qammod('M',M,'SymbolOrder','gray','InputType','Bit');

    modulatedsig = qammod(0:M-1,M);
    Es=mean(abs(modulatedsig).^2);
    %% 
    snr = 2*code_sel+3 + 10*log10(rate)+ 10*log10(log2(M));
    sigma   = sqrt(Es/(2*10^(snr/10)));        
    demodObj = modem.qamdemod(modObj,'DecisionType','LLR', 'NoiseVariance',sigma^2);

    u = round(rand(info_length,1));
    c = encoder(u,z,Hm,unpaired_rotation);

    x = modulate(modObj, c);

    y = x + sigma * (randn(length(x),1)+1i*randn(length(x),1)) ;

    llr = demodulate(demodObj, y);
    AbsMax = 2^(9-1)-1;
    llr( llr > +AbsMax ) = +AbsMax;
    llr( llr < -AbsMax ) = -AbsMax;

    fid = fopen('u.txt','at');
    fprintf(fid,'%d\n',u);
    fid = fopen('y.txt','at');
    fprintf(fid,'%d\n',round(llr));
    fclose('all');
    
    [iw iter] = decoder_vhdl(round(llr),z,Hm,AbsMax);
    
    fprintf('%d %d %d\n',code_sel, iter, sum(iw~=u'));


    % LastRandState = stream.State;

    %% write the input bits in hex format
%     for k = 0:kb-1
%         for m = 0:z/4-1
%             fprintf('%s',dec2hex([8 4 2 1]*u(k*z+m*4+(1:4))));
%         end
%         fprintf('\n')
%     end
end
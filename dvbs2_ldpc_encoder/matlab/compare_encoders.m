% Test DVB-S2 LDPC code 
% BPSK modulation, AWGN channel

clear;
clc;

% Set simulation parameters
max_iterations = 50;
EbN0db         = 4:.25:6;
ferrlim        = 64* 2.^(-floor((1:length(EbN0db))/3));        
max_tests      = 1000000;
ldpc_decode    = 1;


load params_5
n    = 16200;
k    = round(rate*n);

% coef_matrix_file=sprintf('coef_matrix_c%d.mat',code);
% load( [coef_matrix_file]);


Es   = 1;
M    = 8; % number of points  BPSK

% Load code parameters
% load_filename = sprintf('parameters_%d_%d', n,n-r);
% load([load_filename '.mat'], 'c_deg','c_neig_id','c_mailbox_id','v_deg','v_neig_id','v_mailbox_id');

% set/save state of random no gen
% rand('state',0); % set state to 0
% randn('state',0); % set state to 0
%rand('state', sum(100*clock));
save_state = rand('state');
%randn('state', sum(100*clock));
save_state_n = randn('state');


WrongDecoding= zeros(1,length(EbN0db));
maxerr     = zeros(1,length(EbN0db));
maxerrraw  = zeros(1,length(EbN0db));
maxcorerr  = zeros(1,length(EbN0db));
minuncorerr  = 10000* ones(1,length(EbN0db));
errs    = zeros(1,length(EbN0db));
rawerrs = zeros(1,length(EbN0db));
rawber  = zeros(1,length(EbN0db));
nferr   = zeros(1,length(EbN0db));
niterations= zeros(1,length(EbN0db));
min_w=16200;
max_useful_iteration= zeros(1,length(EbN0db));


% data_in = zeros(k,1);
% data_in(1) =  1;
for nEN = 1:length(EbN0db)
    snr = EbN0db(nEN) + 10*log10(rate)+10*log10(log2(M)) ;
    nframe(nEN)=0;
    while (nferr(nEN)<ferrlim(nEN) & nframe(nEN) <= max_tests) % | errs(nEN) < 100
        nframe(nEN)  = nframe(nEN) + 1;  
        data_in =round(rand(k,1));
%         data_in = [0;0;1;0;0;0;0;0;0;0;0;0; zeros(k-12,1)];
        %%
        c       = ldpc_encode_16200(data_in,AA,V_DEG); % transmitted vector     
        c_alp   = bit_accurate_hdl_encoder(data_in,180,Convert2Hb(5,180),0);
        sum(c(12601:end) == c_alp(12601:end))
        %%
        x       = modulate_8PSK(c);        
        sn      = 10^(snr/10) ;
        sigma   = 1/sqrt(2*sn);
        y       = x + (sigma * randn(length(x),1) + sqrt(-1)*sigma * randn(length(x),1));  
        llr_vect= demodulate_8PSK(y);
        data_out_hd = (sign(-llr_vect'+1e-10)+1)/2;

        


        if ldpc_decode == 1
            
            % Call decoder 
             %load hatali_codeword
             %data_in=c(1:k);
            
%             tic
           [hd_all, iteration_no,return_code] = ldpc_dec(ROT,ADR,V_DEG,C_DEG,CNU_ROM,llr_vect,max_iterations);
            hd_all = reshape(hd_all',code_length,1);
%            toc
            
            err= length(find(hd_all(1:k,end)~=data_in));
            rawerrors = length(find(data_out_hd(1:k)~=data_in));
            rawerrs(nEN) = rawerrs(nEN) + rawerrors;
            
            if rawerrors > maxerrraw(nEN) 
                maxerrraw(nEN)=rawerrors;
            end 
            
            
            
            if err>0
               save hatali_codeword c y 
               %return
               if return_code==1
                  WrongDecoding(nEN)=WrongDecoding(nEN)+1;
               end
               
               nferr(nEN) = nferr(nEN)+1;
               if err > maxerr(nEN)
                   maxerr(nEN)=err;
               end
               if rawerrors < minuncorerr(nEN) 
                   minuncorerr(nEN) = rawerrors;
               end
            else
                if rawerrors > maxcorerr(nEN) 
                    maxcorerr(nEN)=rawerrors ;
                end
                    
                if return_code==1
                    if max_useful_iteration(nEN)< iteration_no;
                        max_useful_iteration(nEN)= iteration_no;
                    end
                end
            end   
             
            errs(nEN) = errs(nEN) + err;
            niterations(nEN) = niterations(nEN) + iteration_no;
            

            if rem(nframe(nEN),10)==0 | nferr(nEN)==ferrlim(nEN)
               ber(nEN)    = errs(nEN)/nframe(nEN)/length(data_in);
               fer(nEN)    = nferr(nEN)/nframe(nEN);
               rawber(nEN) = rawerrs(nEN)/nframe(nEN)/length(data_in);
              
               average_iterations(nEN) = niterations(nEN)/nframe(nEN);

               fprintf('**BPSK, Es/N0 =%5.2f, *****  Eb/N0 = %5.2f db ******\n', snr, EbN0db(nEN));
               fprintf('Frame size = %d, rate %5.2f\n', length(data_in), rate);
               fprintf('%d frames transmitted, %d frames in error.\n', nframe(nEN), nferr(nEN));
               fprintf('MinW                   :%d\n', min_w);   
               fprintf('Bit Error Rate         :%8.4e\n', ber(nEN));
               fprintf('Frame Error Rate       :%8.4e\n', fer(nEN));
               fprintf('Raw Bit Error Rate     :%8.4e\n', rawber(nEN));
               fprintf('Max Err @LDPC in       :%d\n',  maxerrraw(nEN));   
               fprintf('Max Err @LDPC out      :%d\n', maxerr(nEN));   
               fprintf('Max Corrected Err      :%d\n', maxcorerr(nEN));   
               if(minuncorerr(nEN)<10000) 
               fprintf('Min Uncorrected Err    :%d\n', minuncorerr(nEN));                                    
               end
               if WrongDecoding(nEN)>0
               fprintf('# of Wrong Decoding    :%d\n', WrongDecoding(nEN));                                    
               end
               fprintf('Avg Iterations         :%8.4e\n', average_iterations(nEN));      
               fprintf('max_useful_iteration   :%d   \n', max_useful_iteration(nEN));                     

             end
       end

   end;
end

   


if ldpc_decode == 1
    figure(1);
    semilogy(EbN0db,ber,'-bo',EbN0db,fer,'-ro',EbN0db,rawber,'-ko');
    xlabel('Eb/N0 (dB)');
    ylabel('FER/BER');
    grid on;
%title(['LDPC kod ba?ar?m?'],'FontSize',12);
%text(5.6,0.05,'BER','FontSize',12);
end;

figure(2);
if ldpc_decode == 1
    % BPSK and QPSK has same EbN0-BER performance
    % SNR is calculated as if the modulation is QPSK
    snr = EbN0db + 10*log10(log2(M))+10*log10(rate);
    semilogy(snr,ber,'-bo',snr,fer,'-ro',snr,rawber,'-co');
    xlabel('Es/N0 (dB)');
    ylabel('FER/BER');
else
EbN0dB = EbN0db +10*log10(rate);
semilogy(EbN0dB,rawber,'-co');
xlabel('Eb/N0 (dB)');
ylabel('BER');
end;
grid on;




function [hd_all,iteration_no,return_code] = ldpc_dec(ROT,ADR,V_DEG,C_DEG,CNU_ROM,llr_in,max_iterations);


q = numel(C_DEG);     
number_of_groups=length(V_DEG)-q;


RAM_I = zeros(number_of_groups,360);
RAM_P = zeros(q,360);
for i=1:number_of_groups
    for j=1:360
       RAM_I(i,j) = llr_in((i-1)*360+j); % this is the channel likelihood (RAM_Channel)
    end;
end;

info_length = number_of_groups*360;
    
for i=1:q
   for j=1:360
      RAM_P(i,j) = llr_in(info_length+(j-1)*q+i);
%       RAM_P(i,j) = llr_in(info_length+(i-1)*360+j);
   end;
end;

llr_ch  = [RAM_I ; RAM_P];

last_edge_index = sum(V_DEG); 

llr_mem     =  zeros(last_edge_index ,360);
llr_mem_hd  =  zeros(last_edge_index ,360);


mem_size = length(ROT);

edge_mem = zeros(mem_size,360);

return_code = 0;
infnty=1e5;
max_c_degree = max(C_DEG);
hd=zeros(1,360);    
     



for iteration_no=1:max_iterations
   % compute messages from variable nodes to check nodes
   llr_index=1;
   for i=1:number_of_groups+q
       llr_sum = llr_ch(i,:);%channel value
        for j=1:V_DEG(i)
            llr_sum=llr_sum+llr_mem(llr_index,:);
            llr_index=llr_index+1;
        end

        llr_index=llr_index-V_DEG(i);
        hd=zeros(1,360);
        hd( llr_sum<=0 )=1;
        hd_all(i,:)=hd;

        for j=1:V_DEG(i)
            rot=ROT(llr_index);
            llr_val=llr_sum - llr_mem(llr_index,:);
%            if llr_index ==last_edge_index
%                llr_mem(llr_index,:)    = [infnty llr_val(1:359)] ;                      
%                llr_mem_hd(llr_index,:) = [0 hd(1:359) ] ;                
%            else
                llr_mem(llr_index,:)    = vec_rotate( llr_val,  rot) ;                      
                llr_mem_hd(llr_index,:) = vec_rotate( hd,  rot) ;
%            end
            llr_index=llr_index+1;
        end        
   end
   
   llr_mem(last_edge_index,:)    = [infnty llr_mem(last_edge_index,1:359)] ;
   llr_mem_hd(last_edge_index,:) = [0 llr_mem_hd(last_edge_index,1:359) ] ;                
   
    edge_index=1;
    min_index=zeros(1,360);
    sign_matrix = zeros(max_c_degree,360);

    par_err_cnt = 0;
    par_err=0;
    for i=1:q
        hd_cum=zeros(1,360);
        min_abs_llr     =  ones(1,360)*infnty;
        sec_min_abs_llr =  ones(1,360)*infnty;
        sign_matrix(:,:)=1;
        sign_cum        =ones(1,360);

        for j=1:C_DEG(i)        
            llr_val   = llr_mem(CNU_ROM(edge_index),:);        
            hd        = llr_mem_hd(CNU_ROM(edge_index),:);        
            hd_cum    = mod(hd_cum+hd,2);
      
            sign_matrix(j,llr_val<0)=-1;%1 for positive values        
            sign_cum=sign_cum.* sign_matrix(j,:);
        
            diff= abs(llr_val) - min_abs_llr ;
        
            sec_min_abs_llr(diff<0) = min_abs_llr(diff<0);
            sec_min_abs_llr(  (diff>=0) & (sec_min_abs_llr> abs(llr_val))) = abs(  llr_val( diff>=0 & ( sec_min_abs_llr> abs(llr_val))  )  );
        
            min_abs_llr=min(min_abs_llr,abs(llr_val));
            min_index(diff<0)=CNU_ROM(edge_index);           
            edge_index=edge_index+1;
        end
        if sum(hd_cum)>0
            par_err_cnt = par_err_cnt + sum(hd_cum);
            par_err=1;
        end
    
        edge_index=edge_index-C_DEG(i);
    
        for j=1:C_DEG(i)
            min_edges     = find(min_index==CNU_ROM(edge_index));
            not_min_edges = find(min_index~=CNU_ROM(edge_index));
        
            llr_out(min_edges)     = sec_min_abs_llr(min_edges).*sign_cum(min_edges).*sign_matrix(j,min_edges);
            llr_out(not_min_edges) = min_abs_llr(not_min_edges).*sign_cum(not_min_edges).*sign_matrix(j,not_min_edges);
%            if CNU_ROM(edge_index)==last_edge_index                                
%                llr_mem(CNU_ROM(edge_index),:)= 1 * [llr_out(2:360) 0];
%            else
                llr_mem(CNU_ROM(edge_index),:)= 1 * vec_rotate(llr_out,360-ROT(CNU_ROM(edge_index)));
%            end
            edge_index=edge_index+1;
        end    
    end
    %par_err_cnt
    
    llr_mem(last_edge_index,:)= 1 * [llr_mem(last_edge_index,2:360) 0];
    
    if par_err==0 %&& iter>10       
        return_code=1; % success
        break;
    end             
end




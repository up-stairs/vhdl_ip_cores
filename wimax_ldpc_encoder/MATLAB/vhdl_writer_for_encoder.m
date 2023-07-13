clear;
clc;
close all;
%% print Hbm1 for single rate
% code_sel = 1;
% switch code_sel
%     case 0
%         load H_r1_2
%     case 1
%         load H_r2_3A
%     case 2
%         load H_r2_3B
%     case 3
%         load H_r3_4A
%     case 4
%         load H_r3_4B
%     case 5
%         load H_r5_6
% end
% 
% [mb nb] = size(Hbm);
% kb = rate * nb;
% mb = nb-kb;

% 
% fprintf('(\n')
% for i = 1:mb
%     fprintf('(')
%     for j = 1:kb
%         if j == kb
%             if Hbm(i,j) ~= -1
%                 if code_sel ~= 1
%                     fprintf('%2d*z/96 ',Hbm(i,j))
%                 else
%                     fprintf('%2d-z*(%2d/z) ',Hbm(i,j),Hbm(i,j)) % 2/3 A kodu icin
%                 end
%             else
%                 fprintf('(2**logZ)-1')
%             end
%         else
%             if Hbm(i,j) ~= -1
%                 if code_sel ~= 1
%                     fprintf('%2d*z/96, ',Hbm(i,j))
%                 else
%                     fprintf('%2d-z*(%2d/z), ',Hbm(i,j),Hbm(i,j)) % 2/3 A kodu icin
%                 end
%             else
%                 fprintf('(2**logZ)-1, ')
%             end
%         end
%     end
%     if i == mb
%         fprintf(')\n')
%     else
%         fprintf('),\n')
%     end
% end
% fprintf(');\n')
%% print Hbm1 for all rates
EdgeCnt = 0;
fprintf('(\n')
for code_sel = 0:5
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

    [mb nb] = size(Hbm);
    kb = nb - mb;

    TotEdgeCnt = 0;
    for i = 1:mb
        EdgeCnt = 0;
        for j = 1:kb
            if Hbm(i,j) ~= -1
                TotEdgeCnt = TotEdgeCnt + 1;
                EdgeCnt = EdgeCnt + 1;
                if EdgeCnt == sum( Hbm(i,1:kb) > -1 )
                    RowEnd = 1;
                else
                    RowEnd = 0;
                end
                if code_sel ~= 1
                    fprintf('4096*%d+(128*%2d)+(%2d*z/96),  ',RowEnd,j-1,Hbm(i,j))
                else
                    fprintf('4096*%d+(128*%2d)+(%2d mod z), ',RowEnd,j-1,Hbm(i,j)) % 2/3 A kodu icin
                end
            end
        end
        fprintf('\n')
    end
    Start(code_sel+1) = TotEdgeCnt;
    for k = TotEdgeCnt+1:128
        if k == 128 && code_sel == 5
            fprintf('%d',0)
        else
            fprintf('%d, ',0)
        end
    end
    fprintf('\n')
end
fprintf(');\n')

Start
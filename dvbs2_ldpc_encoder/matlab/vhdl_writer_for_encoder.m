clear;
clc;
close all;

%%
code_range = 1:21;
P = 180;
%% writing the generic part of the top level encoder
for code = code_range
    [Hb EdgeCnt] = Convert2Hb(code,P);
    EdgeCnts(code) = EdgeCnt;
    kbs(code) = size(Hb(:,:,1),2) - size(Hb(:,:,1),1);
    mbs(code) = size(Hb(:,:,1),1);
end
fprintf('\t\tz\t\t\t\t\t\t: integer :=%d;\n',P)
fprintf('\t\tlogZ\t\t\t\t\t: integer :=%d; --ceil(log2(z))\n',ceil(log2(P)))
fprintf('\t\tlogC\t\t\t\t\t: integer :=%d; -- log2( # of supported codes )\n',ceil(log2(length(code_range))))
fprintf('\t\tlogA\t\t\t\t\t: integer :=%d; -- max( log2( max(kb)*360/z ), log2( max(mb)*360/z ) )\n',max(ceil(log2(max(kbs))),ceil(log2(max(mbs)))))
fprintf('\t\tlogMaE\t\t\t\t\t: integer :=%d; -- log2( max # of edges * 360/z)\n',ceil(log2(max(EdgeCnts))))
fprintf('\t\tlogToE\t\t\t\t\t: integer :=%d -- log2( total # of edges * 360/z )\n',ceil(log2(sum(EdgeCnts))))
%% writing the supported codes' properties for the encoder block
fprintf('constant kb							: INT_VECTOR_A := ( ')
for code = code_range
    if code ~= code_range(end)
        fprintf('%3d*S, ', kbs(code)/(360/P));
    else
        fprintf('%3d*S);', kbs(code)/(360/P));
    end
end
fprintf('\n')
%-----
fprintf('constant mb							: INT_VECTOR_A := ( ')
for code = code_range
    if code ~= code_range(end)
        fprintf('%3d*S, ', mbs(code)/(360/P));
    else
        fprintf('%3d*S);', mbs(code)/(360/P));
    end
end
fprintf('\n')
%-----
fprintf('constant EdgeCnts					: INT_VECTOR_A := ( ')
for code = code_range
    if code ~= code_range(end)
        fprintf('%3d*S, ', EdgeCnts(code)/(360/P));
    else
        fprintf('%3d*S);', EdgeCnts(code)/(360/P));
    end
end
fprintf('\n')
%-----
fprintf('constant EdgeStartIndex				: INT_VECTOR_A := ( ')
for code = code_range
    if code ~= code_range(end)
        fprintf('%3d*S, ', sum(EdgeCnts(1:code-1))/(360/P));
    else
        fprintf('%3d*S);', sum(EdgeCnts(1:code-1))/(360/P));
    end
end
fprintf('\n')
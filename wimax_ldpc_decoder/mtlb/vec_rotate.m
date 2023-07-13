function out_vec = vec_rotate(v,rot)

out_vec = 0*v;
if rot ~= -1
    out_vec(1:rot) = v(end-rot+1:end);
    out_vec(rot+1:end) = v(1:end-rot);
end
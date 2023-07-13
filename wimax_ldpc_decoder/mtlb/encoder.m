function cw = encoder(iw,z,Hm,unpaired_rotation)

nb=24;
kb=length(iw)/z;
mb=nb-kb;

u=reshape(iw,z,kb); %Information Matrix

v = zeros(z,mb); % parity vectors

Hb1 = Hm(:,1:kb);
hb = Hm(:,kb+1);

% find the results of summation terms
for i = 0:mb-1
    if i ~= mb-1
        for j = 0:kb-1
            v(:,i+2) = v(:,i+2) + vec_rotate( u(:,j+1) , Hb1(i+1,j+1) );
            v(:,1) = v(:,1) + vec_rotate( u(:,j+1) , Hb1(i+1,j+1) );
        end
    else
        for j = 0:kb-1
            v(:,1) = v(:,1) + vec_rotate( u(:,j+1) , Hb1(i+1,j+1) );
        end
    end
end

% find v(0) & v(1)
v(:,1) = mod( vec_rotate( v(:,1) , z-unpaired_rotation ) , 2 );
v(:,2) = mod( v(:,2)+ vec_rotate( v(:,1), hb(1)), 2);

% find the rest of the parities
for i = 1:mb-2
    v(:,i+2) = mod( v(:,i+1) + v(:,i+2) + vec_rotate(v(:,1),hb(i+1)) , 2 );
end

% forming the codeword
cw = [iw; reshape(v,mb*z,1)];
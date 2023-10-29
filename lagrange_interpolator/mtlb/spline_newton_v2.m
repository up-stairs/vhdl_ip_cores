
% --------------------------------------------------------------------
% --========== https://github.com/up-stairs/vhdl_ip_cores ==========--
% --------------------------------------------------------------------

function [y] = spline_newton_v2(x, r)

  Lx = length(x);

  y = zeros(1, ceil((Lx-2)/r));

  Ly = length(y);

  frac_acc = 0;
  int_acc = 0;
  iy = 3;
  j = 4;

  node1 = 0;
  node2 = 0;
  node3 = 0;
  node1_r = 0;
  node2_r = 0;
  node3_r = 0;

  while (j<Ly && iy+3<Lx)

    test = 0;
    if (frac_acc >= 1)
      iy = iy + 1;
      frac_acc = frac_acc - 1;
      test = 1;
    endif

    if (test == 1)
    node1_r = node1;
    endif;
    node1 = x(iy) - x(iy-1);

    if (test == 1)
    node2_r = node2;
    endif;
    node2 = (node1 - node1_r)/2;

    if (test == 1)
    node3_r = node3;
    endif;
    node3 = (node2 - node2_r)/3;

    [frac_acc x(iy) node1 node2 node3];

    c1 = -1;
    c2 = c1+1;
    c3 = c2+1;
##    y(j) = x(iy) + node2/3 + node3 - frac_acc * (node1+node3-(frac_acc+1)*(node2-(frac_acc+2)*node3));
    y(j) = x(iy)  + (frac_acc+c1) * (node1+node3+(frac_acc+c2)*(node2+(frac_acc+c3)*node3));

    frac_acc = frac_acc + r;

    j = j + 1;

  endwhile


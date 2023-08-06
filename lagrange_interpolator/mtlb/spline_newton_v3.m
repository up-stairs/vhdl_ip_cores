function [y] = spline_newton_v3(x, r)

  Lx = length(x);

  y = zeros(1, ceil((Lx-2)/r));

  Ly = length(y);

  frac_acc = 0;
  frac_acc_r1 = 0;
  frac_acc_r2 = 0;
  iy = 3;
  j = 1;

  node1 = 0;
  node1u_r1 = 0;
  node2 = 0;
  node2u_r1 = 0;
  node3 = 0;
  node1_r1 = 0;
  node1_r2 = 0;
  node2_r1 = 0;
  node2_r2 = 0;
  node2_r3 = 0;
  node3_r1 = 0;
  node3_r2 = 0;
  node3_r3 = 0;

  snode3 = 0;
  snode3_r1 = 0;
  snode2 = 0;
  snode2_r1 = 0;
  snode1 = 0;
  snode1_r1 = 0;

  x_c = 0;
  x_r1 = 0;
  x_r2 = 0;
  x_r3 = 0;
  xu_r1 = 0;



  while (j<Ly && iy+3<Lx)

    x_r3 = x_r2;
    x_r2 = x_r1;
    x_r1 = x(iy);

    test = 0;
    if (frac_acc >= 1)
      xu_r1 = x(iy);

      iy = iy + 1;
      frac_acc = frac_acc - 1;
      test = 1;
    endif;

    node1_r2 = node1_r1;
    node1_r1 = node1;
    if (test == 1)
    node1u_r1 = node1;
    endif;
    node1 = x(iy) - xu_r1;
##    node1 = x(iy) - x(iy-1);

    node2_r3 = node2_r2;
    node2_r2 = node2_r1;
    node2_r1 = node2;
    if (test == 1)
    node2u_r1 = node2;
    endif;
    node2 = (node1 - node1u_r1)/2;

    node3_r3 = node3_r2;
    node3_r2 = node3_r1;
    node3_r1 = node3;
    node3 = (node2 - node2u_r1)/3;


    c = 1;
    snode3_r1 = snode3;
    snode3 = (frac_acc + c)*node3;

    c = c - 1;
    snode2_r1 = snode2;
    snode2 = (frac_acc_r1 + c) * (snode3_r1 + node2_r1);

    c = c - 1;
    snode1_r1 = snode1;
    snode1 = (frac_acc_r2 + c) * (snode2_r1 + node1_r2 + node3_r2);

    y(j) = x_r3 + snode1_r1 + node3_r3 + node2_r3 / 3;

    frac_acc_r2 = frac_acc_r1;
    frac_acc_r1 = frac_acc;
    frac_acc = frac_acc + r;

    j = j + 1;

  endwhile


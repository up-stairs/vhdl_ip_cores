function [y] = lagrange_newton_v2(x, r)

  Lx = length(x);

  y = zeros(1, ceil((Lx-2)/r));

  Ly = length(y);

  frac_acc = 0;
  int_acc = 0;
  iy = 3;
  j = 1;

  node1 = 0;
  node2 = 0;
  node3 = 0;
  node4 = 0;
  node5 = 0;
  node1_r = 0;
  node2_r = 0;
  node3_r = 0;
  node4_r = 0;
  node5_r = 0;

  while (j<Ly && iy+3<Lx)

    test = 0;
    if (frac_acc >= 1)
      iy = iy + 1;
      frac_acc = frac_acc - 1;
      test = 1;
    endif


    if (test == 1)
    node1_r = node1;
    endif
    node1 = x(iy) - x(iy-1);

    if (test == 1)
    node2_r = node2;
    endif
    node2 = (node1 - node1_r)/2;

    if (test == 1)
    node3_r = node3;
    endif
    node3 = (node2 - node2_r)/3;

    if (test == 1)
    node4_r = node4;
    endif
    node4 = (node3 - node3_r)/4;

    if (test == 1)
    node5_r = node5;
    endif
    node5 = (node4 - node4_r)/5;

    c = frac_acc + 3;
    snode5 = c*node5;
    c = c - 1;
    snode4 = c*(node4+snode5);
    c = c - 1;
    snode3 = c*(node3+snode4);
    c = c - 1;
    snode2 = c*(node2+snode3);
    c = c - 1;
    snode1 = c*(node1+snode2);
    y(j) = x(iy) + snode1;

    frac_acc = frac_acc + r;

    j = j + 1;

  endwhile


function [y] = lagrange_newton_v3(x, r, layer)

  Lx = length(x);

  y = zeros(1, ceil((Lx-2)/r));

  Ly = length(y);

  frac_acc = 0;
  int_acc = 0;
  iy = 1;
  j = 1;

  x_r = 0;
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

  G = 200;
  x = x*G;

  while (j<Ly && iy<Lx)

    test = 0;
    if (frac_acc >= 1)
      frac_acc = frac_acc - 1;
      test = 1;
    endif

    if (test == 1)
      x_r = x(iy);
      iy = iy + 1;
    endif


    if (test == 1)
    node1_r = node1;
    endif
    node1 = x(iy) - x_r;

    if (test == 1)
    node2_r = node2;
    endif
    node2 = floor((node1 - node1_r)*(512/1024));

    if (test == 1)
    node3_r = node3;
    endif
    node3 = floor((node2 - node2_r)*(341/1024));

    if (test == 1)
    node4_r = node4;
    endif
    node4 = floor((node3 - node3_r)*(256/1024));

    if (test == 1)
    node5_r = node5;
    endif
    node5 = floor((node4 - node4_r)*(205/1024));

    c = frac_acc + 3;
    snode5 = floor(c*node5);

    c = c - 1;
    if (layer > 4)
      snode4 = floor(c*(node4+snode5));
    else
      snode4 = floor(c*(node4+0));
    endif

    c = c - 1;
    if (layer > 3)
      snode3 = floor(c*(node3+snode4));
    else
      snode3 = floor(c*(node3+0));
    endif

    c = c - 1;
    if (layer > 2)
      snode2 = floor(c*(node2+snode3));
    else
      snode2 = floor(c*(node2+0));
    endif

    c = c - 1;
    snode1 = floor(c*(node1+snode2));

    y(j) = x(iy) + snode1;

    frac_acc = frac_acc + r;

    j = j + 1;

endwhile

y = y/G;


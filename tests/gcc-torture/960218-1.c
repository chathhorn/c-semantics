#include "fsl-header.h"
int glob;

g (x)
{
  glob = x;
  return 0;
}

void f (x)
{
  int a = ~x;
  while (a)
    a = g (a);
}

main ()
{
  f (3);
  if (glob != -4)
    abort ();
  exit (0);
}
#include <stdlib.h>
char *a = 0;
char *b = 0;

void g (x)
     int x;
{
  if ((!!a) != (!!b))
    abort ();
}

void f (x)
     int x;
{
  g (x * x);
}

int main ()
{
  f (100);
  exit (0);
}

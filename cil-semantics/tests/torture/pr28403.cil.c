/* Generated by CIL v. 1.3.7 */
/* print_CIL_Input is true */

typedef unsigned long long ull;
extern  __attribute__((__nothrow__, __noreturn__)) void abort(void)  __attribute__((__leaf__)) ;
extern  __attribute__((__nothrow__, __noreturn__)) void exit(int __status )  __attribute__((__leaf__)) ;
int global  ;
int ( __attribute__((__noinline__)) foo)(int x1 , int x2 , int x3 , int x4 , int x5 ,
                                         int x6 , int x7 , int x8 ) 
{ 

  {
  global = ((((((x1 + x2) + x3) + x4) + x5) + x6) + x7) + x8;
  return (0);
}
}
ull ( __attribute__((__noinline__)) bar)(ull x ) 
{ 

  {
  foo(1, 2, 1, 3, 1, 4, 1, 5);
  return (x >> global);
}
}
int main(void) 
{ ull tmp ;

  {
  tmp = bar(81985529216486895ULL);
  if (tmp != 81985529216486895ULL >> 18) {
    abort();
  }
  exit(0);
}
}
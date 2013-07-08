## Search.

The C standard allows compilers freedom in optimizing code, which includes
allowing them to choose their own expression evaluation order. This includes
allowing them to:

- delay side effects: e.g., allowing the write to memory required by `x=5` or
  `x++` to be made separately from its evaluation or use;
- interleave evaluation: e.g., A + (B * C) can be evaluated in the order B, A,
  C.

At the same time, the programmer must be able to write programs whose behaviors
are reproducible, and only allow non-determinism in a controlled way.
Therefore, the standard makes undefined certain situations where reordering
creates a "race condition". The latest treatment of this restriction is given
by the C11 standard:

> If a side effect on a scalar object is unsequenced relative to either a
> different side effect on the same scalar object or a value computation using
> the value of the same scalar object, the behavior is undefined. If there are
> multiple allowable orderings [...], the behavior is undefined if such an
> unsequenced side effect occurs in any of the orderings [C1X, §6.5:2].

This means that if there are two writes, or a write and a read to the same
object that are unsequenced (i.e., either is allowed to happen before the
other), then the expression is undefined. Examples of expressions made
undefined by this clause include `(x=0)+(x=1)` and `(x=0)+x` and `x=x++` and
`*p=x++`, for `int x` and `int* p=&x`. This relation is related to the concept
of "sequence points," also defined by the standard. Sequence points cause the
expressions they fall between to be sequenced. The most common example of a
sequence point is the semicolon, i.e., the end of an expression-statement. All
previous evaluations and side effects must be complete before crossing sequence
points.

A hasty read of the standard may wrongly indicate that detecting this kind of
undefined behavior is an easy problem that can be checked statically. In fact,
it is undecidable statically; moreover, one needs to use the entire semantics
in order to check it dynamically. However, one can use kcc to help identify
these problems as well as to explore correct nondeterministic evaluations.

### Undefined examples.

Let's start with a simple example that can be caught just with interpretation:

<pre>
$ cat undefAdd2.c
int main(void){
   int x = 0;
   return (x = 1) + x;
}
</pre>
The `(x = 1) + x` expression is undefined because the read of `x` (the lone
`x`) is unsequenced with respect to the write of `x` (the assignment). Running
this program:
<pre>
$ kcc undefAdd2.c
$ ./a.out
=============================================================
ERROR! KCC encountered an error while executing this program.
=============================================================
Error: 00003
Description: Unsequenced side effect on scalar object with value computation of same object.
=============================================================
File: /home/grosu/celliso2/c-semantics/examples/search/undefAdd2.c
Function: main
Line: 3
=============================================================
Final Computation:
...
</pre>
detects the error. However, we were lucky because the interpreter doesn't
always detect these kinds of errors. Consider this program:

<pre>
$ cat undefComma.c
int main(void){
        int x = 0;
        return x + (x, x = 3);
}
</pre>
This program is also undefined. Here, the read of x in the right argument of
the + is unsequenced with the write to x in x=3. Let's try interpreting:

<pre>
$ kcc undefComma.c
$ ./a.out
$ echo $?
3
</pre>

Running this program through the interpreter fails to find the error! However,
by instructing kcc to search the state space, we can identify this program as
being undefined:

<pre>
$ SEARCH=1 ./a.out 
Performing the search...
Examining the output...
========================================================================
2 solutions found
------------------------------------------------------------------------
Solution 1
Program completed successfully
Return value: 3
Output:

------------------------------------------------------------------------
Solution 2
Program got stuck
File: 
Line: 
Error: 00003
Description: Unsequenced side effect on scalar object with value computation of same object.
Output:

========================================================================
2 solutions found
</pre>

If any of the results returned by search indicate undefined behavior, then the
program is undefined. During interpretation, we don't always notice undefined
behavior, but if it exists, it will always be identified using search.

## Model checking.
...
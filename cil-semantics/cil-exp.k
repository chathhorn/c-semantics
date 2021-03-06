// vim: set ts=2 sw=2:
require "builtins/list.k"
require "builtins/map.k"
require "builtins/set.k"

require "cil-common.k"
require "cil-implementation.k"

/* CId variable conventions:
     X variable
     M structure member
     F function */

module CIL-LITERAL
  imports SET
  imports CIL-COMMON // for Int2Double

  syntax String ::= carStr(String) [function]
                  | racStr(String) [function]
                  | cdrStr(String) [function]
                  | rdcStr(String) [function]

  rule carStr(S:String) => substrString(S, 0, 1)
  rule racStr(S:String)
    => substrString(S, lengthString(S) -Int 1, lengthString(S))
  rule cdrStr(S:String) => substrString(S, 1, lengthString(S))
  rule rdcStr(S:String)
    => substrString(S, 0, lengthString(S) -Int 1)

  syntax String ::= getNumericPart(String) [function]
                  | getDecFloatNumericPart(String) [function]
                  | getHexFloatNumericPart(String) [function]
                  | getHexFloatMantissa(String) [function]
                  | getHexFloatExponent(String) [function]
                  | beforeDot(String) [function]
                  | afterDot(String) [function]
                  | getNumericPart(String, Set, Set) [function]
                  | "getNumericPart'" "(" String "," String "," Set ")"
                    [function]

  syntax Float ::= hexToFloat(String) [function]
                 | "hexToFloat'" "("String")" [function]


  syntax Set ::= "prefixChars" [function]
               | "intSuffixChars" [function]
               | "floatHexPrefixChars" [function]
               | "floatSuffixChars" [function]
               | "floatHexSepChars" [function]

  rule prefixChars =>
    SetItem("0")
    SetItem("x")
    SetItem("X")
    SetItem("\\")

  rule intSuffixChars =>
    SetItem("u")
    SetItem("U")
    SetItem("l")
    SetItem("L")

  rule floatHexPrefixChars =>
    SetItem("x")
    SetItem("X")

  rule floatSuffixChars =>
    SetItem("f")
    SetItem("F")
    SetItem("l")
    SetItem("L")

  rule floatHexSepChars =>
    SetItem("p")
    SetItem("P")

  rule hexToFloat(S:String)
    => hexToFloat'(getHexFloatMantissa(S))
      *Float
      (2.0 ^Float hexToFloat'(getHexFloatExponent(S)))

  rule hexToFloat'(S:String)
    => Int2Double(conv(beforeDot(S), 16))
      +Float
      (Int2Double(conv(afterDot(S), 16))
        /Float Int2Double (16 ^Int lengthString(afterDot(S))))

  rule beforeDot(S:String)
    => #if findChar(S, ".", 0) ==Int -1
      #then S
      #else substrString(S, 0, findChar(S, ".", 0))
      #fi
  rule afterDot(S:String)
    => #if findChar(S, ".", 0) ==Int -1
      #then ""
      #else substrString(S, findChar(S, ".", 0) +Int 1, lengthString(S))
      #fi

  rule getNumericPart(S:String)
    => getNumericPart(S, prefixChars, intSuffixChars)

  rule getDecFloatNumericPart(S:String)
    => getNumericPart(S, .Set, floatSuffixChars)

  rule getHexFloatNumericPart(S:String)
    => getNumericPart(cdrStr(S), floatHexPrefixChars, floatSuffixChars)

  rule getHexFloatMantissa(S:String)
    => getNumericPart(getHexFloatNumericPart(S), .Set, floatHexSepChars)

  rule getHexFloatExponent(S:String)
    => getNumericPart(
        substrString(S,
          findString(S, getHexFloatMantissa(S), 0) +Int lengthString(getHexFloatMantissa(S)),
          lengthString(S)), floatHexSepChars, floatSuffixChars)

  rule getNumericPart(S:String, Pre:Set, Suf:Set)
    => getNumericPart(cdrStr(S), Pre, Suf)
    when (S =/=String "") andBool (carStr(S) in Pre)
  rule getNumericPart(S:String, Pre:Set, Suf:Set)
    => getNumericPart'(S, "", Suf)
    when (S =/=String "") andBool (notBool (carStr(S) in Pre))
  rule getNumericPart("", _:Set, _:Set) => "0"

  rule getNumericPart'(S:String, Num:String, Suf:Set)
    => getNumericPart'(cdrStr(S), Num +String carStr(S), Suf)
    when (S =/=String "") andBool (notBool (carStr(S) in Suf))
  rule getNumericPart'(S:String, Num:String, Suf:Set) => Num
    when (S =/=String "") andBool (carStr(S) in Suf) andBool (Num =/=String "")
  rule getNumericPart'("", Num:String, _:Set) => Num
    when Num =/=String ""
  rule getNumericPart'(S:String, "", Suf:Set) => "0"
    when (carStr(S) in Suf)
  rule getNumericPart'("", "", _:Set) => "0"

  syntax String ::= getSuffix(String) [function]
                  | getFloatSuffix(String) [function]
                  | getSuffix(String, Set) [function]
                  | "getSuffix'" "(" String "," String "," Set ")" [function]

  rule getSuffix(S:String) => getSuffix(S, intSuffixChars)

  rule getFloatSuffix(S:String) => getSuffix(S, floatSuffixChars)

  rule getSuffix(S:String, Sufs:Set) => getSuffix'(S, "", Sufs)

  rule getSuffix'(S:String, Suf:String, Sufs:Set)
    => getSuffix'(rdcStr(S), racStr(S) +String Suf, Sufs)
    when (racStr(S) in Sufs) andBool (S =/=String "")
  rule getSuffix'(S:String, Suf:String, Sufs:Set)
    => normSuffix(Suf)
    when notBool (racStr(S) in Sufs)
  rule getSuffix'("", Suf:String, _:Set) => normSuffix(Suf)

  syntax String ::= normSuffix(String) [function]

  rule normSuffix("") => ""
  rule normSuffix(S:String) => "F"
    when (S ==String "f")
      orBool (S ==String "F")

  rule normSuffix(S:String) => "U"
    when (S ==String "u")
      orBool (S ==String "U")

  rule normSuffix(S:String) => "L"
    when (S ==String "l")
      orBool (S ==String "L")

  rule normSuffix(S:String) => "LL"
    when (S ==String "ll")
      orBool (S ==String "LL")

  rule normSuffix(S:String) => "UL"
    when (S ==String "ul")
      orBool (S ==String "uL")
      orBool (S ==String "Ul")
      orBool (S ==String "UL")
      orBool (S ==String "lu")
      orBool (S ==String "Lu")
      orBool (S ==String "lU")
      orBool (S ==String "LU")

  rule normSuffix(S:String) => "ULL"
    when (S ==String "ull")
      orBool (S ==String "uLL")
      orBool (S ==String "Ull")
      orBool (S ==String "ULL")
      orBool (S ==String "llu")
      orBool (S ==String "LLu")
      orBool (S ==String "llU")
      orBool (S ==String "LLU")

  syntax Int ::= conv(String, Int) [function]

  rule conv(S:String, Base:Int) => String2Base(S, Base)
    when S =/=String ""
  rule conv("", _:Int) => 0

endmodule

module CIL-PROMOTION
  imports CIL-COMMON

  syntax KItem ::= "typeinfo" "(" Int "," Int "," Int ")"

  /* empty: implicit casts inserted by cilly */
endmodule

module CIL-EXP
  imports LIST
  imports MAP
  imports SET
  imports CIL-TYPING-SYNTAX
  imports CIL-PROMOTION
  imports CIL-IMPLEMENTATION
  imports CIL-LITERAL

  syntax KItem ::= "noLeftValueConversion"

  syntax KItem ::= Type [avoid]

  rule I:Int => norm(int, I)

  syntax KItem ::= "$exp2bool" "(" Exp ")"    [strict]
  rule $exp2bool(tv(_:Type, MI:MInt))
    => norm(int, notBool zeroMInt(MI))
  [structural]
  rule $exp2bool(tv(_:Type, Null))
    => norm(int, false)
  [structural]
  rule $exp2bool(tv(_:Type, P:Ptr))
    => norm(int, true)
    when P =/=K Null
  [structural]

  /* Constants. */
  rule C:DecimalConstant
    => norm(int, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String ""
    [structural]
  rule C:DecimalConstant
    => norm(long, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String "L"
    [structural]
  rule C:DecimalConstant
    => norm(long long, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String "LL"
    [structural]
  rule C:DecimalConstant
    => norm(unsigned int, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String "U"
    [structural]
  rule C:DecimalConstant
    => norm(unsigned long, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String "UL"
    [structural]
  rule C:DecimalConstant
    => norm(unsigned long long, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String "ULL"
    [structural]

  rule C:OctalConstant
    => norm(int, conv(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String ""
    [structural]
  rule C:OctalConstant
    => norm(long, conv(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String "L"
    [structural]
  rule C:OctalConstant
    => norm(long long, conv(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String "LL"
    [structural]
  rule C:OctalConstant
    => norm(unsigned int, conv(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String "U"
    [structural]
  rule C:OctalConstant
    => norm(unsigned long, conv(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String "UL"
    [structural]
  rule C:OctalConstant
    => norm(unsigned long long,
      conv(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String "ULL"
    [structural]

  rule C:HexConstant
    => norm(int, conv(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String ""
    [structural]
  rule C:HexConstant
    => norm(long, conv(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String "L"
    [structural]
  rule C:HexConstant
    => norm(long long, conv(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String "LL"
    [structural]
  rule C:HexConstant
    => norm(unsigned int, conv(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String "U"
    [structural]
  rule C:HexConstant
    => norm(unsigned long, conv(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String "UL"
    [structural]
  rule C:HexConstant
    => norm(unsigned long long,
      conv(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String "ULL"
    [structural]

  rule C:DecimalFloatConstant
    => norm(double, String2Float(getDecFloatNumericPart(#tokenToString(C))))
    when getFloatSuffix(#tokenToString(C)) ==String ""
    [structural]
  rule C:DecimalFloatConstant
    => norm(long double, String2Float(getDecFloatNumericPart(#tokenToString(C))))
    when getFloatSuffix(#tokenToString(C)) ==String "L"
    [structural]
  rule C:DecimalFloatConstant
    => norm(float, String2Float(getDecFloatNumericPart(#tokenToString(C))))
    when getFloatSuffix(#tokenToString(C)) ==String "F"
    [structural]

  rule C:NoDotDecimalFloatConstant
    => norm(double, String2Float(getDecFloatNumericPart(#tokenToString(C))))
    when getFloatSuffix(#tokenToString(C)) ==String ""
    [structural]
  rule C:NoDotDecimalFloatConstant
    => norm(long double, String2Float(getDecFloatNumericPart(#tokenToString(C))))
    when getFloatSuffix(#tokenToString(C)) ==String "L"
    [structural]
  rule C:NoDotDecimalFloatConstant
    => norm(float, String2Float(getDecFloatNumericPart(#tokenToString(C))))
    when getFloatSuffix(#tokenToString(C)) ==String "F"
    [structural]

  rule C:HexFloatConstant
    => norm(double, hexToFloat(#tokenToString(C)))
    when getFloatSuffix(#tokenToString(C)) ==String ""
    [structural]
  rule C:HexFloatConstant
    => norm(long double, hexToFloat(#tokenToString(C)))
    when getFloatSuffix(#tokenToString(C)) ==String "L"
    [structural]
  rule C:HexFloatConstant
    => norm(float, hexToFloat(#tokenToString(C)))
    when getFloatSuffix(#tokenToString(C)) ==String "F"
    [structural]

  rule C:NoDotHexFloatConstant
    => norm(double, hexToFloat(#tokenToString(C)))
    when getFloatSuffix(#tokenToString(C)) ==String ""
    [structural]
  rule C:NoDotHexFloatConstant
    => norm(long double, hexToFloat(#tokenToString(C)))
    when getFloatSuffix(#tokenToString(C)) ==String "L"
    [structural]
  rule C:NoDotHexFloatConstant
    => norm(float, hexToFloat(#tokenToString(C)))
    when getFloatSuffix(#tokenToString(C)) ==String "F"
    [structural]

  // TODO(chathhorn): prefixes (wide chars I guess).
  rule ' C:Char ' => norm(int, ordChar(#tokenToString(C)))
  rule '*' => norm(int, ordChar("*"))
  rule ' \' ' => norm(int, 39)
  rule ' \\ ' => norm(int, 92)
  rule ' \a ' => norm(int, 7)
  rule ' \b ' => norm(int, 8)
  rule ' \t ' => norm(int, 9)
  rule ' \v ' => norm(int, 11)
  rule ' C:OctalStringEscape '
    => norm(int, conv(getNumericPart(#tokenToString(C)), 8))
  rule ' C:HexStringEscape '
    => norm(int, conv(getNumericPart(#tokenToString(C)), 16))

  /* Lookup. */
  rule
    <k> X:CId => lv(expandTypedefs(T, E), P) ...</k>
    <env> E:Map (X |-> lv(T:Type, P:Ptr)) </env>
    [structural]

  // Typedefs.
  rule
    <k> X:CId => nt(expandTypedefs(T, E)) ...</k>
    <env> E:Map (X |-> T:Type) </env>
    [structural]

  rule
    <k> S:String
      => newString(S, newObject(normType(char [lengthString(S) +Int 1])))
    ...</k>
    <strings> Ss:Map </strings>
    when notBool (S in keys(Ss))

  rule
    <k> S:String => lv(normType(char [lengthString(S) +Int 1]), P) ...</k>
    <strings>... S |-> P:Ptr ...</strings>

  syntax KItem ::= newString(String, K) [strict(2)]
  rule <k> newString(S:String, tv(T:Type, P:Ptr))
    => store(downPtr(T), P, S) ~> lv(downPtr(T), P)
    ...</k>
    <strings>... .Map => S |-> P </strings>

  // Doesn't work as a macro because it will mangle array declarations.
  rule E1:Exp[E2:Exp] => *(E1 + E2)

  context (HOLE => HOLE ~> noLeftValueConversion) . _:CId
  rule
    <k>
      nclv(Agg:AggTypeSpec, Ptr(Base:BasePtr, Offset:Int)) . M:CId
      => lv(T, Ptr(Base, Offset +Int MOffset))
    ...</k>
    <agg-id> Agg </agg-id>
    <field-id> M </field-id>
    <field-type> T:Type </field-type>
    <offset> MOffset:Int </offset>

  context &(HOLE => HOLE ~> noLeftValueConversion)
  rule &nclv(T:Type, P:Ptr) => tv(upPtr(T), P)
    when isArrayType(T) =/=K true
    [structural]

  /* Pointer dereference. */
  rule *tv(T:Type, P:Ptr) => lv(downPtr(T), P)
    when isVaList(P) =/=K true
    [structural]

  /* Dereference of hacky VaLists, which should never be r-values. */
  rule *tv(T:Type, va_list(tv(_:Type, V:Value))) => tv(downPtr(T), V)
    [structural]

  context '_=_;((HOLE => HOLE ~> noLeftValueConversion),, _:K)
  rule nclv(T:Type, P:Ptr) = tv(T, V:Value); => store(T, P, V)

  rule (lv(T:Type, P:Ptr) => load(T, P)) ~> KI:KItem
    when (KI =/=K noLeftValueConversion) andBool ((isArrayType(T) =/=K true)
      orBool (KI ==K sizeofContext)) andBool (isFunType(T) =/=K true)
  // Arrays decay to a pointer (except as an operand to sizeof() or &).
  rule (lv(T:Type, P:Ptr) => tv(upPtr(downArray(T)), P)) ~> KI:KItem
    when (KI =/=K noLeftValueConversion) andBool (KI =/=K sizeofContext)
      andBool (isArrayType(T) ==K true)
  // Functions decay to a function pointer.
  rule (lv(T:Type, P:Ptr) => tv(upPtr(T), P)) ~> KI:KItem
    when (KI =/=K noLeftValueConversion) andBool (isFunType(T) ==K true)

  // TODO
  //rule ('lv => 'nclv)(_:KList) ~> noLeftValueConversion
  rule ('lv => 'nclv)(_:K,,_:K) ~> noLeftValueConversion
  [structural]

  /*
   * Arithmetic operator semantics.
   */
  /* Unary plus */
  rule +tv(T:Type, I:MInt) => tv(T, I)
  /* Unary minus */
  /* FIXME standard is unclear about the semantics of unary minus. */
  rule -tv(T:Type, I:MInt) => norm(T, 0) - tv(T, I)

  rule -tv(T:Type, F:Float) => norm(T, 0.0) - tv(T, F)

  /* Addition */
  rule tv(T:SignedIntType, MI1:MInt) + tv(T, MI2:MInt)
    => tv(T, miMInt(saddMInt(MI1, MI2)))
  when notBool overflowMInt(saddMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) + tv(T, MI2:MInt)
    => tv(T, addMInt(MI1, MI2))

  /* Subtraction */
  rule tv(T:SignedIntType, MI1:MInt) - tv(T, MI2:MInt)
    => tv(T, miMInt(ssubMInt(MI1, MI2)))
  when notBool overflowMInt(ssubMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) - tv(T, MI2:MInt)
    => tv(T, subMInt(MI1, MI2))

  /* Multiplication */
  rule tv(T:SignedIntType, MI1:MInt) * tv(T, MI2:MInt)
    => tv(T, miMInt(smulMInt(MI1, MI2)))
  when notBool overflowMInt(smulMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) * tv(T, MI2:MInt)
    => tv(T, mulMInt(MI1, MI2))

  /* Division */
  rule tv(T:SignedIntType, MI1:MInt) / tv(T, MI2:MInt)
    => tv(T, miMInt(sdivMInt(MI1, MI2)))
  when notBool(zeroMInt(MI2)) andBool notBool(overflowMInt(sdivMInt(MI1, MI2)))
  rule tv(T:UnsignedIntType, MI1:MInt) / tv(T, MI2:MInt)
    => tv(T, udivMInt(MI1, MI2))
  when notBool zeroMInt(MI2)

  /* Remainder is defined only when division is defined */
  rule tv(T:SignedIntType, MI1:MInt) % tv(T, MI2:MInt)
    => tv(T, miMInt(sremMInt(MI1, MI2)))
  when notBool(zeroMInt(MI2)) andBool notBool(overflowMInt(sremMInt(MI1, MI2)))
  rule tv(T:UnsignedIntType, MI1:MInt) % tv(T, MI2:MInt)
    => tv(T, uremMInt(MI1, MI2))
  when notBool zeroMInt(MI2)

  rule ~tv(T:Type, MI:MInt) => tv(T, negMInt(MI))

  /* Shift */
  // TODO(AndreiS): use library shift
  // TODO(AndreiS): negative shifts
  rule tv(T:Type, I:MInt) << tv(_:Type, N:MInt)
    => norm(T, uvalueMInt(I) <<Int uvalueMInt(N))
    when uvalueMInt(N) <Int width(T)
  rule tv(T:SignedIntType, I:MInt) >> tv(_:Type, N:MInt)
    => norm(T, svalueMInt(I) >>Int uvalueMInt(N))
    when uvalueMInt(N) <Int width(T)
  rule tv(T:UnsignedIntType, I:MInt) >> tv(_:Type, N:MInt)
    => norm(T, uvalueMInt(I) >>Int uvalueMInt(N))
    when uvalueMInt(N) <Int width(T)

  /* Relation operators */
  rule tv(T:SignedIntType, MI1:MInt) < tv(T, MI2:MInt)
    => norm(int, sltMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) < tv(T, MI2:MInt)
    => norm(int, ultMInt(MI1, MI2))
  rule tv(T:SignedIntType, MI1:MInt) <= tv(T, MI2:MInt)
    => norm(int, sleMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) <= tv(T, MI2:MInt)
    => norm(int, uleMInt(MI1, MI2))
  rule tv(T:SignedIntType, MI1:MInt) > tv(T, MI2:MInt)
    => norm(int, sgtMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) > tv(T, MI2:MInt)
    => norm(int, ugtMInt(MI1, MI2))
  rule tv(T:SignedIntType, MI1:MInt) >= tv(T, MI2:MInt)
    => norm(int, sgeMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) >= tv(T, MI2:MInt)
    => norm(int, ugeMInt(MI1, MI2))

  /* Relation operators */
  rule tv(T:Type, MI1:MInt) == tv(T, MI2:MInt)
    => norm(int, eqMInt(MI1, MI2))
  rule tv(T:Type, MI1:MInt) != tv(T, MI2:MInt)
    => norm(int, neMInt(MI1, MI2))

  rule ! E:Exp => $exp2bool(E) ~> ! HOLE    [heat]
  rule TV:TypedValue ~> ! HOLE => ! TV      [cool]

  rule !tv(_:Type, I:MInt) => norm(int, 1)
    when zeroMInt(I)
  rule !tv(_:Type, I:MInt) => norm(int, 0)
    when notBool zeroMInt(I)

  /*
   * Sizeof
   */
  // Things are special inside a sizeof (in particular, arrays don't decay).
  syntax KItem ::= "sizeofContext"
  context sizeof(HOLE => HOLE ~> sizeofContext)

  syntax Exp ::= "sizeof'" "(" Type ")"
  rule sizeof(nt(T:Type)) => sizeof'(T)
  rule sizeof(tv(T:Type, _:Value)) => sizeof'(T)

  rule sizeof'(T:Type) => (size_t) byteWidth(T)
    when (isBasicType(T) ==K true) orBool (isPtrType(T) ==K true)
    [structual]
  rule sizeof'(T:Type)
    => (size_t) sizeof'(downArray(T)) * (size_t) getArraySize(T)
    when isArrayType(T) ==K true
    [structual]
  rule <k> sizeof'(T:AggTypeSpec) => (size_t) Size ...</k>
    <agg-id> T </agg-id>
    <size> Size:Int </size>
    [structural]

  /*
   * Casting
   */
  rule
    <k> T:Type => nt(expandTypedefs(normType(T), E)) ...</k>
    <env> E:Map </env>
    when (isNormType(T) =/=K true)
      // If it's a CId then we look it up in the env until we get an unambiguous
      // type.
      andBool (isCId(T) =/=K true)
      // This case is ambiguous with the Exp syntax.
      andBool ($isConstArrayDeref(T, E) =/=K true)

  // Disambiguate the typedef_name[Constant] case from the var[Constant] case.
  syntax Bool ::= "$isConstArrayDeref" "(" K "," Map ")" [function]
  rule $isConstArrayDeref(X:CId[_:Constant], (_:Map (X |-> lv(_,_)))) => true
  rule $isConstArrayDeref(Lbl:KLabel(_), _) => false
    when Lbl =/=KLabel '_`[_`]
  rule $isConstArrayDeref(_, _) => false [owise]

  // TODO(chathhorn): should find a better way. I'm basically turning something
  // that has been misparsed as a Type into an Exp.
  rule <k> X:CId[C:Constant] => '_`[_`](X,, C):>Exp ...</k>
    <env>... X |-> lv(_,_) ...</env>

  /* the rule for signed integer types is implementation defined */
  rule
    (nt(T:SignedIntType)) tv(_:Type, I:MInt)
  =>
    tv(T, mi(width(T), svalueMInt(I)))
  // TODO: unnecessary?
  //rule (nt(T:SignedIntType)) tv(_:Type, I:Int) => norm(T, I)

  rule
    (nt(T:UnsignedIntType)) tv(_:Type, I:MInt)
  =>
    tv(T, mi(width(T), uvalueMInt(I)))
  // TODO: unnecessary?
  //rule (nt(T:UnsignedIntType)) tv(_:Type, I:Int) => norm(T, I)

  // Allowing all casts between floating point types.
  rule (nt(To:FloatingType)) tv(_:Type, F:Float) => norm(To, F)

  // Allowing all casts between ints and floats.
  rule (nt(To:FloatingType)) tv(_:Type, I:MInt) => norm(To, I)
  rule (nt(To:IntType)) tv(_:Type, F:Float) => norm(To, F)

  // Pointers to void may be cast to or from any pointer type.
  rule (nt(To:Type)) tv(From:Type, V:Value) => tv(To, V)
    when ((isPtrType(To) ==K true) andBool (isPtrType(From) ==K true))
      andBool ((downPtr(To) ==K void) orBool (downPtr(From) ==K void))

  // Null pointers (or 0) may be cast to any pointer type.
  rule (nt(To:Type)) tv(_:Type, I:MInt) => tv(To, Null)
    when (isPtrType(To) ==K true) andBool zeroMInt(I)
  rule (nt(To:IntType)) tv(_:Type, Null) => norm(To, 0)

  // TODO(chathhorn): Pointers may be converted to integers and the result is
  // implementation-defined (apparently except in the case of Null). But also
  // comparisons and such must still work for pointers with the same base, even
  // after being cast to an IntType.
  rule (nt(To:IntType)) tv(_:Type, Ptr(BasePtr(Base:Int, _), Offset:Int))
    => norm(To, symToInt(Base) +Int Offset)

  // Ints to pointers.
  // TODO(AndreiS): this rule causes prover to fail due to non-confluence
//  rule (nt(To:Type)) tv(_:IntType, I:MInt) => norm(To, I)
//    when isPtrType(To) ==K true

  syntax Int ::= symToInt(K) [function]
  // TODO(AndreiS): pointers now have concrete bases
  // rule symToInt(#symInt(I:Int)) => I
  rule symToInt(I:Int) => I

  // Pointers of one type may be converted to pointers of another type and back
  // again. The result should compare equal to the original pointer.
  rule (nt(To:Type)) tv(From:Type, P:Ptr) => tv(To, P)
    when (isPtrType(To) ==K true) andBool (isPtrType(From) ==K true)

  rule tv(T:Type, F1:Float) * tv(T, F2:Float) => tv(T, F1 *Float F2)
  rule tv(T:Type, F1:Float) / tv(T, F2:Float) => tv(T, F1 /Float F2)
    when F2 =/=Float 0.0

  rule tv(T:Type, F1:Float) + tv(T, F2:Float) => tv(T, F1 +Float F2)
  rule tv(T:Type, F1:Float) - tv(T, F2:Float) => tv(T, F1 -Float F2)

  // pointer arithmetic
  rule tv(T:Type, P:Ptr) + tv(_:SignedIntType, MI:MInt)
    => PtrAddHelper(T, P, svalueMInt(MI), sizeof(downPtr(T)))
  rule tv(T:Type, P:Ptr) + tv(_:UnsignedIntType, MI:MInt)
    => PtrAddHelper(T, P, uvalueMInt(MI), sizeof(downPtr(T)))
  when isPtrType(T)
  rule tv(T1:IntType, MI:MInt) + tv(T2:Type, P:Ptr) => tv(T2, P) + tv(T1, MI)
  when isPtrType(T2)
  // TODO: unnecessary?
  //rule tv(_, I:Int) + tv(T:Type, P:Ptr)
  //  => PtrAddHelper(T, P, I, sizeof(downPtr(T)))
  //  when isPtrType(T)
  //rule tv(T:Type, P:Ptr) + tv(_, I:Int)
  //  => PtrAddHelper(T, P, I, sizeof(downPtr(T)))
  //  when isPtrType(T)

  rule tv(T1:Type, P:Ptr) - tv(T2:IntType, MI:MInt) => tv(T1, P) + (-tv(T2, MI))
  when isPtrType(T1)

  rule tv(T:Type, P1:Ptr) - tv(T, P2:Ptr)
    => PtrSubHelper(P1, P2, sizeof(downPtr(T)))
  when isPtrType(T)

  syntax KItem ::= PtrAddHelper(Type, Ptr, Int, Exp)    [strict(4)]
  rule PtrAddHelper(T:Type, P:Ptr, I:Int, TV:TypedValue)
    => tv(T, PtrAdd(P, I, TV))

  syntax KItem ::= PtrSubHelper(Ptr, Ptr, Exp)    [strict(3)]
  rule PtrSubHelper(P1:Ptr, P2:Ptr, TV:TypedValue)
    => tv(ptrdiff_t, mi(width(size_ptr), PtrSub(P1, P2, TV)))

  // float comparisons
  rule tv(T:Type, F1:Float) < tv(T, F2:Float) => norm(int, F1 <Float F2)
  rule tv(T:Type, F1:Float) <= tv(T, F2:Float) => norm(int, F1 <=Float F2)
  rule tv(T:Type, F1:Float) > tv(T, F2:Float) => norm(int, F1 >Float F2)
  rule tv(T:Type, F1:Float) >= tv(T, F2:Float) => norm(int, F1 >=Float F2)

  rule tv(_:Type, P1:Ptr) < tv(_:Type, P2:Ptr) => norm(int, PtrLt(P1, P2))
  rule tv(_:Type, P1:Ptr) <= tv(_:Type, P2:Ptr) => norm(int, PtrLeq(P1, P2))
  rule tv(_:Type, P1:Ptr) > tv(_:Type, P2:Ptr) => norm(int, PtrGt(P1, P2))
  rule tv(_:Type, P1:Ptr) >= tv(_:Type, P2:Ptr) => norm(int, PtrGeq(P1, P2))

  /* TODO: comparison of pointers and integers */
  /* TODO: for now ignoring whether the pointer is alive or dead */
  rule tv(T:Type, I1:Int) == tv(T, I2:Int) => norm(int, I1 ==Int I2)
  rule tv(T:Type, I1:Int) != tv(T, I2:Int) => norm(int, I1 =/=Int I2)
  rule tv(T:Type, F1:Float) == tv(T, F2:Float) => norm(int, F1 ==Float F2)
  rule tv(T:Type, F1:Float) != tv(T, F2:Float) => norm(int, F1 =/=Float F2)
  rule tv(_:Type, P1:Ptr) == tv(_:Type, P2:Ptr) => norm(int, P1 ==K P2)
  rule tv(_:Type, P1:Ptr) != tv(_:Type, P2:Ptr) => norm(int, P1 =/=K P2)

  rule tv(T:Type, I1:MInt) & tv(T, I2:MInt) => tv(T, andMInt(I1, I2))
  rule tv(T:Type, I1:MInt) | tv(T, I2:MInt) => tv(T, orMInt(I1, I2))
  rule tv(T:Type, I1:MInt) ^ tv(T, I2:MInt) => tv(T, xorMInt(I1, I2))
endmodule

program example(input, output);
var ivar, constAdd: real;

function fun(rarg1, rarg2:real) : real;
begin
    fun:= rarg2 + rarg2
end;

begin
    constAdd:=10;
    ivar:=fun(fun(2.0,3.0),fun(4.0,50.0));
    write(ivar)
end.
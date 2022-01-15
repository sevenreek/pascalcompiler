program example(input, output);
var ivar, constAdd: real;

function func(rarg1, rarg2:real; iarg1, iarg2:integer) : real;
begin
    func:= func(rarg1,rarg2, iarg1, iarg2)
end;

begin
    constAdd:=10;
    ivar:=func(ivar, 1.0, 1, 2)
end.
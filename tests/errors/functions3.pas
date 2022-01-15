program example(input, output);
var ivar, constAdd: real;

function func(arg1, arg2:real) : real;
var farg: real;
begin
    farg:= arg1 + arg2 - 1.0;
    func:= farg + constAdd
end;

begin
    ivar:=func()
end.
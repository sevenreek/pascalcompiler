program example(input, output);
var rvar, constAdd: real;
var ivar:integer;
function func(arg1, arg2:real) : integer;
var farg: real;
var iarg, iarg2: integer;
begin
    iarg := iarg2;
    farg:= arg1 + arg2 - 1.0;
    func:= farg + constAdd
end;

begin
    constAdd:=10;
    rvar:=func(ivar, 2)
end.
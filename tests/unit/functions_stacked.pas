program example(input, output);
var ivar: real;

function func(arg1:real) : real;
begin
    func:= 1 + 2
end;

begin
    ivar := func(func(2.0))
end.
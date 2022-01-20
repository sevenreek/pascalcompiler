program example(input, output);
var ivar, constAdd: real;

function func(arg1, arg2:real) : real;
begin
    func:= arg1 - arg2
end;

begin
    
    ivar := func(func(3.0, 2.0), func(1.0, 2.0));
    write(ivar)
end.
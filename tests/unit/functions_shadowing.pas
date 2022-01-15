program example(input, output);
var rvar1, rvar2, rvar3, rvar4: real;
function func(rvar1:real) : real;
var rvar2: real;
begin
    rvar2:= 4.0;
    func:= rvar1 + rvar2 + rvar3
end;

begin
    rvar1:=1.0;
    rvar2:=2.0;
    rvar3:=3.0;
    rvar4:=func(4.0);
    write(rvar1, rvar2, rvar3, rvar4)
end.
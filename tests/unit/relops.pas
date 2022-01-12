program sort(input,output);
var w,x,y,z: integer;
begin
	y:=1;
	z:=2;
	write((y<z) and (z>y));
	write((y>=z) or (z<=y));
	write(y<>z);
	write(z=y);
	write(not (z=y))
end.


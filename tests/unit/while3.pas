program sort(input,output);
var p :array [1..10] of integer;

procedure czytajtab(a: array[1..10] of integer);
var i: integer;
begin
  i:=1;
  while i<11 do
  begin
    read(a[i]);
    i:=i+1
  end
end;

procedure wypisztab(a: array[1..10] of integer);
var i: integer;
begin
  i:=1;
  while i<11 do
  begin
    write(a[i]);
    i:=i+1
    
  end
end;

begin
wypisztab(p)
end.
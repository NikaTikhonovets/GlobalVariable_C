program PMSiS_Laba2;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  RegExpr;

const
  FILE_NAME = 'Ñode.txt';
  TYPEOFVARIABLE = '(void|char|int|short int|long int|unsigned long int|float|double|long float)';

var
  AnalysedCode: string;
  ArrayOfStrings, ArrayOfMethods,ArrayOfGlobalVariables: array of string;
  NeededFile: TextFile;
  Aup, Pup:integer;

procedure ReadFromFile();
var
  NumberOfStrings, CurrentNumberOfStrings: Integer;
begin
  SetLength(ArrayOfStrings, 500);
  Assignfile(NeededFile, FILE_NAME);
  Reset(NeededFile);
  NumberOfStrings := 0;
  while not EOf(NeededFile) do
  begin
    ReadLn(NeededFile, ArrayOfStrings[NumberOfStrings]);
    Inc(NumberOfStrings);
  end;
  CloseFile(NeededFile);
  SetLength(ArrayOfStrings, NumberOfStrings + 1);
  AnalysedCode := '';
  for CurrentNumberOfStrings := 0 to NumberOfStrings do
    AnalysedCode := AnalysedCode + ArrayOfStrings[CurrentNumberOfStrings] +
      #10#13;
  AnalysedCode := LowerCase(AnalysedCode);
end;

procedure DeleteCommentsAndLiterals();
var
  RegularExpression: TRegExpr;
begin
  RegularExpression := TRegExpr.Create;
  try
    RegularExpression.Expression := '(\/\/.*?\n|\/\*.*?\*\/|\".*?\"|''.*?'')';
    while RegularExpression.Exec(AnalysedCode) do
    begin
      Delete(AnalysedCode, RegularExpression.MatchPos[0],
        RegularExpression.MatchLen[0]);
    end;
  finally
    RegularExpression.Free;
  end;
end;


procedure ReplaceStringBySpace (var AnalysedCode:string; StringPosition,LengthOfString:integer);
var NeededString:string;
    CurrentNumberSpace:Integer;
begin
  Delete(AnalysedCode,StringPosition,LengthOfString);
  NeededString:='';
  for CurrentNumberSpace:=1 to LengthOfString do
    NeededString:=NeededString + ' ';
  Insert(NeededString,AnalysedCode,StringPosition);
end;


procedure DivideIntoMethods();
var
  CountBracket, FunctionPosition: integer;
  RegularExpression: TRegExpr;
begin
   RegularExpression := TRegExpr.Create;
  try
  SetLength(ArrayOfMethods,0);
  RegularExpression.ModifierS := true;
  RegularExpression.Expression := ('\b' + TYPEOFVARIABLE + '\b') +'[ ,a-z,0-9,_,\n]*\([^}]*?\{';
  if RegularExpression.Exec(AnalysedCode) then
    repeat
      CountBracket := 1;
      FunctionPosition := RegularExpression.MatchPos[0];
      ReplaceStringBySpace(AnalysedCode, RegularExpression.MatchPos[0],RegularExpression.MatchLen[1]);
      RegularExpression.Expression := '[\{\}]';
      if RegularExpression.ExecPos(FunctionPosition + RegularExpression.MatchLen[0]) then
        repeat
          if RegularExpression.Match[0] = '{' then
            inc(CountBracket)
          else if RegularExpression.Match[0] = '}' then
            dec(CountBracket);
        until (CountBracket = 0) or (not (RegularExpression.ExecNext));
        SetLength(ArrayOfMethods,length(ArrayOfMethods)+1);
        ArrayOfMethods[length(ArrayOfMethods)-1]:=Copy(AnalysedCode,FunctionPosition,RegularExpression.MatchPos[0] - FunctionPosition + 1);
        ReplaceStringBySpace(AnalysedCode,FunctionPosition,RegularExpression.MatchPos[0] - FunctionPosition +1 );
        RegularExpression.Expression := ('\b' + TYPEOFVARIABLE + '\b') +'[ ,a-z,0-9,_,\n]*\([^}]*?\{';
    until not (RegularExpression.ExecPos(RegularExpression.MatchPos[0]));
      finally
    RegularExpression.Free;
  end;
end;

procedure FindGlobalVariable();
var
  RegularExpression: TRegExpr;
begin
  SetLength(ArrayOfGlobalVariables,0);
   RegularExpression := TRegExpr.Create;
  try
   RegularExpression.Expression := ('\b'+TYPEOFVARIABLE+'\b') + '( .*?)([a-z,0-9,_,]*)';
   if RegularExpression.Exec(AnalysedCode) then
    repeat
     SetLength(ArrayOfGlobalVariables,length(ArrayOfGlobalVariables)+1);
     ArrayOfGlobalVariables[length(ArrayOfGlobalVariables)-1]:=RegularExpression.Match[3];
    until not (RegularExpression.ExecNext);
  finally
    RegularExpression.Free;
  end;
end;

procedure FindLocalVariable ();
var    RegularExpression: TRegExpr;
  CurrentNumberOfMethod,ArrayElementCount:integer;
  StartPosition:integer;
  VariableName:string;
begin
  RegularExpression := TRegExpr.Create;
  try
  for CurrentNumberOfMethod:=0 to length(ArrayOfMethods)-1 do
    begin
       RegularExpression.Expression := ('\b'+TYPEOFVARIABLE+'\b') + '( .*?)([a-z,0-9,_,]*)';
       if RegularExpression.Exec(ArrayOfMethods[CurrentNumberOfMethod]) then
       repeat
         ReplaceStringBySpace(ArrayOfMethods[CurrentNumberOfMethod],RegularExpression.MatchPos[0],RegularExpression.MatchLen[0]);
         StartPosition:=RegularExpression.MatchPos[0] + RegularExpression.MatchLen[0];
         VariableName:=RegularExpression.Match[3];
         RegularExpression.Expression := '\b' + VariableName + '\b';
         if RegularExpression.ExecPos(RegularExpression.MatchPos[0] + RegularExpression.MatchLen[0]) then
         repeat
           ReplaceStringBySpace(ArrayOfMethods[CurrentNumberOfMethod],RegularExpression.MatchPos[0],RegularExpression.MatchLen[0]);
         until not (RegularExpression.ExecNext);
        RegularExpression.Expression := ('\b'+TYPEOFVARIABLE+'\b')+ '( .*?)([a-z,0-9,_,]*)';
       until not (RegularExpression.ExecPos(StartPosition));
    end;
  finally
    RegularExpression.Free;
  end;
end;

procedure Find_Aup_Pup();
var
  RegularExpression: TRegExpr;
  CurrentNumberOfGlobalVariable,CurrentNumberOfMethod:integer;
begin
  RegularExpression := TRegExpr.Create;
  try
  for CurrentNumberOfGlobalVariable := 0 to length(ArrayOfGlobalVariables)-1 do
    begin
      RegularExpression.Expression:='\b' + ArrayOfGlobalVariables[CurrentNumberOfGlobalVariable] + '\b';
      for CurrentNumberOfMethod:=0 to length(ArrayOfMethods)-1 do
        begin
          if RegularExpression.Exec(ArrayOfMethods[CurrentNumberOfMethod]) then
            inc(Aup);
        end;
    end;
  finally
    RegularExpression.Free;
  end;
  Pup:=length(ArrayOfGlobalVariables)*length(ArrayOfMethods);
end;

procedure Output();
begin
  Writeln('Number of global variable: ', length(ArrayOfGlobalVariables));
  Writeln('Aup: ',Aup);
  Writeln('Pup: ', Pup);
  Writeln('Aup/Pup = ', (Aup/Pup):0:5);
end;

begin
  ReadFromFile();
  DeleteCommentsAndLiterals();
  DivideIntoMethods();
  FindGlobalVariable();
  FindLocalVariable();
  Find_Aup_Pup();
  Output();
  readln;
end.


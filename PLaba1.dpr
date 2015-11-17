program PLaba1;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  RegExpr;
const
  FILE_NAME = 'Ñode2.txt';
  TYPEOFVARIABLE ='(void|char|int|short int|long int|unsigned long int|float|double|long float)';
type
  TRecordOfConstants=record
  ConstantName:string;
  Number:Integer;
  end;

  TMyRecordOfVariables=record
  VariableName: string;
  NumberOfVariables: Integer;
  end;

  TRecordOfVariableInMethod = record
    MethodName: string;
    ArrayOfVariable:array[1..10] of TMyRecordOfVariables;
    NumberOfVariable:Integer;
    end;
  TArrayOfVariableInMethod= array of TRecordOfVariableInMethod;
  TArrayOfConstants=array of TRecordOfConstants ;
var
  ArrayOfConstants:TArrayOfConstants;
  ArrayOfVariableInMethod:TArrayOfVariableInMethod;
  RegularExpression: TRegExpr;
  AnalysedCode,text: string;
  ArrayOfStrings, ArrayOfMethods: array of string;
  NeededFile: TextFile;
  NumberOfMethods,NumberOfConstants:Integer;

function FindTheNumberOfVarieble(AnalysedCode:string;Variable:string):integer;
var NumberOfVarieble:Integer;
    RegularExpression: TRegExpr;
begin
  NumberOfVarieble:=0;
 RegularExpression := TRegExpr.Create;
  try
    RegularExpression.Expression := '\b'+Variable+'\b';
    while RegularExpression.Exec(AnalysedCode) do
    begin
     inc(NumberOfVarieble);
     Delete(AnalysedCode,RegularExpression.MatchPos[0],RegularExpression.MatchLen[0]);
    end;
  finally
    RegularExpression.Free;
  end;
    result:=NumberOfVarieble;
end;

procedure FindConstant() ;
var RegularExpression:TRegExpr;
    CurrentConstantNumber:Integer;
begin
  SetLength(ArrayOfConstants,20);
  RegularExpression := TRegExpr.Create;
  try
    NumberOfConstants:=0;
    RegularExpression.Expression := '(#define)'+'([ ,a-z]*)'+'(.*?\n)';
    while RegularExpression.Exec(AnalysedCode) do
    begin
      inc(NumberOfConstants);
      ArrayOfConstants[NumberOfConstants].ConstantName:=trim(RegularExpression.Match[2]);
      Delete(AnalysedCode, RegularExpression.MatchPos[0], RegularExpression.MatchLen[0]);
    end;
  finally
    RegularExpression.Free;
  end;
  SetLength(ArrayOfConstants,NumberOfConstants+1);
   for CurrentConstantNumber:=1 to NumberOfConstants do
   ArrayOfConstants[CurrentConstantNumber].Number:=FindTheNumberOfVarieble(AnalysedCode,ArrayOfConstants[CurrentConstantNumber].ConstantName);
end;


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
    AnalysedCode := AnalysedCode + ArrayOfStrings[CurrentNumberOfStrings] + #10#13;
    AnalysedCode:=LowerCase(AnalysedCode);
end;

procedure DeleteCommentsAndLiterals();
var RegularExpression:TRegExpr;
begin
  RegularExpression := TRegExpr.Create;
  try
    RegularExpression.Expression := '(\/\/.*?\n|\/\*.*?\*\/|\".*?\"|''.*?'')';
    while RegularExpression.Exec(AnalysedCode) do
    begin
      Delete(AnalysedCode, RegularExpression.MatchPos[0], RegularExpression.MatchLen[0]);
    end;
  finally
    RegularExpression.Free;
  end;
end;

procedure DivideIntoMethods;
var
  IsMainElementFind: Boolean;
  tempAnalysedCode: string;
  RegularExpression:TRegExpr;
  CurrentPositionInAnalysedCode, CounterBracket,PositionOfRegularExpression: Integer;
begin
  RegularExpression := TRegExpr.Create;
  try
    RegularExpression.Expression := '(\b'+TYPEOFVARIABLE+'\b)' + '([ ,a-z,0-9,_,\n]*)'+'(\()';
    NumberOfMethods := 0;
    while RegularExpression.Exec(AnalysedCode) do
    begin
      inc(NumberOfMethods);
      SetLength(ArrayOfMethods, NumberOfMethods + 1);
      CounterBracket := 0;
      IsMainElementFind := False;
      for CurrentPositionInAnalysedCode := (RegularExpression.MatchPos[0] + RegularExpression.MatchLen[0]) to Length(AnalysedCode) do
      begin
        if AnalysedCode[CurrentPositionInAnalysedCode] = '{' then
        begin
          Inc(CounterBracket);
          IsMainElementFind := True;
        end;
        if AnalysedCode[CurrentPositionInAnalysedCode] = '}' then
          Dec(CounterBracket);
        if (CounterBracket = 0) and (IsMainElementFind = True) then
          Break;
      end;
      tempAnalysedCode := RegularExpression.Match[0];
      PositionOfRegularExpression:= RegularExpression.MatchPos[0] + RegularExpression.MatchLen[0];
      tempAnalysedCode:=Copy(AnalysedCode,PositionOfRegularExpression,CurrentPositionInAnalysedCode-PositionOfRegularExpression);
      ArrayOfMethods[NumberOfMethods] := tempAnalysedCode;
      SetLength(ArrayOfVariableInMethod,NumberOfMethods+1);
      ArrayOfVariableInMethod[NumberOfMethods].MethodName:=Trim(RegularExpression.Match[3]);
      Delete(AnalysedCode, RegularExpression.MatchPos[0], RegularExpression.MatchLen[0]);
    end;
  finally
    RegularExpression.Free;
  end;

end;

function FindBorderOfAnalysedCode(AnalysedCode:string):string;
var CurrentPositionInAnalysedCode,CounterBracket:Integer;
begin
  CounterBracket:=1;
  for CurrentPositionInAnalysedCode := (RegularExpression.MatchPos[2]-1 ) to length(AnalysedCode) do
      begin
        if AnalysedCode[CurrentPositionInAnalysedCode] = '{' then
          Inc(CounterBracket);
        if AnalysedCode[CurrentPositionInAnalysedCode] = '}' then
          Dec(CounterBracket);
        if (CounterBracket = 0)  then
          Break;
      end;
  result:=Copy(AnalysedCode,(RegularExpression.MatchPos[2]-1),(CurrentPositionInAnalysedCode-(RegularExpression.MatchPos[2] + RegularExpression.MatchLen[2])));
end;

procedure FindVariebleInMethod();
var CurrentMethod,NumberOfVarieble,CurrentNumbOfVar:Integer;
    AnalysedCode,CurrentVariable:string;
IsOverlap:Boolean;
begin
  SetLength(ArrayOfVariableInMethod,NumberOfMethods+1);
   RegularExpression := TRegExpr.Create;
  try
   for CurrentMethod:=1 to NumberOfMethods do
   begin
     NumberOfVarieble:=0;
   RegularExpression.Expression := ('\b'+TYPEOFVARIABLE+'\b')+'([ ,a-z,\*]*)'+'([;,=,\,,\[])';
    while RegularExpression.Exec(ArrayOfMethods[CurrentMethod]) do
    begin
      Inc(NumberOfVarieble);
      IsOverlap:=False;
      ArrayOfVariableInMethod[CurrentMethod].ArrayOfVariable[NumberOfVarieble].VariableName:=trim(RegularExpression.Match[2]);
      Delete(ArrayOfMethods[CurrentMethod], RegularExpression.MatchPos[0], RegularExpression.MatchLen[0]);
      CurrentVariable:= ArrayOfVariableInMethod[CurrentMethod].ArrayOfVariable[NumberOfVarieble].VariableName  ;
      for  CurrentNumbOfVar:=1 to (NumberOfVarieble) do
      begin
        if (ArrayOfVariableInMethod[CurrentMethod].ArrayOfVariable[CurrentNumbOfVar].VariableName=CurrentVariable) and (CurrentNumbOfVar<>NumberOfVarieble )then
        begin
        IsOverlap:=True;
        AnalysedCode:=FindBorderOfAnalysedCode(ArrayOfMethods[CurrentMethod]) ;
        break;
        end
        else
        AnalysedCode:= ArrayOfMethods[CurrentMethod];
      end;
     ArrayOfVariableInMethod[CurrentMethod].ArrayOfVariable[NumberOfVarieble].NumberOfVariables:=FindTheNumberOfVarieble(AnalysedCode,CurrentVariable);
      if IsOverlap=True then
      with ArrayOfVariableInMethod[CurrentMethod] do
       ArrayOfVariable[CurrentNumbOfVar].NumberOfVariables:= ArrayOfVariable[CurrentNumbOfVar].NumberOfVariables-ArrayOfVariable[NumberOfVarieble].NumberOfVariables-1;
      ArrayOfVariableInMethod[CurrentMethod].NumberOfVariable:=NumberOfVarieble;
    end;
    end;
  finally
    RegularExpression.Free;
  end;
end;

 procedure Output();
 var CurrentMethod,CurrentVarieble,CurrentConstant:Integer;
 begin
   for CurrentMethod:=1 to NumberOfMethods do
   begin
     Writeln;
     Writeln('Method: ',ArrayOfVariableInMethod[CurrentMethod].MethodName);
     for CurrentVarieble:=1 to ArrayOfVariableInMethod[CurrentMethod].NumberOfVariable  do
     with  ArrayOfVariableInMethod[CurrentMethod].ArrayOfVariable[CurrentVarieble]do
     Writeln(VariableName,' - ',NumberOfVariables);
   end;
   writeln('------------------------------------');
   for CurrentConstant:=1 to NumberOfConstants do
   Writeln(ArrayOfConstants[CurrentConstant].ConstantName,' - ',ArrayOfConstants[CurrentConstant].Number);

 end;

begin
  ReadFromFile();
  DeleteCommentsAndLiterals();
  FindConstant();
  DivideIntoMethods(); 
  FindVariebleInMethod();
  Output();
  readln;
end.


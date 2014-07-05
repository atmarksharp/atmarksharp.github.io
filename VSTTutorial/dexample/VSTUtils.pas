//******************************************************************************
//
//  VstUtils.pas
//  18 February 2000
//
//  Part of the Delphi VST SDK
//  by Frederic Vanmol
//     http://www.indubio.net         
//     http://www.frederic.vanmol.com
//     frevan@bigfoot.com
//
//------------------------------------------------------------------------------
//
//  Types : PPERect
//          PERect
//          ERect
//
//  Functions : FourCharToLong
//              FMod
//              dB2string
//              db2stringRound
//              float2string
//              long2string
//              float2stringAsLong
//              Hz2string (new)
//              ms2string (new)
//              gapSmallValue
//              invGapSmallValue
//              LogZ (note: this is the same as LogN in the Math unit)
//
//  Note : This unit requires the Delphi Math unit
//
//******************************************************************************
unit
    VstUtils;

interface


type
    PPERect = ^PERect;
    PERect = ^ERect;
    ERect = record
      top,
      left,
      bottom,
      right   : Smallint;
    end;


function FourCharToLong(C1, C2, C3, C4: Char): Longint;

function FMod(d1, d2: Double): Double;

procedure dB2string(value: Single; text: PChar);
procedure dB2stringRound(value: single; text: pchar);
procedure float2string(value: Single; text: PChar);
procedure long2string(value: Longint; text: PChar);
procedure float2stringAsLong(value: Single; text: PChar);
procedure Hz2string(samples, sampleRate: Single; text: pchar);
procedure ms2string(samples, sampleRate: Single; text: pchar);

function gapSmallValue(value, maxValue: Double): Double;
function invGapSmallValue(value, maxValue: Double): Double;

function logZ(z, x: Double): Double;



implementation

uses
    Math, SysUtils;

{ this function converts four char variables to one longint. }
function FourCharToLong(C1, C2, C3, C4: Char): Longint;
begin
  Result := Ord(C4)  + (Ord(C3) shl 8) + (Ord(C2) shl 16) + (Ord(C1) shl 24);
end;


function FMod(d1, d2: Double): Double;
var
   i: Integer;
begin
  try
    i := Trunc(d1 / d2);
  except
    on EInvalidOp do i := High(Longint);
  end;
  Result := d1 - (i * d2);
end;



procedure dB2string(value: Single; text: PChar);
begin
  if (value <= 0) then
    StrCopy(text, '   -°   ')
  else
    float2string(20 * log10(value), text);
end;

procedure dB2stringRound(value: single; text: pchar);
begin
  if (value <= 0) then
    StrCopy(text, '    -96 ')
  else
    long2string(Round(20 * log10(value)), text);
end;

procedure float2string(value: Single; text: PChar);
var
   TheString : String;
begin
  TheString := Format('%f', [value]);
  StrCopy(text, PChar(TheString));
end;

procedure long2string(value: Longint; text: PChar);
var
   aString : Array[0..31] of Char;
   TempS   : AnsiString;
begin
  if (value >= 100000000) then
  begin
    StrCopy(text, ' Huge!  ');
    Exit;
  end;

  TempS := Format('%7d', [Value]);
  StrCopy(aString, PChar(TempS));  // sprintf(aString, '%7d', value);
  aString[8] := #0;
  StrCopy(text, aString);
end;

procedure float2stringAsLong(value: Single; text: PChar);
var
   aString : Array[0..31] of char;
   TempS   : AnsiString;
begin
  if (value >= 100000000) then
  begin
    StrCopy(text, ' Huge!  ');
    Exit;
  end;

  TempS := Format('%7.0f', [value]);
  StrCopy(aString, PChar(TempS));  // sprintf(aString, '%7d', value);
  aString[8] := #0;
  StrCopy(text, aString);
end;

procedure Hz2string(samples, sampleRate: Single; text: pchar);
begin
  if (samples = 0) then
    float2string(0, text)
  else
    float2string(sampleRate / samples, text);
end;

procedure ms2string(samples, sampleRate: Single; text: pchar);
begin
  float2string(samples * 1000 / sampleRate, text);
end;

function gapSmallValue(value, maxValue: Double): Double;
begin
  Result := Power(maxValue, value);
end;

function invGapSmallValue(value, maxValue: Double): Double;
var
   r: Double;
begin
  r := 0;
  if (value <> 0) then
    r := logZ(maxValue, value);
  Result :=  r;
end;

function logZ(z, x: Double): Double;
begin
  Result := LogN(z, x);
end;


end.

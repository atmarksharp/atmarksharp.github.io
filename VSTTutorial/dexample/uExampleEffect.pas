unit
    uExampleEffect;

interface

uses
    DAEffect, DAudioE, VSTUtils;

const
     kTreshold  = 0;
     kFactor    = 1;
     kNumParams = 2;


type
    AExampleEffect = class(AudioEffect)
    private
      programName : Array[0..63] of Char;
      fTreshold,
      fFactor     : Single;
      vu          : Single;
    public
      constructor Create(audioMaster: TAudioMasterCallbackFunc; numPrograms,
                         numParams: Longint); override;
      destructor Destroy; override;

      procedure process(inputs, outputs: PPSingle; sampleframes: Longint); override;
      procedure processReplacing(inputs, outputs: PPSingle; sampleframes: Longint); override;

      procedure setParameter(index: Longint; value: Single); override;
      function getParameter(index: Longint): Single; override;
      procedure getParameterLabel(index: Longint; aLabel: PChar); override;
      procedure getParameterDisplay(index: Longint; text: PChar); override;
      procedure getParameterName(index: Longint; text: PChar); override;
      function getVu: Single; override;
    end;




implementation

uses
    SysUtils;


constructor AExampleEffect.Create(audioMaster: TAudioMasterCallbackFunc;
                                  numPrograms, numParams: Longint);
begin
  // we ignore numPrograms and numParams
  inherited Create(audioMaster, 1, kNumParams);

  fTreshold := 0.8;
  fFactor := 0.5;
  setProgram(0);
  setNumInputs(1);
  setNumOutputs(2);
  hasVu(TRUE);
  canProcessReplacing(TRUE);
  setUniqueID(FourCharToLong('E', 'x', 'm', 'E'));
  suspend;
  StrCopy(programName, 'Default');
end;

destructor AExampleEffect.Destroy;
begin
  inherited Destroy;
end;

function AExampleEffect.getVu: Single;
var
   cvu: Single;
begin
  cvu := vu;

  vu := 0;
  Result := cvu;
end;

procedure AExampleEffect.setParameter(index: Longint; value: Single);
begin
  case index of
    kTreshold :  fTreshold := value;
    kFactor   :  if (value < 1) then
                   fFactor := value
                 else
                   fFactor := 1;
  end;
end;

function AExampleEffect.getParameter(index: Longint): Single;
var
   v: Single;
begin
  v := 0;

  case index of
    kTreshold :  v := fTreshold;
    kFactor   :  v := fFactor;
  end;

  Result := v;
end;

procedure AExampleEffect.getParameterName(index: Longint; text: PChar);
begin
  case index of
    kTreshold :  StrCopy(text, 'Treshold');
    kFactor   :  StrCopy(text, ' Factor ');
  end; 
end;

procedure AExampleEffect.getParameterDisplay(index: Longint; text:PChar);
begin
  case index of
    kTreshold :  dB2string(fTreshold, text);
    kFactor   :  float2string(fFactor, text);
  end;
end;

procedure AExampleEffect.getParameterLabel(index:Longint; aLabel: PChar);
begin
  case index of
    kTreshold :  StrCopy(aLabel, '  dB    ');
    kFactor   :  StrCopy(aLabel, '        ');
  end; 
end;

//--------------------------------------------------------------------------------

procedure AExampleEffect.process(inputs, outputs: PPSingle; sampleframes: Longint);
var
   in1, out1, out2 : PSingle;
   temp : Single;
   i    : integer;
begin
  in1 := inputs^;
  out1 := outputs^;
  inc(outputs);
  out2 := outputs^;

  for i := 0 to sampleframes-1 do
  begin
    temp := in1^;
//    temp := dosomething(temp);
    out1^ := temp + out1^;
    out2^ := temp + out2^;

    inc(in1);
    inc(out1);
    inc(out2);
  end;
end;


//--------------------------------------------------------------------------------
// replacing

procedure AExampleEffect.processReplacing(inputs, outputs: PPSingle; sampleframes: Longint);
var
   in1, out1, out2 : PSingle;
   temp : Single;
   i    : integer;
begin
  in1 := inputs^;
  out1 := outputs^;
  inc(outputs);
  out2 := outputs^;

  for i := 0 to sampleframes-1 do
  begin
    temp := in1^;
//    temp := dosomething(temp);
    out1^ := temp;
    out2^ := temp;

    inc(in1);
    inc(out1);
    inc(out2);
  end;
end;




end.

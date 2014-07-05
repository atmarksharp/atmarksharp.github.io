unit
    uDoubler;

interface

uses
    Windows,
    DAEffect, DAudioE, VSTUtils, uEditor;

const
     kFactor    = 0;
     kNumParams = 1;


type
    ADoublerEditor = class;

    ADoubler = class(AudioEffect)
    private
      programName   : Array[0..31] of Char;
      vu            : Single;
      FFactor       : Single;
      function GetFactor: Single;
      procedure SetFactor(NewValue: Single);
      function GetDoublerEditor: ADoublerEditor;

    public
      constructor CreateADoubler(audioMaster: TAudioMasterCallbackFunc); virtual;
      destructor Destroy; override;

      procedure process(inputs, outputs: PPSingle; sampleframes: Longint); override;
      procedure processReplacing(inputs, outputs: PPSingle; sampleframes: Longint); override;
      procedure setProgram(aProgram: Longint); override;
      procedure setProgramName(name: PChar); override;
      procedure getProgramName(name: PChar); override;
      procedure setParameter(index: Longint; value: Single); override;
      function getParameter(index: Longint): Single; override;
      function getVu: Single; override;
      procedure suspend; override;

      property DoublerEditor: ADoublerEditor read GetDoublerEditor;
    end;


    ADoublerEditor = class(AEffEditor)
    private
      r            : ERect;
      useCount     : Longint;
      Editor       : TDoublerEditorWindow;
      systemWindow : HWnd;
      procedure SetEditorValues;
      function GetDoubler: ADoubler;
    public
      constructor Create(effect: AudioEffect); override;
      destructor Destroy; override;
      function getRect(var rect: PERect): Longint; override;
      function open(ptr: Pointer): Longint; override;
      procedure close; override;
      procedure idle; override;
      procedure update; override;

      property Doubler: ADoubler read GetDoubler;
    end;








implementation

uses
    SysUtils;


constructor ADoubler.CreateADoubler(audioMaster: TAudioMasterCallbackFunc);
begin
  inherited Create(audioMaster, 1, kNumParams);

  editor := ADoublerEditor.Create(Self);
  setProgram(0);
  setNumInputs(1);
  setNumOutputs(2);
  hasVu(TRUE);
  canProcessReplacing(FALSE);
  setUniqueID(FourCharToLong('D', 'b', 'l', 'r'));
  suspend;
  StrCopy(programName, 'Default');

  FFactor := 0.83;
end;

destructor ADoubler.Destroy;
begin
  inherited Destroy;
end;

procedure ADoubler.setProgram(aProgram: Longint);
begin
  curProgram := aProgram;
end;

procedure ADoubler.setProgramName(name: PChar);
begin
  StrCopy(programName, name);
end;

procedure ADoubler.getProgramName(name: PChar);
begin
  StrCopy(name, programName);
end;

procedure ADoubler.suspend;
begin
  {}
end;

function ADoubler.getVu: Single;
var
   cvu: Single;
begin
  cvu := vu;

  vu := 0;
  Result := cvu;
end;

procedure ADoubler.setParameter(index: Longint; value: Single);
begin
  case index of
    kFactor :  SetFactor(value);
  end;
end;

function ADoubler.getParameter(index: Longint): Single;
begin
  case index of
    kFactor :  Result := GetFactor;
  else
    Result := 0;
  end;
end;


//--------------------------------------------------------------------------------

procedure ADoubler.process(inputs, outputs: PPSingle; sampleframes: Longint);
var
   InBuf, Out1, Out2 : PSingle;
   a, d, f           : Single;
   i                 : Integer;
begin
  InBuf := inputs^;
  Out1 := outputs^;
  Out2 := PPSingle(Longint(outputs)+SizeOf(PSingle))^;
  f := FFactor;

  for i := 0 to sampleFrames-1 do
  begin
    a := InBuf^;

    // let's do some magic
    if a <> 0 then
      d := a * f
    else
      d := a;

    Out1^ := Out1^ + d;
    Out2^ := Out2^ + d;
    Inc(InBuf);
    Inc(Out1);
    Inc(Out2);
  end;
end;


//--------------------------------------------------------------------------------
// replacing

procedure ADoubler.processReplacing(inputs, outputs: PPSingle; sampleframes: Longint);
var
   InBuf, Out1, Out2 : PSingle;
   a, d, f           : Single;
   i                 : Integer;
begin
  InBuf := inputs^;
  Out1 := outputs^;
  Out2 := PPSingle(Longint(outputs)+SizeOf(PSingle))^;
  f := FFactor;

  for i := 0 to sampleFrames-1 do
  begin
    a := InBuf^;

    // let's do some magic
    if a <> 0 then
      d := a * f
    else
      d := a;

    Out1^ := d;
    Out2^ := d;
    Inc(InBuf);
    Inc(Out1);
    Inc(Out2);
  end;
end;


//------------------------------------------------------------------------------

function ADoubler.GetFactor: Single;
begin
  Result := FFactor;
end;

procedure ADoubler.SetFactor(NewValue: Single);
begin
  if NewValue > 1 then
    NewValue := 1
  else if NewValue < -1 then
    NewValue := -1;
    
  FFactor := NewValue;

  // this is where the editor window is notified of the param change
  if Assigned(DoublerEditor.Editor) then
    DoublerEditor.Editor.Factor := FFactor;
end;

function ADoubler.GetDoublerEditor: ADoublerEditor;
begin
  Result := (editor as ADoublerEditor);
end;








//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

constructor ADoublerEditor.Create(effect: AudioEffect);
begin
  inherited Create(effect);
  effect.setEditor(Self);
  useCount := 0;
end;

destructor ADoublerEditor.Destroy;
begin
  if useCount > 0 then
  begin
    useCount := 1;
    close;
  end;
  
  inherited Destroy;
end;

function ADoublerEditor.getRect(var rect: PERect): Longint;
begin
  r.top := 0;
  r.left := 0;
  r.bottom := 78;
  r.right := 268;
  rect := @r;
  Result := 1;
end;

function ADoublerEditor.open(ptr: Pointer): Longint;
begin
  // Remember the parent window
  systemWindow := HWnd(ptr);

  // Create window class, if we are called the first time
  Inc(useCount);
  if (useCount = 1) then
  begin
    { create an instance of the window }
    Editor := TDoublerEditorWindow.CreateParented(systemWindow);
    Editor.SetBounds(0, 0, Editor.Width, Editor.Height);
    Editor.Effect := Self.Doubler;
  end;

  { set values }
  SetEditorValues;

  { show the window }
  Editor.Show;

  Result := 1;
end;

procedure ADoublerEditor.close;
begin
  Dec(useCount);
  if useCount = 0 then
  begin
    Editor.Free;
    Editor := nil;
    systemWindow := 0;
  end;
end;

procedure ADoublerEditor.idle;
begin
  {}
end;

procedure ADoublerEditor.update;
begin
  if Assigned(Editor) then
    Editor.Refresh;
end;

function ADoublerEditor.GetDoubler: ADoubler;
begin
  Result := (effect as ADoubler);
end;

procedure ADoublerEditor.SetEditorValues;
begin
  if not Assigned(Editor) then
    Exit;
  if not Assigned(Doubler) then
    Exit;

  Editor.Factor := Doubler.FFactor;
end;








end.

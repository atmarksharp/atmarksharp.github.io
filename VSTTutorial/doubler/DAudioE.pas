//******************************************************************************
//
//  DAudioE.pas
//  version 1.16
//  3rd November 2000
//
//  Part of the Delphi VST SDK
//  by Frederic Vanmol
//     http://www.indubio.net
//     http://www.frederic.vanmol.com 
//     frevan@bigfoot.com
//
//------------------------------------------------------------------------------
//
//  Classes : AudioEffect
//            AEffEditor
//
//  Functions : dispatchEffectClass
//              getParameterClass
//              setParameterClass
//              processClass
//              processClassReplacing
//
//******************************************************************************
unit
    DAudioE;



interface

uses
    DAEffect, VSTUtils;


type
    AEffEditor = class;
    AudioEffect = class;


    AudioEffect = class
    protected
      // members
      sampleRate  : Single;
      editor      : AEffEditor;
      audioMaster : TAudioMasterCallbackFunc;
      numPrograms : Longint;
      numParams   : Longint;
      curProgram  : Longint;
      blockSize   : Longint;
      cEffect     : AEffect;

      // called from audio master
      procedure process(inputs, outputs: PPSingle; sampleFrames: Longint); virtual; abstract;
      procedure processReplacing(inputs, outputs: PPSingle; sampleFrames: Longint); virtual;
      function dispatcher(opCode, index, value: Longint; ptr: Pointer; opt: Single): Longint; virtual;
      procedure open; virtual;
      procedure close; virtual;
      function getProgram: Longint; virtual;
      procedure setProgram(aProgram: Longint); virtual; // don't forget to set curProgram
      procedure setProgramName(name: PChar); virtual;   // all following refer to curProgram
      procedure getProgramName(name: PChar);  virtual;
      procedure getParameterLabel(index: Longint; aLabel: PChar); virtual;
      procedure getParameterDisplay(index: Longint; text: PChar); virtual;
      procedure getParameterName(index: Longint; text: PChar); virtual;
      function getVu: Single; virtual;
      procedure setSampleRate(sampleRate: Single); virtual;
      procedure setBlockSize(aBlockSize: Longint); virtual;
      procedure suspend; virtual;
      procedure resume; virtual;

      // setup
      procedure setUniqueID(iD: Longint); virtual;  // must call this!
      procedure setNumInputs(inputs: Longint); virtual;
      procedure setNumOutputs(outputs: Longint); virtual;
      procedure hasVu(state: Boolean);  virtual;
      procedure hasClip(state: Boolean); virtual;
      procedure canMono(state: Boolean); virtual;
      procedure canProcessReplacing(state: Boolean); virtual;
      procedure setRealtimeQualities(qualities: Longint); virtual;
      procedure setOfflineQualities(qualities: Longint); virtual;
      procedure setInitialDelay(delay: Longint); virtual;

      // inquiry
      function getSampleRate: Single; virtual;
      function getBlockSize: Longint; virtual;

      // host communication
      function getMasterVersion: Longint; virtual;
      function getCurrentUniqueId: Longint; virtual;
      procedure masterIdle; virtual;
      function isInputConnected(input: Longint): Boolean; virtual;
      function isOutputConnected(output: Longint): Boolean; virtual;

    public
      constructor Create(audioMaster: TAudioMasterCallbackFunc; numPrograms, numParams: Longint); virtual;
      destructor Destroy; override;

      procedure setParameter(index: Longint; value: Single); virtual;
      function getParameter(index: Longint): Single; virtual;
      procedure setParameterAutomated(index: Longint; value: Single); virtual;

      function getAeffect: PAEffect;
      procedure setEditor(editor: AEffEditor);
    end;



    AEffEditor = class
    protected
      effect       : AudioEffect;
      systemWindow : Pointer;
      updateFlag   : Longint;

    public
      constructor Create(Effect: AudioEffect); virtual;
      destructor Destroy; override;

      function getRect(var rect: PERect): Longint; virtual;
      function open(ptr: Pointer): Longint; virtual;
      procedure close; virtual;
      procedure idle; virtual;

      procedure update; virtual;
      procedure postUpdate; virtual;
    end;




// The following function needs to be defined by the audio effect and is
//   called to create the audio effect object instance.  (?)
// I have commented this out from the original VST SDK. I don't think it's
//   necessary in Delphi (I don't use it).  
// !!!! function CreateEffectInstance(audioMaster: TAudioMasterCallbackFunc): AudioEffect;

function dispatchEffectClass(E: PAEffect; opCode, index, value: Longint; ptr: Pointer; opt: Single): Longint; cdecl;
//function getParameterClass(index: Longint): Single; cdecl;
function getParameterClass(E: PAEffect; index: Longint): Single; cdecl;
//procedure setParameterClass(index: Longint; value: Single); cdecl;
procedure setParameterClass(E: PAEffect; index: Longint; value: Single); cdecl;
procedure processClass(E: PAEffect; inputs, outputs: PPSingle; sampleFrames: Longint); cdecl;
procedure processClassReplacing(E: PAEffect; inputs, outputs: PPSingle; sampleFrames: Longint); cdecl;






implementation

uses
    SysUtils;


//------------------------------------------------------------------------------
//  AudioEffect

constructor AudioEffect.Create(audioMaster: TAudioMasterCallbackFunc;
                                    numPrograms, numParams: Longint);
begin
  Self.audioMaster := audioMaster;
  editor := nil;
  Self.numPrograms := numPrograms;
  Self.numParams := numParams;
  curProgram := 0;

  FillChar(cEffect, SizeOf(cEffect), #0);  // memset(&cEffect, 0, sizeof(cEffect));

  cEffect.Magic := FourCharToLong(kEffectMagic[1], kEffectMagic[2], kEffectMagic[3], kEffectMagic[4]);
  cEffect.dispatcher := dispatchEffectClass;
  cEffect.process := processClass;
  cEffect.setParameter := setParameterClass;
  cEffect.getParameter := getParameterClass;
  cEffect.numPrograms := numPrograms;
  cEffect.numParams := numParams;
  cEffect.numInputs := 1;
  cEffect.numOutputs := 2;
  cEffect.flags := 0;
  cEffect.resvd1 := 0;
  cEffect.resvd2 := 0;
  cEffect.initialDelay := 0;
  cEffect.realQualities := 0;
  cEffect.offQualities := 0;
  cEffect.ioRatio := 1;
  cEffect.vobject := Self;
  cEffect.user := nil;
  cEffect.uniqueID := FourCharToLong('N', 'o', 'E', 'f');
  cEffect.version := 1;
  cEffect.processReplacing := processClassReplacing;

  sampleRate := 44100;
  blockSize := 1024;
end;

destructor AudioEffect.Destroy;
begin
  if Assigned(editor) then
    editor.Free;
  inherited Destroy;
end;

function AudioEffect.dispatcher(opCode, index, value: Longint; ptr: Pointer;
                                opt: Single): Longint;
var
   v  : Longint;
   pe : PERect;
begin
  v := 0;

  case opCode of
    effOpen            :  open;
    effClose           :  close;
    effSetProgram      :  if (value < numPrograms) then
                            setProgram(value);
    effGetProgram      :  v := getProgram;
    effSetProgramName  :  setProgramName(PChar(ptr));
    effGetProgramName  :  getProgramName(PChar(ptr));
    effGetParamLabel   :  getParameterLabel(index, PChar(ptr));
    effGetParamDisplay :  getParameterDisplay(index, PChar(ptr));
    effGetParamName    :  getParameterName(index, PChar(ptr));
    effSetSampleRate   :  setSampleRate(opt);
    effSetBlockSize    :  setBlockSize(value);
    effMainsChanged    :  if (value = 0) then  suspend
                          else  resume;
    effGetVu           :  v := Round(getVu * 32767);

    // editor
    effEditGetRect     :  if Assigned(Editor) then
                          begin
                            pe := PPERect(ptr)^;
                            v := Editor.getRect(pe);
                            PPERect(ptr)^ := pe;
                          end;
    effEditOpen        :  if Assigned(editor) then
                            v := editor.open(ptr);
    effEditClose       :  if Assigned(editor) then
                            editor.close;
    effEditIdle        :  if Assigned(editor) then
                            editor.idle;

    // new
    effIdentify        :  v := FourCharToLong('N', 'v', 'E', 'f');
  end;

  Result := v;
end;

function AudioEffect.getMasterVersion: Longint;
var
   version: Longint;
begin
  version := 1;

  if Assigned(audioMaster) then
  begin
    version := audioMaster(@cEffect, audioMasterVersion, 0, 0, nil, 0);
    if (version = 0) then // old
      version := 1;
  end;

  Result := version;
end;

function AudioEffect.getCurrentUniqueId: Longint;
var
   id: Longint;
begin
  id := 0;
  if Assigned(audioMaster) then
    id := audioMaster(@cEffect, audioMasterCurrentId, 0, 0, nil, 0);
  Result := id;
end;

procedure AudioEffect.masterIdle;
begin
  if Assigned(audioMaster) then
    audioMaster(@cEffect, audioMasterIdle, 0, 0, nil, 0);
end;

function AudioEffect.isInputConnected(input: Longint): Boolean;
var
   ret: Longint;
begin
  ret := 0;
  if Assigned(audioMaster) then
    ret := audioMaster(@cEffect, audioMasterPinConnected, input, 0, nil, 0);

  Result := (ret = 0);
end;

function AudioEffect.isOutputConnected(output: Longint): Boolean;
var
   ret: Longint;
begin
  ret := 0;
  if Assigned(audioMaster) then
    ret := audioMaster(@cEffect, audioMasterPinConnected, output, 1, nil, 0);

  Result := (ret = 0);
end;


// flags
procedure AudioEffect.hasVu(state: Boolean);
begin
  if state then
    cEffect.flags := cEffect.Flags or effFlagsHasVu
  else
    cEffect.flags := cEffect.Flags and not effFlagsHasVu;
end;

procedure AudioEffect.hasClip(state: Boolean);
begin
  if state then
    cEffect.flags := cEffect.Flags or effFlagsHasClip
  else
    cEffect.flags := cEffect.Flags and not effFlagsHasClip;
end;

procedure AudioEffect.canMono(state: Boolean);
begin
  if state then
    cEffect.flags := cEffect.flags or effFlagsCanMono
  else
    cEffect.flags := cEffect.flags and not effFlagsCanMono;
end;

procedure AudioEffect.canProcessReplacing(state: Boolean);
begin
  if state then
    cEffect.flags := cEffect.flags or effFlagsCanReplacing
  else
    cEffect.flags := cEffect.flags and not effFlagsCanReplacing;
end;

procedure AudioEffect.setRealtimeQualities(qualities: Longint);
begin
  cEffect.realQualities := qualities;
end;

procedure AudioEffect.setOfflineQualities(qualities: Longint);
begin
  cEffect.offQualities := qualities;
end;

procedure AudioEffect.setInitialDelay(delay: Longint);
begin
  cEffect.initialDelay := delay;
end;

//------------------------------------------------------------------------------

procedure AudioEffect.setParameterAutomated(index: Longint; value: Single);
begin
  setParameter(index, value);
  if Assigned(audioMaster) then
    audioMaster(@cEffect, audioMasterAutomate, index, 0, nil, value);  // value is in opt
end;



procedure AudioEffect.setParameter(index: Longint; value: Single);
begin
  index := index;
  value := value;
end;

function AudioEffect.getParameter(index: Longint): Single;
begin
  index := index;
  Result := 0;
end;

function AudioEffect.getAeffect: PAEffect;
begin
  Result := @cEffect;
end;

procedure AudioEffect.setEditor(editor: AEffEditor);
begin
  Self.editor := editor;
  if Assigned(editor) then
    cEffect.flags := cEffect.flags or effFlagsHasEditor
  else
    cEffect.flags := cEffect.Flags and not effFlagsHasEditor;
end;

procedure AudioEffect.processReplacing(inputs, outputs: PPSingle; sampleFrames: Longint);
begin
  inputs := inputs;
  outputs := outputs;
  sampleFrames := sampleFrames;
end;

procedure AudioEffect.open;
begin
  {}
end;

procedure AudioEffect.close;
begin
  {}
end;

function AudioEffect.getProgram: Longint;
begin
  Result := curProgram;
end;

procedure AudioEffect.setProgram(aProgram: Longint);
begin
  curProgram := aProgram;
end;

procedure AudioEffect.setProgramName(name: PChar);
begin
  {}
end;

procedure AudioEffect.getProgramName(name: PChar);
begin
  StrCopy(name, '');
end;

procedure AudioEffect.getParameterLabel(index: Longint; aLabel: PChar);
begin
  index := index;
  StrCopy(aLabel, '');
end;

procedure AudioEffect.getParameterDisplay(index: Longint; text: PChar);
begin
  index := index;
  StrCopy(text, '');
end;

procedure AudioEffect.getParameterName(index: Longint; text: PChar);
begin
  index := index;
  StrCopy(text, '');
end;

function AudioEffect.getVu: Single;
begin
  Result := 0;
end;

procedure AudioEffect.setSampleRate(sampleRate: Single);
begin
  Self.sampleRate := sampleRate;
end;

procedure AudioEffect.setBlockSize(aBlockSize: Longint);
begin
  blockSize := blockSize;
end;

procedure AudioEffect.suspend;
begin
  {}
end;

procedure AudioEffect.resume;
begin
  {}
end;

procedure AudioEffect.setUniqueID(iD: Longint);
begin
  cEffect.uniqueID := iD;
end;

procedure AudioEffect.setNumInputs(inputs: Longint);
begin
  cEffect.numInputs := inputs;
end;

procedure AudioEffect.setNumOutputs(outputs: Longint);
begin
  cEffect.numOutputs := outputs;
end;

function AudioEffect.getSampleRate: Single;
begin
  Result := sampleRate;
end;

function AudioEffect.getBlockSize: Longint;
begin
  Result := blockSize;
end;





//------------------------------------------------------------------------------
//  AEffEditor

constructor AEffEditor.Create(Effect: AudioEffect);
begin
  Self.effect := effect;
end;

destructor AEffEditor.Destroy;
begin
  inherited Destroy;
end;

function AEffEditor.getRect(var rect: PERect): Longint;
begin
  rect := nil;
  Result := 0;
end;

function AEffEditor.open(ptr: Pointer): Longint;
begin
  systemWindow := ptr;
  Result := 0;
end;

procedure AEffEditor.close;
begin
  {}
end;

procedure AEffEditor.idle;
begin
  if updateFlag <> 0 then
  begin
    updateFlag := 0;
    update;
  end;
end;

procedure AEffEditor.update;
begin
  {}
end;

procedure AEffEditor.postUpdate;
begin
  updateFlag := 1;
end;




//------------------------------------------------------------------------------

function dispatchEffectClass (E: PAEffect; opCode, index, value: Longint;
                              ptr: Pointer; opt: Single): Longint;
var
   AE: AudioEffect;
begin
  AE := AudioEffect(e^.vobject);

  if (opCode = effClose) then
  begin
    AE.dispatcher(opCode, index, value, ptr, opt);
    AE.Free;
    Result := 1;
    Exit;
  end;

  Result := AE.dispatcher(opCode, index, value, ptr, opt);
end;


function getParameterClass(e: PAEffect; index: Longint): Single;
var
   AE: AudioEffect;
begin
  AE := AudioEffect(e^.vobject);
  Result := AE.getParameter(index);
end;

procedure setParameterClass(E: PAEffect; index: Longint; value: Single);
var
   AE: AudioEffect;
begin
  AE := AudioEffect(e^.vobject);
  AE.setParameter(index, value);
end;

procedure processClass(E: PAEffect; inputs, outputs: PPSingle; sampleFrames: Longint);
var
   AE: AudioEffect;
begin
  AE := AudioEffect(e^.vobject);
  AE.process(inputs, outputs, sampleFrames);
end;

procedure processClassReplacing(E: PAEffect; inputs, outputs: PPSingle; sampleFrames: Longint);
var
   AE: AudioEffect;
begin
  AE := AudioEffect(e^.vobject);
  AE.processReplacing(inputs, outputs, sampleFrames);
end;



initialization
  Set8087CW(Default8087CW or $3F);
end.

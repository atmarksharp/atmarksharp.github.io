{
  DAEffect.pas
  3rd December 1998

  Types : AEffect (record)
          TAudioMasterCallbackFunc (function)
          TDispatcherFunc (function)
          TProcessProc (procedure)
          TSetParameterProc (procedure)
          TGetParameterFunc (function)

  This unit is part of the Delphi VST SDK by Frédéric Vanmol
}
unit
    DAEffect;

interface

//---------------------------------------------------------------------------------------------
// misc def's
//---------------------------------------------------------------------------------------------
const
     kEffectMagic = 'VstP';


type
    PSingle = ^Single;
    PPSingle = ^PSingle;


type
    PAEffect = ^AEffect;

    TAudioMasterCallbackFunc = function (Effect: PAEffect; opcode, index,
                     value: Longint; ptr: Pointer; opt: Single): Longint; cdecl;
    TDispatcherFunc = function(Effect: PAEffect; opCode, index, value: Longint;
                               ptr: Pointer; opt: Single): Longint; cdecl;
    TProcessProc = procedure(Effect: PAEffect; inputs, outputs: PPSingle; sampleframes: Longint); cdecl;
    TSetParameterProc = procedure(Effect: PAEffect; index: Longint; parameter: Single); cdecl;
    TGetParameterFunc = function(Effect: PAEffect; index: Longint): Single; cdecl;



    AEffect = record
      Magic                 : Longint;            // must be kEffectMagic ('VstP')
      dispatcher            : TDispatcherFunc;
      process               : TProcessProc;
      setParameter          : TSetParameterProc;
      getParameter          : TGetParameterFunc;

      numPrograms           : Longint;
      numParams             : Longint;            // all programs are assumed to have numParams parameters
      numInputs             : Longint;            //
      numOutputs            : Longint;            //
      flags                 : Longint;            // see constants
      resvd1                : Longint;            // reserved, must be 0
      resvd2                : Longint;            // reserved, must be 0
      initialDelay          : Longint;            // for algorithms which need input in the first place
      realQualities         : Longint;            // number of realtime qualities (0: realtime)
      offQualities          : Longint;            // number of offline qualities (0: realtime only)
      ioRatio               : Single;             // input samplerate to output samplerate ratio, not used yet
      vobject               : Pointer;            // for class access (see AudioEffect.hpp), MUST be 0 else!
      user                  : Pointer;            // user access
      uniqueID              : Longint;            // pls choose 4 character as unique as possible.
                                                  // this is used to identify an effect for save+load
      version               : Longint;            //
      processReplacing      : TProcessProc;
      future                : Array[0..59] of Char;  // pls zero
    end;









//---------------------------------------------------------------------------------------------
// flags bits
//---------------------------------------------------------------------------------------------
const
     effFlagsHasEditor    = 1;     // if set, is expected to react to editor messages
     effFlagsHasClip      = 2;     // return > 1. in getVu() if clipped
     effFlagsHasVu        = 4;     // return vu value in getVu(); > 1. means clipped
     effFlagsCanMono      = 8;     // if numInputs == 2, makes sense to be used for mono in
     effFlagsCanReplacing = 16;    // supports in place output (processReplacing() exsists)

     
//---------------------------------------------------------------------------------------------
// dispatcher opCodes
//---------------------------------------------------------------------------------------------
const
     effOpen               = 0;        // initialise
     effClose              = 1;        // exit, release all memory and other resources!

     effSetProgram         = 2;        // program no in <value>
     effGetProgram         = 3;        // return current program no.
     effSetProgramName     = 4;        // user changed program name (max 24 char + 0) to as passed in string
     effGetProgramName     = 5;        // stuff program name (max 24 char + 0) into string

     effGetParamLabel      = 6;        // stuff parameter <index> label (max 8 char + 0) into string
                                       // (examples: sec, dB, type)
     effGetParamDisplay    = 7;        // stuff parameter <index> textual representation into string
                                       // (examples: 0.5, -3, PLATE)
     effGetParamName       = 8;        // stuff parameter <index> label (max 8 char + 0) into string
                                       // (examples: Time, Gain, RoomType)
     effGetVu              = 9;        // called if (flags & (effFlagsHasClip | effFlagsHasVu))

     // system
     effSetSampleRate      = 10;       // in opt (float)
     effSetBlockSize       = 11;       // in value
     effMainsChanged       = 12;       // the user has switched the 'power on' button to
                                       // value (0 off, else on). This only switches audio
                                       // processing; you should flush delay buffers etc.
     // editor
     effEditGetRect        = 13;       // stuff rect (top, left, bottom, right) into ptr
     effEditOpen           = 14;       // system dependant Window pointer in ptr
     effEditClose          = 15;       // no arguments
     effEditDraw           = 16;       // draw method, ptr points to rect
     effEditMouse          = 17;       // index: x, value: y
     effEditKey            = 18;       // system keycode in value
     effEditIdle           = 19;       // no arguments. Be gentle!
     effEditTop            = 20;       // window has topped, no arguments
     effEditSleep          = 21;       // window goes to background

     // new
     effIdentify           = 22;       // returns 'NvEf'

     effNumOpcodes         = 23;



//---------------------------------------------------------------------------------------------
// audioMaster opCodes
//---------------------------------------------------------------------------------------------
const
     audioMasterAutomate      = 0;      // index, value, returns 0
     audioMasterVersion       = 1;      // vst version, currently 2 (0 for older)
     audioMasterCurrentId     = 2;      // returns the unique id of a plug that's currently
                                        // loading
     audioMasterIdle          = 3;      // call application idle routine (this will
                                        // call effEditIdle for all open editors too)
     audioMasterPinConnected  = 4;      // inquire if an input or output is beeing connected;
                                        // index enumerates input or output counting from zero,
                                        // value is 0 for input and != 0 otherwise. note: the
                                        // return value is 0 for <true> such that older versions
                                        // will always return true.







implementation



end.

library
       Doubler;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  View-Project Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the DELPHIMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using DELPHIMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  DAEffect in 'DAEffect.pas',
  DAudioE in 'DAudioE.pas',
  VSTUtils in 'VSTUtils.pas',
  uDoubler in 'uDoubler.pas',
  uEditor in 'uEditor.pas' {DoublerEditorWindow};



var
   Effect : ADoubler;
   Oome   : Boolean;



function main(audioMaster: TAudioMasterCallbackFunc): PAEffect; cdecl; export;
begin
  // get vst version
  if audioMaster(nil, audioMasterVersion, 0, 0, nil, 0) = 0 then
  begin
    Result := nil;
    Exit;         // Old version
  end;

  effect := ADoubler.CreateADoubler(audioMaster);
  if not Assigned(effect) then
  begin
    Result := nil;
    Exit;
  end;

  if oome then
  begin
    Effect.Free;
    Result := nil;
    Exit;
  end;

  Result := effect.getAeffect;
end;



exports
       Main name 'main';

begin
end.

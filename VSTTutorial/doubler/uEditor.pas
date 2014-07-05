unit
    uEditor;


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, DAudioE, Spin;

type
  TDoublerEditorWindow = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    btnSet: TButton;
    spnFactor: TSpinEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnSetClick(Sender: TObject);
  private
    FSettingManually : Integer;
    FEffect          : AudioEffect;
    FFactor          : Single;
    procedure SetFactor(NewValue: Single);
    function GetSettingManually: Boolean;
    procedure SetSettingManually(NewValue: Boolean);
  public
    property Factor: Single read FFactor write SetFactor;
    property Effect: AudioEffect read FEffect write FEffect;
    property SettingManually: Boolean read GetSettingManually write SetSettingManually;
  end;



implementation

{$R *.DFM}

uses
    uDoubler;

procedure TDoublerEditorWindow.SetFactor(NewValue: Single);
begin
  if SettingManually then
    Exit;

  SettingManually := TRUE;
  spnFactor.Value := Round(NewValue * 100000);
  FFactor := NewValue;
  SettingManually := FALSE;
end;

function TDoublerEditorWindow.GetSettingManually: Boolean;
begin
  Result := (FSettingManually > 0);
end;

procedure TDoublerEditorWindow.SetSettingManually(NewValue: Boolean);
begin
  if NewValue = TRUE then
    Inc(FSettingManually)
  else if FSettingManually <> 0 then
    Dec(FSettingManually);
end;

procedure TDoublerEditorWindow.FormCreate(Sender: TObject);
begin
  Factor := 0.83;
end;

procedure TDoublerEditorWindow.btnSetClick(Sender: TObject);
begin
  if SettingManually then
    Exit;

  FFactor := spnFactor.Value / 100000;

  Effect.setParameterAutomated(kFactor, FFactor);
end;

end.

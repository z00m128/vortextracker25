unit UnloopDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TUnloopDlg = class(TForm)
    Label1: TLabel;
    UnloopCount: TEdit;
    Label2: TLabel;
    UnloopUpDown: TUpDown;
    CalcSlides: TCheckBox;
    OkBtn: TButton;
    CancelBtn: TButton;
    procedure UnloopCountKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  UnloopDialog: TUnloopDlg;

implementation

{$R *.dfm}

procedure TUnloopDlg.UnloopCountKeyPress(Sender: TObject; var Key: Char);
begin
  if Key in ['0'..'9'] then Exit;
  Key := #0;
end;

end.

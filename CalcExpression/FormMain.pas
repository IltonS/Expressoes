unit FormMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TFrmMain = class(TForm)
    BtnHello: TButton;
    procedure BtnHelloClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

function GetHelloMsg(): ShortString; stdcall;
  external 'ExParser.dll' name 'GetHelloMsg';

procedure TFrmMain.BtnHelloClick(Sender: TObject);
begin
  ShowMessage(GetHelloMsg);
end;

end.

unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, IBConnection, sqldb, FileUtil, SynEdit,
  SynHighlighterSQL, Forms, Controls, Graphics, Dialogs, DBGrids, Menus,
  StdCtrls, DbCtrls, references, DBData, MetaData, uschedule;

type

  { TForm1 }

  TForm1 = class(TForm)
    BrowseBtn: TButton;
    Button1: TButton;
    ConnectBtn: TButton;
    HostnameBtn: TEdit;
    DatabaseNameBtn: TEdit;
    HostLbl: TLabel;
    DBNameLbl: TLabel;
    HelpItem: TMenuItem;
    ScheduleItem: TMenuItem;
    SynSQLSyn1: TSynSQLSyn;
    UsernameBtn: TEdit;
    PasswordBtn: TEdit;
    CommitBtn: TButton;
    Datasource1: TDatasource;
    DBGrid1: TDBGrid;
    UserLbl: TLabel;
    PasswordLbl: TLabel;
    MainMenu1: TMainMenu;
    OpenDialog1: TOpenDialog;
    SQLQuery1: TSQLQuery;
    SynEdit1: TSynEdit;
    procedure BrowseBtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ConnectBtnClick(Sender: TObject);
    procedure DBNavigator1Click(Sender: TObject; Button: TDBNavButtonType);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure CommitBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ReferenceListItemClick(Sender: TObject);
    procedure ScheduleItemClick(Sender: TObject);
  end;

var
  Form1: TForm1;


implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.CommitBtnClick(Sender: TObject);
begin
  SQLQuery1.Close;
  SQLQuery1.SQL.Text := SynEdit1.LineText;
  SQLQuery1.Open;
end;

procedure TForm1.FormCreate(Sender: TObject);
var i:integer;
begin
  for i := 0 to High(Tables) do begin
    HelpItem.Add(Reference.CreateMenuItem(HelpItem, Tables[i]));
    HelpItem.Items[i].Tag := i;
  end;
end;

procedure TForm1.ReferenceListItemClick(Sender: TObject);
begin

end;

procedure TForm1.ScheduleItemClick(Sender: TObject);
begin
  ScheduleForm := TScheduleForm.Create(Form1);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
end;

procedure TForm1.BrowseBtnClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    DatabaseNameBtn.Caption := OpenDialog1.FileName;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  //SQLQuery1.Close;
  //SQLTransaction1.Active := False;
  //IBConnection1.Connected := False;
end;

procedure TForm1.ConnectBtnClick(Sender: TObject);
begin
  SQLQuery1.Close;
  DBData.DBConnector.SQLTransaction1.Active := False;
  DBData.DBConnector.IBConnection1.Connected := False;
  with DBData.DBConnector.IBConnection1 do begin
    HostName := HostnameBtn.Text;
    DatabaseName := DatabaseNameBtn.Text;
    Username := UsernameBtn.Text;
    Password := PasswordBtn.Text;
  end;
end;

procedure TForm1.DBNavigator1Click(Sender: TObject; Button: TDBNavButtonType);
begin

end;

end.

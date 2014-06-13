unit references;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, sqldb, FileUtil, Forms, Controls, Graphics, Dialogs,
  DBGrids, Menus, StdCtrls, ExtCtrls, EditBtn, MetaData, Grids, DbCtrls,
  types, DBData, ueditcard, UQuery, ufilters;

type



  { TReferenceForm }

  TReferenceForm = class(TForm)
    AddRecordBtn: TButton;
    AlterRecordBtn: TButton;
    DeleteRecordBtn: TButton;
    CheckBox1: TCheckBox;
    Datasource1: TDatasource;
    Grid1: TDBGrid;
    SQLQuery1: TSQLQuery;
    procedure AddRecordBtnClick(Sender: TObject);
    procedure AlterRecordBtnClick(Sender: TObject);
    procedure ApplyBtnClick(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure Grid1TitleClick(Column: TColumn);
    procedure DeleteRecordBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FixGrid;
    procedure DeleteCard(Id: string);
    procedure AfterCloseCard(AID: string);
    procedure Swap(a,b: Pointer);
  private
    Ascend: boolean;
    Cards: array of TCardForm;
    procedure IntKeyPress(Sender: TObject; var Key: char);
  public
    RefFilter: TFilterPack;
  end;

   { TReference }

  TReference = class(TObject)
  public
    ActiveTable: integer;
    Query, ParQuery: string;
    procedure CreateReference(Index: integer; AForm: TReferenceForm);
    procedure ShowReference(Sender: TObject);
    function CreateMenuItem(AOwner: TComponent; ATable: TTableInfo): TMenuItem;
  end;

var
  ReferenceForm: TReferenceForm;
  Reference: TReference;
 // RefFilter: TFilterPack;

implementation

{$R *.lfm}

{ TReferenceForm }
procedure TReferenceForm.AddRecordBtnClick(Sender: TObject);
var
  FForm: TCardForm;
begin
  FForm := TCardForm.Init(ReferenceForm, '0', Tables[Reference.ActiveTable], @ReferenceForm.AfterCLoseCard);
end;

procedure TReferenceForm.AlterRecordBtnClick(Sender: TObject);
var
  id: string;
  i: Integer;
begin
  id := SQLQuery1.FieldByName('Id').AsString;
  for i := 0 to high(Cards) do
    if Cards[i].ID = id then begin Cards[i].Show; exit; end;
  SetLength(Cards, Length(Cards) + 1);
  Cards[high(Cards)] := TCardForm.Init(ReferenceForm, id,
    Tables[Reference.ActiveTable], @ReferenceForm.AfterCLoseCard);
end;

procedure TReferenceForm.ApplyBtnClick(Sender: TObject);
var
  i: integer;
  fieldname: string;
begin
  RefFilter.SetImage(true);
  try
    SQLQuery1.Close;
    SQLQuery1.SQL.Text := Reference.Query;
    SelectQ(SQLQuery1,Self.RefFilter.FilterList,Tables[Reference.ActiveTable],[]);
    Reference.ParQuery := SQLQuery1.SQL.Text;
    SQLQuery1.Open;
  except
    on E: EDatabaseError do
      MessageDlg('Error', 'A database error has occurred. Technical error message: '
        + E.Message, mtError, [mbOK], 0);
  end;
  FixGrid;
end;

procedure TReferenceForm.CheckBox1Change(Sender: TObject);
begin
    Grid1.Columns[0].Visible := (Sender as TCheckBox).Checked;
end;

procedure TReferenceForm.FormClose(Sender: TObject;

  var CloseAction: TCloseAction);
var i: integer;
begin
  for i := 0 to high(Cards) do
    if Cards[i].Visible then Cards[i].Close;
end;

procedure TReferenceForm.Grid1TitleClick(Column: TColumn);
var
  direction: string;
begin
  try
    SQLQuery1.Close;
    if length(RefFilter.FilterList) = 0 then
      SQLQuery1.SQL.Text := Reference.Query
    else
      SQLQuery1.SQL.Text := Reference.ParQuery;
    if Ascend then
      direction := 'asc'
    else
      direction := 'desc';
    Ascend := not Ascend;
    SelectQ(SQLQuery1,RefFilter.FilterList,Tables[Reference.ActiveTable],[]);
    SQLQuery1.SQL.Add(format('order by %s %s',
      [Tables[Reference.ActiveTable].Fields[Column.Tag].Name,
      direction]));

    SQLQuery1.Open;
  except
    on E: EDatabaseError do
      MessageDlg('Error', 'A database error has occurred. Technical error message: '
        + E.Message, mtError, [mbOK], 0);
  end;
  FixGrid;
end;

procedure TReferenceForm.DeleteRecordBtnClick(Sender: TObject);
var
  id: string;
  i: Integer;
begin
  id := SQLQuery1.FieldByName('ID').AsString;
  if MessageDlg('Вы уверены ?','Вы точно хотите удалить запись ?', mtWarning, mbYesNo, 0)
    <> mrYes then exit;
  for i := 0 to high(Cards) do
    if Cards[i].ID = id then Cards[i].Free;
  SQLQuery1.Close;
  SQLQuery1.SQL.Text := format('Delete from %s where ID = %s', [
    Tables[Reference.ActiveTable].Name, id]);
  SQLQuery1.ExecSQL;
  DBConnector.SQLTransaction1.Commit;
  Reference.CreateReference(Reference.ActiveTable, Self);
end;

procedure TReferenceForm.IntKeyPress(Sender: TObject; var Key: char);
begin
    if not (key in ['0'..'9',#8]) then Key := #0;
end;

procedure TReferenceForm.FormCreate(Sender: TObject);
begin
  RefFilter := TFilterPack.Create(560,64,Self, @ApplyBtnClick);
  RefFilter.ActiveTable := @Tables[Reference.ActiveTable];
end;

procedure TReferenceForm.FixGrid;
var
  i, index: integer;
begin

  index := Reference.ActiveTable;
  for i := 0 to high(Tables[index].Fields) do begin
    Grid1.Columns.Items[i].Width := Tables[index].Fields[i].Width;
    Grid1.Columns.Items[i].Title.Caption := Tables[index].Fields[i].Translation;
    Grid1.Columns.Items[i].Tag := i;
  end;
end;

procedure TReferenceForm.DeleteCard(Id: string);
var
  i: Integer;
  j: Integer;
begin
  for i := 0 to high(Cards) do
    if Cards[i].ID = Id then begin
        for j := i to high(Cards) - 1 do
          swap(Cards[i],Cards[i+1]);
        break;
    end;
  SetLength(Cards, length(Cards) - 1);
end;

procedure TReferenceForm.AfterCloseCard(AID: string);
var
  i: Integer;
begin
  //DeleteCard(AID);
  ApplyBtnClick(nil);
  for i := 0 to high(Cards) do
    Cards[i].Refresh;
end;

procedure TReferenceForm.Swap(a, b: Pointer);
var
  c: pointer;
begin
  c := a;
  a := b;
  b := c;
end;

{ TReference }

procedure TReference.CreateReference(Index: integer; AForm: TReferenceForm);
var
  i: integer;
begin
  with AForm do begin
    RefFilter.ClearFilterList;
    RefFilter.ActiveTable := @Tables[Index];
    Reference.ActiveTable := index;
    SQLQuery1.close;
    SelectQ(SQLQuery1,RefFilter.FilterList,Tables[Index],[]);
    SQLQuery1.Open;
    FixGrid;
    Show;
  end;
end;

procedure TReference.ShowReference(Sender: TObject);
begin
  CreateReference((Sender as TMenuItem).Tag, ReferenceForm);
end;

function TReference.CreateMenuItem(AOwner: TComponent; ATable: TTableInfo): TMenuItem;
begin
  Result := TMenuItem.Create(AOwner);
  Result.Name := ATable.Name + 'Item';
  Result.Caption := ATable.Translation;
  Result.OnClick := @ShowReference;
end;

initialization
  Reference := TReference.Create;
end.

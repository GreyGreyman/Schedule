unit ueditcard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  DbCtrls, ExtCtrls, PairSplitter, MetaData, sqldb, db, DBData;

type

  TFinalize = procedure(AID: string) of object;

  { TValueEdit }

  TValueEdit = class(TObject)
    Edit: TControl;
    procedure Refresh(Table: TTableInfo; Index: Integer); virtual; abstract;
  end;

  { TValueDbEdit }

  TValueDbEdit = class(TValueEdit)
    procedure Refresh(Table: TTableInfo; Index: Integer); override;
    constructor Create(AOwner: TComponent; Table: TTableInfo; Index: Integer;
      FormDataSource: TDataSource);
  end;

  { TValueDbLookUp }

  TValueDbLookUp = class(TValueEdit)
    SqlQuery: TSQLQuery;
    Datasource: TDataSource;
    procedure Refresh(Table: TTableInfo; Index: Integer); override;
    constructor create(AOwner: TComponent; Table: TTableInfo; Index: Integer;
      FormDataSource: TDataSource);
  end;

  { TCardForm }

  TCardForm = class(TForm)
    AcceptBtn: TButton;
    CancelBtn: TButton;
    FormDatasource: TDatasource;
    FieldBox: TScrollBox;
    BtnPanel: TPanel;
    FormQuery: TSQLQuery;
    procedure AcceptBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure Refresh;
    function GetID: string;
    procedure SetEditsFixed(AFieldIndexes, AValueIndexes: array of integer);
    procedure InitControl(Sender: TControl; index: integer);
    constructor Init(TheOwner: TComponent; AId: string; ATable: TTableInfo;
      AFinalize: TFinalize);

  public
    Values: array of TValueEdit;
    ID: string;
    Table: TTableInfo;
    Adding: boolean;
    FinalizeFunc: TFinalize;
  end;

implementation

{$R *.lfm}

{ TValueDbLookUp }

procedure TValueDbLookUp.Refresh(Table: TTableInfo; Index: Integer);
begin
  SqlQuery.Close;
  SqlQuery.SQL.Text := format('select * from %s', [Table.Fields[index].RefTable]);
  SqlQuery.Open;
end;

constructor TValueDbLookUp.create(AOwner: TComponent ;Table: TTableInfo; Index: Integer;
  FormDataSource: TDataSource);
begin
  Inherited Create;
  Edit := TDBLookupComboBox.Create(AOwner);
  SqlQuery := TSQLQuery.Create(Edit);
  SqlQuery.DataBase := DBConnector.IBConnection1;
  SqlQuery.Transaction := DBConnector.SQLTransaction1;
  Datasource := TDataSource.Create(Edit);
  Datasource.DataSet := SqlQuery;

  SqlQuery.Close;
  SqlQuery.SQL.Text := format('select * from %s order by %s asc',[
    Table.Fields[index].RefTable,
    Table.Fields[index].RefField]);
  SqlQuery.Open;
  with (Edit as TDBLookupComboBox) do begin
    Style := csDropDownList;
    ListSource := Self.DataSource;
    DataSource := FormDatasource;
    ListField := Table.Fields[index].RefField;
    DataField := Table.Fields[index].Name;
    KeyField := Table.Fields[0].Name;
  end;
end;

{ TValueDbEdit }

procedure TValueDbEdit.Refresh(Table: TTableInfo; Index: Integer);
begin
    (Edit as TDBEdit).DataField := Table.Fields[index].Name;
end;

constructor TValueDbEdit.Create(AOwner: TComponent ;Table: TTableInfo; Index: Integer;
  FormDataSource: TDataSource);
begin
  Edit := TDBEdit.Create(AOwner);
  with (Edit as TDBEdit) do begin
    DataSource := FormDatasource;
    DataField := Table.Fields[index].Name;
  end;
end;

{ TCardForm }

procedure TCardForm.InitControl(Sender: TControl; index: integer);
begin
  with Sender do begin
    Top := 25 * index;
    Width := 150;
    Height := 20;
    Left := 120;
    Parent := FieldBox;
  end;
end;

constructor TCardForm.Init(TheOwner: TComponent; AId: string; ATable: TTableInfo; AFinalize: TFinalize);
var
  i: integer;
  FLabel: TLabel;
begin
  Create(TheOwner);
  Table := ATable;
  ID := AId;
  if ID = '0' then Adding := True;
  FinalizeFunc := AFinalize;

  FormQuery.Close;
  FormQuery.SQL.Text := format('select * from %s where ID = %s', [Table.Name, ID]);
  FormQuery.Open;

  SetLength(Values, length(Values) + 1);
  for i := 1 to High(Table.Fields) do begin
    FLabel := TLabel.Create(Self.FieldBox);
    with FLabel do begin
      Top := 25 * i; Width := 100;
      Height := 30;  Left := 20;
      Text := Table.Fields[i].Translation;
      Parent := FieldBox;
    end;
    SetLength(Values, length(Values) + 1);
    if Table.Fields[i].NeedRef then
      Values[i] := TValueDbLookUp.Create(FieldBox,Table,i,FormDatasource)
    else
      Values[i] := TValueDbEdit.Create(FieldBox,Table,i,FormDatasource);
    InitControl(Values[i].Edit,i);
  end;
  Self.Show;
end;

procedure TCardForm.AcceptBtnClick(Sender: TObject);
begin
  if ID = '0' then
    FormQuery.FieldByName('ID').AsString := GetID;
  FormQuery.ApplyUpdates;
  DBConnector.SQLTransaction1.Commit;
  FinalizeFunc(ID);
  Close;
end;

procedure TCardForm.CancelBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TCardForm.Refresh;
var
  i: Integer;
begin
  FormQuery.Close;
  FormQuery.SQL.Text := format('select * from %s where ID = %s', [Table.Name, ID]);
  FormQuery.Open;
  for i := 1 to high(Values) do
    Values[i].Refresh(Table, i);
end;

function TCardForm.GetID: string;
var
    TempQuery: TSQLQuery;
begin
    TempQuery := TSQLQuery.Create(Self);
    TempQuery.DataBase := DBConnector.IBConnection1;
    TempQuery.Transaction := DBConnector.SQLTransaction1;
    TempQuery.Close;
    TempQuery.SQL.Text := format('select next value for %s from RDB$DATABASE',[Table.Generator]);
    TempQuery.Open;
    result := TempQuery.FieldByName('GEN_ID').AsString;
end;

procedure TCardForm.SetEditsFixed(AFieldIndexes, AValueIndexes: array of integer);
var
  i: Integer;
begin
  FormDatasource.Edit;
  for i := 0 to high(AFieldIndexes) do
    with (Values[AFieldIndexes[i]].Edit as TDBLookupComboBox) do begin
      ItemIndex := AValueIndexes[i];
      Field.Value := KeyValue;
      Enabled := false;
    end;
end;
end.

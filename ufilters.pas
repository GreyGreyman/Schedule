unit ufilters;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, Controls, MetaData, Forms, ExtCtrls, Graphics;
type


  { TFilter }

  TFinalizer = procedure(Sender: TObject) of object;

  TPPack = ^TFilterPack;

  TFilter = class(TObject)
  public
    FieldNameBox, TypeBox: TComboBox;
    ValueEdit: TEdit;
    DeleteBtn: TButton;
    ValueType: string;
    Pack : ^TFilterPack;
    procedure OnFilterChange(Sender: TObject);
    procedure OnDeleteBtnClick(Sender: TObject);
    constructor Create(Index: integer; ATable: TTableInfo; AOwner: TWinControl;
      PPack: TPPack);
    destructor Destroy; override;
    procedure Init(Sender: TControl; Owner: TWinControl; Index, ALeft: integer);
    procedure ChangeFilter(AFieldIndex: integer; AType, AValue: string);
    function Condition(FilterType, FieldName, ParametrName: string): string;
  end;

  TFilters = array of TFilter;

  { TFilterPack }
  TFilterPack = class(TObject)
    FilterBox: TScrollBox;
    FilterList: TFilters;
    AcceptBtn, AddBtn, RemoveBtn: TButton;
    FieldLbl, TypeLbl, ValueLbl: TLabel;
    ActiveTable: ^TTableInfo;
    constructor Create(X, Y: integer; AOwner: TWinControl; AFinalize: TFinalizer);
    procedure ClearFilterList;
    procedure SetImage(Applied: boolean);
    procedure AddFilter;
  private
    Panel: TPanel;
    Image: TImage;
    procedure AddFilterBtnClick(Sender: TObject);
    procedure DeleteFilterBtnClick(Sender: TObject);
    procedure InitCntrl(AControl: TControl; ALeft, ATop, AWidth, AHeight: Integer; AParent: TWinControl);
    procedure IntKeyPress(Sender: TObject; var Key: char);
    procedure FilterTypeChange(Sender: TObject);
end;

function LoadPNgImage(Filepath: string): TBitmap;

implementation

{ TFilter }

procedure TFilter.OnFilterChange(Sender: TObject);
begin
 // SetImage(False);
end;

procedure TFilter.OnDeleteBtnClick(Sender: TObject);
begin
  //Pack^.DeleteFilter((Sender as TButton).Tag);
end;

constructor TFilter.Create(Index: integer; ATable: TTableInfo; AOwner: TWinControl; PPack: TPPack);
var
  i: integer;
begin
  inherited Create;
  Pack := PPack;
  FieldNameBox := TComboBox.Create(FieldNameBox);
  with FieldNameBox do begin
    Init(FieldNameBox, AOwner, Index, 5);
    for i := 0 to high(ATable.Fields) do
      Items.Add(ATable.Fields[i].Translation);
    ItemIndex := 0;
    OnChange := @Pack^.FilterTypeChange;
  end;
  TypeBox := TComboBox.Create(AOwner);
  with TypeBox do begin
    Items.Add('>');
    TypeBox.Items.Add('<');
    TypeBox.Items.Add('=');
    Items.Add('Содержит'); TypeBox.Items.Add('Начинается с');
    ItemIndex := 0;
    Init(TypeBox, AOwner, Index, 100);
    OnChange := @OnFilterChange;
  end;
  ValueEdit := TEdit.Create(AOwner);
  with ValueEdit do begin
    Init(ValueEdit,AOwner, Index, 195);
    OnChange := @OnFilterChange;
    OnKeyPress := @Pack^.IntKeyPress;
  end;
  DeleteBtn := TButton.Create(AOwner);
  //with DeleteBtn do begin
  //  //Init(DeleteBtn, ReferenceForm.FilterBox, Index, 280);
  //  Tag := Index;
  //  Width := 30;
  //  OnClick := @OnDeleteBtnClick;
  //end;
end;

destructor TFilter.Destroy;
begin
  inherited Destroy;
  FieldNameBox.Free;
  ValueEdit.Free;
  TypeBox.Free;
  DeleteBtn.Free;
end;

procedure TFilter.Init(Sender: TControl; Owner: TWinControl; Index, ALeft: integer);
begin
  Sender.Parent := Owner;
  Sender.Top := 5 + Index * 35;
  Sender.Width := 85;
  Sender.Height := 25;
  Sender.Left := ALeft;
  Sender.Tag := index;
end;

procedure TFilter.ChangeFilter(AFieldIndex: integer; AType, AValue: string);
var
  i: Integer;
begin
  FieldNameBox.ItemIndex := AFieldIndex;
  for i := 0 to TypeBox.Items.Count - 1 do
    if TypeBox.Items[i] = AType then begin
      TypeBox.ItemIndex := i;
      Break;
    end;
  ValueEdit.Caption := AValue;
end;

function TFilter.Condition(FilterType, FieldName, ParametrName: string): string;
begin
  case FilterType of
    '<', '>', '=', '<>':
      Result := format(' %s %s :%s', [FieldName, FilterType, ParametrName]);
    'Содержит':
      Result := format(' position(:%s in %s) <> 0', [ParametrName, FieldName]);
    'Начинается с':
      Result := format(' position(:%s in %s) = 1', [ParametrName, FieldName]);
    else
      Result := '';
  end;
end;

{ TFilterPack }

constructor TFilterPack.Create(X, Y: integer; AOwner: TWinControl; AFinalize: TFinalizer);
begin
  inherited create;
  Panel := TPanel.Create(AOwner);
  Panel.Parent := AOwner;
  Panel.Left:= X;
  Panel.Top := Y;
  Panel.Height := 410;
  Panel.Width := 310;

  FieldLbl := TLabel.Create(Panel);
  InitCntrl(FieldLbl, 8, 60, 0, 0, Panel);
  FieldLbl.Caption := 'Поле';

  TypeLbl := TLabel.Create(Panel);
  InitCntrl(TypeLbl, 110, 60, 0, 0, Panel);
  TypeLbl.Caption := 'Тип фильтра';

  ValueLbl := TLabel.Create(Panel);
  InitCntrl(ValueLbl, 200, 60, 0, 0, Panel);
  ValueLbl.Caption := 'Поле';

  AcceptBtn := TButton.Create(Panel);
  AcceptBtn.OnClick := AFinalize;
  AcceptBtn.Caption := 'Применить';
  InitCntrl(AcceptBtn, 8, 15, 80, 25, Panel);

  RemoveBtn := TButton.Create(Panel);
  RemoveBtn.Caption := 'Удалить';
  RemoveBtn.OnClick := @DeleteFilterBtnClick;
  InitCntrl(RemoveBtn, 184, 15, 80, 25, Panel);

  AddBtn := TButton.Create(Panel);
  AddBtn.Caption := 'Добавить';
  AddBtn.OnClick := @AddFilterBtnClick;
  InitCntrl(AddBtn, 96, 15, 80, 25, Panel);

  Image := TImage.Create(Panel);
  InitCntrl(Image, 269, 15, 25, 25, Panel);
  Image.AutoSize := True;
  SetImage(false);
  Image.ShowHint := true;

  FilterBox := TScrollBox.Create(AOwner);
  InitCntrl(FilterBox, 5, 95, 300, 310, Panel);
  FilterBox.VertScrollBar.Tracking := True;
end;

procedure TFilterPack.AddFilterBtnClick(Sender: TObject);
begin
  AddFilter;
end;

procedure TFilterPack.AddFilter;
begin
  SetLength(FilterList, Length(FilterList) + 1);
  FilterList[High(FilterList)] := TFilter.Create(High(FilterList),
   ActiveTable^, FilterBox, @Self);
  FilterList[High(FilterList)].Pack := @Self;
  SetImage(False);
end;

procedure TFilterPack.InitCntrl(AControl: TControl; ALeft, ATop, AWidth,
  AHeight: Integer; AParent: TWinControl);
begin
  AControl.Parent := AParent;
  AControl.Left := ALeft;
  AControl.Top := ATop;
  AControl.Width := AWidth;
  AControl.Height := AHeight;
end;

procedure TFilterPack.SetImage(Applied: boolean);
begin
  if Applied then begin
    Image.Picture.Bitmap := LoadPNgImage('Ok.png');
    Image.Hint := 'Фильтры применены';
  end
  else
  begin
    Image.Picture.Bitmap := LoadPNgImage('cancel.png');
    Image.Hint := 'Фильтры не применены';
  end;
end;

procedure TFilterPack.FilterTypeChange(Sender: TObject);
var
  Index: integer;
begin
  if (Sender as TComboBox).ItemIndex = -1 then exit;
  Index := (Sender as TComboBox).ItemIndex;
  if ActiveTable^.Fields[Index].ValueType = 'string' then begin
    index := (Sender as TComboBox).Tag;
    FilterList[index].TypeBox.Items.Clear;
    FilterList[index].TypeBox.Items.AddStrings(
      ['>', '<', '=', '<>', 'Содержит', 'Начинается с']);
    FilterList[index].ValueEdit.OnKeyPress := nil;
  end
  else
  begin
    index := (Sender as TComboBox).tag;
    FilterList[index].ValueEdit.Clear;
    with FilterList[index].TypeBox do begin
      Items.Clear;
      Items.AddStrings(['>', '<', '=', '<>']);
      ItemIndex := 0;
      FilterList[index].ValueEdit.OnKeyPress := @intKeyPress;
    end;
  end;
  FilterList[index].ValueType := ActiveTable^.Fields[Index].ValueType;
  SetImage(False);
end;

procedure TFilterPack.IntKeyPress(Sender: TObject; var Key: char);
begin
    if not (key in ['0'..'9',#8]) then Key := #0;
end;

function LoadPNgImage(Filepath: string): TBitmap;
var
  PNGImage: TPortableNetworkGraphic;
begin
  PNGImage := TPortableNetworkGraphic.Create();
  PNGImage.LoadFromFile('Images\' + Filepath);
  Result := TBitmap.Create();
  Result.Assign(PNGImage);
end;

procedure TFilterPack.DeleteFilterBtnClick(Sender: TObject);
begin
  if Length(FilterList) = 0 then
    Exit;
  FilterList[high(FilterList)].Free;
  SetLength(FilterList, Length(FilterList) - 1);
  SetImage(False);
end;


procedure TFilterPack.ClearFilterList;
var
  i: integer;
begin
  for i := 0 to high(FilterList) do
    FilterList[i].Free;
  SetLength(FilterList, 0);
  SetImage(True);
end;

end.

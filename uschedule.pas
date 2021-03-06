unit uschedule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, DbCtrls, ExtCtrls, Buttons, Menus, references, MetaData, sqldb, db,
  types, UQuery, ufilters, math, DBData, ueditcard;

type

  TStringArray = array of String;

  { TAxis }

  TAxis = class
    id: array of integer;
    value: TStringList;
    Count: integer;
    constructor Create(ATable: TTableInfo; AField: TFieldInfo);
  end;

  { TFieldData }

  TFieldData = class(TObject)
    Name, Value : string;
    constructor Create(AName: string);
  end;

  { TRecordData }

  TRecordData = class(TObject)
    Fields: array of TFieldData;
    Buttons: array of TSpeedButton;
    constructor Create;
  end;

  { TCellData }

  TCellData = class(TObject)
    private
      Records: array of TRecordData;
      Height: integer;
      Opened: boolean;
      AddBtn, ShowBtn: TSpeedButton;
    public
      procedure AddRecord(AQuery: TSQLQuery);
      procedure CreateBtns(AParent: TWinControl; ACol, ARow: Integer);
      procedure RemoveBtns;
      procedure InitBtnPositions(ACol, ARow: integer);
      procedure Close;
      destructor Destroy; override;
  end;

  { TScheduleForm }
  TScheduleForm = class(TForm)
    FieldNamesItem: TMenuItem;
    SortedOutItem: TMenuItem;
    ScheduleMenu: TMainMenu;
    ExportItem: TMenuItem;
    HTMLItem: TMenuItem;
    PreferencesItem: TMenuItem;
    ExportDlg: TSaveDialog;
    ScheduleGrid: TDrawGrid;
    ScheduleDatasource: TDatasource;
    ScheduleQuery: TSQLQuery;
    CheckGroup: TCheckGroup;
    Timer1: TTimer;
    XFieldLbl: TLabel;
    YFieldLbl: TLabel;
    YFieldBox: TComboBox;
    XFieldBox: TComboBox;
    procedure ApplyBtnClick(Sender: TObject);
    procedure CheckGroupItemClick(Sender: TObject; Index: integer);
    procedure FieldNamesItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure HTMLItemClick(Sender: TObject);
    procedure PreferencesItemClick(Sender: TObject);
    procedure ScheduleGridDblClick(Sender: TObject);
    procedure ScheduleGridDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure ScheduleGridDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure ScheduleGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure ScheduleGridEndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure ScheduleGridMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ScheduleGridStartDrag(Sender: TObject; var DragObject: TDragObject
      );
    procedure SetData;
    function MaxWidth(AStringList: TStringList): integer;
    procedure FixHeights(Row: integer);
    function GetTable(ATableName: string): TTableInfo;
    function GetFilters(AFieldName: string; AFilters: TFilters): TFilters;
    procedure InitHeights(ACol, ARow, AValue: integer);
    procedure InitDeleteBtn(Button: TButton; X, Y: Integer);
    procedure DeleteBtnClick(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure AlterBtnClick(Sender: TObject);
    procedure ShowBtnClick(Sender: TObject);
    procedure AfterCardClose(AId: string);
    procedure AddStringValue(var AArray: TStringArray; AValue: String);
    procedure InitHints;
    procedure InitGlyphs;
    procedure AddBtnProc(AProc: TNotifyEvent);
    procedure CellClick(ACol, ARow: integer);
    procedure MoveCellBtns;
    function CreateButton(AParent: TWinControl; AOnClick: TNotifyEvent;
      AHint: string): TSpeedButton;
    function CreateRecordBtn(AParent: TWinControl; ID: string; AOnClick: TNotifyEvent;
      APicture, AHint: string): TSpeedButton;
    function CreateCellBtn(AParent: TWinControl; AOnClick: TNotifyEvent; ACaption,
      AHint: string): TSpeedButton;
    procedure InitBtnProcs;
    function GetHtmlString: string;
    procedure DragRecord(ID, ToCol, ToRow : integer);
    procedure SortedOutItemClick(Sender: TObject);
    procedure XFieldBoxChange(Sender: TObject);
    procedure YFieldBoxChange(Sender: TObject);
    procedure InvalidateGroupCheck;
    function ScheduleTable: TTableInfo;
  private
    CheckedCount, LastCol, LastRow, CurCol, CurRow, OpenedCol, OpenedRow: integer;
    MousePos: TPoint;
    DragID: integer;
    Initialized, ShowFieldNames, ShowSortedOut: Boolean;
    XFields, YFields: TAxis;
    XField, YField: TFieldInfo;
    Data : array of array of TCellData;
    MaxHeights: array of integer;
    SFilters: TFilterPack;
    Cards: array of TCardForm;
    Referenceforms: array of TReferenceForm;
  end;

  var
    ScheduleForm: TScheduleForm;
    BtnProcs: array of TNotifyEvent;
    BtnHints, BtnGlyphs: array of string;

  const
    TextHeight = 20;
    BtnCount = 2;
    BtnAspect = 30;

implementation

{$R *.lfm}

{ TAxis }

constructor TAxis.Create(ATable: TTableInfo; AField: TFieldInfo);
var
  i: Integer;
  FieldName: string;
  TempFilters: TFilters;
begin
  inherited Create;
  value := TStringList.Create;
  FieldName := AField.RefField;
  with ScheduleForm do begin
   if ScheduleForm.ShowSortedOut then
    TempFilters := GetFilters(AField.Translation ,SFilters.FilterList)
  else
    TempFilters := nil;
  ScheduleQuery.Close;
  SelectQ(ScheduleQuery,  GetFilters(AField.Translation ,SFilters.FilterList), ATable, [ATable.FieldByName(AField.RefField)]);
  //temp := ScheduleQuery.SQL.Text;
  ScheduleQuery.Open;

  Count := ScheduleQuery.RowsAffected ;
  SetLength(id, Count);

  for i := 0 to Count - 1 do begin
     value.Add(ScheduleQuery.FieldByName(FieldName).AsString);
     id[i] := ScheduleQuery.Fields[0].AsInteger;
     ScheduleQuery.Next;
  end;
  end;
end;

{ TCellData }

procedure TCellData.AddRecord(AQuery: TSQLQuery);
var
  i: Integer;
begin
  SetLength(Records ,Length(Records) + 1);
  Records[High(Records)] := TRecordData.Create;
  Height += ScheduleForm.CheckedCount * TextHeight;
  for i := 0 to AQuery.FieldCount - 1 do
    Records[High(Records)].Fields[i].Value := AQuery.Fields[i].AsString;
end;

procedure TCellData.CreateBtns(AParent: TWinControl ; ACol, ARow: Integer);
var
  i: Integer;
  j: Integer;
  count: Integer;
  temp: TRect;
begin
  temp := ScheduleForm.ScheduleGrid.CellRect(ACol, ARow);
  count := (temp.Bottom - temp.Top) div ScheduleForm.CheckedCount div TextHeight;
  for i := 0 to high(Records) do begin
    SetLength(Records[i].Buttons, BtnCount);
    for j := 0 to high(Records[i].Buttons) do
      Records[i].Buttons[j] := ScheduleForm.CreateRecordBtn(AParent,
        Records[i].Fields[0].Value, BtnProcs[j], BtnGlyphs[j], BtnHints[j]);
    count -= 1;
    if count = 0 then break;
  end;
  AddBtn := ScheduleForm.CreateCellBtn(AParent, BtnProcs[High(BtnProcs) - 1],
    'Добавить', BtnHints[High(BtnHints) - 1]);
  ShowBtn := ScheduleForm.CreateCellBtn(AParent, BtnProcs[High(BtnProcs)],
    'Отобразить', BtnHints[High(BtnHints)]);
end;

procedure TCellData.RemoveBtns;
var
  i: Integer;
  j: Integer;
begin
  for i := 0 to High(Records) do begin
    for j := 0 to High(Records[i].Buttons) do
      FreeAndNil(Records[i].Buttons[j]);
    SetLength(Records[i].Buttons, 0);
  end;
    FreeAndNil(AddBtn);
    FreeAndNil(ShowBtn);
end;

procedure TCellData.InitBtnPositions(ACol, ARow: integer);
var
  i, j: Integer;
  TempRect: TRect;
  Temp: Integer;
begin
  TempRect := ScheduleForm.ScheduleGrid.CellRect(Acol, ARow);
  for i := 0 to High(Records) do
    for j := 0 to High(Records[i].Buttons) do begin
        Records[i].Buttons[j].Top := TempRect.Top
          + i*TextHeight*ScheduleForm.CheckedCount + j*BtnAspect;
        Records[i].Buttons[j].Left := TempRect.Right - BtnAspect - 1;
    end;
    temp := (TempRect.Right - TempRect.Left) div 2;

    AddBtn.Left := TempRect.Left;
    AddBtn.Width := Temp + 1;
    AddBtn.Top := TempRect.Bottom - AddBtn.Height;

    ShowBtn.Left := TempRect.Left + Temp - 1;
    ShowBtn.Width := Temp;
    ShowBtn.Top := TempRect.Bottom - AddBtn.Height;
end;

procedure TCellData.Close;
begin
    Opened := false;
    RemoveBtns;
end;

destructor TCellData.Destroy;
begin
  inherited Destroy;
  RemoveBtns;
end;

{ TRecordData }

constructor TRecordData.Create;
var
  i : integer;
begin
  inherited Create;
  SetLength(Fields, length(ScheduleForm.ScheduleTable.Fields));
  for i := 0 to High(Fields) do
    Fields[i] := TFieldData.Create(ScheduleForm.ScheduleTable.Fields[i].Translation);
end;

{ TFieldData }

constructor TFieldData.Create(AName: string);
begin
  inherited create;
  Name := AName;
end;

{ TScheduleForm }

procedure TScheduleForm.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  CheckedCount := 0;
  for i := 1 to high(ScheduleTable.Fields) do
    with ScheduleTable.Fields[i] do begin
        CheckGroup.Items.Add(Translation);
        CheckGroup.Checked[i-1] := true;
        CheckedCount += 1;
        XFieldBox.Items.Add(Translation);
        YFieldBox.Items.Add(Translation);
    end;
  XFieldBox.ItemIndex := 0;
  YFieldBox.ItemIndex := 0;

  SFilters := TFilterPack.Create(10, 315, Self, @Self.ApplyBtnClick);
  SFilters.ActiveTable := @Tables[High(Tables)];
  InitBtnProcs;
  InitGlyphs;
  InitHints;

  ShowFieldNames := True;
  ShowSortedOut := True;
  OpenedRow:= 0; OpenedCol := 0;
  InvalidateGroupCheck;
  Show;
end;

procedure TScheduleForm.FormDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  If (Source = ScheduleGrid) and
    ((ScheduleGrid.MouseToCell(Point(x,y)).x <> 0) or
      (ScheduleGrid.MouseToCell(Point(x,y)).y <>0)) then Accept := true;
end;

procedure TScheduleForm.HTMLItemClick(Sender: TObject);
var
  AFile: TextFile;
begin
  if not ExportDlg.Execute then exit;
  AssignFile(AFile, ExportDlg.FileName);
  Rewrite(AFile);
  Write(AFile, UTF8ToSys(GetHtmlString));
  CloseFile(AFile);
end;

procedure TScheduleForm.PreferencesItemClick(Sender: TObject);
begin

end;

procedure TScheduleForm.ScheduleGridDblClick(Sender: TObject);
begin
  CellClick(CurCol, CurRow);
end;

procedure TScheduleForm.ScheduleGridDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  CurCell: TPoint;
begin
  CurCell := ScheduleGrid.MouseToCell(Point(x,y));
  if (CurCell.x <> 0) and (CurCell.y <> 0) then
    DragRecord(DragID,CurCell.x, CurCell.y);
  ApplyBtnClick(Self);
  CellClick(OpenedCol, OpenedRow);
end;

procedure TScheduleForm.ScheduleGridDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var
  c: Classes.TPoint;
begin
  c := ScheduleGrid.MouseToCell(Point(x,y));
  Accept := (Source = ScheduleGrid) and (c.x <> 0) and (c.y <> 0);
end;

procedure TScheduleForm.ScheduleGridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  i, j: Integer;
  k: Integer;
  temp: String;
begin
  if (not Initialized) or ((XFields.Count = 0) or (YFields.Count = 0)) then exit;
  if (aCol = 0) and (aRow = 0) then begin
    if CheckedCount > 1 then begin
      ScheduleGrid.Canvas.TextOut(aRect.Left + 5, aRect.bottom - 20, YFieldBox.Caption);
      ScheduleGrid.Canvas.TextOut(aRect.Right - ScheduleGrid.Canvas.TextWidth(XFieldBox.Caption) - 5,
        aRect.Top, XFieldBox.Caption);
      ScheduleGrid.Canvas.Line(aRect.TopLeft,aRect.BottomRight);
    end;
  end
  else if (aCol = 0) and (aRow <> 0)  then begin
    ScheduleGrid.Canvas.TextOut(aRect.Left + 5, aRect.Top, YFields.value[aRow - 1])
  end
  else if (aRow = 0) and (aCol <> 0) then begin
    ScheduleGrid.Canvas.TextOut(aRect.Left + 5, aRect.Top, XFields.value[aCol - 1])
  end
  else if (aRow + aCol <> 0) then
    if (Data[aCol][aRow] <> Nil) and (length(Data[aCol][aRow].Records) <> 0) then begin
      j := 0;
      for k := 0 to high(Data[aCol][aRow].Records) do begin
        for i := 0 to High(Data[aCol][aRow].Records[k].Fields) - 1 do
          if CheckGroup.Checked[i] then begin
            ScheduleGrid.Canvas.Brush.Style := bsClear;
            if ShowFieldNames then temp :=  Format('%s : %s', [
                Data[aCol][aRow].Records[k].Fields[i + 1].Name,
                Data[aCol][aRow].Records[k].Fields[i + 1].Value])
            else temp :=  Format('%s', [
                Data[aCol][aRow].Records[k].Fields[i + 1].Value]);
            ScheduleGrid.Canvas.TextOut(aRect.Left + 5, aRect.Top + j*TextHeight, temp);
            j += 1;
          end;
        ScheduleGrid.Canvas.Pen.Style := psDot;
        ScheduleGrid.Canvas.Pen.Color := clGray;
        ScheduleGrid.Canvas.Line(aRect.Left, aRect.Top + j*TextHeight, aRect.Right,
          aRect.Top + j*TextHeight);
      end;
      if length(Data[aCol][aRow].Records) > 1 then
        if (CheckedCount > 1) and (Data[aCol][aRow].Height > MaxHeights[aRow]) then begin
          ScheduleGrid.Canvas.Brush.Style := bsSolid;
          ScheduleGrid.Canvas.Brush.Color := clPurple;
          ScheduleGrid.Canvas.Pen.Color:= clPurple;
          ScheduleGrid.Canvas.Polygon([
            Point(aRect.Right, aRect.Bottom - 10),
            aRect.BottomRight,
            Point(aRect.Right - 10, aRect.Bottom)]);
        end;
    end;
  ScheduleGrid.Canvas.Brush.Style := bsClear;
  ScheduleGrid.Canvas.Pen.Color := clBlack;
  ScheduleGrid.Canvas.Pen.Style := psSolid;
  ScheduleGrid.Canvas.Rectangle(aRect.Left, aRect.Top, aRect.Right - 1, aRect.Bottom - 1);
  MoveCellBtns;
end;

procedure TScheduleForm.ScheduleGridEndDrag(Sender, Target: TObject; X,
  Y: Integer);
begin

end;

procedure TScheduleForm.ScheduleGridMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if not Initialized then exit;
  ScheduleGrid.MouseToCell(x,y,CurCol,CurRow);
  MousePos.x := x;
  MousePos.y := y;
  if (CurCol = 0) or (CurRow = 0) or ((LastCol = CurCol) and (LastRow = CurRow)) then exit;
  if (not Data[LastCol][LastRow].Opened) and ((LastCol <> 0) or (LastRow <> 0)) then begin
      Data[LastCol][LastRow].RemoveBtns;
      LastCol:= 0; LastRow:= 0;
  end;
  if not (Data[CurCol][CurRow].Opened) then begin
    Data[CurCol][CurRow].CreateBtns(ScheduleGrid, CurCol, CurRow);
    Data[CurCol][CurRow].InitBtnPositions(CurCol,CurRow);
    LastCol := CurCol;
    LastRow := CurRow;
  end;
end;

procedure TScheduleForm.ScheduleGridStartDrag(Sender: TObject;
  var DragObject: TDragObject);
var
  h: LongInt;
  i: Integer;
begin
  DragID := -1;
  h := ScheduleGrid.CellRect(CurCol, CurRow).Top;
  i := 0;
  while (h < MousePos.y) and (i <= High(Data[CurCol][CurRow].Records)) do begin
    h += TextHeight * CheckedCount;
    Inc(i);
  end;
  if (i <> 0) and (CurCol * CurRow <> 0) then
    DragID := strtoint(Data[CurCol][CurRow].Records[i - 1].Fields[0].Value);
end;

procedure TScheduleForm.SetData;
var
  i, j: Integer;
begin
  SetLength(Data, XFields.Count + 1);
  SetLength(MaxHeights, XFields.Count);
  for i := 0 to High(Data) do begin
    SetLength(Data[i], YFields.Count + 1);
    for j := 0 to High(Data[i]) do
      Data[i][j] := TCellData.Create;
  end;
  i := 0; j := 0;
    while not ScheduleQuery.EOF do begin

    while (ScheduleQuery.Fields[XFieldBox.ItemIndex + 1].AsString <> XFields.value[i]) do begin
      i += 1;
      j := 0;
    end;

    while (ScheduleQuery.Fields[YFieldBox.ItemIndex + 1].AsString <> YFields.value[j]) do
       j += 1;

    Data[i + 1][j + 1].AddRecord(ScheduleQuery);
    ScheduleQuery.Next;
  end;
  //for i := 1 to high(Data) do
  //  for j := 1 to high(Data[i]) do
  //    while (ScheduleQuery.FieldByName(XField.RefField).AsString = XFields.value[j - 1]) and
  //      (ScheduleQuery.FieldByName(YField.RefField).AsString = YFields.value[i - 1]) do begin
  //        Data[i][j].AddRecord(ScheduleQuery);
  //        ScheduleQuery.Next;
  //      end;
end;

function TScheduleForm.MaxWidth(AStringList: TStringList): integer;
var
  i, max: integer;
begin
  max := 0;
  for i := 0 to AStringList.Count - 1 do
    if ScheduleGrid.Canvas.TextWidth(AStringList[i]) > max then
      max := ScheduleGrid.Canvas.TextWidth(AStringList[i]);
  if max > 250 then result := 250 else result := max + 5;
end;

procedure TScheduleForm.FixHeights(Row: integer);
var
  max, i: Integer;
begin
  max := 0;
  for i := 0 to High(Data) do
    if Data[i][Row].Height > max then max := Data[i][Row].Height;
  MaxHeights[Row] := max;
end;

function TScheduleForm.GetTable(ATableName: string): TTableInfo;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(Tables) do
    if Tables[i].Name = ATableName then begin
      Result := Tables[i];
      Break;
    end;
end;

function TScheduleForm.GetFilters(AFieldName: string; AFilters: TFilters): TFilters;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(AFilters) do
    if AFilters[i].FieldNameBox.Caption = AFieldName then begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := AFilters[i];
    end;
end;

procedure TScheduleForm.InitHeights(ACol, ARow, AValue: integer);
begin
  ScheduleGrid.RowHeights[ARow] :=  AValue;
  MaxHeights[ARow] := AValue;
end;

procedure TScheduleForm.InitDeleteBtn(Button: TButton; X, Y: Integer);
begin
  with Button do begin
    Top := Y;
    Left:= X;
    Width := 25;
    Height := 25;
    Caption := 'X';
  end;
end;

procedure TScheduleForm.DeleteBtnClick(Sender: TObject);
begin
  if MessageDlg('Вы уверены ?','Вы точно хотите удалить запись ?', mtWarning, mbYesNo, 0)
    <> mrYes then exit;
  DeleteQ(ScheduleQuery, ScheduleTable, (Sender as TBitBtn).Tag);
  DBConnector.SQLTransaction1.Commit;
  ApplyBtnClick(ScheduleForm);
  CellClick(ScheduleGrid.Col, ScheduleGrid.Row);
end;

procedure TScheduleForm.AddBtnClick(Sender: TObject);
var
  FForm: TCardForm;
begin
  FForm := TCardForm.Init(ScheduleForm, '0', ScheduleTable,
    @Self.AfterCardClose);
  FForm.SetEditsFixed([XFieldBox.ItemIndex + 1, YFieldBox.ItemIndex + 1],
    [CurCol - 1, CurRow - 1]);
end;

procedure TScheduleForm.AlterBtnClick(Sender: TObject);
var
  id: string;
  i: Integer;
begin
  id := inttostr((Sender as TSpeedButton).Tag);
  for i := 0 to High(Cards) do
    if Cards[i].ID = id then begin Cards[i].Show; exit; end;
  SetLength(Cards, Length(Cards) + 1);
  Cards[high(Cards)] := TCardForm.Init(ScheduleForm, id,
    Tables[high(Tables)], @ScheduleForm.AfterCardClose);
end;

procedure TScheduleForm.ShowBtnClick(Sender: TObject);
begin
  SetLength(Referenceforms, Length(Referenceforms) + 1);
  Referenceforms[High(Referenceforms)] := TReferenceForm.Create(ScheduleForm);
  Reference.CreateReference(High(Tables), Referenceforms[High(Referenceforms)]);
  with Referenceforms[High(Referenceforms)] do begin
    RefFilter.AddFilter;
    RefFilter.FilterList[High(RefFilter.FilterList)].ChangeFilter(
      XFieldBox.ItemIndex + 1, '=',XFields.value[CurCol - 1]);
    RefFilter.AddFilter;
    RefFilter.FilterList[High(RefFilter.FilterList)].ChangeFilter(
      YFieldBox.ItemIndex + 1, '=',YFields.value[CurRow - 1]);
    RefFilter.AcceptBtn.Click;
  end;
end;

procedure TScheduleForm.AfterCardClose(AId: string);
var
  i: Integer;
begin
  ApplyBtnClick(ScheduleForm);
  for i := 0 to high(Cards) do
    Cards[i].Refresh;
  CellClick(ScheduleGrid.Col, ScheduleGrid.Row);
end;

procedure TScheduleForm.AddStringValue(var AArray: TStringArray; AValue: String);
begin
  SetLength(AArray, Length(AArray) + 1);
  AArray[High(AArray)] := AValue;
end;

procedure TScheduleForm.InitHints;
begin
  AddStringValue(BtnHints, 'Изменить запись');
  AddStringValue(BtnHints, 'Удалить запись');
  AddStringValue(BtnHints, 'Добавить запись');
  AddStringValue(BtnHints, 'Просмотреть ячейку');
end;

procedure TScheduleForm.InitGlyphs;
begin
  AddStringValue(BtnGlyphs, 'Alter.png');
  AddStringValue(BtnGlyphs, 'Delete.png');
  AddStringValue(BtnGlyphs, 'Add.png');
  AddStringValue(BtnGlyphs, 'ShowCell.png');
end;

procedure TScheduleForm.AddBtnProc(AProc: TNotifyEvent);
begin
  SetLength(BtnProcs, Length(BtnProcs) + 1);
  BtnProcs[High(BtnProcs)] := AProc;
end;

procedure TScheduleForm.CellClick(ACol, ARow: integer);
begin
  if (not Initialized) or (ACol = 0) or (ARow = 0)  then Exit;
  with ScheduleGrid do begin
    if (not Data[ACol][ARow].Opened)  then begin
      if (ACol = LastCol) and (ARow = LastRow) then Data[ACol][ARow].RemoveBtns;
      Data[OpenedCol][OpenedRow].Close;
      InitHeights(OpenedCol, OpenedRow, TextHeight * CheckedCount);
      OpenedCol := ACol; OpenedRow := ARow;
      if Length(Data[ACol][ARow].Records) <> 0 then begin
        Data[ACol][ARow].Height :=
          TextHeight * CheckedCount * length(Data[ACol][ARow].Records);
        InitHeights(ACol, ARow, Data[ACol][ARow].Height);
      end;
      with Data[ACol][ARow] do begin
        Opened := true;
        CreateBtns(ScheduleGrid, ACol, ARow);
        InitBtnPositions(ACol,ARow);
      end;
    end
    else begin
      InitHeights(ACol, ARow, TextHeight * CheckedCount);
      OpenedCol := 0; OpenedRow := 0;
      Data[ACol][ARow].Close;
    end;
    ScheduleGrid.Invalidate;
  end;
end;

procedure TScheduleForm.MoveCellBtns;
begin
    if Data[OpenedCol][OpenedRow].Opened then
      Data[OpenedCol][OpenedRow].InitBtnPositions(OpenedCol, OpenedRow);
end;

function TScheduleForm.CreateButton(AParent: TWinControl;
  AOnClick: TNotifyEvent; AHint: string): TSpeedButton;
begin
  Result := TSpeedButton.Create(AParent);
  with Result do begin
    Parent := AParent;
    OnClick := AOnClick;
    ShowHint := True;
    Hint := AHint;
  end;
end;

function TScheduleForm.CreateRecordBtn(AParent: TWinControl; ID: string;
  AOnClick: TNotifyEvent; APicture, AHint: string): TSpeedButton;
begin
  Result := CreateButton(AParent,AOnClick,AHint);
  with Result do begin
    Height := BtnAspect;
    Width := BtnAspect;
    Glyph := LoadPNgImage(APicture);
    Tag := strtoint(ID);
  end;
end;

function TScheduleForm.CreateCellBtn(AParent: TWinControl;
  AOnClick: TNotifyEvent; ACaption, AHint: string): TSpeedButton;
begin
  Result := CreateButton(AParent,AOnClick,AHint);
  with Result do begin
    Height := 20;
    Width := BtnAspect;
    Caption := ACaption;
  end;
end;

procedure TScheduleForm.InitBtnProcs;
begin
  AddBtnProc(@AlterBtnClick);
  AddBtnProc(@DeleteBtnClick);
  AddBtnProc(@AddBtnClick);
  AddBtnProc(@ShowBtnClick);
end;

function TScheduleForm.GetHtmlString: string;
var
  i, j, k, l: Integer;
begin
   Result := '<!DOCTYPE html>'
          + '<html>'#10
          + '  <head>'#10
          + '    <tittle> Расписание </title>'#10
          + '  </head>'#10
          + '  <body>'#10
          + '    <table cellspacing="5" cellpading="10" border="2">'#10
          + '      <tr>'#10
          + '        <th></th>';
  for i := 0 to XFields.Count - 1 do
    Result +=
            '        <th>' + XFields.Value[i] + '</th>'#10;
  Result += '      </tr>';
  for i := 1 to YFields.Count do begin
    Result +=
            '      <tr>'
          +          '<th>' + YFields.Value[i - 1] + '</th>'#10 ;
    for j := 1 to XFields.Count do begin
      Result += '  <td valign="top">';
      for k:= 0 to high(Data[j][i].Records) do begin
        for l := 0 to high(Data[j][i].Records[k].Fields) do
          Result += Data[j][i].Records[k].Fields[l].Name + ' : ' +
            Data[j][i].Records[k].Fields[l].Value + #10#13 + '<br>';
          Result += '<hr>';
        end;
      Result += '  </td>';
      end;
    Result +=
            '      </tr>';
    end;
  Result += '    </table>'#10
          + '  </body>'#10
          + '</html>';
end;

procedure TScheduleForm.DragRecord(ID, ToCol, ToRow: integer);
begin
  UpdateQ(ScheduleQuery,ScheduleTable.Name,XField.Name,
    XFields.id[ToCol - 1], ID);
  UpdateQ(ScheduleQuery,ScheduleTable.Name,YField.Name,
    YFields.id[ToRow - 1], ID);
end;

procedure TScheduleForm.SortedOutItemClick(Sender: TObject);
begin
  ShowSortedOut := not ShowSortedOut;
end;

procedure TScheduleForm.XFieldBoxChange(Sender: TObject);
begin
 InvalidateGroupCheck;
end;

procedure TScheduleForm.YFieldBoxChange(Sender: TObject);
begin
  InvalidateGroupCheck;
end;

procedure TScheduleForm.InvalidateGroupCheck;
var
  i: Integer;
begin
  CheckedCount := 0;
   for i := 0 to CheckGroup.Items.Count - 1 do
    if (CheckGroup.Items[i] = XFieldBox.Items[XFieldBox.ItemIndex]) or
      (CheckGroup.Items[i] = YFieldBox.Items[YFieldBox.ItemIndex]) then
        CheckGroup.Checked[i] := false
      else begin
        CheckGroup.Checked[i] := true;
        CheckedCount += 1;
      end;
end;

function TScheduleForm.ScheduleTable: TTableInfo;
begin
  result := Tables[High(Tables)];
end;

procedure TScheduleForm.ApplyBtnClick(Sender: TObject);
var
  i, j: integer;
begin
  for i := 0 to high(Data) do
    for j := 0 to high(Data[i]) do
        FreeAndNil(Data[i][j]);
  XField := ScheduleTable.Fields[XFieldBox.ItemIndex + 1];
  YField := ScheduleTable.Fields[YFieldBox.ItemIndex + 1];

  XFields := TAxis.Create(GetTable(XField.RefTable), XField);
  ScheduleGrid.ColCount := XFields.Count + 1;

  YFields := TAxis.Create(GetTable(YField.RefTable), YField);
  ScheduleGrid.RowCount := YFields.Count + 1;

  ScheduleQuery.Close;
  SelectQ(ScheduleQuery, SFilters.FilterList, ScheduleTable,[XField, YField]);
  ScheduleQuery.Open;

  SetData;

  if CheckedCount = 0 then
    ScheduleGrid.DefaultRowHeight := TextHeight
  else
    ScheduleGrid.DefaultRowHeight := CheckedCount * TextHeight;

  if not Initialized then Initialized := True;
  ScheduleGrid.ColWidths[0] := max(MaxWidth(YFields.value),
    max(ScheduleGrid.Canvas.TextWidth(YFieldBox.Caption),
    ScheduleGrid.Canvas.TextWidth(XFieldBox.Caption))) + 30;
  ScheduleGrid.Invalidate;
end;

procedure TScheduleForm.CheckGroupItemClick(Sender: TObject; Index: integer);
var
  i: Integer;
begin
  CheckedCount := 0;
  for i := 0 to CheckGroup.Items.Count - 1 do
    CheckedCount += 1;
end;

procedure TScheduleForm.FieldNamesItemClick(Sender: TObject);
begin
  ShowFieldNames := not ShowFieldNames;
end;

end.


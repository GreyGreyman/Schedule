unit MetaData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

{ TFieldInfo }

 TFieldInfo = class
     Name, Translation, RefTable, RefField: string;
     NeedRef: boolean;
     Width: integer;
     ValueType: string;
     procedure AssignRef(TableName, FieldName: string);
     constructor Create;
 end;

 { TTableInfo }

 TTableInfo = class
     Name, Translation, Generator: string;
     Fields: array of TFieldinfo;
     procedure AddField(AValueType, AName, ATranslation: string; AWidth: integer);
     function FieldByName(AFieldName: string): TFieldInfo;
     constructor Create(AGenerator, AName, ATranslation: string);
 end;
 var
   Tables: array of TTableInfo;

implementation

procedure AddTable(AGenerator, AName, ATranslation: string);
begin
  Setlength(Tables, Length(Tables) + 1);
  Tables[high(Tables)] := TTableInfo.Create(AGenerator, AName, ATranslation);
end;

procedure InitializeTables;
begin

  AddTable('Subject_ID', 'Subjects', 'Предметы');
  with Tables[High(Tables)] do begin
    AddField('int','ID', 'ID', 30);
    AddField('string','Name', 'Предмет', 400);
  end;

  AddTable('Type_ID', 'Subject_Types', 'Типы предметов');
  with Tables[High(Tables)] do begin
    AddField('int','ID', 'ID', 30);
    AddField('string','Name', 'Тип', 30);
  end;

  AddTable('Professor_ID', 'Professors', 'Преподаватели');
  with Tables[High(Tables)] do begin
    AddField('int','ID', 'ID', 30);
    AddField('string','Name', 'ФИО', 150);
  end;

 AddTable('Time_ID', 'Times', 'Время начала/конца пар');
  with Tables[High(Tables)] do begin
    AddField('int','ID', 'ID', 30);
    AddField('string','Begin1', 'Начало', 100);
    AddField('string','End1', 'Конец', 100);
  end;

  AddTable('Day_ID','Days', 'Дни недели');
  with Tables[High(Tables)] do begin
    AddField('int','ID','ID', 30);
    AddField('string','Name', 'День недели', 100);
  end;

  AddTable('Group_ID','Groups', 'Группы');
  with Tables[High(Tables)] do begin
    AddField('int','ID','ID', 30);
    AddField('string','Name', 'Группа', 50);
    AddField('int','Group_Size', 'Размер', 50);
  end;

  AddTable('Room_ID','Rooms', 'Аудитории');
  with Tables[High(Tables)] do begin
    AddField('int','ID','ID', 30);
    AddField('string','Name', 'Аудитория', 100);
    AddField('int','Size1', 'Размер', 50);
  end;

  AddTable('Week_ID','Weeks', 'Недели');
  with Tables[High(Tables)] do begin
    AddField('int','ID','ID', 30);
    AddField('string','Name', 'Неделя', 100);
  end;

  AddTable('PS_ID','Professors_Subjects', 'Специализация преподавателей');
  with Tables[High(Tables)] do begin
    AddField('int','ID', 'ID', 30);
    AddField('string','Professor_ID', 'Преподаватель', 150);
    Fields[high(Fields)].AssignRef('Professors','Name');
    AddField('string','Subject_ID', 'Предмет', 200);
    Fields[high(Fields)].AssignRef('Subjects','Name');
  end;

  AddTable('SG_ID','Subjects_Groups', 'Предметы по группам');
  with Tables[High(Tables)] do begin
    AddField('int','ID', 'ID', 30);
    AddField('string','Subject_ID', 'Предмет', 200);
    Fields[high(Fields)].AssignRef('Subjects','Name');
    AddField('string','Group_ID', 'Группа', 50);
    Fields[high(Fields)].AssignRef('Groups','Name');
  end;

  AddTable('Item_ID','Schedule_Items', 'Расписание');
  with Tables[High(Tables)] do begin
    AddField('int','ID', 'ID', 30);
    AddField('string','Subject_ID', 'Предмет', 200);
    Fields[high(Fields)].AssignRef('Subjects','Name');
    AddField('string','Subject_Type_ID', 'Тип', 30);
    Fields[high(Fields)].AssignRef('Subject_Types','Name');
    AddField('string','Professor_ID', 'Преподаватель', 150);
    Fields[high(Fields)].AssignRef('Professors','Name');
    AddField('string','Time_ID', 'Время начала пары', 50);
    Fields[high(Fields)].AssignRef('Times','Begin1');
    AddField('string','Day_ID', 'День недели', 100);
    Fields[high(Fields)].AssignRef('Days','Name');
    AddField('string','Group_ID', 'Группа', 40);
    Fields[high(Fields)].AssignRef('Groups','Name');
    AddField('string','Room_ID', 'Аудитория', 40);
    Fields[high(Fields)].AssignRef('Rooms','Name');
    AddField('string','Week_ID', 'Неделя', 30);
    Fields[high(Fields)].AssignRef('Weeks','Name');
  end;
end;

{ TFieldInfo }

procedure TFieldInfo.AssignRef(TableName, FieldName: string);
begin
  NeedRef := true;
  RefTable := TableName;
  RefField := FieldName;
end;

constructor TFieldInfo.Create;
begin
  inherited;
  NeedRef := false;
end;


{ TTableInfo }

procedure TTableInfo.AddField(AValueType, AName, ATranslation: string;
  AWidth: integer);
begin
  SetLength(Fields,length(Fields) + 1);
  Fields[high(Fields)] := TFieldInfo.Create;
  with Fields[high(Fields)] do begin
    ValueType := AValueType;
    Name := AName;
    Translation := ATranslation;
    Width := AWidth;
  end;
end;

function TTableInfo.FieldByName(AFieldName: string): TFieldInfo;
var
  i: Integer;
begin
  result := nil;
  for i := 0 to High(Fields) do
    if Fields[i].Name = AFieldName then begin
      result := Fields[i];
      Break;
    end;
end;

constructor TTableInfo.Create(AGenerator, AName, ATranslation: string);
begin
  inherited Create;
  Name := AName;
  Translation := ATranslation;
  Generator := AGenerator;
end;
initialization
  InitializeTables;
end.


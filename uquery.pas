unit UQuery;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, ufilters, MetaData;

procedure SelectQ(ASQLQuery: TSQLQuery; AFilterList: TFilters; ATable: TTableInfo;
 SortFields: array of TFieldInfo);
procedure DeleteQ(AQuery: TSQLQuery; ATable: TTableInfo; ID: integer);
procedure UpdateQ(AQuery: TSQLQuery; ATableName, AFieldName: string; Value, ID: integer);

implementation

procedure SelectQ(ASQLQuery: TSQLQuery; AFilterList: TFilters;
  ATable: TTableInfo; SortFields: array of TFieldInfo);
var
  i, inttemp: integer;
  fieldname, from, SelFields, orderby, temp1, temp2: string;
  tablename: String;
  p: TParam;
begin
  from := ' from ' + ATable.Name;
  SelFields := 'select';
  for i := 0 to high(ATable.Fields) do
    with ATable.Fields[i] do begin
      if NeedRef then begin
        SelFields += format(' %s.%s,', [RefTable, RefField]);
        from += format(' inner join %s on %s.%s = %s.%s',
          [RefTable, RefTable, 'ID', ATable.Name, Name]);
      end
      else
        SelFields += format(' %s.%s,', [ATable.Name, Name]);
    end;
  ASQLQuery.SQL.Text := copy(SelFields, 1, length(SelFields) - 1) + from;

  if Length(AFilterList) <> 0 then
    ASQLQuery.SQL.Add(' where');
  for i := 0 to High(AFilterList) do begin
    if i <> 0 then ASQLQuery.SQL.Add('and');
    if  ATable.Fields[AFilterList[i].FieldNameBox.ItemIndex].NeedRef then begin
      fieldname := ATable.Fields[AFilterList[i].FieldNameBox.ItemIndex].RefField;
      tablename := ATable.Fields[AFilterList[i].FieldNameBox.ItemIndex].RefTable;
    end
    else begin
      fieldname := ATable.Fields[AFilterList[i].FieldNameBox.ItemIndex].Name;
      tablename := ATable.Name;
    end;

    ASQLQuery.SQL.Add(AFilterList[i].Condition(
      AFilterList[i].TypeBox.Text, Format('%s.%s',
      [tablename, fieldname]), 'value' + IntToStr(i)));

    inttemp := AFilterList[i].FieldNameBox.ItemIndex;
    p := ASQLQuery.ParamByName('value' + IntToStr(i));
    case ATable.Fields[AFilterList[i].FieldNameBox.ItemIndex].ValueType of
      'string':
        p.AsString := AFilterList[i].ValueEdit.Caption;
      'int':
        if AFilterList[i].ValueEdit.Caption <> '' then
          p.AsInteger := StrToInt(AFilterList[i].ValueEdit.Caption);
    end;
  end;

  if Length(SortFields) <> 0 then begin
    orderby := ' order by';
    for i := 0 to High(SortFields) do begin
      if SortFields[i].NeedRef then begin
        temp1 := SortFields[i].RefTable;
        temp2 := SortFields[i].RefField
      end
      else begin
        temp1 := ATable.Name;
        temp2 := SortFields[i].Name;
      end;
      orderby += format(' %s.%s asc ,',[temp1, temp2]);
    end;
    ASQLQuery.SQL.Add(copy(orderby, 1, length(orderby) - 1));
  end;
end;

procedure DeleteQ(AQuery: TSQLQuery; ATable: TTableInfo; ID: integer);
begin
  AQuery.Close;
  AQuery.SQL.Text := format('Delete from %s where ID = %d', [ATable.Name, ID]);
  AQuery.ExecSQL;
end;

procedure UpdateQ(AQuery: TSQLQuery; ATableName, AFieldName :string; Value, ID: integer);
begin
  AQuery.Close;
  AQuery.SQL.Text := format('Update %s set %s = :param where ID = %d', [
    ATableName, AFieldName, ID]);
  AQuery.ParamByName('param').AsInteger := Value;
  AQuery.ExecSQL;
end;

end.


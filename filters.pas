unit Filters;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MetaData, StdCtrls;
type

  { TFilter }

  TFilter = class(TObject)
    private
      FieldNameBox, TypeBox: TComboBox;
      ValueEdit: TEdit;
      procedure OnFilterChange(Sender: TObject);
    public
      Up: boolean;
      constructor Create(Owner: TObject; Index: integer);
      procedure Init(Owner: TObject; Index, ALeft: integer);
      function Condition(FilterType, FieldName, ParametrName: string): string;
  end;

var
  Filter: TFilter;

implementation

{ TFilter }

procedure TFilter.OnFilterChange(Sender: TObject);
begin

end;

constructor TFilter.Create(Owner: TObject; Index: integer);
var
  i: integer;
begin
  inherited create;
    with FieldNameBox do begin
      FieldNameBox := TComboBox.Create(Owner);
      for i := 0 to high(Tables[Reference.ActiveTable].Fields) do
        FieldNameBox.Items.Add(Tables[Reference.ActiveTable].Fields[i].Translation);
      ItemIndex := 0;
      Init(Owner,Index,5);
    end;
    with TypeBox do begin
      TypeBox := TComboBox.Create(FilterBox);
      Items.Add('>'); TypeBox.Items.Add('<'); TypeBox.Items.Add('=');
      Items.Add('Содержит'); TypeBox.Items.Add('Начинается с');
      ItemIndex := 0;
      Init(Owner,Index,100);
    end;
    with ValueEdit do begin
      ValueEdit := TEdit.Create(FilterBox);
      Init(Owner,Index,195);
    end;
  end;

procedure TFilter.Init(Owner: TObject; Index, ALeft: integer);
begin
  Parent := Owner;
  Top := 5 + Index *35 ; Width := 85; Height := 25; Left := ALeft;
end;

function TFilter.Condition(FilterType, FieldName, ParametrName: string): string;
begin
  case FilterType of
    '<','>','=':
      result := format(' %s %s :%s',[FieldName, FilterType, ParametrName]);
    'Содержит':
      result := format(' position(:%s in %s) <> 0',[ParametrName, FieldName]);
    'Начинается с':
      result := format(' position(:%s in %s) = 1',[ParametrName, FieldName]);
    else
      result := '';
  end;
end;

initialization
  Filter := TFilter.Create;

end.



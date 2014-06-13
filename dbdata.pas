unit DBData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, FileUtil;

type

  { TDBConnector }

  TDBConnector = class(TDataModule)
    IBConnection1: TIBConnection;
    SQLTransaction1: TSQLTransaction;
  end;

var
  DBConnector: TDBConnector;

implementation

{$R *.lfm}

end.


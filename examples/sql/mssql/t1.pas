program t1;

{$mode objfpc}{$H+}

uses
  heaptrc,
  Classes, SysUtils, DB, mssqlconn,
  // gh
  gh_SQL, gh_SQLdbLib;

{$DEFINE MSSQLBroker}

const
  TABLE_NAME = '#user_tmp';

var
  co: TghSQLConnector;
  sql: TghSQLObject;

procedure ExecSelect;
var
  ds: TDataSet;
begin
  writeln;
  writeln('Show data:');

  sql.Clear;
  sql.Script.Text := 'select * from ' + TABLE_NAME;
  sql.Open(ds);
  try
    while not ds.EOF do
    begin
      writeln('User: ', ds.FieldByName('id').AsString, '-', ds.FieldByName('name').AsString);
      ds.Next;
    end;
  finally
    ds.Free;
  end;
end;

procedure InsertUser(const ALogin, APasswd, AName: string);
begin
  writeln;
  writeln('Inserting ', ALogin, ' ', AName);

  with sql do
  begin
    Clear;
    Prepared := True;
    Script.Text := 'insert into ' + TABLE_NAME + ' values (:login, :passwd, :name)';
    Params['login'].AsString := ALogin;
    Params['passwd'].AsString := APasswd;
    Params['name'].AsString := AName;
    Execute;
  end;
end;

begin
  co := TghSQLConnector.Create;
  sql := TghSQLObject.Create(co);
  try
    // set configurations
    // using MSSQLServer
    co.SetLibClass(TghMSSQLLib);

    // set params
    co.Host := 'YOUR_HOST';
    co.Database := 'YOUR_DATABASE';
    co.User := 'YOUR_USER';
    co.Password := 'YOUR_PASSWORD';

    co.Connect;
    writeln('Connected.');

    // creating a temp table
    sql.Clear;
    sql.Script.Add('create table ' + TABLE_NAME + ' ( ');
    sql.Script.Add('  [id] int identity not null primary key ');
    sql.Script.Add(' ,[login] varchar(20) not null ');
    sql.Script.Add(' ,[passwd] varchar(30) null ');
    sql.Script.Add(' ,[name] varchar(50) null )');
    sql.Execute;
    writeln('Table created.');

    // insert
    InsertUser('mjane', '123', 'Mary Jane');

    ExecSelect;

    // using transaction
    co.StartTransaction;
    InsertUser('venon', 'xxx', 'Venon');
    ExecSelect;
    writeln('Rollback');
    co.Rollback;

    ExecSelect;

    // again, using Commit
    co.StartTransaction;
    InsertUser('pparker', '1', 'Peter Parker');
    writeln('Commit');
    co.Commit;

    ExecSelect;

    // drop table
    sql.Clear;
    sql.Script.Text := 'drop table '+TABLE_NAME;
    sql.Execute;

  finally
    sql.Free;
    co.Free;
  end;

  writeln;
  writeln('Done.');
  writeln;

end.


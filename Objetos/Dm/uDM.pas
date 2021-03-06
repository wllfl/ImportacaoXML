unit uDM;

interface

uses
  SysUtils, Classes, DBXMSSQL, DB, SqlExpr, FMTBcd, DBClient, Provider, UConexao,
  Windows, Forms, Dialogs;

type
  Tdm = class(TDataModule)
    conexaoMonitoramento: TSQLConnection;
    qryAgendamento: TSQLQuery;
    dspAgendamento: TDataSetProvider;
    cdsAgendamento: TClientDataSet;
    dtsAgendamento: TDataSource;
    qryAux: TSQLQuery;
    dspAux: TDataSetProvider;
    cdsAux: TClientDataSet;
    conexao: TSQLConnection;
    procedure conexaoMonitoramentoBeforeConnect(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
    procedure conexaoBeforeConnect(Sender: TObject);
  private
    { Private declarations }
  public
    conn: TConexao;
  end;

var
  dm: Tdm;

implementation


{$R *.dfm}

procedure Tdm.conexaoBeforeConnect(Sender: TObject);
begin
    if not conexao.Connected then
    begin
        try
            try
                 conn := TConexao.Create(ExtractFilePath(Application.ExeName) + 'Config.ini', 'Conexao');
                 conn.Conectar(conexao);
            except
                 on E:Exception do
                 begin
                     ShowMessage('Erro ao iniciar conex�o!'#13 + E.Message);
                     Application.Terminate;
                 end;
            end;
        finally
            //FreeAndNil(conn);
        end;
    end;
end;

procedure Tdm.conexaoMonitoramentoBeforeConnect(Sender: TObject);
begin
    if not conexaoMonitoramento.Connected then
    begin
        try
            try
                 conn := TConexao.Create(ExtractFilePath(Application.ExeName) + 'Config.ini', 'Conexao');
                 conn.Conectar(conexaoMonitoramento);
            except
                 on E:Exception do
                 begin
                     ShowMessage('Erro ao iniciar conex�o!'#13 + E.Message);
                     Application.Terminate;
                 end;
            end;
        finally
            //FreeAndNil(conn);
        end;
    end;
end;

procedure Tdm.DataModuleCreate(Sender: TObject);
begin
     try
         conn := TConexao.Create(ExtractFilePath(Application.ExeName) + 'Config.ini', 'Conexao');
         conn.LeINI();
     except
         on E:Exception do
         begin
             ShowMessage('Erro ao carregar dados do arquivo INI!'#13 + E.Message);
             Application.Terminate;
         end;
     end;
end;

end.

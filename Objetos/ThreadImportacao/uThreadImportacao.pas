
unit uThreadImportacao;

interface

uses
   Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, JvExStdCtrls, JvGroupBox, ExtCtrls, IOUtils,
  FMTBcd, DB, SqlExpr, DateUtils, xmldom, XMLIntf, msxmldom, XMLDoc,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, jpeg, StrUtils,
  PngImage, ActiveX, DBXCommon, SyncObjs, DBClient, Provider;

type
  TRGBArray = array[Word] of TRGBTriple;
  pRGBArray = ^TRGBArray;

type
   TDefaultXML = (dxNone, dxDogus);

type
  ThreadImportacao = class(TThread)
  private
    FDefaultXML: TDefaultXML;
    FIdAgendameto: integer;
    FIdImobiliaria: Integer;
    FIdBancoDados: Integer;
    FPortal: string;
    FUrlXml: string;
    FPathXml: string;
    FPathMarcaAgua: string;
    FPathImagem: string;
    FNomeMarcaAgua: string;
    FTipoXml: string;
    FConexaoPortal: TSQLConnection;
    FConexaoAux: TSQLConnection;
    procedure setConexaoAux(const Value: TSQLConnection);
    function getConexaoAux: TSQLConnection;

  protected
    procedure AtualizaInfoTarefa(idAgendamento: integer; duracao, status, msg, nameXml: string);
    procedure Execute; override;

  public
    property ConexaoAux: TSQLConnection read getConexaoAux write setConexaoAux;
    function VerificaEstado(): Boolean;
    procedure Finalizar();

    constructor Create(CreateSuspended: Boolean; idAgendamento, idImobiliaria, idBancoDados: integer; tipoXML: string; var ConexaoAux: TSQLConnection);
  end;

var
  FCritical : TCriticalSection;

implementation

uses uPrincipal, uDM, uImportacaoDogus;

{ ThreadImportacao }

// Método que dispara a Thread
procedure ThreadImportacao.Execute;
begin
    if not Terminated then
    begin
        try
            // Inicializa a Seção critica
            FCritical.Enter;

            CoInitialize(nil);
            case FDefaultXML of
               dxDogus : TImportacaoDogus.Create(FIdAgendameto, FIdImobiliaria, FIdBancoDados, FConexaoAux);
            else
               Abort;
            end;
        finally
            // Inicializa a Seção critica
            FCritical.Leave;
        end;
    end;
end;

procedure ThreadImportacao.Finalizar;
begin
    Self.Terminate;
    Self.AtualizaInfoTarefa(FIdAgendameto, '', 'C', 'Cancelado pelo usuário', '');
end;

// Método constutor da Classe
constructor ThreadImportacao.Create(CreateSuspended: Boolean; idAgendamento,
  idImobiliaria, idBancoDados: integer; tipoXML: string; var ConexaoAux: TSQLConnection);
begin
    inherited Create(CreateSuspended);
    Self.FDefaultXML := dxNone;
    Self.FIdAgendameto  := idAgendamento;
    Self.FIdImobiliaria := idImobiliaria;
    Self.FIdBancoDados  := idBancoDados;
    Self.setConexaoAux(ConexaoAux);

    if tipoXML = 'dogus' then
       Self.FDefaultXML := dxDogus
end;

// Procedure para finalizar a tarefa inserindo os dados necessários na TAB_TAREFA
procedure ThreadImportacao.AtualizaInfoTarefa(idAgendamento: integer; duracao, status, msg, nameXml: string);
var
  oQry: TSQLQuery;
  sSql : string;
begin
     try
         sSql := 'UPDATE TAB_TAREFA SET statusAtual = :status, msg = :msg  ';

         try
             oQry := TSQLQuery.Create(nil);
             oQry.SQLConnection := Self.getConexaoAux();
             oQry.Close;
             oQry.SQL.Clear;
             oQry.SQL.Add(sSql);
             oQry.SQL.Add('WHERE idAgendamento = :id AND statusAtual = :statusAtual AND dataCadastro = :data');
             oQry.ParamByName('status').AsString        := status;
             oQry.ParamByName('msg').AsString           := msg;
             oQry.ParamByName('id').AsInteger           := idAgendamento;
             oQry.ParamByName('statusAtual').AsString   := 'E';
             oQry.ParamByName('data').AsDateTime        := Date;
             oQry.ExecSQL();

             DeleteFile(FPathXml + nameXml);
         except
             on E:Exception do
             MessageDlg('Erro ao atualizar status da tarefa: ' + E.Message, mtError, [mbOK], 0);
         end;
     finally
         FreeAndNil(oQry);
     end;
end;

function ThreadImportacao.getConexaoAux: TSQLConnection;
begin
    if not FConexaoAux.Connected then
    begin
        FConexaoAux.Open;
        Sleep(2000);
    end;
    
    Result := FConexaoAux;
end;

procedure ThreadImportacao.setConexaoAux(const Value: TSQLConnection);
begin
    if Assigned(Value) then
       FConexaoAux := Value;
end;

function ThreadImportacao.VerificaEstado: Boolean;
var
  oQry: TSQLQuery;
begin
     try
         try
             Result := False;

             if not Self.FConexaoAux.Connected then
                Self.FConexaoAux.Open;

             oQry := TSQLQuery.Create(nil);
             oQry.SQLConnection := dm.conexaoMonitoramento;
             oQry.Close;
             oQry.SQL.Clear;
             oQry.SQL.Add('SELECT acao FROM TAB_CONTROLE');
             oQry.Open;

             if not oQry.IsEmpty then
             begin
                 if oQry.FieldByName('acao').AsString = 'D' then
                    Self.Finalizar;
             end;
         except
             on E:Exception do
             begin
                MessageDlg('Erro ao verificar estado do monitoramento Thread: ' + E.Message, mtError, [mbOK], 0);
             end;
         end;
     finally
         FreeAndNil(oQry);
     end;
end;


initialization
  FCritical := TCriticalSection.Create;

finalization
  FreeAndNil(FCritical);

end.

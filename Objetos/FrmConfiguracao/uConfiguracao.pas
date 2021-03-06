unit uConfiguracao;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Mask, JvExMask, JvSpin, Buttons, IniFiles, UConexao,
  ExtCtrls;

type
  TfrmConfiguracao = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    edtPrimeira: TJvSpinEdit;
    GroupBox4: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    edtHost: TEdit;
    edtDataBase: TEdit;
    edtUsuario: TEdit;
    edtSenha: TEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label8: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    GroupBox5: TGroupBox;
    Label16: TLabel;
    Label17: TLabel;
    edtMaxLargura: TJvSpinEdit;
    Label2: TLabel;
    edtTimeOut: TJvSpinEdit;
    Label3: TLabel;
    rgSeparador: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);

  private
    { Private declarations }
  public
    FHost: string;
    FDataBase: string;
    FSenha: string;
    FUsuario: string;
    FQuality1: integer;
    FQuality2: integer;
    FThreadSimultanea: Integer;
    FMaxWidth: Integer;
    FTimeOut: Integer;
    FSeparador: string;

    procedure LeINI();
    procedure GravaINI();
  end;

var
  frmConfiguracao: TfrmConfiguracao;
  conn: TConexao;

implementation

uses uPrincipal, uDM;


{$R *.dfm}

{ TfrmConfiguracao }

procedure TfrmConfiguracao.BitBtn1Click(Sender: TObject);
begin
    GravaINI();
end;

procedure TfrmConfiguracao.FormCreate(Sender: TObject);
begin
    Self.LeINI();
end;

procedure TfrmConfiguracao.GravaINI;
var
    ArqIni : TIniFile;
    Separador: string;
begin
     if (edtPrimeira.Value > 0) and (edtHost.Text <> '') and (edtDataBase.Text <> '') and (edtUsuario.Text <> '') and (edtSenha.Text <> '') and (edtMaxLargura.Value >  0) and (edtTimeOut.Value >= 60) then
     begin
         ArqIni := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'Config.ini');
         try
            try
                //Grava os valores para conex�o com banco de dados
                ArqIni.WriteString('Conexao', 'user_name', edtUsuario.Text);
                ArqIni.WriteString('Conexao', 'Password', edtSenha.Text);
                ArqIni.WriteString('Conexao', 'Database', edtDataBase.Text);
                ArqIni.WriteString('Conexao', 'Hostname', edtHost.Text);
                ArqIni.WriteInteger('Conexao', 'TimeOut', Trunc(edtTimeOut.Value));

                //Grava os valores para qualidade de grava��o das imagens
                ArqIni.WriteInteger('Qualidade', 'Quality1', Trunc(edtPrimeira.Value));

                //Grava os valores limite da lagura das imagens
                ArqIni.WriteInteger('Dimensao', 'MaxWidth', Trunc(edtMaxLargura.Value));

                if rgSeparador.ItemIndex = 0 then
                   FSeparador := 'BRA'
                else
                   FSeparador := 'USA';

                //Grava o separador decimal a ser usado no sistema
                ArqIni.WriteString('Configuracao', 'SeparadorDecimal', FSeparador);

                // Atualiza as vari�veis do sistemma
                frmMonitoramento.FLAG_QUALITY_SM := Trunc(edtPrimeira.Value);
                frmMonitoramento.FLAG_MAX_WIDTH  := Trunc(edtMaxLargura.Value);
                frmMonitoramento.FALG_SEPARADOR  := FSeparador;
                dm.conn.Hostname                 := edtHost.Text;
                dm.conn.Banco                    := edtDataBase.Text;
                dm.conn.Usuario                  := edtUsuario.Text;
                dm.conn.Senha                    := edtSenha.Text;

                MessageDlg('Informa��es gravadas e atualizadas com sucesso!', mtConfirmation, [mbOK], 0);
            except
               on E:Exception do
               MessageDlg('Erro ao gravar dados: ' + E.Message, mtError, [mbOK], 0);
            end;
         finally
             ArqIni.Free;
         end;
     end
     else
        MessageDlg('Todos os campos s�o de preenchimento obrigat�rio (*)!', mtWarning, [mbOK], 0);
end;
procedure TfrmConfiguracao.LeINI;
var
    ArqIni : TIniFile;
begin
     ArqIni := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'Config.ini');
     try
        try
            //Carrega valores para conex�o com banco de dados
            FHost     := ArqIni.ReadString('Conexao', 'Hostname', '');
            FDatabase := ArqIni.ReadString('Conexao', 'Database', '');
            FSenha    := ArqIni.ReadString('Conexao', 'Password', '');
            FUsuario  := ArqIni.ReadString('Conexao', 'user_name', '');
            FTimeOut  := ArqIni.ReadInteger('Conexao', 'TimeOut', 0);

            edtHost.Text     := FHost;
            edtDataBase.Text := FDataBase;
            edtSenha.Text    := FSenha;
            edtUsuario.Text  := FUsuario;
            edtTimeOut.Value := FTimeOut;

            //Carrega valores para qualidade das imagens
            FQuality1 := ArqIni.ReadInteger('Qualidade', 'Quality1', 0);

            edtPrimeira.Value := FQuality1;

            //Carrega valor com limite da  largura das imagens
            FMaxWidth := ArqIni.ReadInteger('Dimensao', 'MaxWidth', 0);

            edtMaxLargura.Value := FMaxWidth;

            //Carrega o valore referente ao separador decimal
            FSeparador := ArqIni.ReadString('Configuracao', 'SeparadorDecimal', '');

            if FSeparador = 'BRA' then
               rgSeparador.ItemIndex := 0
            else
               rgSeparador.ItemIndex := 1;

        except
           on E:Exception do
           MessageDlg('Erro ao ler dados: ' + E.Message, mtError, [mbOK], 0);
        end;
     finally
         ArqIni.Free;
     end;
end;

end.

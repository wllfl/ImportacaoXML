unit uImportacaoDogus;

interface

uses
   uImportacao, Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, JvExStdCtrls, JvGroupBox, ExtCtrls, IOUtils,
  FMTBcd, DB, SqlExpr, DateUtils, xmldom, XMLIntf, msxmldom, XMLDoc,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, jpeg, StrUtils,
  PngImage, ActiveX, DBXCommon, SyncObjs, DBClient, Provider;

type
    TImportacaoDogus = class(TImportacao)
    public
       procedure ContaImoveisFotos(pathXML: string); override;
       procedure InseriTempXML(pathXML: string); override;
       function ValidaTagsXML(node: IXMLNode): Boolean; override;

    end;

implementation

uses uThreadImportacao, uPrincipal;

const
   TAGS : array[1..23] of string = ('title','guid','cidade','categoria','tipo','endereco','cond_pag', 'descricao', 'area', 'area_c', 'quartos', 'suites',
                                    'salas', 'ambientes', 'cozinhas', 'wc', 'lavabo', 'piscina', 'garagem', 'telefone', 'valor', 'bairro', 'fotos');

{ TImportacaoDogus }

procedure TImportacaoDogus.ContaImoveisFotos(pathXML: string);
var
  oNodePai, oNodeItem, oNodeFotos, oNodeFoto: IXMLNode;
  oXMLDoc: TXMLDocument;
begin
     // Inseri os dados para atualização da tarefa
     self.AtualizaInfoTarefa(FIdAgendameto, Self.CalculaDuracao(tTimeInicial, Now), 'E', 'Contando imóveis e fotos do arquivo XML', '');
     try
          try
               // Instância o objeto XMLDocument e carrega o arquivo XML
               oXMLDoc := TXMLDocument.Create(Application);
               oXMLDoc.FileName := pathXML;
               oXMLDoc.Active := True;

               // Identifica o Node principal do XML
               oNodePai := oXMLDoc.DocumentElement.ChildNodes.FindNode('channel');
               repeat
                    oNodeItem := oNodePai.ChildNodes.FindNode('item');
                    oNodeItem.ChildNodes.First;

                    repeat
                          // Valida se todas as TAGs estão presentes no Node['item'] atual
                          if(Self.ValidaTagsXML(oNodeItem)) then
                          begin
                               // Contador para gravar a quantidade de registros lidos e gravados no banco de dados
                               Inc(iContTotalItem);

                               oNodeFotos := oNodeitem.ChildNodes.FindNode('fotos');
                               if oNodeFotos <> nil then
                               begin
                                   oNodeFotos.ChildNodes.First;

                                   repeat
                                        oNodeFoto := oNodeFotos.ChildNodes.FindNode('foto');
                                        if oNodeFoto <> nil then
                                        begin
                                            oNodeFoto.ChildNodes.First;

                                            repeat
                                                // Processa as imagens do XML
                                                Inc(iContTotalFoto);

                                                oNodeFoto := oNodeFoto.NextSibling;
                                            until (oNodeFoto = nil) or (ThreadImportacao.CheckTerminated);
                                        end;

                                        oNodeFotos := oNodeFotos.NextSibling;
                                   until (oNodeFotos = nil) ;
                               end;
                          end;

                          oNodeItem := oNodeItem.NextSibling;
                    until (oNodeItem = nil) or (ThreadImportacao.CheckTerminated) ;

                    oNodePai := oNodePai.NextSibling;
               until (oNodePai = nil) ;
          except

          end;

     finally
        FreeAndNil(oXMLDoc);
     end;
end;

procedure TImportacaoDogus.InseriTempXML(pathXML: string);
var
   oNodePai, oNodeItem, oNodeFotos, oNodeFoto : IXMLNode;
   oXMLDoc: TXMLDocument;
   oQry, oQryImg: TSQLQuery;
   sNameImagem, sValor: string;
   iIdExterno, iContTemp, iContTempImovel: Integer;
begin
      try
           try
               iContTemp := 0;

               // Instância o objeto XMLDocument e carrega o arquivo XML
               oXMLDoc := TXMLDocument.Create(Application);
               oXMLDoc.FileName := pathXML;
               oXMLDoc.Active := True;

               // Chama a função para executar a conexão com o respectivo portal onde serão gravados os dados
               Self.ConectarPortal;
               oQry := TSQLQuery.Create(nil);
               oQry.SQLConnection := Self.FConexaoPortal;

               // Limpa a tabela imoveis_xml
               oQry.Close;
               oQry.SQL.Clear;
               oQry.SQL.Add('DELETE FROM imoveis_xml');
               oQry.ExecSQL();

               // Limpa a tabela imoveis_fotos_xml
               oQry.Close;
               oQry.SQL.Clear;
               oQry.SQL.Add('DELETE FROM imoveis_fotos_xml');
               oQry.ExecSQL();

               oQryImg := TSQLQuery.Create(nil);
               oQryImg.SQLConnection := Self.FConexaoPortal;

               // Identifica o Node principal do XML
               oNodePai := oXMLDoc.DocumentElement.ChildNodes.FindNode('channel');
               repeat
                    oNodeItem := oNodePai.ChildNodes.FindNode('item');
                    oNodeItem.ChildNodes.First;

                    // Inseri os dados para atualização da tarefa
                    self.AtualizaInfoTarefa(FIdAgendameto, Self.CalculaDuracao(tTimeInicial, Now), 'E', 'Executando inclusões temporárias de imóveis', '');
                    repeat
                          // Valida se todas as TAGs estão presentes no Node['item'] atual e se existem fotos para esse Node['item']
                          if(Self.ValidaTagsXML(oNodeItem)) then
                          begin
                              iIdExterno := StrToInt(oNodeItem.ChildNodes['guid'].Text);

                              if frmMonitoramento.FALG_SEPARADOR = 'BRA' then
                              begin
                                 sValor := StringReplace(oNodeItem.ChildNodes['valor'].Text, '.', '', [rfReplaceAll]);
                              end
                              else
                              begin
                                 sValor := StringReplace(oNodeItem.ChildNodes['valor'].Text, '.', '', [rfReplaceAll]);
                                 sValor := StringReplace(sValor, ',', '.', [rfReplaceAll]);
                              end;

                              // Grava os imóveis no banco de dados
                              oQry.Close;
                              oQry.SQL.Clear;
                              oQry.SQL.Add('INSERT INTO imoveis_xml (id_externo, categoria, tipo, cidade, endereco, titulo, descricao, cond_pag, area, area_c, quartos, suites, tipo_construcao, salas, ambientes, cozinhas, ');
                              oQry.SQL.Add('wc, lavabo, piscina, garagem, telefone, data, cod_usuario, views, status, aprovado, valor, bairro)VALUES');
                              oQry.SQL.Add('(:id_externo, :categoria, :tipo, :cidade, :endereco, :titulo, :descricao, :cond_pag, :area, :area_c, :quartos, :suites, :tipo_construcao, :salas, :ambientes, :cozinhas, ');
                              oQry.SQL.Add(':wc, :lavabo, :piscina, :garagem, :telefone, :data, :cod_usuario, :views, :status, :aprovado, :valor, :bairro)');
                              oQry.ParamByName('id_externo').AsInteger     := StrToInt(oNodeItem.ChildNodes['guid'].Text);
                              oQry.ParamByName('categoria').AsString       := Self.Ternario(' ', AcertoAcento(oNodeItem.ChildNodes['categoria'].Text), ' ');
                              oQry.ParamByName('tipo').AsString            := Self.Ternario(' ', AcertoAcento(oNodeItem.ChildNodes['tipo'].Text), ' ');
                              oQry.ParamByName('cidade').AsString          := Self.Ternario(' ', AcertoAcento(oNodeItem.ChildNodes['cidade'].Text), ' ');
                              oQry.ParamByName('endereco').AsString        := Self.Ternario(' ', AcertoAcento(oNodeItem.ChildNodes['endereco'].Text), ' ');
                              oQry.ParamByName('titulo').AsString          := Self.Ternario(' ', AcertoAcento(oNodeItem.ChildNodes['title'].Text), ' ');
                              oQry.ParamByName('descricao').AsString       := Self.Ternario(' ', AcertoAcento(oNodeItem.ChildNodes['descricao'].Text), ' ');
                              oQry.ParamByName('cond_pag').AsString        := Self.Ternario(' ', oNodeItem.ChildNodes['cond_pag'].Text, ' ');
                              oQry.ParamByName('area').AsString            := Self.Ternario(' ', oNodeItem.ChildNodes['area'].Text, ' ');
                              oQry.ParamByName('area_c').AsString          := Self.Ternario(' ', oNodeItem.ChildNodes['area_c'].Text, ' ');
                              oQry.ParamByName('quartos').AsString         := Self.Ternario(' ', oNodeItem.ChildNodes['quartos'].Text, ' ');
                              oQry.ParamByName('suites').AsString          := Self.Ternario(' ', oNodeItem.ChildNodes['suites'].Text, ' ');
                              oQry.ParamByName('tipo_construcao').AsString := Self.Ternario(' ', oNodeItem.ChildNodes['tipo_construcao'].Text, ' ');
                              oQry.ParamByName('salas').AsString           := Self.Ternario(' ', oNodeItem.ChildNodes['salas'].Text, ' ');
                              oQry.ParamByName('ambientes').AsString       := Self.Ternario(' ', oNodeItem.ChildNodes['ambientes'].Text, ' ');
                              oQry.ParamByName('cozinhas').AsString        := Self.Ternario(' ', oNodeItem.ChildNodes['cozinhas'].Text, ' ');
                              oQry.ParamByName('wc').AsString              := Self.Ternario(' ', oNodeItem.ChildNodes['wc'].Text, ' ');
                              oQry.ParamByName('lavabo').AsString          := Self.Ternario(' ', oNodeItem.ChildNodes['lavabo'].Text, ' ');
                              oQry.ParamByName('piscina').AsString         := Self.Ternario(' ', oNodeItem.ChildNodes['piscina'].Text, ' ');
                              oQry.ParamByName('garagem').AsString         := Self.Ternario(' ', oNodeItem.ChildNodes['garagem'].Text, ' ');
                              oQry.ParamByName('telefone').AsString        := Self.Ternario(' ', oNodeItem.ChildNodes['telefone'].Text, ' ');
                              oQry.ParamByName('data').AsString            := FormatDateTime('dd/mm/yyyy', Date);
                              oQry.ParamByName('cod_usuario').AsString     := IntToStr(FIdImobiliaria);
                              OQry.ParamByName('views').AsString           := '0';
                              oQry.ParamByName('status').AsString          := 'Ativo';
                              oQry.ParamByName('aprovado').AsString        := 'SIM';
                              oQry.ParamByName('valor').AsFloat            := StrToFloat(sValor);
                              oQry.ParamByName('bairro').AsString          := oNodeItem.ChildNodes['bairro'].Text;
                              oQry.ExecSQL();

                              // Inseri os dados para atualização da tarefa
                              self.AtualizaInfoTarefa(FIdAgendameto, Self.CalculaDuracao(tTimeInicial, Now), 'E', 'Executando inclusões temporárias de imóveis - ' + IntToStr(iContTempImovel) + ' de ' + IntToStr(iContTotalItem) , '');

                              oNodeFotos := oNodeitem.ChildNodes.FindNode('fotos');
                              if oNodeFotos <> nil then
                              begin
                                   oNodeFotos.ChildNodes.First;

                                   repeat
                                        oNodeFoto := oNodeFotos.ChildNodes.FindNode('foto');
                                        if oNodeFoto <> nil then
                                        begin
                                            oNodeFoto.ChildNodes.First;

                                            // Inseri os dados para atualização da tarefa
                                            self.AtualizaInfoTarefa(FIdAgendameto, Self.CalculaDuracao(tTimeInicial, Now), 'E', 'Executando inclusões temporárias de imagens - ' + IntToStr(iContTemp) + ' de ' + IntToStr(iContTotalFoto) , '');
                                            repeat

                                                if not Self.FConexaoPortal.Connected then
                                                   Self.ConectarPortal;

                                                oQryImg.Close;
                                                oQryImg.SQL.Clear;
                                                oQryImg.SQL.Add('INSERT INTO imoveis_fotos_xml (id_imovel, destaque, cod_imobiliaria, data, id_externo, url_foto, processada, nova)VALUES');
                                                oQryImg.SQL.Add('(:id_imovel, :destaque, :cod_imobiliaria, :data, :id_externo, :url_foto, :processada, :nova)');
                                                oQryImg.ParamByName('id_imovel').AsInteger       := 0; /////
                                                oQryImg.ParamByName('destaque').AsString         := 'NAO'; //////
                                                oQryImg.ParamByName('cod_imobiliaria').AsInteger := Self.FIdImobiliaria;
                                                oQryImg.ParamByName('data').AsString             := FormatDateTime('dd/mm/yyyy', Date);
                                                oQryImg.ParamByName('id_externo').AsInteger      := iIdExterno;
                                                oQryImg.ParamByName('url_foto').AsString         := Trim(oNodeFoto.ChildNodes['url_foto'].Text);
                                                oQryImg.ParamByName('processada').AsString       := 'NAO';  //////
                                                oQryImg.ParamByName('nova').AsString             := 'NAO';  //////
                                                oQryImg.ExecSQL();

                                                Inc(iContTemp);
                                                oNodeFoto := oNodeFoto.NextSibling;
                                            until (oNodeFoto = nil) or (ThreadImportacao.CheckTerminated);
                                        end;

                                        oNodeFotos := oNodeFotos.NextSibling;
                                   until (oNodeFotos = nil) ;
                              end;

                              Inc(iContTempImovel);
                          end;

                          oNodeItem := oNodeItem.NextSibling;
                    until (oNodeItem = nil) or (ThreadImportacao.CheckTerminated) ;

                    oNodePai := oNodePai.NextSibling;
               until (oNodePai = nil) ;

               // Fecha Conexão com banco de dados do  portal
               Self.FConexaoPortal.Close;
           except
               on E:Exception do
               begin
                  MessageDlg('Erro ao inserir dados na tabela temporária: '#13 + E.Message, mtError, [mbOK], 0);
                  Self.FConexaoPortal.Close;
               end;
           end;
      finally
         FreeAndNil(oXMLDoc);
         FreeAndNil(oQry);
         FreeAndNil(oQryImg);
      end;
end;

function TImportacaoDogus.ValidaTagsXML(node: IXMLNode): Boolean;
var
    i : Integer;
    nodeTemp1, nodeTemp2 : IXMLNode;
    t: string;
begin
    // Verifica se existe valor para o parâmetro
    if Assigned(node) then
    begin

        // Loop para percorrer todas as TAGs dentro do Node['item'] verificando a ausência de TAGs
        for i := 1 to 23 do
        begin
            nodeTemp1 := node.ChildNodes.FindNode(TAGS[i]);

            if nodeTemp1 = nil then
            begin
                Result := False;
                Exit();
            end;
        end;

        // Verificando se existem fotos para o Node['fotos']
        nodeTemp1 := node.ChildNodes.FindNode('fotos');
        nodeTemp1.ChildNodes.First;
        nodeTemp2 := nodeTemp1.ChildNodes.FindNode('foto');

        if nodeTemp2 = nil then
        begin
            Result := False;
            Exit();
        end;

        Result := True;
    end
    else
       Result := false;
end;

end.

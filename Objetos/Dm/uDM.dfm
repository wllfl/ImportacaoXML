object dm: Tdm
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Left = 632
  Top = 217
  Height = 285
  Width = 493
  object conexaoMonitoramento: TSQLConnection
    LoginPrompt = False
    BeforeConnect = conexaoMonitoramentoBeforeConnect
    Left = 336
    Top = 24
  end
  object qryAgendamento: TSQLQuery
    MaxBlobSize = -1
    Params = <>
    SQL.Strings = (
      'SELECT * FROM TAB_AGENDAMENTO')
    SQLConnection = conexaoMonitoramento
    Left = 80
    Top = 104
  end
  object dspAgendamento: TDataSetProvider
    DataSet = qryAgendamento
    Left = 192
    Top = 104
  end
  object cdsAgendamento: TClientDataSet
    Aggregates = <>
    Params = <>
    ProviderName = 'dspAgendamento'
    Left = 296
    Top = 104
  end
  object dtsAgendamento: TDataSource
    DataSet = cdsAgendamento
    Left = 392
    Top = 104
  end
  object qryAux: TSQLQuery
    Params = <>
    Left = 80
    Top = 168
  end
  object dspAux: TDataSetProvider
    DataSet = qryAux
    Left = 192
    Top = 168
  end
  object cdsAux: TClientDataSet
    Aggregates = <>
    PacketRecords = 500
    Params = <>
    ProviderName = 'dspAux'
    Left = 296
    Top = 168
  end
  object conexao: TSQLConnection
    BeforeConnect = conexaoBeforeConnect
    Left = 160
    Top = 24
  end
end

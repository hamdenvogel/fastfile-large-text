object frmTailExportDialog: TfrmTailExportDialog
  Left = 380
  Top = 220
  BorderStyle = bsDialog
  Caption = 'Export tail lines'
  ClientHeight = 278
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblTitle: TLabel
    Left = 16
    Top = 12
    Width = 320
    Height = 26
    AutoSize = False
    Caption = 
      'Export lines appended while Tail / Follow mode was active (Ctrl+' +
      'T).'
    WordWrap = True
  end
  object lblAvailable: TLabel
    Left = 16
    Top = 44
    Width = 448
    Height = 13
    AutoSize = False
    Caption = 'Tail captured 0 line(s).'
  end
  object grpScope: TRadioGroup
    Left = 16
    Top = 68
    Width = 448
    Height = 72
    Caption = 'What to export'
    TabOrder = 0
    OnClick = grpScopeClick
  end
  object lblFrom: TLabel
    Left = 32
    Top = 152
    Width = 54
    Height = 13
    Caption = 'From line:'
  end
  object lblTo: TLabel
    Left = 248
    Top = 152
    Width = 41
    Height = 13
    Caption = 'To line:'
  end
  object edtFromLine: TEdit
    Left = 96
    Top = 148
    Width = 120
    Height = 21
    TabOrder = 1
  end
  object edtToLine: TEdit
    Left = 296
    Top = 148
    Width = 120
    Height = 21
    TabOrder = 2
  end
  object lblPath: TLabel
    Left = 16
    Top = 180
    Width = 59
    Height = 13
    Caption = 'Save to file:'
  end
  object edtPath: TEdit
    Left = 16
    Top = 196
    Width = 368
    Height = 21
    TabOrder = 3
  end
  object btnBrowse: TButton
    Left = 392
    Top = 194
    Width = 72
    Height = 25
    Caption = 'Browse...'
    TabOrder = 4
    OnClick = btnBrowseClick
  end
  object Bevel1: TBevel
    Left = 16
    Top = 228
    Width = 448
    Height = 2
  end
  object btnExport: TButton
    Left = 304
    Top = 240
    Width = 75
    Height = 25
    Caption = 'Export'
    Default = True
    TabOrder = 5
    OnClick = btnExportClick
  end
  object btnCancel: TButton
    Left = 389
    Top = 240
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 6
    OnClick = btnCancelClick
  end
end

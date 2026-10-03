object frmFindReplace: TfrmFindReplace
  Left = 380
  Top = 280
  BorderStyle = bsDialog
  Caption = 'Find and Replace'
  ClientHeight = 230
  ClientWidth = 460
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = True
  Position = poScreenCenter
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object lblFind: TLabel
    Left = 16
    Top = 20
    Width = 52
    Height = 13
    Caption = 'Find what:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblReplace: TLabel
    Left = 16
    Top = 56
    Width = 73
    Height = 13
    Caption = 'Replace with:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Bevel1: TBevel
    Left = 16
    Top = 132
    Width = 425
    Height = 2
  end
  object lblStatus: TLabel
    Left = 16
    Top = 146
    Width = 3
    Height = 13
  end
  object edtFind: TEdit
    Left = 108
    Top = 16
    Width = 333
    Height = 21
    TabOrder = 0
  end
  object edtReplace: TEdit
    Left = 108
    Top = 52
    Width = 333
    Height = 21
    TabOrder = 1
  end
  object chkCaseSensitive: TCheckBox
    Left = 16
    Top = 92
    Width = 120
    Height = 17
    Caption = 'Case sensitive'
    TabOrder = 2
  end
  object chkWholeWord: TCheckBox
    Left = 150
    Top = 92
    Width = 120
    Height = 17
    Caption = 'Whole word'
    TabOrder = 3
  end
  object btnFindNext: TButton
    Left = 16
    Top = 180
    Width = 95
    Height = 30
    Caption = 'Find &Next'
    Default = True
    TabOrder = 4
    OnClick = btnFindNextClick
  end
  object btnReplace: TButton
    Left = 120
    Top = 180
    Width = 95
    Height = 30
    Caption = '&Replace'
    TabOrder = 5
    OnClick = btnReplaceClick
  end
  object btnReplaceAll: TButton
    Left = 224
    Top = 180
    Width = 95
    Height = 30
    Caption = 'Replace A&ll'
    TabOrder = 6
    OnClick = btnReplaceAllClick
  end
  object btnClose: TButton
    Left = 346
    Top = 180
    Width = 95
    Height = 30
    Cancel = True
    Caption = '&Close'
    TabOrder = 7
    OnClick = btnCloseClick
  end
end

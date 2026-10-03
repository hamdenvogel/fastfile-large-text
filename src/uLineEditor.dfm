object frmLineEditor: TfrmLineEditor
  Left = 452
  Top = 236
  BorderStyle = bsSizeable
  Caption = 'File Line Editor'
  ClientHeight = 380
  ClientWidth = 520
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
  OnCloseQuery = FormCloseQuery
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 16
    Width = 60
    Height = 13
    Caption = 'Operation:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 16
    Top = 64
    Width = 76
    Height = 13
    Caption = 'Line Number:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label3: TLabel
    Left = 16
    Top = 112
    Width = 49
    Height = 13
    Caption = 'Content:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object cbOperation: TComboBox
    Left = 16
    Top = 32
    Width = 488
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
    OnChange = cbOperationChange
  end
  object edtLineNumber: TEdit
    Left = 16
    Top = 80
    Width = 121
    Height = 21
    TabOrder = 1
  end
  object chkMergeLines: TCheckBox
    Left = 152
    Top = 82
    Width = 352
    Height = 17
    Caption = 'Merge lines'
    TabOrder = 2
    OnClick = chkMergeLinesClick
  end
  object pnlMemoTools: TPanel
    Left = 16
    Top = 128
    Width = 488
    Height = 28
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 3
    object btnSelectAll: TButton
      Left = 0
      Top = 2
      Width = 98
      Height = 25
      Caption = 'Select All'
      TabOrder = 0
      OnClick = btnSelectAllClick
    end
    object btnCopy: TButton
      Left = 104
      Top = 2
      Width = 80
      Height = 25
      Caption = 'Copy'
      TabOrder = 1
      OnClick = btnCopyClick
    end
    object btnPaste: TButton
      Left = 190
      Top = 2
      Width = 80
      Height = 25
      Caption = 'Paste'
      TabOrder = 2
      OnClick = btnPasteClick
    end
    object btnClear: TButton
      Left = 276
      Top = 2
      Width = 80
      Height = 25
      Caption = 'Clear'
      TabOrder = 3
      OnClick = btnClearClick
    end
    object btnAskAI: TButton
      Left = 362
      Top = 2
      Width = 120
      Height = 25
      Caption = 'Ask AI'
      TabOrder = 4
      OnClick = btnAskAIClick
    end
  end
  object mmContent: TMemo
    Left = 16
    Top = 160
    Width = 488
    Height = 164
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 4
    OnKeyDown = mmContentKeyDown
  end
  object pnlMerge: TPanel
    Left = 16
    Top = 200
    Width = 488
    Height = 168
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 5
    Visible = False
    object lblMergeHint: TLabel
      Left = 0
      Top = 0
      Width = 488
      Height = 28
      AutoSize = False
      Caption = 'Select lines to merge into one (current line stays as target).'
      WordWrap = True
    end
    object clbMerge: TCheckListBox
      Left = 0
      Top = 30
      Width = 488
      Height = 138
      ItemHeight = 13
      TabOrder = 0
      OnClickCheck = clbMergeClickCheck
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 332
    Width = 520
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 6
    object Bevel1: TBevel
      Left = 16
      Top = 4
      Width = 488
      Height = 2
    end
    object btnConfirm: TButton
      Left = 340
      Top = 14
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Confirm'
      Default = True
      TabOrder = 0
      OnClick = btnConfirmClick
    end
    object btnCancel: TButton
      Left = 429
      Top = 14
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
end

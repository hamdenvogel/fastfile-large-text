object frmDeltaEditor: TfrmDeltaEditor
  Left = 200
  Top = 120
  Caption = 'Merge lines'
  ClientHeight = 420
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = True
  Position = poScreenCenter
  OnShow = FormShow
  OnResize = FormResize
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 88
    Align = alTop
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 0
    object lblHint: TLabel
      Left = 12
      Top = 8
      Width = 616
      Height = 28
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 
        'Edit the lines to replace in the file, then click Merge. Select ' +
        'a row to edit it.'
      WordWrap = True
    end
    object lblLineNum: TLabel
      Left = 12
      Top = 48
      Width = 70
      Height = 13
      Caption = 'Line Number:'
    end
    object edtLineNum: TEdit
      Left = 90
      Top = 44
      Width = 72
      Height = 21
      TabOrder = 0
      OnKeyPress = edtLineNumKeyPress
    end
    object lblContent: TLabel
      Left = 174
      Top = 48
      Width = 43
      Height = 13
      Caption = 'Content:'
    end
    object edtContent: TEdit
      Left = 224
      Top = 44
      Width = 292
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
      OnKeyPress = edtContentKeyPress
    end
    object btnAdd: TButton
      Left = 524
      Top = 42
      Width = 104
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Add/Update'
      Default = True
      TabOrder = 2
      OnClick = btnAddClick
    end
  end
  object lvDelta: TListView
    Left = 0
    Top = 88
    Width = 640
    Height = 284
    Align = alClient
    Columns = <
      item
        Caption = 'Line Number'
        Width = 100
      end
      item
        Caption = 'Content'
        Width = 500
      end>
    HideSelection = False
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnDblClick = lvDeltaDblClick
    OnSelectItem = lvDeltaSelectItem
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 372
    Width = 640
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 2
    object Bevel1: TBevel
      Left = 12
      Top = 4
      Width = 616
      Height = 2
      Anchors = [akLeft, akTop, akRight]
    end
    object lblStatus: TLabel
      Left = 180
      Top = 20
      Width = 260
      Height = 13
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object btnCopy: TButton
      Left = 12
      Top = 14
      Width = 75
      Height = 25
      Caption = 'Copy'
      TabOrder = 0
      OnClick = btnCopyClick
    end
    object btnDelete: TButton
      Left = 95
      Top = 14
      Width = 75
      Height = 25
      Caption = 'Remove'
      TabOrder = 1
      OnClick = btnDeleteClick
    end
    object btnConfirm: TButton
      Left = 452
      Top = 14
      Width = 85
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Merge'
      ModalResult = 1
      TabOrder = 2
    end
    object btnCancel: TButton
      Left = 545
      Top = 14
      Width = 83
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 3
    end
  end
end

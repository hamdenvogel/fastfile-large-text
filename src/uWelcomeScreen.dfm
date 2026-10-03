object frmWelcomeScreen: TfrmWelcomeScreen
  Left = 129
  Top = 97
  Width = 736
  Height = 519
  Caption = 'FastFile  '#226#8364#8221'  Start'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 720
    Height = 72
    Align = alTop
    BevelOuter = bvNone
    Color = clNavy
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 14
      Top = 8
      Width = 72
      Height = 30
      Caption = 'FastFile'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object lblTagline: TLabel
      Left = 14
      Top = 42
      Width = 364
      Height = 36
      AutoSize = False
      Caption = 
        'Open and edit multi-gigabyte text files instantly - where other' +
        ' editors can''t keep up. Exclusive features like Python macros, A' +
        'I to extract/analyze files, and much more.'
      WordWrap = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 12303291
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblVersion: TLabel
      Left = 697
      Top = 26
      Width = 3
      Height = 13
      Alignment = taRightJustify
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 7838088
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 428
    Width = 720
    Height = 52
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object chkDontShow: TCheckBox
      Left = 12
      Top = 16
      Width = 266
      Height = 20
      Caption = 'Don'#39't show this screen on startup'
      TabOrder = 0
      OnClick = chkDontShowClick
    end
    object btnOpenFile: TButton
      Left = 430
      Top = 12
      Width = 88
      Height = 28
      Caption = 'Open File...'
      TabOrder = 1
      OnClick = btnOpenFileClick
    end
    object btnOpenSelected: TButton
      Left = 524
      Top = 12
      Width = 108
      Height = 28
      Caption = 'Open Selected'
      Default = True
      Enabled = False
      TabOrder = 2
      OnClick = btnOpenSelectedClick
    end
    object btnClose: TButton
      Left = 638
      Top = 12
      Width = 72
      Height = 28
      Cancel = True
      Caption = 'Close'
      TabOrder = 3
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 72
    Width = 720
    Height = 356
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object Splitter1: TSplitter
      Left = 513
      Top = 0
      Width = 6
      Height = 356
      Align = alRight
      ResizeStyle = rsUpdate
    end
    object pnlRecentFolders: TPanel
      Left = 519
      Top = 0
      Width = 201
      Height = 356
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 0
      object lblRecentFolders: TLabel
        Left = 8
        Top = 8
        Width = 87
        Height = 13
        Caption = 'Recent Folders'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lvRecentFolders: TListView
        Left = 0
        Top = 28
        Width = 201
        Height = 328
        Align = alBottom
        Columns = <
          item
            AutoSize = True
            Caption = 'Folder'
          end>
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        OnDblClick = lvRecentFoldersDblClick
      end
    end
    object pnlRecentFiles: TPanel
      Left = 0
      Top = 0
      Width = 513
      Height = 356
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object lblRecentFiles: TLabel
        Left = 8
        Top = 8
        Width = 72
        Height = 13
        Caption = 'Recent Files'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lvRecentFiles: TListView
        Left = 0
        Top = 28
        Width = 513
        Height = 328
        Align = alBottom
        Columns = <
          item
            Caption = 'File Name'
            Width = 150
          end
          item
            Caption = 'Folder'
            Width = 178
          end
          item
            Alignment = taRightJustify
            Caption = 'Size'
            Width = 72
          end
          item
            Caption = 'Modified'
            Width = 110
          end
          item
            Caption = 'Session'
            Width = 58
          end>
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        OnChange = lvRecentFilesChange
        OnCustomDrawItem = lvRecentFilesCustomDrawItem
        OnDblClick = lvRecentFilesDblClick
        OnKeyDown = lvRecentFilesKeyDown
      end
    end
  end
end

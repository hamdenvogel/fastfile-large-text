object frmCompareMerge: TfrmCompareMerge
  Left = 150
  Top = 160
  Width = 900
  Height = 560
  Caption = 'Compare / merge + session history'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = True
  Position = poScreenCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnMouseWheel = FormMouseWheel
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 884
    Height = 481
    ActivePage = TabSheetHistory
    Align = alClient
    TabOrder = 0
    object TabSheetHistory: TTabSheet
      Caption = 'Session history'
      OnResize = TabSheetHistoryResize
      DesignSize = (
        876
        453)
      object lblHistPath: TLabel
        Left = 8
        Top = 8
        Width = 3
        Height = 13
      end
      object lblJournalHint: TLabel
        Left = 8
        Top = 64
        Width = 860
        Height = 28
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        WordWrap = True
      end
      object lblHistPreview: TLabel
        Left = 8
        Top = 304
        Width = 3
        Height = 13
      end
      object btnReloadHist: TButton
        Left = 8
        Top = 32
        Width = 120
        Height = 25
        Caption = 'Reload'
        TabOrder = 0
        OnClick = btnReloadHistClick
      end
      object btnClearHist: TButton
        Left = 136
        Top = 32
        Width = 120
        Height = 25
        Caption = 'Clear history'
        TabOrder = 3
        OnClick = btnClearHistClick
      end
      object mmoJournal: TMemo
        Left = 8
        Top = 96
        Width = 860
        Height = 200
        Anchors = [akLeft, akTop, akRight]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Consolas'
        Font.Style = []
        HideSelection = False
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
        WantReturns = False
        WordWrap = False
        OnClick = mmoJournalClick
        OnMouseUp = mmoJournalMouseUp
      end
      object lvHistFile: TListView
        Left = 8
        Top = 320
        Width = 860
        Height = 120
        Anchors = [akLeft, akTop, akRight]
        Columns = <
          item
            Caption = 'Line'
            Width = 56
          end
          item
            Caption = 'Text'
            Width = 720
          end>
        GridLines = True
        HideSelection = True
        HotTrack = False
        ReadOnly = True
        RowSelect = True
        PopupMenu = popLvHist
        TabOrder = 2
        ViewStyle = vsReport
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        OnCustomDrawItem = lvHistFileCustomDrawItem
        OnCustomDrawSubItem = lvHistFileCustomDrawSubItem
        OnAdvancedCustomDrawItem = lvHistFileAdvancedCustomDrawItem
        OnMouseDown = lvHistFileMouseDown
        OnSelectItem = lvHistFileSelectItem
      end
    end
    object TabSheetDiff: TTabSheet
      Caption = 'Two-file diff'
      OnResize = TabSheetDiffResize
      DesignSize = (
        876
        453)
      object lblLeft: TLabel
        Left = 8
        Top = 10
        Width = 118
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Caption = 'Left file'
      end
      object lblRight: TLabel
        Left = 8
        Top = 42
        Width = 118
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Caption = 'Right file'
      end
      object lblFirst: TLabel
        Left = 8
        Top = 86
        Width = 118
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Caption = 'First line'
      end
      object lblLast: TLabel
        Left = 200
        Top = 86
        Width = 80
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Caption = 'Last line'
      end
      object lblLegend: TLabel
        Left = 8
        Top = 112
        Width = 3
        Height = 13
      end
      object edtLeftFile: TEdit
        Left = 132
        Top = 6
        Width = 636
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
      end
      object btnBrowseLeft: TButton
        Left = 780
        Top = 4
        Width = 90
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Browse...'
        TabOrder = 1
        OnClick = btnBrowseLeftClick
      end
      object edtRightFile: TEdit
        Left = 132
        Top = 38
        Width = 636
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 2
      end
      object btnBrowseRight: TButton
        Left = 780
        Top = 36
        Width = 90
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Browse...'
        TabOrder = 3
        OnClick = btnBrowseRightClick
      end
      object edtFirstLine: TEdit
        Left = 132
        Top = 82
        Width = 57
        Height = 21
        TabOrder = 4
        Text = '1'
      end
      object edtLastLine: TEdit
        Left = 288
        Top = 82
        Width = 57
        Height = 21
        TabOrder = 5
        Text = '2000'
      end
      object btnRunDiff: TButton
        Left = 360
        Top = 80
        Width = 160
        Height = 25
        Caption = 'Build diff'
        TabOrder = 6
        OnClick = btnRunDiffClick
      end
      object chkSyncScroll: TCheckBox
        Left = 540
        Top = 82
        Width = 200
        Height = 17
        Caption = 'Sync scroll'
        Checked = True
        State = cbChecked
        TabOrder = 7
        OnClick = chkSyncScrollClick
      end
      object chkDiffByLines: TCheckBox
        Left = 540
        Top = 105
        Width = 300
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Diff by lines (range)'
        TabOrder = 14
        OnClick = chkDiffByLinesClick
      end
      object chkFastLargeFiles: TCheckBox
        Left = 540
        Top = 126
        Width = 320
        Height = 30
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Fast mode for large files (auto range above %d MB)'
        Checked = True
        State = cbChecked
        TabOrder = 15
        WordWrap = True
      end
      object btnCopyLeft: TButton
        Left = 8
        Top = 160
        Width = 160
        Height = 25
        Caption = 'Copy selected left'
        TabOrder = 8
        OnClick = btnCopyLeftClick
      end
      object btnCopyRight: TButton
        Left = 180
        Top = 160
        Width = 160
        Height = 25
        Caption = 'Copy selected right'
        TabOrder = 9
        OnClick = btnCopyRightClick
      end
      object btnApplyLeftToRight: TButton
        Left = 350
        Top = 160
        Width = 210
        Height = 25
        Caption = 'Apply left to right (disk)'
        TabOrder = 12
        OnClick = btnApplyLeftToRightClick
      end
      object btnApplyRightToLeft: TButton
        Left = 570
        Top = 160
        Width = 210
        Height = 25
        Caption = 'Apply right to left (disk)'
        TabOrder = 13
        OnClick = btnApplyRightToLeftClick
      end
      object lvLeft: TListView
        Left = 8
        Top = 194
        Width = 432
        Height = 270
        Anchors = [akLeft, akTop, akBottom]
        Columns = <
          item
            Caption = 'Line'
          end
          item
            Caption = 'Text'
            Width = 520
          end>
        GridLines = True
        HideSelection = False
        HotTrack = True
        ReadOnly = True
        RowSelect = True
        PopupMenu = popLvLeft
        TabOrder = 10
        ViewStyle = vsReport
        OnCustomDrawItem = lvLeftCustomDrawItem
        OnSelectItem = lvMergeListSelectItem
      end
      object lvRight: TListView
        Left = 448
        Top = 194
        Width = 420
        Height = 270
        Anchors = [akLeft, akTop, akRight, akBottom]
        Columns = <
          item
            Caption = 'Line'
          end
          item
            Caption = 'Text'
            Width = 520
          end>
        GridLines = True
        HideSelection = False
        HotTrack = True
        ReadOnly = True
        RowSelect = True
        PopupMenu = popLvRight
        TabOrder = 11
        ViewStyle = vsReport
        OnCustomDrawItem = lvRightCustomDrawItem
        OnSelectItem = lvMergeListSelectItem
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 481
    Width = 884
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      884
      40)
    object lblNote: TLabel
      Left = 8
      Top = 4
      Width = 3
      Height = 13
    end
    object btnClose: TButton
      Left = 780
      Top = 6
      Width = 100
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Close'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object OpenDialog1: TOpenDialog
    Options = [ofHideReadOnly, ofFileMustExist]
    Left = 840
    Top = 440
  end
  object tmrSync: TTimer
    Enabled = False
    Interval = 80
    OnTimer = tmrSyncTimer
    Left = 800
    Top = 440
  end
  object popLvLeft: TPopupMenu
    OnPopup = popLvLeftPopup
    Left = 720
    Top = 400
    object mnuLCopy: TMenuItem
      Caption = 'Copy selection'
      OnClick = mnuLCopyClick
    end
    object mnuLApplyToRight: TMenuItem
      Caption = 'Apply left to right (disk)'
      OnClick = mnuLApplyToRightClick
    end
    object mnuLApplyToLeft: TMenuItem
      Caption = 'Apply right to left (disk)'
      OnClick = mnuLApplyToLeftClick
    end
    object mnuLSelectAll: TMenuItem
      Caption = 'Select all'
      OnClick = mnuLSelectAllClick
    end
    object mnuLGoToLine: TMenuItem
      Caption = '&Go to line...'
      OnClick = mnuLGoToLineClick
    end
  end
  object popLvRight: TPopupMenu
    OnPopup = popLvRightPopup
    Left = 760
    Top = 400
    object mnuRCopy: TMenuItem
      Caption = 'Copy selection'
      OnClick = mnuRCopyClick
    end
    object mnuRApplyToRight: TMenuItem
      Caption = 'Apply left to right (disk)'
      OnClick = mnuRApplyToRightClick
    end
    object mnuRApplyToLeft: TMenuItem
      Caption = 'Apply right to left (disk)'
      OnClick = mnuRApplyToLeftClick
    end
    object mnuRSelectAll: TMenuItem
      Caption = 'Select all'
      OnClick = mnuRSelectAllClick
    end
    object mnuRGoToLine: TMenuItem
      Caption = '&Go to line...'
      OnClick = mnuRGoToLineClick
    end
  end
  object popLvHist: TPopupMenu
    OnPopup = popLvHistPopup
    Left = 680
    Top = 400
    object mnuHistCopyLine: TMenuItem
      Caption = 'Copy preview line'
      OnClick = mnuHistCopyLineClick
    end
    object mnuHistCopyText: TMenuItem
      Caption = 'Copy preview text only'
      OnClick = mnuHistCopyTextClick
    end
    object mnuHistGotoLine: TMenuItem
      Caption = '&Go to line...'
      OnClick = mnuHistGotoLineClick
    end
    object mnuHistSelectAll: TMenuItem
      Caption = 'Select all'
      OnClick = mnuHistSelectAllClick
    end
  end
end

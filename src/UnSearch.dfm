object frmSearch: TfrmSearch
  Left = 0
  Top = 0
  Width = 161
  Height = 330
  TabOrder = 0
  object sGroupBox2: TsGroupBox
    Left = 0
    Top = 0
    Width = 161
    Height = 330
    Align = alClient
    Caption = 'Features'
    TabOrder = 0
    CaptionMargin.Left = 0
    CaptionMargin.Right = 0
    CaptionMargin.Bottom = 2
    object sLabel3: TsLabel
      Tag = 1
      Left = 13
      Top = 57
      Width = 125
      Height = 24
      Alignment = taCenter
      AutoSize = False
      SkinSection = 'SELECTION'
      Caption = 'Found words below:'
      Color = 14810367
      ParentColor = False
      ParentFont = False
      Layout = tlCenter
      WordWrap = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
    end
    object sListBox1: TsListBox
      Left = 16
      Top = 83
      Width = 127
      Height = 149
      ItemHeight = 16
      TabOrder = 0
      OnClick = sListBox1Click
    end
    object edtGoToLine: TsComboEdit
      Left = 67
      Top = 243
      Width = 77
      Height = 21
      DoubleBuffered = False
      TabOrder = 1
      AddedGlyph.ImageIndex = 10
      BoundLabel.Active = True
      BoundLabel.Caption = 'Go to line:'
      CheckOnExit = True
      Text = '0'
    end
    object edtSearch: TsComboEdit
      Left = 56
      Top = 32
      Width = 93
      Height = 21
      DoubleBuffered = False
      TabOrder = 2
      AddedGlyph.ImageIndex = 23
      BoundLabel.Active = True
      BoundLabel.Caption = 'Search:'
      CheckOnExit = True
      Text = 'word'
    end
  end
  object sFrameAdapter1: TsFrameAdapter
    Left = 8
    Top = 4
  end
end

object FormPopupMruList: TFormPopupMruList
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 320
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Scaled = False
  ShowHint = True
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 14
  object sPanel1: TsPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 320
    Align = alClient
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 0
    object pnlAccent: TsPanel
      Left = 1
      Top = 1
      Width = 5
      Height = 318
      SkinData.CustomColor = True
      Align = alLeft
      BevelOuter = bvNone
      Color = clHighlight
      ParentBackground = False
      TabOrder = 0
    end
    object pnlBody: TsPanel
      Left = 6
      Top = 1
      Width = 393
      Height = 318
      Align = alClient
      BevelOuter = bvNone
      BorderWidth = 12
      TabOrder = 1
      object pnlHeader: TsPanel
        Left = 12
        Top = 12
        Width = 369
        Height = 58
        SkinData.SkinSection = 'TRANSPARENT'
        Align = alTop
        BevelOuter = bvNone
        BorderWidth = 2
        TabOrder = 0
        object lblHeader: TsLabel
          Left = 2
          Top = 2
          Width = 365
          Height = 26
          Align = alTop
          AutoSize = False
          Caption = 'Recent'
          ParentFont = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
        end
        object pnlSearchRow: TsPanel
          Left = 2
          Top = 28
          Width = 365
          Height = 28
          SkinData.CustomColor = True
          SkinData.SkinSection = 'TRANSPARENT'
          Align = alTop
          BevelOuter = bvNone
          BorderWidth = 3
          Color = clWindow
          ParentBackground = False
          TabOrder = 0
          object btnSearchGlyph: TsSpeedButton
            Left = 3
            Top = 3
            Width = 22
            Height = 22
            Align = alLeft
            ImageIndex = 0
            Images = imgSearchGlyphs
            Flat = True
            Margin = 0
            ParentShowHint = False
            ShowHint = True
            Spacing = 0
            OnClick = btnSearchGlyphClick
            SkinData.SkinSection = 'TRANSPARENT'
          end
          object btnClearSearch: TsSpeedButton
            Left = 340
            Top = 3
            Width = 22
            Height = 22
            Align = alRight
            ImageIndex = 1
            Images = imgSearchGlyphs
            Flat = True
            Margin = 0
            ParentShowHint = False
            ShowHint = True
            Spacing = 0
            Visible = False
            OnClick = btnClearSearchClick
            SkinData.SkinSection = 'TRANSPARENT'
          end
          object edtSearch: TsEdit
            Left = 25
            Top = 3
            Width = 315
            Height = 22
            Align = alClient
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 0
            OnChange = edtSearchChange
            OnKeyDown = edtSearchKeyDown
            SkinData.SkinSection = 'TRANSPARENT'
            BoundLabel.Active = False
            BoundLabel.Caption = 'Search'
          end
        end
      end
      object sBevelHeader: TsBevel
        Left = 12
        Top = 70
        Width = 369
        Height = 8
        Align = alTop
        Shape = bsBottomLine
      end
      object lstItems: TListBox
        Left = 12
        Top = 78
        Width = 369
        Height = 228
        Align = alClient
        BorderStyle = bsNone
        Color = 15987947
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ItemHeight = 40
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        Style = lbOwnerDrawFixed
        TabOrder = 1
        OnDrawItem = lstItemsDrawItem
        OnKeyDown = lstItemsKeyDown
        OnMouseLeave = lstItemsMouseLeave
        OnMouseMove = lstItemsMouseMove
        OnMouseUp = lstItemsMouseUp
      end
    end
  end
  object sSkinProvider1: TsSkinProvider
    AddedTitle.Font.Charset = DEFAULT_CHARSET
    AddedTitle.Font.Color = clNone
    AddedTitle.Font.Height = -13
    AddedTitle.Font.Name = 'Tahoma'
    AddedTitle.Font.Style = []
    SkinData.SkinSection = 'FORM'
    TitleButtons = <>
    Left = 300
    Top = 20
  end
  object imgSearchGlyphs: TsCharImageList
    Height = 16
    Width = 16
    EmbeddedFonts = <
      item
        FontName = 'FontAwesome'
        FontData = {}
      end>
    Items = <
      item
        ScalingFactor = 0.900000000000000000
        Char = 61442
        Color = 6908265
      end
      item
        ScalingFactor = 0.850000000000000000
        Char = 61453
        Color = 6908265
      end
      item
        ScalingFactor = 0.900000000000000000
        Char = 61463
        Color = 6908265
      end
      item
        ScalingFactor = 0.900000000000000000
        Char = 61686
        Color = 6908265
      end
      item
        ScalingFactor = 0.900000000000000000
        Char = 61560
        Color = 11567144
      end
      item
        ScalingFactor = 0.900000000000000000
        Char = 61559
        Color = 11567144
      end
      item
        ScalingFactor = 0.900000000000000000
        Char = 61530
        Color = 6908265
      end
      item
        ScalingFactor = 0.900000000000000000
        Char = 61527
        Color = 6908265
      end>
    Left = 268
    Top = 20
    Bitmap = {}
  end
end

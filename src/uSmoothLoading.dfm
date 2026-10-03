object frmSmoothLoadingForm: TfrmSmoothLoadingForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'frmSmoothLoading'
  ClientHeight = 720
  ClientWidth = 760
  Color = 2631710
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWhite
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnPaint = FormPaint
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlContainer: TPanel
    Left = 150
    Top = 140
    Width = 460
    Height = 420
    BevelOuter = bvNone
    Color = 3946026
    ParentBackground = False
    TabOrder = 0
    object imgLogo: TImage
      Left = 0
      Top = 0
      Width = 460
      Height = 200
      Center = True
      Stretch = True
      Transparent = True
    end
    object lblMessage: TLabel
      Left = 0
      Top = 205
      Width = 460
      Height = 25
      Alignment = taCenter
      AutoSize = False
      Caption = 'Processing ...'
      Color = 3946026
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16773350
      Font.Height = -16
      Font.Name = 'Segoe UI Semilight'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      WordWrap = True
    end
    object lblDetail: TLabel
      Left = 0
      Top = 225
      Width = 460
      Height = 44
      Alignment = taCenter
      AutoSize = False
      Color = 3946026
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 142667007
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      WordWrap = True
    end
    object pbProgressBar: TPaintBox
      Left = 100
      Top = 310
      Width = 260
      Height = 6
      OnPaint = pbProgressBarPaint
    end
    object btnCancel: TBitBtn
      Left = 165
      Top = 340
      Width = 130
      Height = 26
      Cursor = crHandPoint
      Caption = 'Cancel'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 10022143
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsUnderline]
      ParentFont = False
      ParentShowHint = False
      ShowHint = False
      Spacing = 0
      TabOrder = 0
      OnClick = btnCancelClick
    end
  end
  object tmrAnimation: TTimer
    Enabled = False
    Interval = 15
    OnTimer = tmrAnimationTimer
    Left = 24
    Top = 24
  end
end

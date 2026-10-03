object frmSplitView: TfrmSplitView
  Left = 308
  Top = 202
  Width = 918
  Height = 540
  Caption = 'frmSplitView'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    902
    484)
  PixelsPerInch = 96
  TextHeight = 13
  object About: TsSplitView
    Left = 0
    Top = 0
    Width = 1100
    Height = 484
    AutoHide = True
    AnimatedHiding = True
    ContentMoved = True
    BlurData.Mode = bmParent
    BlurData.Opacity = 0
    CloseStyle = svcaCompact
    CompactSize = 20
    DisplayMode = svmaOverlay
    OpenedSize = 1100
    Placement = svpaLeft
    BevelOuter = bvNone
    BorderWidth = 1
    TabOrder = 0
    object sPanel4: TsGradientPanel
      Left = 1
      Top = 1
      Width = 1098
      Height = 482
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 0
      PaintData.CustomGradient = 
        '16755200;0;60;-2097239808;17;20;1459595776;24;16;402718719;34;16' +
        ';402718462;34;20;65278;56;20;65535;100;28;G'
      object sPanel7: TsPanel
        Left = 0
        Top = 220
        Width = 1098
        Height = 303
        Align = alTop
        BevelOuter = bvNone
        BorderWidth = 16
        DoubleBuffered = False
        TabOrder = 0
        object lblAboutTopLeft: TsLabel
          Left = 16
          Top = 16
          Width = 458
          Height = 185
          Align = alLeft
          AutoSize = False
          Caption = 
            'FastFile is a powerful tool designed specially to read and edit ' +
            'huge text files from Windows O.S. It is suitable not only for ve' +
            'ry large files, but can be files of any size.'#13#10#9#13#10'With this soft' +
            'ware you can perform CRUD (Create, read, update and delete) line' +
            ' operations for large files.     '#13#10#13#10'Freeware. You can use it fr' +
            'eely without restrictions.'#13#10'This software is distributed under t' +
            'he Mozilla Public License 1.0 (MPL-1.0).'
          WordWrap = True
        end
        object lblUsefulLinksName: TsLabel
          Left = 17
          Top = 166
          Width = 57
          Height = 13
          Caption = 'Useful links:'
        end
        object sWebLabel3: TsWebLabel
          Left = 86
          Top = 166
          Width = 196
          Height = 13
          Caption = 'https://www.mozilla.org/en-US/MPL/1.1/'
          ParentFont = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          HoverFont.Charset = DEFAULT_CHARSET
          HoverFont.Color = clWindowText
          HoverFont.Height = -11
          HoverFont.Name = 'Tahoma'
          HoverFont.Style = []
          URL = 'https://www.mozilla.org/en-US/MPL/1.1/'
        end
        object sWebLabel4: TsWebLabel
          Left = 87
          Top = 182
          Width = 324
          Height = 13
          Caption = 
            'https://www.tldrlegal.com/license/mozilla-public-license-1-0-mpl' +
            '-1-0'
          ParentFont = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          HoverFont.Charset = DEFAULT_CHARSET
          HoverFont.Color = clWindowText
          HoverFont.Height = -11
          HoverFont.Name = 'Tahoma'
          HoverFont.Style = []
          URL = 
            'https://www.tldrlegal.com/license/mozilla-public-license-1-0-mpl' +
            '-1-0'
        end
        object sGroupBox3: TsGroupBox
          Left = 496
          Top = 16
          Width = 586
          Height = 185
          Align = alRight
          Caption = 'License'
          TabOrder = 0
          object memoLicense: TsMemo
            Left = 2
            Top = 15
            Width = 582
            Height = 168
            Align = alClient
            Color = clGray
            Lines.Strings = (
              ''
              
                'This software is distributed under the Mozilla Public License 1.' +
                '0 (MPL-1.0).'
              ''
              'Copyright (c) 2024, Hamden Vogel.'
              'All rights reserved.'
              ''
              'Mozilla Public License Version 1.1'
              '1. Definitions.'
              '1.0.1. "Commercial Use"'
              
                'means distribution or otherwise making the Covered Code availabl' +
                'e to a third party.'
              '1.1. "Contributor"'
              
                'means each entity that creates or contributes to the creation of' +
                ' Modifications.'
              '1.2. "Contributor Version"'
              
                'means the combination of the Original Code, prior Modifications ' +
                'used by a Contributor, and the Modifications made by that partic' +
                'ular Contributor.'
              '1.3. "Covered Code"'
              
                'means the Original Code or Modifications or the combination of t' +
                'he Original Code and Modifications, in each case including porti' +
                'ons thereof.'
              '1.4. "Electronic Distribution Mechanism"'
              
                'means a mechanism generally accepted in the software development' +
                ' community for the electronic transfer of data.'
              '1.5. "Executable"'
              'means Covered Code in any form other than Source Code.'
              '1.6. "Initial Developer"'
              
                'means the individual or entity identified as the Initial Develop' +
                'er in the Source Code notice required by Exhibit A.'
              '1.7. "Larger Work"'
              
                'means a work which combines Covered Code or portions thereof wit' +
                'h code not governed by the terms of this License.'
              '1.8. "License"'
              'means this document.'
              '1.8.1. "Licensable"'
              
                'means having the right to grant, to the maximum extent possible,' +
                ' whether at the time of the initial grant or subsequently acquir' +
                'ed, any and all of the rights conveyed herein.'
              '1.9. "Modifications"'
              
                'means any addition to or deletion from the substance or structur' +
                'e of either the Original Code or any previous Modifications. Whe' +
                'n Covered Code is released as a series of files, a Modification ' +
                'is:'
              ''
              
                'Any addition to or deletion from the contents of a file containi' +
                'ng Original Code or previous Modifications.'
              
                'Any new file that contains any part of the Original Code or prev' +
                'ious Modifications.'
              '1.10. "Original Code"'
              
                'means Source Code of computer software code which is described i' +
                'n the Source Code notice required by Exhibit A as Original Code,' +
                ' and which, at the time of its release under this License is not' +
                ' already Covered Code governed by this License.'
              '1.10.1. "Patent Claims"'
              
                'means any patent claim(s), now owned or hereafter acquired, incl' +
                'uding without limitation, method, process, and apparatus claims,' +
                ' in any patent Licensable by grantor.'
              '1.11. "Source Code"'
              
                'means the preferred form of the Covered Code for making modifica' +
                'tions to it, including all modules it contains, plus any associa' +
                'ted interface definition files, scripts used to control compilat' +
                'ion and installation of an Executable, or source code differenti' +
                'al comparisons against either the Original Code or another well ' +
                'known, available Covered Code of the Contributor'#39's choice. The S' +
                'ource Code can be in a compressed or archival form, provided the' +
                ' appropriate decompression or de-archiving software is widely av' +
                'ailable for no charge.'
              '1.12. "You" (or "Your")'
              
                'means an individual or a legal entity exercising rights under, a' +
                'nd complying with all of the terms of, this License or a future ' +
                'version of this License issued under Section 6.1. For legal enti' +
                'ties, "You" includes any entity which controls, is controlled by' +
                ', or is under common control with You. For purposes of this defi' +
                'nition, "control" means (a) the power, direct or indirect, to ca' +
                'use the direction or management of such entity, whether by contr' +
                'act or otherwise, or (b) ownership of more than fifty percent (5' +
                '0%) of the outstanding shares or beneficial ownership of such en' +
                'tity.'
              '2. Source Code License.'
              '2.1. The Initial Developer Grant.'
              
                'The Initial Developer hereby grants You a world-wide, royalty-fr' +
                'ee, non-exclusive license, subject to third party intellectual p' +
                'roperty claims:'
              ''
              
                'under intellectual property rights (other than patent or tradema' +
                'rk) Licensable by Initial Developer to use, reproduce, modify, d' +
                'isplay, perform, sublicense and distribute the Original Code (or' +
                ' portions thereof) with or without Modifications, and/or as part' +
                ' of a Larger Work; and'
              
                'under Patents Claims infringed by the making, using or selling o' +
                'f Original Code, to make, have made, use, practice, sell, and of' +
                'fer for sale, and/or otherwise dispose of the Original Code (or ' +
                'portions thereof).'
              
                'the licenses granted in this Section 2.1 (a) and (b) are effecti' +
                've on the date Initial Developer first distributes Original Code' +
                ' under the terms of this License.'
              
                'Notwithstanding Section 2.1 (b) above, no patent license is gran' +
                'ted: 1) for code that You delete from the Original Code; 2) sepa' +
                'rate from the Original Code; or 3) for infringements caused by: ' +
                'i) the modification of the Original Code or ii) the combination ' +
                'of the Original Code with other software or devices.'
              '2.2. Contributor Grant.'
              
                'Subject to third party intellectual property claims, each Contri' +
                'butor hereby grants You a world-wide, royalty-free, non-exclusiv' +
                'e license'
              ''
              
                'under intellectual property rights (other than patent or tradema' +
                'rk) Licensable by Contributor, to use, reproduce, modify, displa' +
                'y, perform, sublicense and distribute the Modifications created ' +
                'by such Contributor (or portions thereof) either on an unmodifie' +
                'd basis, with other Modifications, as Covered Code and/or as par' +
                't of a Larger Work; and'
              
                'under Patent Claims infringed by the making, using, or selling o' +
                'f Modifications made by that Contributor either alone and/or in ' +
                'combination with its Contributor Version (or portions of such co' +
                'mbination), to make, use, sell, offer for sale, have made, and/o' +
                'r otherwise dispose of: 1) Modifications made by that Contributo' +
                'r (or portions thereof); and 2) the combination of Modifications' +
                ' made by that Contributor with its Contributor Version (or porti' +
                'ons of such combination).'
              
                'the licenses granted in Sections 2.2 (a) and 2.2 (b) are effecti' +
                've on the date Contributor first makes Commercial Use of the Cov' +
                'ered Code.'
              
                'Notwithstanding Section 2.2 (b) above, no patent license is gran' +
                'ted: 1) for any code that Contributor has deleted from the Contr' +
                'ibutor Version; 2) separate from the Contributor Version; 3) for' +
                ' infringements caused by: i) third party modifications of Contri' +
                'butor Version or ii) the combination of Modifications made by th' +
                'at Contributor with other software (except as part of the Contri' +
                'butor Version) or other devices; or 4) under Patent Claims infri' +
                'nged by Covered Code in the absence of Modifications made by tha' +
                't Contributor.'
              '3. Distribution Obligations.'
              '3.1. Application of License.'
              
                'The Modifications which You create or to which You contribute ar' +
                'e governed by the terms of this License, including without limit' +
                'ation Section 2.2. The Source Code version of Covered Code may b' +
                'e distributed only under the terms of this License or a future v' +
                'ersion of this License released under Section 6.1, and You must ' +
                'include a copy of this License with every copy of the Source Cod' +
                'e You distribute. You may not offer or impose any terms on any S' +
                'ource Code version that alters or restricts the applicable versi' +
                'on of this License or the recipients'#39' rights hereunder. However,' +
                ' You may include an additional document offering the additional ' +
                'rights described in Section 3.5.'
              ''
              '3.2. Availability of Source Code.'
              
                'Any Modification which You create or to which You contribute mus' +
                't be made available in Source Code form under the terms of this ' +
                'License either on the same media as an Executable version or via' +
                ' an accepted Electronic Distribution Mechanism to anyone to whom' +
                ' you made an Executable version available; and if made available' +
                ' via Electronic Distribution Mechanism, must remain available fo' +
                'r at least twelve (12) months after the date it initially became' +
                ' available, or at least six (6) months after a subsequent versio' +
                'n of that particular Modification has been made available to suc' +
                'h recipients. You are responsible for ensuring that the Source C' +
                'ode version remains available even if the Electronic Distributio' +
                'n Mechanism is maintained by a third party.'
              ''
              '3.3. Description of Modifications.'
              
                'You must cause all Covered Code to which You contribute to conta' +
                'in a file documenting the changes You made to create that Covere' +
                'd Code and the date of any change. You must include a prominent ' +
                'statement that the Modification is derived, directly or indirect' +
                'ly, from Original Code provided by the Initial Developer and inc' +
                'luding the name of the Initial Developer in (a) the Source Code,' +
                ' and (b) in any notice in an Executable version or related docum' +
                'entation in which You describe the origin or ownership of the Co' +
                'vered Code.'
              ''
              '3.4. Intellectual Property Matters'
              '(a) Third Party Claims'
              
                'If Contributor has knowledge that a license under a third party'#39 +
                's intellectual property rights is required to exercise the right' +
                's granted by such Contributor under Sections 2.1 or 2.2, Contrib' +
                'utor must include a text file with the Source Code distribution ' +
                'titled "LEGAL" which describes the claim and the party making th' +
                'e claim in sufficient detail that a recipient will know whom to ' +
                'contact. If Contributor obtains such knowledge after the Modific' +
                'ation is made available as described in Section 3.2, Contributor' +
                ' shall promptly modify the LEGAL file in all copies Contributor ' +
                'makes available thereafter and shall take other steps (such as n' +
                'otifying appropriate mailing lists or newsgroups) reasonably cal' +
                'culated to inform those who received the Covered Code that new k' +
                'nowledge has been obtained.'
              ''
              '(b) Contributor APIs'
              
                'If Contributor'#39's Modifications include an application programmin' +
                'g interface and Contributor has knowledge of patent licenses whi' +
                'ch are reasonably necessary to implement that API, Contributor m' +
                'ust also include this information in the LEGAL file.'
              ''
              '(c) Representations.'
              
                'Contributor represents that, except as disclosed pursuant to Sec' +
                'tion 3.4 (a) above, Contributor believes that Contributor'#39's Modi' +
                'fications are Contributor'#39's original creation(s) and/or Contribu' +
                'tor has sufficient rights to grant the rights conveyed by this L' +
                'icense.'
              ''
              '3.5. Required Notices.'
              
                'You must duplicate the notice in Exhibit A in each file of the S' +
                'ource Code. If it is not possible to put such notice in a partic' +
                'ular Source Code file due to its structure, then You must includ' +
                'e such notice in a location (such as a relevant directory) where' +
                ' a user would be likely to look for such a notice. If You create' +
                'd one or more Modification(s) You may add your name as a Contrib' +
                'utor to the notice described in Exhibit A. You must also duplica' +
                'te this License in any documentation for the Source Code where Y' +
                'ou describe recipients'#39' rights or ownership rights relating to C' +
                'overed Code. You may choose to offer, and to charge a fee for, w' +
                'arranty, support, indemnity or liability obligations to one or m' +
                'ore recipients of Covered Code. However, You may do so only on Y' +
                'our own behalf, and not on behalf of the Initial Developer or an' +
                'y Contributor. You must make it absolutely clear than any such w' +
                'arranty, support, indemnity or liability obligation is offered b' +
                'y You alone, and You hereby agree to indemnify the Initial Devel'
              ''
              '3.6. Distribution of Executable Versions.'
              
                'You may distribute Covered Code in Executable form only if the r' +
                'equirements of Sections 3.1, 3.2, 3.3, 3.4 and 3.5 have been met' +
                ' for that Covered Code, and if You include a notice stating that' +
                ' the Source Code version of the Covered Code is available under ' +
                'the terms of this License, including a description of how and wh' +
                'ere You have fulfilled the obligations of Section 3.2. The notic' +
                'e must be conspicuously included in any notice in an Executable ' +
                'version, related documentation or collateral in which You descri' +
                'be recipients'#39' rights relating to the Covered Code. You may dist' +
                'ribute the Executable version of Covered Code or ownership right' +
                's under a license of Your choice, which may contain terms differ' +
                'ent from this License, provided that You are in compliance with ' +
                'the terms of this License and that the license for the Executabl' +
                'e version does not attempt to limit or alter the recipient'#39's rig' +
                'hts in the Source Code version from the rights set forth in this' +
                ' License. If You distribute the Executable version under a diffe'
              ''
              '3.7. Larger Works.'
              
                'You may create a Larger Work by combining Covered Code with othe' +
                'r code not governed by the terms of this License and distribute ' +
                'the Larger Work as a single product. In such a case, You must ma' +
                'ke sure the requirements of this License are fulfilled for the C' +
                'overed Code.'
              ''
              '4. Inability to Comply Due to Statute or Regulation.'
              
                'If it is impossible for You to comply with any of the terms of t' +
                'his License with respect to some or all of the Covered Code due ' +
                'to statute, judicial order, or regulation then You must: (a) com' +
                'ply with the terms of this License to the maximum extent possibl' +
                'e; and (b) describe the limitations and the code they affect. Su' +
                'ch description must be included in the LEGAL file described in S' +
                'ection 3.4 and must be included with all distributions of the So' +
                'urce Code. Except to the extent prohibited by statute or regulat' +
                'ion, such description must be sufficiently detailed for a recipi' +
                'ent of ordinary skill to be able to understand it.'
              ''
              '5. Application of this License.'
              
                'This License applies to code to which the Initial Developer has ' +
                'attached the notice in Exhibit A and to related Covered Code.'
              ''
              '6. Versions of the License.'
              '6.1. New Versions'
              
                'Netscape Communications Corporation ("Netscape") may publish rev' +
                'ised and/or new versions of the License from time to time. Each ' +
                'version will be given a distinguishing version number.'
              ''
              '6.2. Effect of New Versions'
              
                'Once Covered Code has been published under a particular version ' +
                'of the License, You may always continue to use it under the term' +
                's of that version. You may also choose to use such Covered Code ' +
                'under the terms of any subsequent version of the License publish' +
                'ed by Netscape. No one other than Netscape has the right to modi' +
                'fy the terms applicable to Covered Code created under this Licen' +
                'se.'
              ''
              '6.3. Derivative Works'
              
                'If You create or use a modified version of this License (which y' +
                'ou may only do in order to apply it to code which is not already' +
                ' Covered Code governed by this License), You must (a) rename You' +
                'r license so that the phrases "Mozilla", "MOZILLAPL", "MOZPL", "' +
                'Netscape", "MPL", "NPL" or any confusingly similar phrase do not' +
                ' appear in your license (except to note that your license differ' +
                's from this License) and (b) otherwise make it clear that Your v' +
                'ersion of the license contains terms which differ from the Mozil' +
                'la Public License and Netscape Public License. (Filling in the n' +
                'ame of the Initial Developer, Original Code or Contributor in th' +
                'e notice described in Exhibit A shall not of themselves be deeme' +
                'd to be modifications of this License.)'
              ''
              '7. DISCLAIMER OF WARRANTY'
              
                'COVERED CODE IS PROVIDED UNDER THIS LICENSE ON AN "AS IS" BASIS,' +
                ' WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCL' +
                'UDING, WITHOUT LIMITATION, WARRANTIES THAT THE COVERED CODE IS F' +
                'REE OF DEFECTS, MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE OR NO' +
                'N-INFRINGING. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE ' +
                'OF THE COVERED CODE IS WITH YOU. SHOULD ANY COVERED CODE PROVE D' +
                'EFECTIVE IN ANY RESPECT, YOU (NOT THE INITIAL DEVELOPER OR ANY O' +
                'THER CONTRIBUTOR) ASSUME THE COST OF ANY NECESSARY SERVICING, RE' +
                'PAIR OR CORRECTION. THIS DISCLAIMER OF WARRANTY CONSTITUTES AN E' +
                'SSENTIAL PART OF THIS LICENSE. NO USE OF ANY COVERED CODE IS AUT' +
                'HORIZED HEREUNDER EXCEPT UNDER THIS DISCLAIMER.'
              ''
              '8. Termination'
              
                '8.1. This License and the rights granted hereunder will terminat' +
                'e automatically if You fail to comply with terms herein and fail' +
                ' to cure such breach within 30 days of becoming aware of the bre' +
                'ach. All sublicenses to the Covered Code which are properly gran' +
                'ted shall survive any termination of this License. Provisions wh' +
                'ich, by their nature, must remain in effect beyond the terminati' +
                'on of this License shall survive.'
              ''
              
                '8.2. If You initiate litigation by asserting a patent infringeme' +
                'nt claim (excluding declatory judgment actions) against Initial ' +
                'Developer or a Contributor (the Initial Developer or Contributor' +
                ' against whom You file such action is referred to as "Participan' +
                't") alleging that:'
              ''
              
                'such Participant'#39's Contributor Version directly or indirectly in' +
                'fringes any patent, then any and all rights granted by such Part' +
                'icipant to You under Sections 2.1 and/or 2.2 of this License sha' +
                'll, upon 60 days notice from Participant terminate prospectively' +
                ', unless if within 60 days after receipt of notice You either: (' +
                'i) agree in writing to pay Participant a mutually agreeable reas' +
                'onable royalty for Your past and future use of Modifications mad' +
                'e by such Participant, or (ii) withdraw Your litigation claim wi' +
                'th respect to the Contributor Version against such Participant. ' +
                'If within 60 days of notice, a reasonable royalty and payment ar' +
                'rangement are not mutually agreed upon in writing by the parties' +
                ' or the litigation claim is not withdrawn, the rights granted by' +
                ' Participant to You under Sections 2.1 and/or 2.2 automatically ' +
                'terminate at the expiration of the 60 day notice period specifie' +
                'd above.'
              
                'any software, hardware, or device, other than such Participant'#39's' +
                ' Contributor Version, directly or indirectly infringes any paten' +
                't, then any rights granted to You by such Participant under Sect' +
                'ions 2.1(b) and 2.2(b) are revoked effective as of the date You ' +
                'first made, used, sold, distributed, or had made, Modifications ' +
                'made by that Participant.'
              
                '8.3. If You assert a patent infringement claim against Participa' +
                'nt alleging that such Participant'#39's Contributor Version directly' +
                ' or indirectly infringes any patent where such claim is resolved' +
                ' (such as by license or settlement) prior to the initiation of p' +
                'atent infringement litigation, then the reasonable value of the ' +
                'licenses granted by such Participant under Sections 2.1 or 2.2 s' +
                'hall be taken into account in determining the amount or value of' +
                ' any payment or license.'
              ''
              
                '8.4. In the event of termination under Sections 8.1 or 8.2 above' +
                ', all end user license agreements (excluding distributors and re' +
                'sellers) which have been validly granted by You or any distribut' +
                'or hereunder prior to termination shall survive termination.'
              ''
              '9. LIMITATION OF LIABILITY'
              
                'UNDER NO CIRCUMSTANCES AND UNDER NO LEGAL THEORY, WHETHER TORT (' +
                'INCLUDING NEGLIGENCE), CONTRACT, OR OTHERWISE, SHALL YOU, THE IN' +
                'ITIAL DEVELOPER, ANY OTHER CONTRIBUTOR, OR ANY DISTRIBUTOR OF CO' +
                'VERED CODE, OR ANY SUPPLIER OF ANY OF SUCH PARTIES, BE LIABLE TO' +
                ' ANY PERSON FOR ANY INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENT' +
                'IAL DAMAGES OF ANY CHARACTER INCLUDING, WITHOUT LIMITATION, DAMA' +
                'GES FOR LOSS OF GOODWILL, WORK STOPPAGE, COMPUTER FAILURE OR MAL' +
                'FUNCTION, OR ANY AND ALL OTHER COMMERCIAL DAMAGES OR LOSSES, EVE' +
                'N IF SUCH PARTY SHALL HAVE BEEN INFORMED OF THE POSSIBILITY OF S' +
                'UCH DAMAGES. THIS LIMITATION OF LIABILITY SHALL NOT APPLY TO LIA' +
                'BILITY FOR DEATH OR PERSONAL INJURY RESULTING FROM SUCH PARTY'#39'S ' +
                'NEGLIGENCE TO THE EXTENT APPLICABLE LAW PROHIBITS SUCH LIMITATIO' +
                'N. SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR LIMITATION O' +
                'F INCIDENTAL OR CONSEQUENTIAL DAMAGES, SO THIS EXCLUSION AND LIM' +
                'ITATION MAY NOT APPLY TO YOU.'
              ''
              '10. U.S. government end users'
              
                'The Covered Code is a "commercial item," as that term is defined' +
                ' in 48 C.F.R. 2.101 (Oct. 1995), consisting of "commercial compu' +
                'ter software" and "commercial computer software documentation," ' +
                'as such terms are used in 48 C.F.R. 12.212 (Sept. 1995). Consist' +
                'ent with 48 C.F.R. 12.212 and 48 C.F.R. 227.7202-1 through 227.7' +
                '202-4 (June 1995), all U.S. Government End Users acquire Covered' +
                ' Code with only those rights set forth herein.'
              ''
              '11. Miscellaneous'
              
                'This License represents the complete agreement concerning subjec' +
                't matter hereof. If any provision of this License is held to be ' +
                'unenforceable, such provision shall be reformed only to the exte' +
                'nt necessary to make it enforceable. This License shall be gover' +
                'ned by California law provisions (except to the extent applicabl' +
                'e law, if any, provides otherwise), excluding its conflict-of-la' +
                'w provisions. With respect to disputes in which at least one par' +
                'ty is a citizen of, or an entity chartered or registered to do b' +
                'usiness in the United States of America, any litigation relating' +
                ' to this License shall be subject to the jurisdiction of the Fed' +
                'eral Courts of the Northern District of California, with venue l' +
                'ying in Santa Clara County, California, with the losing party re' +
                'sponsible for costs, including without limitation, court costs a' +
                'nd reasonable attorneys'#39' fees and expenses. The application of t' +
                'he United Nations Convention on Contracts for the International ' +
                'Sale of Goods is expressly excluded. Any law or regulation which'
              ''
              '12. Responsibility for claims'
              
                'As between Initial Developer and the Contributors, each party is' +
                ' responsible for claims and damages arising, directly or indirec' +
                'tly, out of its utilization of rights under this License and You' +
                ' agree to work with Initial Developer and Contributors to distri' +
                'bute such responsibility on an equitable basis. Nothing herein i' +
                's intended or shall be deemed to constitute any admission of lia' +
                'bility.'
              ''
              '13. Multiple-licensed code'
              
                'Initial Developer may designate portions of the Covered Code as ' +
                '"Multiple-Licensed". "Multiple-Licensed" means that the Initial ' +
                'Developer permits you to utilize portions of the Covered Code un' +
                'der Your choice of the MPL or the alternative licenses, if any, ' +
                'specified by the Initial Developer in the file described in Exhi' +
                'bit A.'
              ''
              'Exhibit A - Mozilla Public License.'
              
                '"The contents of this file are subject to the Mozilla Public Lic' +
                'ense'
              'Version 1.1 (the "License"); you may not use this file except in'
              
                'compliance with the License. You may obtain a copy of the Licens' +
                'e at'
              'https://www.mozilla.org/MPL/'
              ''
              
                'Software distributed under the License is distributed on an "AS ' +
                'IS"'
              
                'basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. ' +
                'See the'
              
                'License for the specific language governing rights and limitatio' +
                'ns'
              'under the License.'
              ''
              'The Original Code is ______________________________________.'
              ''
              
                'The Initial Developer of the Original Code is __________________' +
                '______.'
              
                'Portions created by ______________________ are Copyright (C) ___' +
                '___'
              '_______________________. All Rights Reserved.'
              ''
              'Contributor(s): ______________________________________.'
              ''
              
                'Alternatively, the contents of this file may be used under the t' +
                'erms'
              'of the _____ license (the  "[___] License"), in which case the'
              'provisions of [______] License are applicable instead of those'
              
                'above. If you wish to allow use of your version of this file onl' +
                'y'
              
                'under the terms of the [____] License and not to allow others to' +
                ' use'
              
                'your version of this file under the MPL, indicate your decision ' +
                'by'
              
                'deleting the provisions above and replace them with the notice a' +
                'nd'
              
                'other provisions required by the [___] License. If you do not de' +
                'lete'
              
                'the provisions above, a recipient may use your version of this f' +
                'ile'
              'under either the MPL or the [___] License."')
            ReadOnly = True
            ScrollBars = ssBoth
            TabOrder = 0
            Text = 
              #13#10'This software is distributed under the Mozilla Public License ' +
              '1.0 (MPL-1.0).'#13#10#13#10'Copyright (c) 2024, Hamden Vogel.'#13#10'All rights ' +
              'reserved.'#13#10#13#10'Mozilla Public License Version 1.1'#13#10'1. Definitions.' +
              #13#10'1.0.1. "Commercial Use"'#13#10'means distribution or otherwise makin' +
              'g the Covered Code available to a third party.'#13#10'1.1. "Contributo' +
              'r"'#13#10'means each entity that creates or contributes to the creatio' +
              'n of Modifications.'#13#10'1.2. "Contributor Version"'#13#10'means the combi' +
              'nation of the Original Code, prior Modifications used by a Contr' +
              'ibutor, and the Modifications made by that particular Contributo' +
              'r.'#13#10'1.3. "Covered Code"'#13#10'means the Original Code or Modification' +
              's or the combination of the Original Code and Modifications, in ' +
              'each case including portions thereof.'#13#10'1.4. "Electronic Distribu' +
              'tion Mechanism"'#13#10'means a mechanism generally accepted in the sof' +
              'tware development community for the electronic transfer of data.' +
              #13#10'1.5. "Executable"'#13#10'means Covered Code in any form other than S' +
              'ource Code.'#13#10'1.6. "Initial Developer"'#13#10'means the individual or e' +
              'ntity identified as the Initial Developer in the Source Code not' +
              'ice required by Exhibit A.'#13#10'1.7. "Larger Work"'#13#10'means a work whi' +
              'ch combines Covered Code or portions thereof with code not gover' +
              'ned by the terms of this License.'#13#10'1.8. "License"'#13#10'means this do' +
              'cument.'#13#10'1.8.1. "Licensable"'#13#10'means having the right to grant, t' +
              'o the maximum extent possible, whether at the time of the initia' +
              'l grant or subsequently acquired, any and all of the rights conv' +
              'eyed herein.'#13#10'1.9. "Modifications"'#13#10'means any addition to or del' +
              'etion from the substance or structure of either the Original Cod' +
              'e or any previous Modifications. When Covered Code is released a' +
              's a series of files, a Modification is:'#13#10#13#10'Any addition to or de' +
              'letion from the contents of a file containing Original Code or p' +
              'revious Modifications.'#13#10'Any new file that contains any part of t' +
              'he Original Code or previous Modifications.'#13#10'1.10. "Original Cod' +
              'e"'#13#10'means Source Code of computer software code which is describ' +
              'ed in the Source Code notice required by Exhibit A as Original C' +
              'ode, and which, at the time of its release under this License is' +
              ' not already Covered Code governed by this License.'#13#10'1.10.1. "Pa' +
              'tent Claims"'#13#10'means any patent claim(s), now owned or hereafter ' +
              'acquired, including without limitation, method, process, and app' +
              'aratus claims, in any patent Licensable by grantor.'#13#10'1.11. "Sour' +
              'ce Code"'#13#10'means the preferred form of the Covered Code for makin' +
              'g modifications to it, including all modules it contains, plus a' +
              'ny associated interface definition files, scripts used to contro' +
              'l compilation and installation of an Executable, or source code ' +
              'differential comparisons against either the Original Code or ano' +
              'ther well known, available Covered Code of the Contributor'#39's cho' +
              'ice. The Source Code can be in a compressed or archival form, pr' +
              'ovided the appropriate decompression or de-archiving software is' +
              ' widely available for no charge.'#13#10'1.12. "You" (or "Your")'#13#10'means' +
              ' an individual or a legal entity exercising rights under, and co' +
              'mplying with all of the terms of, this License or a future versi' +
              'on of this License issued under Section 6.1. For legal entities,' +
              ' "You" includes any entity which controls, is controlled by, or ' +
              'is under common control with You. For purposes of this definitio' +
              'n, "control" means (a) the power, direct or indirect, to cause t' +
              'he direction or management of such entity, whether by contract o' +
              'r otherwise, or (b) ownership of more than fifty percent (50%) o' +
              'f the outstanding shares or beneficial ownership of such entity.' +
              #13#10'2. Source Code License.'#13#10'2.1. The Initial Developer Grant.'#13#10'Th' +
              'e Initial Developer hereby grants You a world-wide, royalty-free' +
              ', non-exclusive license, subject to third party intellectual pro' +
              'perty claims:'#13#10#13#10'under intellectual property rights (other than ' +
              'patent or trademark) Licensable by Initial Developer to use, rep' +
              'roduce, modify, display, perform, sublicense and distribute the ' +
              'Original Code (or portions thereof) with or without Modification' +
              's, and/or as part of a Larger Work; and'#13#10'under Patents Claims in' +
              'fringed by the making, using or selling of Original Code, to mak' +
              'e, have made, use, practice, sell, and offer for sale, and/or ot' +
              'herwise dispose of the Original Code (or portions thereof).'#13#10'the' +
              ' licenses granted in this Section 2.1 (a) and (b) are effective ' +
              'on the date Initial Developer first distributes Original Code un' +
              'der the terms of this License.'#13#10'Notwithstanding Section 2.1 (b) ' +
              'above, no patent license is granted: 1) for code that You delete' +
              ' from the Original Code; 2) separate from the Original Code; or ' +
              '3) for infringements caused by: i) the modification of the Origi' +
              'nal Code or ii) the combination of the Original Code with other ' +
              'software or devices.'#13#10'2.2. Contributor Grant.'#13#10'Subject to third ' +
              'party intellectual property claims, each Contributor hereby gran' +
              'ts You a world-wide, royalty-free, non-exclusive license'#13#10#13#10'unde' +
              'r intellectual property rights (other than patent or trademark) ' +
              'Licensable by Contributor, to use, reproduce, modify, display, p' +
              'erform, sublicense and distribute the Modifications created by s' +
              'uch Contributor (or portions thereof) either on an unmodified ba' +
              'sis, with other Modifications, as Covered Code and/or as part of' +
              ' a Larger Work; and'#13#10'under Patent Claims infringed by the making' +
              ', using, or selling of Modifications made by that Contributor ei' +
              'ther alone and/or in combination with its Contributor Version (o' +
              'r portions of such combination), to make, use, sell, offer for s' +
              'ale, have made, and/or otherwise dispose of: 1) Modifications ma' +
              'de by that Contributor (or portions thereof); and 2) the combina' +
              'tion of Modifications made by that Contributor with its Contribu' +
              'tor Version (or portions of such combination).'#13#10'the licenses gra' +
              'nted in Sections 2.2 (a) and 2.2 (b) are effective on the date C' +
              'ontributor first makes Commercial Use of the Covered Code.'#13#10'Notw' +
              'ithstanding Section 2.2 (b) above, no patent license is granted:' +
              ' 1) for any code that Contributor has deleted from the Contribut' +
              'or Version; 2) separate from the Contributor Version; 3) for inf' +
              'ringements caused by: i) third party modifications of Contributo' +
              'r Version or ii) the combination of Modifications made by that C' +
              'ontributor with other software (except as part of the Contributo' +
              'r Version) or other devices; or 4) under Patent Claims infringed' +
              ' by Covered Code in the absence of Modifications made by that Co' +
              'ntributor.'#13#10'3. Distribution Obligations.'#13#10'3.1. Application of Li' +
              'cense.'#13#10'The Modifications which You create or to which You contr' +
              'ibute are governed by the terms of this License, including witho' +
              'ut limitation Section 2.2. The Source Code version of Covered Co' +
              'de may be distributed only under the terms of this License or a ' +
              'future version of this License released under Section 6.1, and Y' +
              'ou must include a copy of this License with every copy of the So' +
              'urce Code You distribute. You may not offer or impose any terms ' +
              'on any Source Code version that alters or restricts the applicab' +
              'le version of this License or the recipients'#39' rights hereunder. ' +
              'However, You may include an additional document offering the add' +
              'itional rights described in Section 3.5.'#13#10#13#10'3.2. Availability of' +
              ' Source Code.'#13#10'Any Modification which You create or to which You' +
              ' contribute must be made available in Source Code form under the' +
              ' terms of this License either on the same media as an Executable' +
              ' version or via an accepted Electronic Distribution Mechanism to' +
              ' anyone to whom you made an Executable version available; and if' +
              ' made available via Electronic Distribution Mechanism, must rema' +
              'in available for at least twelve (12) months after the date it i' +
              'nitially became available, or at least six (6) months after a su' +
              'bsequent version of that particular Modification has been made a' +
              'vailable to such recipients. You are responsible for ensuring th' +
              'at the Source Code version remains available even if the Electro' +
              'nic Distribution Mechanism is maintained by a third party.'#13#10#13#10'3.' +
              '3. Description of Modifications.'#13#10'You must cause all Covered Cod' +
              'e to which You contribute to contain a file documenting the chan' +
              'ges You made to create that Covered Code and the date of any cha' +
              'nge. You must include a prominent statement that the Modificatio' +
              'n is derived, directly or indirectly, from Original Code provide' +
              'd by the Initial Developer and including the name of the Initial' +
              ' Developer in (a) the Source Code, and (b) in any notice in an E' +
              'xecutable version or related documentation in which You describe' +
              ' the origin or ownership of the Covered Code.'#13#10#13#10'3.4. Intellectu' +
              'al Property Matters'#13#10'(a) Third Party Claims'#13#10'If Contributor has ' +
              'knowledge that a license under a third party'#39's intellectual prop' +
              'erty rights is required to exercise the rights granted by such C' +
              'ontributor under Sections 2.1 or 2.2, Contributor must include a' +
              ' text file with the Source Code distribution titled "LEGAL" whic' +
              'h describes the claim and the party making the claim in sufficie' +
              'nt detail that a recipient will know whom to contact. If Contrib' +
              'utor obtains such knowledge after the Modification is made avail' +
              'able as described in Section 3.2, Contributor shall promptly mod' +
              'ify the LEGAL file in all copies Contributor makes available the' +
              'reafter and shall take other steps (such as notifying appropriat' +
              'e mailing lists or newsgroups) reasonably calculated to inform t' +
              'hose who received the Covered Code that new knowledge has been o' +
              'btained.'#13#10#13#10'(b) Contributor APIs'#13#10'If Contributor'#39's Modifications' +
              ' include an application programming interface and Contributor ha' +
              's knowledge of patent licenses which are reasonably necessary to' +
              ' implement that API, Contributor must also include this informat' +
              'ion in the LEGAL file.'#13#10#13#10'(c) Representations.'#13#10'Contributor repr' +
              'esents that, except as disclosed pursuant to Section 3.4 (a) abo' +
              've, Contributor believes that Contributor'#39's Modifications are Co' +
              'ntributor'#39's original creation(s) and/or Contributor has sufficie' +
              'nt rights to grant the rights conveyed by this License.'#13#10#13#10'3.5. ' +
              'Required Notices.'#13#10'You must duplicate the notice in Exhibit A in' +
              ' each file of the Source Code. If it is not possible to put such' +
              ' notice in a particular Source Code file due to its structure, t' +
              'hen You must include such notice in a location (such as a releva' +
              'nt directory) where a user would be likely to look for such a no' +
              'tice. If You created one or more Modification(s) You may add you' +
              'r name as a Contributor to the notice described in Exhibit A. Yo' +
              'u must also duplicate this License in any documentation for the ' +
              'Source Code where You describe recipients'#39' rights or ownership r' +
              'ights relating to Covered Code. You may choose to offer, and to ' +
              'charge a fee for, warranty, support, indemnity or liability obli' +
              'gations to one or more recipients of Covered Code. However, You ' +
              'may do so only on Your own behalf, and not on behalf of the Init' +
              'ial Developer or any Contributor. You must make it absolutely cl' +
              'ear than any such warranty, support, indemnity or liability obli' +
              'gation is offered by You alone, and You hereby agree to indemnif' +
              'y the Initial Devel'#13#10#13#10'3.6. Distribution of Executable Versions.' +
              #13#10'You may distribute Covered Code in Executable form only if the' +
              ' requirements of Sections 3.1, 3.2, 3.3, 3.4 and 3.5 have been m' +
              'et for that Covered Code, and if You include a notice stating th' +
              'at the Source Code version of the Covered Code is available unde' +
              'r the terms of this License, including a description of how and ' +
              'where You have fulfilled the obligations of Section 3.2. The not' +
              'ice must be conspicuously included in any notice in an Executabl' +
              'e version, related documentation or collateral in which You desc' +
              'ribe recipients'#39' rights relating to the Covered Code. You may di' +
              'stribute the Executable version of Covered Code or ownership rig' +
              'hts under a license of Your choice, which may contain terms diff' +
              'erent from this License, provided that You are in compliance wit' +
              'h the terms of this License and that the license for the Executa' +
              'ble version does not attempt to limit or alter the recipient'#39's r' +
              'ights in the Source Code version from the rights set forth in th' +
              'is License. If You distribute the Executable version under a dif' +
              'fe'#13#10#13#10'3.7. Larger Works.'#13#10'You may create a Larger Work by combin' +
              'ing Covered Code with other code not governed by the terms of th' +
              'is License and distribute the Larger Work as a single product. I' +
              'n such a case, You must make sure the requirements of this Licen' +
              'se are fulfilled for the Covered Code.'#13#10#13#10'4. Inability to Comply' +
              ' Due to Statute or Regulation.'#13#10'If it is impossible for You to c' +
              'omply with any of the terms of this License with respect to some' +
              ' or all of the Covered Code due to statute, judicial order, or r' +
              'egulation then You must: (a) comply with the terms of this Licen' +
              'se to the maximum extent possible; and (b) describe the limitati' +
              'ons and the code they affect. Such description must be included ' +
              'in the LEGAL file described in Section 3.4 and must be included ' +
              'with all distributions of the Source Code. Except to the extent ' +
              'prohibited by statute or regulation, such description must be su' +
              'fficiently detailed for a recipient of ordinary skill to be able' +
              ' to understand it.'#13#10#13#10'5. Application of this License.'#13#10'This Lice' +
              'nse applies to code to which the Initial Developer has attached ' +
              'the notice in Exhibit A and to related Covered Code.'#13#10#13#10'6. Versi' +
              'ons of the License.'#13#10'6.1. New Versions'#13#10'Netscape Communications ' +
              'Corporation ("Netscape") may publish revised and/or new versions' +
              ' of the License from time to time. Each version will be given a ' +
              'distinguishing version number.'#13#10#13#10'6.2. Effect of New Versions'#13#10'O' +
              'nce Covered Code has been published under a particular version o' +
              'f the License, You may always continue to use it under the terms' +
              ' of that version. You may also choose to use such Covered Code u' +
              'nder the terms of any subsequent version of the License publishe' +
              'd by Netscape. No one other than Netscape has the right to modif' +
              'y the terms applicable to Covered Code created under this Licens' +
              'e.'#13#10#13#10'6.3. Derivative Works'#13#10'If You create or use a modified ver' +
              'sion of this License (which you may only do in order to apply it' +
              ' to code which is not already Covered Code governed by this Lice' +
              'nse), You must (a) rename Your license so that the phrases "Mozi' +
              'lla", "MOZILLAPL", "MOZPL", "Netscape", "MPL", "NPL" or any conf' +
              'usingly similar phrase do not appear in your license (except to ' +
              'note that your license differs from this License) and (b) otherw' +
              'ise make it clear that Your version of the license contains term' +
              's which differ from the Mozilla Public License and Netscape Publ' +
              'ic License. (Filling in the name of the Initial Developer, Origi' +
              'nal Code or Contributor in the notice described in Exhibit A sha' +
              'll not of themselves be deemed to be modifications of this Licen' +
              'se.)'#13#10#13#10'7. DISCLAIMER OF WARRANTY'#13#10'COVERED CODE IS PROVIDED UNDE' +
              'R THIS LICENSE ON AN "AS IS" BASIS, WITHOUT WARRANTY OF ANY KIND' +
              ', EITHER EXPRESSED OR IMPLIED, INCLUDING, WITHOUT LIMITATION, WA' +
              'RRANTIES THAT THE COVERED CODE IS FREE OF DEFECTS, MERCHANTABLE,' +
              ' FIT FOR A PARTICULAR PURPOSE OR NON-INFRINGING. THE ENTIRE RISK' +
              ' AS TO THE QUALITY AND PERFORMANCE OF THE COVERED CODE IS WITH Y' +
              'OU. SHOULD ANY COVERED CODE PROVE DEFECTIVE IN ANY RESPECT, YOU ' +
              '(NOT THE INITIAL DEVELOPER OR ANY OTHER CONTRIBUTOR) ASSUME THE ' +
              'COST OF ANY NECESSARY SERVICING, REPAIR OR CORRECTION. THIS DISC' +
              'LAIMER OF WARRANTY CONSTITUTES AN ESSENTIAL PART OF THIS LICENSE' +
              '. NO USE OF ANY COVERED CODE IS AUTHORIZED HEREUNDER EXCEPT UNDE' +
              'R THIS DISCLAIMER.'#13#10#13#10'8. Termination'#13#10'8.1. This License and the ' +
              'rights granted hereunder will terminate automatically if You fai' +
              'l to comply with terms herein and fail to cure such breach withi' +
              'n 30 days of becoming aware of the breach. All sublicenses to th' +
              'e Covered Code which are properly granted shall survive any term' +
              'ination of this License. Provisions which, by their nature, must' +
              ' remain in effect beyond the termination of this License shall s' +
              'urvive.'#13#10#13#10'8.2. If You initiate litigation by asserting a patent' +
              ' infringement claim (excluding declatory judgment actions) again' +
              'st Initial Developer or a Contributor (the Initial Developer or ' +
              'Contributor against whom You file such action is referred to as ' +
              '"Participant") alleging that:'#13#10#13#10'such Participant'#39's Contributor ' +
              'Version directly or indirectly infringes any patent, then any an' +
              'd all rights granted by such Participant to You under Sections 2' +
              '.1 and/or 2.2 of this License shall, upon 60 days notice from Pa' +
              'rticipant terminate prospectively, unless if within 60 days afte' +
              'r receipt of notice You either: (i) agree in writing to pay Part' +
              'icipant a mutually agreeable reasonable royalty for Your past an' +
              'd future use of Modifications made by such Participant, or (ii) ' +
              'withdraw Your litigation claim with respect to the Contributor V' +
              'ersion against such Participant. If within 60 days of notice, a ' +
              'reasonable royalty and payment arrangement are not mutually agre' +
              'ed upon in writing by the parties or the litigation claim is not' +
              ' withdrawn, the rights granted by Participant to You under Secti' +
              'ons 2.1 and/or 2.2 automatically terminate at the expiration of ' +
              'the 60 day notice period specified above.'#13#10'any software, hardwar' +
              'e, or device, other than such Participant'#39's Contributor Version,' +
              ' directly or indirectly infringes any patent, then any rights gr' +
              'anted to You by such Participant under Sections 2.1(b) and 2.2(b' +
              ') are revoked effective as of the date You first made, used, sol' +
              'd, distributed, or had made, Modifications made by that Particip' +
              'ant.'#13#10'8.3. If You assert a patent infringement claim against Par' +
              'ticipant alleging that such Participant'#39's Contributor Version di' +
              'rectly or indirectly infringes any patent where such claim is re' +
              'solved (such as by license or settlement) prior to the initiatio' +
              'n of patent infringement litigation, then the reasonable value o' +
              'f the licenses granted by such Participant under Sections 2.1 or' +
              ' 2.2 shall be taken into account in determining the amount or va' +
              'lue of any payment or license.'#13#10#13#10'8.4. In the event of terminati' +
              'on under Sections 8.1 or 8.2 above, all end user license agreeme' +
              'nts (excluding distributors and resellers) which have been valid' +
              'ly granted by You or any distributor hereunder prior to terminat' +
              'ion shall survive termination.'#13#10#13#10'9. LIMITATION OF LIABILITY'#13#10'UN' +
              'DER NO CIRCUMSTANCES AND UNDER NO LEGAL THEORY, WHETHER TORT (IN' +
              'CLUDING NEGLIGENCE), CONTRACT, OR OTHERWISE, SHALL YOU, THE INIT' +
              'IAL DEVELOPER, ANY OTHER CONTRIBUTOR, OR ANY DISTRIBUTOR OF COVE' +
              'RED CODE, OR ANY SUPPLIER OF ANY OF SUCH PARTIES, BE LIABLE TO A' +
              'NY PERSON FOR ANY INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIA' +
              'L DAMAGES OF ANY CHARACTER INCLUDING, WITHOUT LIMITATION, DAMAGE' +
              'S FOR LOSS OF GOODWILL, WORK STOPPAGE, COMPUTER FAILURE OR MALFU' +
              'NCTION, OR ANY AND ALL OTHER COMMERCIAL DAMAGES OR LOSSES, EVEN ' +
              'IF SUCH PARTY SHALL HAVE BEEN INFORMED OF THE POSSIBILITY OF SUC' +
              'H DAMAGES. THIS LIMITATION OF LIABILITY SHALL NOT APPLY TO LIABI' +
              'LITY FOR DEATH OR PERSONAL INJURY RESULTING FROM SUCH PARTY'#39'S NE' +
              'GLIGENCE TO THE EXTENT APPLICABLE LAW PROHIBITS SUCH LIMITATION.' +
              ' SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR LIMITATION OF ' +
              'INCIDENTAL OR CONSEQUENTIAL DAMAGES, SO THIS EXCLUSION AND LIMIT' +
              'ATION MAY NOT APPLY TO YOU.'#13#10#13#10'10. U.S. government end users'#13#10'Th' +
              'e Covered Code is a "commercial item," as that term is defined i' +
              'n 48 C.F.R. 2.101 (Oct. 1995), consisting of "commercial compute' +
              'r software" and "commercial computer software documentation," as' +
              ' such terms are used in 48 C.F.R. 12.212 (Sept. 1995). Consisten' +
              't with 48 C.F.R. 12.212 and 48 C.F.R. 227.7202-1 through 227.720' +
              '2-4 (June 1995), all U.S. Government End Users acquire Covered C' +
              'ode with only those rights set forth herein.'#13#10#13#10'11. Miscellaneou' +
              's'#13#10'This License represents the complete agreement concerning sub' +
              'ject matter hereof. If any provision of this License is held to ' +
              'be unenforceable, such provision shall be reformed only to the e' +
              'xtent necessary to make it enforceable. This License shall be go' +
              'verned by California law provisions (except to the extent applic' +
              'able law, if any, provides otherwise), excluding its conflict-of' +
              '-law provisions. With respect to disputes in which at least one ' +
              'party is a citizen of, or an entity chartered or registered to d' +
              'o business in the United States of America, any litigation relat' +
              'ing to this License shall be subject to the jurisdiction of the ' +
              'Federal Courts of the Northern District of California, with venu' +
              'e lying in Santa Clara County, California, with the losing party' +
              ' responsible for costs, including without limitation, court cost' +
              's and reasonable attorneys'#39' fees and expenses. The application o' +
              'f the United Nations Convention on Contracts for the Internation' +
              'al Sale of Goods is expressly excluded. Any law or regulation wh' +
              'ich'#13#10#13#10'12. Responsibility for claims'#13#10'As between Initial Develop' +
              'er and the Contributors, each party is responsible for claims an' +
              'd damages arising, directly or indirectly, out of its utilizatio' +
              'n of rights under this License and You agree to work with Initia' +
              'l Developer and Contributors to distribute such responsibility o' +
              'n an equitable basis. Nothing herein is intended or shall be dee' +
              'med to constitute any admission of liability.'#13#10#13#10'13. Multiple-li' +
              'censed code'#13#10'Initial Developer may designate portions of the Cov' +
              'ered Code as "Multiple-Licensed". "Multiple-Licensed" means that' +
              ' the Initial Developer permits you to utilize portions of the Co' +
              'vered Code under Your choice of the MPL or the alternative licen' +
              'ses, if any, specified by the Initial Developer in the file desc' +
              'ribed in Exhibit A.'#13#10#13#10'Exhibit A - Mozilla Public License.'#13#10'"The' +
              ' contents of this file are subject to the Mozilla Public License' +
              #13#10'Version 1.1 (the "License"); you may not use this file except ' +
              'in'#13#10'compliance with the License. You may obtain a copy of the Li' +
              'cense at'#13#10'https://www.mozilla.org/MPL/'#13#10#13#10'Software distributed u' +
              'nder the License is distributed on an "AS IS"'#13#10'basis, WITHOUT WA' +
              'RRANTY OF ANY KIND, either express or implied. See the'#13#10'License ' +
              'for the specific language governing rights and limitations'#13#10'unde' +
              'r the License.'#13#10#13#10'The Original Code is _________________________' +
              '_____________.'#13#10#13#10'The Initial Developer of the Original Code is ' +
              '________________________.'#13#10'Portions created by _________________' +
              '_____ are Copyright (C) ______'#13#10'_______________________. All Rig' +
              'hts Reserved.'#13#10#13#10'Contributor(s): _______________________________' +
              '_______.'#13#10#13#10'Alternatively, the contents of this file may be used' +
              ' under the terms'#13#10'of the _____ license (the  "[___] License"), i' +
              'n which case the'#13#10'provisions of [______] License are applicable ' +
              'instead of those'#13#10'above. If you wish to allow use of your versio' +
              'n of this file only'#13#10'under the terms of the [____] License and n' +
              'ot to allow others to use'#13#10'your version of this file under the M' +
              'PL, indicate your decision by'#13#10'deleting the provisions above and' +
              ' replace them with the notice and'#13#10'other provisions required by ' +
              'the [___] License. If you do not delete'#13#10'the provisions above, a' +
              ' recipient may use your version of this file'#13#10'under either the M' +
              'PL or the [___] License."'#13#10
            SkinData.SkinSection = 'TRANSPARENCY'
          end
        end
        object sGroupBox1: TsGroupBox
          Left = 16
          Top = 201
          Width = 1066
          Height = 86
          Align = alBottom
          Caption = 'Specifications'
          TabOrder = 1
          object sWebLabel2: TsLabel
            Left = 47
            Top = 20
            Width = 144
            Height = 52
            Alignment = taRightJustify
            Caption = 
              'Stable Version:'#13#10#13#10'Compatible Windows versions:'#13#10'Supported platf' +
              'orms:'
            Layout = tlCenter
          end
          object sLabel1: TsLabel
            Left = 197
            Top = 20
            Width = 132
            Height = 52
            Caption = 
              'Full Version - Registered'#13#10#13#10'Windows XP .. Windows 11'#13#10'Win32 and' +
              ' Win64'
            Layout = tlCenter
          end
        end
      end
      object sPanel9: TsPanel
        Tag = 4
        Left = 0
        Top = 0
        Width = 1098
        Height = 220
        Align = alTop
        BevelOuter = bvNone
        BorderWidth = 16
        DoubleBuffered = False
        TabOrder = 1
        object pnlAboutTop: TsPanel
          Left = 201
          Top = 16
          Width = 352
          Height = 188
          Align = alLeft
          BevelOuter = bvNone
          DoubleBuffered = False
          TabOrder = 0
          object sLabel33: TsLabel
            Left = 0
            Top = 47
            Width = 352
            Height = 24
            Align = alTop
            Alignment = taCenter
            AutoSize = False
            Caption = 'FastFile - Huge text file processor'
            Layout = tlBottom
            WordWrap = True
          end
          object sLabelFX1: TsLabelFX
            Left = 0
            Top = 0
            Width = 352
            Height = 47
            Align = alTop
            Alignment = taCenter
            AutoSize = False
            Caption = 'FastFile'
            ParentFont = False
            Layout = tlCenter
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -19
            Font.Name = 'Tahoma'
            Font.Style = [fsBold]
            Angle = 0
            Shadow.OffsetKeeper.LeftTop = -3
            Shadow.OffsetKeeper.RightBottom = 5
            Shadow.AlphaValue = 100
          end
          object sLabel32: TsLabel
            Left = 0
            Top = 71
            Width = 352
            Height = 34
            Align = alTop
            Alignment = taCenter
            AutoSize = False
            Caption = 'Copyright (c) 2024, Hamden Vogel.'#13#10'All rights reserved.'
            WordWrap = True
          end
          object sWebLabel1: TsWebLabel
            Left = 0
            Top = 105
            Width = 352
            Height = 19
            Align = alTop
            Alignment = taCenter
            AutoSize = False
            Caption = 'http://hvogel.com.br/'
            ParentFont = False
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clOlive
            Font.Height = -12
            Font.Name = 'Tahoma'
            Font.Style = [fsBold]
            HoverFont.Charset = DEFAULT_CHARSET
            HoverFont.Color = clBlue
            HoverFont.Height = -12
            HoverFont.Name = 'Tahoma'
            HoverFont.Style = [fsBold]
            URL = 'http://hvogel.com.br/'
          end
        end
        object pnlLogo: TsPanel
          Left = 16
          Top = 16
          Width = 185
          Height = 188
          Align = alLeft
          BevelOuter = bvNone
          DoubleBuffered = False
          TabOrder = 1
          object sImage2: TsImage
            Left = 34
            Top = 0
            Width = 145
            Height = 188
            Align = alLeft
            Picture.Data = {
              0B54504E47477261706869637A250100424D7A25010000000000360000002800
              0000890000008900000001002000000000004425010000000000000000000000
              000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00000000011C13131B1E11113B1E1212551E10
              106D201212801E12128F201111991F1111A7201111AA201111AA201111AA1F11
              11A2201111991F11118A1F11117B1F1212641E11114D2010103020101010FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002010
              101021121246201111781F1111A71F1111D01F1111F71F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111EC1F1111C31E111198201111681D0F0F3433000005FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002211110F1F1010521F1111961F11
              11D41F1111FE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F61F11
              11C01E10107F1E11113B00000004FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001B12121C1E10106E1F1111BE1F1111FB1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FB1F1111E4201010CA1F1111B61F1111A6201111991F10108E2011
              118820111188201111881F1111941F10109B1F1010AB1F1111BE1F1111D31F11
              11EB1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111EE1F1111A51E1212541A1A1A0AFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF002412120E1F1212641E1111C11F1111FD1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111F91F1212CB1F11119A1E10106D1E13
              13442010102000000004FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001A1A1A0A1D11112C1F1010511F11117B201111A91F1111DB1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11F31F1111A31E12124500000002FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F10
              10311F10109B1F1111F41F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111F7201010BA201111781F12123A24000007FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001A0D0D141E11114D1F10108D1F1111D01F1111FE1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111DF20111179240C0C15FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000011E11114D1E11
              11C11F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111EB1F10
              109B1E11114C1A1A1A0AFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D14141A1E1212661F11
              11B71F1111FA1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F71F10
              109B21141427FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000011E121255201111D21F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F71F1111A71F1111490000
              0004FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00202020081E0F0F1100000002FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001B0D0D13201111681F1111C61F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FD201111AA1D11112CFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212471F1111CE1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111DB201212711C0E0E12FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E0F0F112010103F1E1212661E1111871E1111A81F11
              11C41F1111D71F1111EA1F1111FD1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111F71F1111E41F1111D11F1010BB1F10109D1F10107C201111592110
              102F2B000006FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D11112C1F1111941F11
              11F21F1111FF1F1111FF1F1111FF1F1111FF1F1111FD1F1111A51F0F0F21FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1313291E1111B81F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111C51D10104E00000002FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000042012
              12381F1212721F1212AE1E1111E21F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FA201111D2201111991E10105E1F0F0F21FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF002211110F1F1111751F1111E51F1111FF1F1111FF1F1111FF1F1111FF1F11
              11F8201111892714140DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001717170B1F11118A1F1111FA1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111C020101040FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002010101020101060201111AA1F11
              11EF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F10
              10D9201212911E13134400000003FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00240000071F11116A1F1111E41F1111FF1F11
              11FF1F1111FF1F1111FF1F1111E51E121255FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E0F0F431F1111DE1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111D020121247FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00330000051D10104E1F1010AB1F1111F71F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111E51F11118B1C11112DFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001C1C1C091E11
              11761F1111EF1F1111FF1F1111FF1F1111FF1F1111FF201111B21D14141AFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001C1C1C091F1111941F1111FE1F1111FF1F1111FF1F1111FF1F11
              11EB1E12126600000003FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF002110102F1F1111921F1111EB1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11D01F1212721C0E0E12FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001A0D0D141E1111981F1111FD1F1111FF1F1111FF1F1111FF1F11
              11EE20111159FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001C11112D1F1111D51F1111FF1F1111FF1F1111FF1F1111FE1F12
              129E1B0D0D13FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1212391F1111B41F1111FE1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111F22011118921161617FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D1313351F1111CF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111A21515150CFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00201010611F1111F61F1111FF1F1111FF1F1111FF1F1111E01E0F
              0F43FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F0F
              0F421F1212BD1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111EE1F1212CC1F1212AE1F11
              119A2012129120111188201111781E11117720111179201111881F1111962011
              11A11F1010AC201010CA1F1111EF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F61F1111922312
              121DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00330000051F11
              117B1F1111F91F1111FF1F1111FF1F1111FF1F1111D71E12122AFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00330000051F1111961F1111FF1F1111FF1F1111FF1F1111FF1F1111A22412
              120EFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F0F0F321F11
              11C31F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FB1F1111CF1F1111962010105F1E0F0F331E0F0F11FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00230C0C161E11113B201010612012
              12911F1111D11F1111FD1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111F91F11119220101010FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00201010301F1111D51F1111FF1F1111FF1F1111FF1F1111F31F10
              1052FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001E0F0F111F1111BE1F1111FF1F1111FF1F1111FF1F1111F41E10105EFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002211110F1F1111931F11
              11FC1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111D61F10108E1F11
              116A1F11115A1F1212641F11117B201111881F10108D201111991F11118B1E10
              107E1F1212721E1212661D10104E1F1313292B000006FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001B0D0D1320101050201212901E1212DA1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1010E81E10105D00000001FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001A1A1A0A1F10109D1F1111FF1F1111FF1F11
              11FF1F1111FE1F10107CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF002110101F1F1111D61F1111FF1F1111FF1F1111FF1E1212DA1D11112CFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000011E11115C1F1111E71F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111ED1F1212CC1F1111D31F11
              11F91F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FC1F1111DB1F11
              11B3201111792013133700000004FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D13
              13351F10108E1F1111E51F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111C01E12
              122BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212621F11
              11F71F1111FF1F1111FF1F1111FF1F10109D00000004FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001E12122B1F1111E41F1111FF1F1111FF1F1111FF1E1111B91E0F0F11FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001C13131B1F1212BD1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111F1201111B21F12126420101010FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00000000031E0F0F431F1212AD1F1111FD1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FA2012128100000003FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00201212381F1111E71F1111FF1F1111FF1F1111FF201111B21C1C1C09FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F0F0F321F1111EC1F1111FF1F1111FF1F1111FF2011119900000004FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212471F1111EA1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1212E91F1111C81F1010BB1F1010AB1E12
              129F201111991F11119A201111AA1F1111B71F1111C41F1111DF1F1111FD1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11F7201111AA1D10104E33000005FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00221414261F11
              119A1F1111F81F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111BF1F141419FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF002211111E1F1111D41F1111FF1F1111FF1F1111FF1F11
              11BE1717170BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001E0F0F331F1111EE1F1111FF1F1111FF1F1111FF1E10107EFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00000000041F1111851F1111FD1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11D81F1111962010105F201313371E0F0F11FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001C1C
              1C092110102F1E1212551E1111861E1010C91F1111FC1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1E1111E21E10106D1C1C1C09FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1414191F10108C1F1111F81F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1212E91E121245FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E0F0F111F1111C31F1111FF1F11
              11FF1F1111FF1E1111C11717170BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF002111112E1F1111ED1F1111FF1F1111FF1F1111FE1E10106DFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001D14141A201111C21F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F91F1111AF1E10105E1C13
              131BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002211110F1D10104E1F11
              119A1F1111EF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1010E81E11
              11771515150CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001C0E0E24201111B11F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FD1F12128300000002FFFFFF00FFFFFF00FFFFFF00FFFFFF001A1A1A0A1E11
              11B81F1111FF1F1111FF1F1111FF1F1111BE1C1C1C09FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001C0E0E241F1111E71F1111FF1F1111FF1F1111FE1E121266FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1313291F1111E11F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111C81F11116B1B0D0D13FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00202020081E121255201111B21F1111FB1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111E420111158FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002112
              12461F1111D61F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF201111AA24000007FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00240000071F1111B31F1111FF1F1111FF1F1111FF201111B200000004FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00230C0C161F1111DC1F1111FF1F1111FF1F1111FE1F11116BFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201313371F1111EC1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111B61E11113BFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E0F0F22201111991F11
              11F91F1111FF1F1111FF1F1111FF1F1111FF1F1212BD1F131329FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00330000051F1111841F1111FC1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111BE2412120EFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00240000071E1111B81F1111FF1F1111FF1F1111FF1F10
              109DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001C1C1C091F1111C81F1111FF1F1111FF1F1111FF20111178FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1111491F1111F41F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF201111B11F0F0F32FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001B12121C1F1111921F1111FA1F1111FF1F1111FF1F1111FF1F1111F91F12
              127300000001FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002110103E1F1111E11F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111CE2015
              1518FFFFFF00FFFFFF00FFFFFF00FFFFFF001A1A1A0A1F1111C31F1111FF1F11
              11FF1F1111FF1F11117BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1111A51F1111FF1F1111FF1F1111FF20121290FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F11115B1F1111FA1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111DC1F111149FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001E12122A1F1111BF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111B31B0D0D13FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E0F0F112011
              11AA1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111DD1E0F0F22FFFFFF00FFFFFF00FFFFFF00FFFFFF00201010101F11
              11D31F1111FF1F1111FF1F1111FE1F101052FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1212731F1111FF1F1111FF1F1111FF1F1111AF00000002FFFF
              FF00FFFFFF00FFFFFF00FFFFFF002010104F1F1111FC1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11F92012128020202008FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000011E11115C1F12
              12E91F1111FF1F1111FF1F1111FF1E1111E21F121239FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1212741F1111FD1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111DD20151518FFFFFF00FFFFFF00FFFFFF00FFFF
              FF002110101F1F1111E71F1111FF1F1111FF1F1111F31E12122BFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001D11113D1F1111FB1F1111FF1F1111FF1F1111CF1717170BFFFF
              FF00FFFFFF00FFFFFF00FFFFFF001D11113D1F1111F61F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11DD1D0F0F34FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1313291E1212561E10107E1F1111A71F1111C41F1111D01F11
              11DD1F1111ED1F1111E01F1111D41F1111C71F1111AF1E111187201010601D0F
              0F3400000004FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1414191F1111BE1F1111FF1F1111FF1F1111FF1F1111F620101050FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1212531F1111F61F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111CE2412120EFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00201212381F1111F81F1111FF1F1111FF1F1111D71515
              150CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001B0D0D131F1111E31F1111FF1F1111FF1F1111ED20101020FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001C11112D1F1111EF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F10
              10AC2211110FFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002412120E1E10
              105D1F1111A21F1111E61F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111F01E1111B01F11116C1D14141AFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF0000000003201212801F1111FD1F1111FF1F1111FF1F11
              11FC20111167FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212381F1212E91F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111BE2400
              0007FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212621F1111FF1F1111FF1F11
              11FF201111A1FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1212AD1F1111FF1F1111FF1F1111FE1F111149FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201010201F1111E51F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FE2011
              1178FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000001211212461F1111A41F11
              11F51F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FC1F1111B62011
              11582B000006FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212481F1111F31F11
              11FF1F1111FF1F1111FF1F10107DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E0F
              0F221E1111E21F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF201111AA00000002FFFFFF00FFFFFF00FFFFFF00FFFFFF001F12129E1F11
              11FF1F1111FF1F1111FF20111158FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E10105E1F1111FF1F1111FF1F1111FF1F11118BFFFF
              FF00FFFFFF00FFFFFF00FFFFFF001C1C1C091F1111D11F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FB2010
              1060FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00000000021E1212551F1111D11F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111E12011116924000007FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D13
              13351F1111EA1F1111FF1F1111FF1F1111FF20101070FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00221414261F1111E71F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F121283FFFFFF00FFFFFF00FFFFFF00FFFFFF001A1A
              1A0A1F1111D51F1111FF1F1111FF1F1111EE1D14141AFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00201515181F1111EE1F1111FF1F1111FF1F1111CE2B00
              0006FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11119A1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F51E11
              114CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00211212461F1111D51F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111E31E11115CFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00221414261F1111DF1F1111FF1F1111FF1F1111FE1F11115BFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001D11112C1F1111EC1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FD1E121245FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00201010301F1111F91F1111FF1F1111FF201111B2FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201111A91F1111FF1F1111FF1F1111F91C11
              112DFFFFFF00FFFFFF00FFFFFF00FFFFFF001F11115A1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FA2012
              1248FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001D14141A1E1111A81F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F12
              12BD22141426FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201010201F1111E51F1111FF1F1111FF1F11
              11FA20121248FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E0F0F331F1111F01F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1010E81F141419FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F11117B1F1111FF1F1111FF1F1111FF1E12
              1256FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201212471F1111FF1F1111FF1F1111FF1E10
              107EFFFFFF00FFFFFF00FFFFFF00FFFFFF00221414261F1111F21F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FE1E11
              115CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1212531F1111F01F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111F720111168FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002111112E1F1111EF1F11
              11FF1F1111FF1F1111EF1E0F0F22FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002012
              12481F1111FC1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11BE00000003FFFFFF00FFFFFF00FFFFFF00000000041F1111CF1F1111FF1F11
              11FF1F1111E42714140DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00330000051F1111D81F1111FF1F1111FF1F11
              11D72B000006FFFFFF00FFFFFF00FFFFFF00240000071F1111D01F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F12
              1272FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00240000071F1111931F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111A41515150CFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002110
              103E1F1111F71F1111FF1F1111FF1F1212CC24000007FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00201111791F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF20121280FFFFFF00FFFFFF00FFFFFF00FFFFFF001D1313351F11
              11FD1F1111FF1F1111FF20111188FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10106E1F1111FF1F1111FF1F11
              11FF1E0F0F43FFFFFF00FFFFFF00FFFFFF00FFFFFF001F10107D1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E12
              129FFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001E0F0F111F1111C41F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111D02015
              1518FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1212641F1111FF1F1111FF1F1111FF1F111194FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00000000011F1010AC1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FA1E12122AFFFFFF00FFFFFF00FFFFFF00FFFF
              FF001E1111981F1111FF1F1111FF1F1111F720101020FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002412120E1F1111EB1F1111FF1F11
              11FF1F1111AFFFFFFF00FFFFFF00FFFFFF00FFFFFF001E0F0F221F1111F61F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11D51717170BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001C13131B1F1111D31F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111DC1E0F0F22FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1111A41F1111FF1F1111FF1F1111FF1D10
              104EFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001515150C1F1111D41F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111BF00000001FFFFFF00FFFF
              FF00FFFFFF001A0D0D141F1111EF1F1111FF1F1111FF1F1111A3FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10107F1F1111FF1F11
              11FF1F1111FA1C0E0E25FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111B41F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11F51E12122BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF002211111E1F1111E01F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111E61D0F0F23FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001515150C1F1111D81F1111FF1F11
              11FF1F1111E11717170BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1010311F11
              11FA1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E11115CFFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1111751F1111FF1F1111FF1F1111FD1D11
              112CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002211110F1F1111EF1F11
              11FF1F1111FF1E111197FFFFFF00FFFFFF00FFFFFF00FFFFFF00201010501F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F11116CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001A0D0D141F1111D61F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111DB230C0C16FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E0F0F331F11
              11FC1F1111FF1F1111FF20111188FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1111841F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11E72211110FFFFFFF00FFFFFF00FFFFFF001C1C1C091F1111E41F1111FF1F11
              11FF201111AAFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11117A1F11
              11FF1F1111FF1F1111F81B12121CFFFFFF00FFFFFF00FFFFFF001A1A1A0A1F11
              11E11F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111CD00000003FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001717170B1F1111C81F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF201010CA1717
              170BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1111931F1111FF1F1111FF1F1111FA1E12122AFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00240000071F1111D51F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF20121291FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11116A1F11
              11FF1F1111FF1F1111FD20131328FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00202020081F10
              10E81F1111FF1F1111FF1E111198FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10
              106F1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FD21131336FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00201111A11F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1E12129FFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00201010101F1010E81F1111FF1F1111FF1F1111B3FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201212381F1111FC1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111F81B12121CFFFFFF00FFFFFF00FFFFFF002400
              00071F1111E51F1111FF1F1111FF1F10109BFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002010
              10611F1111FF1F1111FF1F1111FC1D0F0F23FFFFFF00FFFFFF00FFFFFF002B00
              00061F1111E31F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F11119AFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1212621F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1E10105DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001E10105E1F1111FF1F1111FF1F1111FE1F10
              1031FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F10109B1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF20121291FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001E1111761F1111FF1F1111FF1F1111F7240C0C15FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1111CE1F1111FF1F1111FF1F1212ADFFFFFF00FFFFFF00FFFFFF00FFFF
              FF001E1212651F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111F92312121DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00201313281F1111F51F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111F31E0F0F22FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000021F1111D71F1111FF1F11
              11FF1F1010ACFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001B12121C1F11
              11F61F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F521161617FFFF
              FF00FFFFFF00FFFFFF002211110F1F1111F31F1111FF1F1111FF20111179FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00201313371F1111FF1F1111FF1F1111FF2010103FFFFFFF00FFFFFF00FFFF
              FF00000000041F1111DC1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F10109BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00000000011F1111BE1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111B3FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10105E1F11
              11FF1F1111FF1F1111FD1E12122BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F11118B1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF2011
              1188FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111941F1111FF1F1111FF1F11
              11DE00000002FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F11119A1F1111FF1F1111FF1F1111D5FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F11115B1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FB1D0F0F23FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001E11115C1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E11
              114DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
              00041F1111DD1F1111FF1F1111FF1E111198FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001B0D0D131F1111F01F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111F21C0E0E12FFFFFF00FFFFFF00FFFFFF001D11112C1F1111FF1F11
              11FF1F1111FF1E121245FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00202020081F1111F01F1111FF1F1111FF1F121272FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1111C81F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF201111A9FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001A1A1A0A1F1111E71F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111DC00000004FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F11116C1F1111FF1F1111FF1F1111EE24000007FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001E10107F1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F121272FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11
              11C81F1111FF1F1111FF1F1111A2FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1212531F1111FF1F1111FF1F1111FB21161617FFFF
              FF00FFFFFF00FFFFFF00211414271F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F111149FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212711F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1E10105DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001C0E0E121F1111F91F1111FF1F1111FF1E121254FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00211616171F1111F91F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111CFFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00201111681F1111FF1F1111FF1F1111F31A1A1A0AFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201111A91F1111FF1F1111FF1E1111B8FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1111841F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111E700000004FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00202020081F1111E51F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111D600000002FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F1111FF1F1111FF2011
              11B1FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111A61F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1D11112CFFFFFF00FFFF
              FF00FFFFFF001B0D0D131F1111FA1F1111FF1F1111FF1F121253FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00240000071F1111F21F1111FF1F1111FF1F12
              1263FFFFFF00FFFFFF00FFFFFF00000000021F1111E01F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F10108DFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E1212651F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E11114DFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1010511F1111FF1F11
              11FF1F1111FA2714140DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002110
              103E1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF20111189FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1111B71F1111FF1F1111FF1F1111A5FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212481F1111FF1F1111FF1F11
              11FC240C0C15FFFFFF00FFFFFF00FFFFFF001F1010411F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF20131337FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111C61F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1010ACFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00240000071F11
              11F31F1111FF1F1111FF1F11114BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1111D31F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11E400000003FFFFFF00FFFFFF00FFFFFF001E1212661F1111FF1F1111FF1F11
              11ED00000004FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212901F1111FF1F11
              11FF1F1111C3FFFFFF00FFFFFF00FFFFFF00FFFFFF001F10109D1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F00000
              0003FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00221414261F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11F81E0F0F11FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1111B71F1111FF1F1111FF1F10108DFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00201010701F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1E0F0F43FFFFFF00FFFFFF00FFFFFF001C13131B1F1111FE1F11
              11FF1F1111FF1E11113BFFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111D31F11
              11FF1F1111FF1F10107CFFFFFF00FFFFFF00FFFFFF00000000011F1010E81F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF2011
              11B1FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F12
              12821F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F121263FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1111751F1111FF1F1111FF1F1111CFFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F0F0F211F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1E12128FFFFFFF00FFFFFF00FFFFFF00FFFFFF001F11
              11D11F1111FF1F1111FF20121280FFFFFF00FFFFFF00FFFFFF00230C0C161F11
              11FE1F1111FF1F1111FF1F121239FFFFFF00FFFFFF00FFFFFF001E0F0F331F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1E10106FFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001E1010C91F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF201111AAFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E0F0F331F1111FF1F1111FF1F1111FD1C0E0E12FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201111D21F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111D8FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F10108E1F1111FF1F1111FF1F1111C0FFFFFF00FFFFFF00FFFFFF001F10
              10511F1111FF1F1111FF1F1111F333000005FFFFFF00FFFFFF00FFFFFF002011
              11791F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1E0F0F33FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00201010101F1111FC1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111EA00000001FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00000000021F1111F31F1111FF1F1111FF1E11
              113CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111841F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF20101020FFFFFF00FFFF
              FF00FFFFFF001D10104E1F1111FF1F1111FF1F1111F633000005FFFFFF00FFFF
              FF00201111891F1111FF1F1111FF1F1212BDFFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1111B61F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FE1515150CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF002010104F1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF2111112EFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111CD1F1111FF1F11
              11FF1F121263FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002113
              13361F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E10105DFFFF
              FF00FFFFFF00FFFFFF001A0D0D141F1111FE1F1111FF1F1111FF1D0F0F34FFFF
              FF00FFFFFF001F1212BD1F1111FF1F1111FF1E111187FFFFFF00FFFFFF00FFFF
              FF00000000021F1111EE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111E3FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1212821F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF2010105FFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111A61F11
              11FF1F1111FF1F11118BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00000000011F1111EC1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E11
              1198FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111DC1F1111FF1F1111FF2011
              1168FFFFFF00FFFFFF001F1111EC1F1111FF1F1111FF1E121254FFFFFF00FFFF
              FF00FFFFFF001F1313291F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1212BCFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201111AA1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E11
              1186FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10
              107F1F1111FF1F1111FF201111B2FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E1111B91F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111D1FFFFFF00FFFFFF00FFFFFF00FFFFFF00201111AA1F1111FF1F11
              11FF1E111198FFFFFF001D14141A1F1111FF1F1111FF1F1111FF22141426FFFF
              FF00FFFFFF00FFFFFF00201111591F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111EE1F1111FF1F1111FF1E111198FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201111D21F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1212ADFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F11115B1F1111FF1F1111FF1F1111CFFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001E1111861F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111F92B000006FFFFFF00FFFFFF00FFFFFF001F10107C1F11
              11FF1F1111FF1F1111C4FFFFFF001F0F0F421F1111FF1F1111FF1F1111F80000
              0003FFFFFF00FFFFFF00FFFFFF001E1111871F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111F81F1111CE1F1111FF1F1111FF20111188FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111F31F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111CEFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F11114B1F1111FF1F1111FF1F1111DDFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1010521F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF2111112EFFFFFF00FFFFFF00FFFFFF001F10
              10511F1111FF1F1111FF1F1111ECFFFFFF001E1212651F1111FF1F1111FF1F11
              11D5FFFFFF00FFFFFF00FFFFFF00FFFFFF00201111B21F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111D4201010CA1F1111FF1F1111FF1F11117BFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000031F1111FE1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111DDFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001D11113D1F1111FF1F1111FF1F1111EAFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002110101F1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF20111159FFFFFF00FFFFFF00FFFF
              FF001D11112C1F1111FF1F1111FF1F1111FF201010101E1111861F1111FF1F11
              11FF1F1111B4FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111D41F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1010AC201010CA1F1111FF1F1111FF1E10
              106EFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002211110F1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111EAFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201010301F1111FF1F1111FF1F1111F7FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11
              11EE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11117BFFFFFF00FFFF
              FF00FFFFFF001717170B1F1111FF1F1111FF1F1111FF1F101031201111A11F11
              11FF1F1111FF1F111196FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111F41F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F111185201010CA1F1111FF1F11
              11FF1F121262FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001C13
              131B1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F7FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D0F0F231F1111FF1F1111FF1F11
              11FF33000005FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1111D11F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F10109CFFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1111EC1F1111FF1F1111FF1E11114D1E11
              11B91F1111FF1F1111FF1F10107DFFFFFF00FFFFFF00FFFFFF001B0D0D131F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E10105D201111C21F11
              11FF1F1111FF1E121266FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00211616171F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FBFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D0F0F231F1111FF1F11
              11FF1F1111FF1A1A1A0AFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1111B61F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F10
              10BBFFFFFF00FFFFFF00FFFFFF00FFFFFF00201111D21F1111FF1F1111FF1E12
              12651F1111CE1F1111FF1F1111FF20111167FFFFFF00FFFFFF00FFFFFF002013
              13281F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E0F0F431F11
              11B51F1111FF1F1111FF1F121273FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001717170B1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FBFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E12122B1F11
              11FF1F1111FF1F1111FF1A1A1A0AFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F10109C1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111CFFFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212BC1F1111FF1F11
              11FF1F11117A1F1111DF1F1111FF1F1111FF1E121256FFFFFF00FFFFFF00FFFF
              FF001E11113B1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF2110
              102F201111A91F1111FF1F1111FF20121280FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00000000011F1111FC1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FBFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11
              114B1F1111FF1F1111FF1F1111FF1A1A1A0AFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201212811F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111E3FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1010AB1F11
              11FF1F1111FF1F11118A1F1111ED1F1111FF1F1111FF20121248FFFFFF00FFFF
              FF00FFFFFF001E11114D1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1B12121C1F10109C1F1111FF1F1111FF1F10108CFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111EA1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FC1E0F0F331E0F0F331E0F0F331E0F0F331E0F0F331E0F0F331E0F
              0F331E12128F1F1111FF1F1111FF1F1111FF1E11113B1E0F0F331E0F0F331E0F
              0F331E0F0F331E0F0F331E0F0F331E0F0F331E0F0F331E0F0F331E0F0F331E0F
              0F331E0F0F331E0F0F331E0F0F331E0F0F331E1111871F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111F5FFFFFF00FFFFFF00FFFFFF00FFFFFF001F10
              109D1F1111FF1F1111FF1E1111981F1111F61F1111FF1F1111FF1D11113DFFFF
              FF00FFFFFF00FFFFFF001E1212551F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1B0D0D131F10108C1F1111FF1F1111FF1F1111A3FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111C41F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FDFFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1111931F1111FF1F1111FF201111A11F1111FC1F1111FF1F1111FF2013
              1337FFFFFF00FFFFFF00FFFFFF001E11115C1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1515150C1F11116A1F1111FF1F1111FF1E1010C9FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F10109C1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF33000005FFFFFF00FFFF
              FF00FFFFFF001F10108C1F1111FF1F1111FF1E1111A81F1111FF1F1111FF1F11
              11FF1D131335FFFFFF00FFFFFF00FFFFFF00201010611F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF202020081E0F0F431F1111FF1F1111FF1F11
              11F0FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F12
              12731F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111C72011118820111188201111882011
              11882011118820111188201111881F1212CB1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1717170BFFFF
              FF00FFFFFF00FFFFFF001F11118A1F1111FF1F1111FF201111AA1F1111FD1F11
              11FF1F1111FF21131336FFFFFF00FFFFFF00FFFFFF001E10105E1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1C0E0E122312121D1F1111FF1F11
              11FF1F1111FF20151518FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00201212381F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F11115BFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111B71F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF2400
              0007FFFFFF00FFFFFF00FFFFFF001F11118B1F1111FF1F1111FF1E1111A81F11
              11F81F1111FF1F1111FF1F12123AFFFFFF00FFFFFF00FFFFFF00201212571F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF2110101F000000011F11
              11F41F1111FF1F1111FF1E121245FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00000000041F1111F01F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF2211111EFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000011F1111EC1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FE00000001FFFFFF00FFFFFF00FFFFFF00201212901F1111FF1F1111FF1F11
              11A41F1111F01F1111FF1F1111FF1E131344FFFFFF00FFFFFF00FFFFFF001F10
              10511F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1D11112CFFFF
              FF001F1111C31F1111FF1F1111FF1F111185FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201111B11F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111D3FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001C0E0E251F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111F9FFFFFF00FFFFFF00FFFFFF00FFFFFF00201111991F1111FF1F11
              11FF1F10109C1F1111E41F1111FF1F1111FF1F101051FFFFFF00FFFFFF00FFFF
              FF001F0F0F421F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF2012
              1238FFFFFF001F1212821F1111FF1F1111FF1F1111C7FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201010611F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F111185FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11116A1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1212E9FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111A61F11
              11FF1F1111FF1E12128F1F1111D51F1111FF1F1111FF20101061FFFFFF00FFFF
              FF00FFFFFF002110102F1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1E121245FFFFFF001F0F0F421F1111FF1F1111FF1F1111FB2412120EFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001515150C1F1111F41F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FE2214
              1426FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002011
              11B21F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111D6FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11
              11B61F1111FF1F1111FF201212801E1111C11F1111FF1F1111FF1F111175FFFF
              FF00FFFFFF00FFFFFF001C13131B1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1E11115CFFFFFF001C1C1C091F1111F71F1111FF1F1111FF2010
              1050FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E12
              12A01F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E11
              11B9FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001A1A
              1A0A1F1111F41F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF201111C2FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00201010CA1F1111FF1F1111FF1F11116C201111AA1F1111FF1F1111FF1F10
              108EFFFFFF00FFFFFF00FFFFFF00000000041F1111FB1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F121283FFFFFF00FFFFFF00201010BA1F1111FF1F11
              11FF1F1010ACFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00201313371F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1D10104EFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00201111581F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111A7FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1111E31F1111FF1F1111FF1E1212551E12128F1F1111FF1F11
              11FF201111AAFFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111DF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1010ABFFFFFF00FFFFFF00201010601F11
              11FF1F1111FF1F1111F81C0E0E12FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00201010BA1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111DF00000003FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1111B51F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E111186FFFFFF00FFFF
              FF00FFFFFF00000000041F1111FB1F1111FF1F1111FF1E11113B201010701F11
              11FF1F1111FF1F1212CBFFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111BF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF201111D2FFFFFF00FFFFFF002714
              140D1F1111F51F1111FF1F1111FF20111169FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001E11113C1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF20101061FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001C13131B1F1111FB1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E121265FFFF
              FF00FFFFFF00FFFFFF00201010201F1111FF1F1111FF1F1111FF1B12121C1D10
              104E1F1111FF1F1111FF1F1111EEFFFFFF00FFFFFF00FFFFFF00FFFFFF001E11
              11971F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F600000002FFFF
              FF00FFFFFF001F1111A61F1111FF1F1111FF1F1111CE00000001FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111B41F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF201010CA00000002FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E1111861F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1D11
              113DFFFFFF00FFFFFF00FFFFFF001E1313441F1111FF1F1111FF1F1111F70000
              0001211414271F1111FF1F1111FF1F1111FF20151518FFFFFF00FFFFFF00FFFF
              FF00201111681F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1C0E
              0E24FFFFFF00FFFFFF00201212471F1111FF1F1111FF1F1111FF1F111149FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201010201F11
              11F51F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FE20121238FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001A1A1A0A1F1111EC1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF20101010FFFFFF00FFFFFF00FFFFFF001E10106D1F1111FF1F1111FF1F11
              11D1FFFFFF00000000041F1111F71F1111FF1F1111FF1E121245FFFFFF00FFFF
              FF00FFFFFF001F12123A1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F121263FFFFFF00FFFFFF00000000011F1111D01F1111FF1F1111FF1F11
              11C4FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001E1111771F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1E1212A0FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1212721F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1E1111E2FFFFFF00FFFFFF00FFFFFF00FFFFFF00201111991F1111FF1F11
              11FF1F1111A6FFFFFF00FFFFFF001F1111CD1F1111FF1F1111FF1E111176FFFF
              FF00FFFFFF00FFFFFF001A1A1A0A1F1111FA1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111A4FFFFFF00FFFFFF00FFFFFF00201212571F1111FF1F11
              11FF1F1111FF2010103FFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00000000041F1111C31F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111DC20101010FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF002412120E1F1111EB1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1010ACFFFFFF00FFFFFF00FFFFFF00FFFFFF00201010CA1F11
              11FF1F1111FF20111178FFFFFF00FFFFFF001F11119A1F1111FF1F1111FF1F10
              10ABFFFFFF00FFFFFF00FFFFFF00FFFFFF00201010CA1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111E6FFFFFF00FFFFFF00FFFFFF00000000031E12
              12DA1F1111FF1F1111FF1E1010C900000002FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001C13131B1F1212E91F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111F620101030FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212811F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF20121271FFFFFF00FFFFFF00FFFFFF00240000071F11
              11F81F1111FF1F1111FF21121246FFFFFF00FFFFFF001F1212641F1111FF1F11
              11FF1F1111E4FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212901F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F131329FFFFFF00FFFFFF00FFFF
              FF00201010601F1111FF1F1111FF1F1111FF20111168FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E1212451F1111FB1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F121262FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D0F0F231F1111F61F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF21131336FFFFFF00FFFFFF00FFFFFF001F12
              123A1F1111FF1F1111FF1F1111FD1E0F0F11FFFFFF00FFFFFF001E12122A1F11
              11FF1F1111FF1F1111FF1D0F0F23FFFFFF00FFFFFF00FFFFFF001E11114C1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11116CFFFFFF00FFFF
              FF00FFFFFF00000000021F1111C81F1111FF1F1111FF1F1111EE230C0C16FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10
              105E1F1111FE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF20121290FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E1111B81F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111EE00000004FFFFFF00FFFFFF00FFFF
              FF00201111781F1111FF1F1111FF1F1111D4FFFFFF00FFFFFF00FFFFFF000000
              00011F1111EA1F1111FF1F1111FF1E121265FFFFFF00FFFFFF00FFFFFF001717
              170B1F1111F81F1111FF1F1111FF1F1111FF1F1111FF1F1111FF201111C2FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F0F0F321F1111FC1F1111FF1F1111FF1F11
              11A5FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001E10106F1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F11119400000001FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10105E1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF201111A9FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001E1111B91F1111FF1F1111FF1F111195FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1111A71F1111FF1F1111FF1F1010ABFFFFFF00FFFFFF00FFFF
              FF00FFFFFF001E1111B91F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FE1E0F0F22FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111941F1111FF1F11
              11FF1F1111FF20101061FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201212711F1111FD1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F11119500000001FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D0F0F231F1111F21F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF2010105FFFFFFF00FFFF
              FF00FFFFFF001C1C1C091F1111F61F1111FF1F1111FF1F101052FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00201010601F1111FF1F1111FF1F1111F12B000006FFFF
              FF00FFFFFF00FFFFFF00201010611F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1E10107FFFFFFF00FFFFFF00FFFFFF00FFFFFF00201010101F11
              11E01F1111FF1F1111FF1F1111F51E12122AFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201111591F1111F91F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F10108C00000001FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002B0000061F1111C81F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F720101010FFFF
              FF00FFFFFF00FFFFFF001E11114C1F1111FF1F1111FF1F1111FB20101010FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00230C0C161F1111FD1F1111FF1F1111FF2012
              1247FFFFFF00FFFFFF00FFFFFF002714140D1F1111F51F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111DC00000001FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1212391F1111FA1F1111FF1F1111FF1F1111D41515150CFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002010
              10401F1111E71F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111F320121257FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F10109D1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF201111AAFFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F10109C1F1111FF1F1111FF1F1111BFFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111C41F1111FF1F11
              11FF1F10109BFFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111A51F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1D11113DFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1111751F1111FF1F1111FF1F1111FF1E1111B92B00
              0006FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF0021161617201010BA1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111D61F131329FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212721F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E11
              114DFFFFFF00FFFFFF00FFFFFF00330000051F1111EB1F1111FF1F1111FF1E10
              106FFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10106F1F11
              11FF1F1111FF1F1111ED2B000006FFFFFF00FFFFFF00FFFFFF00201212471F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E1111B0FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00000000011F1111B41F1111FF1F1111FF1F11
              11FF1F1111A700000002FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF0000000002201010701F1111F11F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FA1F10108C1515150CFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11115A1F11
              11FD1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11EA33000005FFFFFF00FFFFFF00FFFFFF001F1111491F1111FF1F1111FF1F11
              11FE2312121DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D14
              141A1F1111FC1F1111FF1F1111FF1F121253FFFFFF00FFFFFF00FFFFFF000000
              00031F1111E61F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FE1C11
              112DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002714140D1F1111CD1F11
              11FF1F1111FF1F1111FF1F11119400000001FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D14141A1F11
              11A51F1111FE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1E1111B820131328FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201010501F11
              11FB1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F111192FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111A61F1111FF1F11
              11FF201111C2FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00201010BA1F1111FF1F1111FF1F1111B5FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1111841F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111A7FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00230C
              0C161E1212DA1F1111FF1F1111FF1F1111FF1F12129E00000004FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001D1313351F1212AE1F1111FD1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111C51E11114DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E1212551F11
              11F91F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FE2111112EFFFFFF00FFFFFF00FFFFFF001C0E0E121F1111F71F11
              11FF1F1111FF1E121265FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00201111581F1111FF1F1111FF1F1111FC2110101FFFFF
              FF00FFFFFF00FFFFFF00240C0C151F1111F51F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FC22141426FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F0F0F211F1111E61F1111FF1F1111FF1F1111FF201111B11C1C
              1C09FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1313291E1111981F1111EE1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F51F10
              109C1F101031FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11116B1F11
              11FD1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111B3FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212711F11
              11FF1F1111FF1F1111F42412120EFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00240000071F1111EA1F1111FF1F1111FF2011
              1188FFFFFF00FFFFFF00FFFFFF00FFFFFF00201212901F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111A2FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00211414271F1111E01F1111FF1F1111FF1F11
              11FF1F1111C41F141419FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002400
              00071F1212531F1010AB1F1111EC1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F0F
              0F21FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000041F10108E1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF20121238FFFFFF00FFFFFF00FFFFFF00000000021F11
              11DB1F1111FF1F1111FF1F10109CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E1111861F1111FF1F11
              11FF1F1111ED1515150CFFFFFF00FFFFFF00FFFFFF001B12121C1F1111F81F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FE1E11113CFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001C13131B1F1111D31F11
              11FF1F1111FF1F1111FF1F1212E921121246FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00000000022110102F201010701F10109C1F11
              11C31F1111EB1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111F41F1111D11F1111A61F1212721D0F0F34201111B11F1111FF1F11
              11FF1A0D0D14FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00230C0C161F1111C01F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1212BCFFFFFF00FFFFFF00FFFFFF00FFFFFF001D10
              104E1F1111FF1F1111FF1F1111FF1F101031FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001C13131B1F11
              11FA1F1111FF1F1111FF20101070FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11
              119A1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF201111D20000
              0004FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E0F
              0F111F1111C41F1111FF1F1111FF1F1111FF1F1111FD1F11118400000004FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00202020081B0D0D131E0F0F222111112E1C0E0E251E0F
              0F222714140DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F11
              11FF1F1111FF1A0D0D14FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002010104F1F1010E81F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F101041FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1111C41F1111FF1F1111FF1E1111C1FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1111A21F1111FF1F1111FF1F1111E324000007FFFFFF00FFFFFF00FFFF
              FF001D0F0F231F1111F91F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F121273FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00240000071F1111931F1111FF1F1111FF1F1111FF1F1111FF2011
              11D21E11113CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F12
              12AE1F1111FF1F1111FF1A0D0D14FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001A0D0D14201111A11F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF201111C2FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00201010401F1111FF1F1111FF1F1111FF1E11114DFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001E12122B1F1111FD1F1111FF1F1111FF1F11116BFFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E1111871F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111F21B12121CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1010521F1111EF1F1111FF1F11
              11FF1F1111FF1F1111FE1E12129F240C0C15FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1212AE1F1111FF1F1111FF1A0D0D14FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00000000041E10106D1F1111EE1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FC1F101031FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1111C01F1111FF1F1111FF201111D200000001FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201111AA1F1111FF1F1111FF1F1111E61717
              170BFFFFFF00FFFFFF00FFFFFF001A1A1A0A1F1111E01F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1010BB00000002FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201010201F11
              11C01F1111FF1F1111FF1F1111FF1F1111FF1F1111F22011118821161617FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1212AE1F1111FF1F1111FF1A0D0D14FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00000000041E10105D1F1111D71F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F111192FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00201212481F1111FF1F1111FF1F1111FF1E121255FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E12122A1F1111FC1F1111FF1F11
              11FF1E10107EFFFFFF00FFFFFF00FFFFFF00FFFFFF002010104F1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F10107DFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00000000011E10105D1F1111E71F1111FF1F1111FF1F1111FF1F1111FF1F11
              11F61F1111921E0F0F22FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1212AE1F1111FF1F1111FF1A0D0D14FFFFFF00FFFF
              FF00FFFFFF002211110F1F11116B1F1111DC1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111E72211110FFFFFFF00FFFF
              FF00FFFFFF00000000031F1111D11F1111FF1F1111FF1F1111D000000002FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F10109C1F11
              11FF1F1111FF1F1111F41B12121CFFFFFF00FFFFFF00FFFFFF00FFFFFF001F11
              11B31F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FC2010
              1040FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF002211110F1F1111921F1111FA1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FE201111C21F1212642211110FFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F1111FF1F1111FF1A0D0D140000
              00041E0F0F431F12129E1F1111F51F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11115BFFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E1212661F1111FF1F1111FF1F1111FF20121248FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D14
              141A1F1111F31F1111FF1F1111FF201111A9FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F0F0F211F1111F31F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111E621161617FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002211111E1F11
              11921F1111F61F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F61F11
              11B31F1212722010103000000002FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F1111FF1F1111FF1F10
              10AC1F1111ED1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1212BC00000001FFFF
              FF00FFFFFF00FFFFFF001B0D0D131F1111EB1F1111FF1F1111FF1E1111B9FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00201111791F1111FF1F1111FF1F1111FF1F111149FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E11115C1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF201111C21C1C1C09FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00230C0C161E1111861F1212E91F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111EC1F1111B71E12128F201111681F0F
              0F421D0F0F231E0F0F1133000005FFFFFF00FFFFFF00FFFFFF00330000051C0E
              0E121E0F0F222013133720111158201111791F11119A1F1111E61F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1212E91D14141AFFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F10109D1F1111FF1F1111FF1F1111FA1E12
              122AFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00240000071F1111D81F1111FF1F1111FF1F1111E02714
              140DFFFFFF00FFFFFF00FFFFFF00FFFFFF001F10109C1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111AF00000003FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000041F11114B1F1111A71F11
              11F61F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F91F1111EE1F1111F61F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FD20121247FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001E1313441F1111FE1F1111FF1F1111FF1F11
              118AFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201010401F1111FE1F1111FF1F11
              11FF1F11119AFFFFFF00FFFFFF00FFFFFF00FFFFFF001A1A1A0A1F1111D31F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F10109B0000
              0001FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF002211110F1E1212551F1111961F1111D71F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F111185FFFF
              FF00FFFFFF00FFFFFF00FFFFFF002211110F1F1111E01F1111FF1F1111FF1F11
              11DD1A1A1A0AFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E1111971F11
              11FF1F1111FF1F1111FF1D10104EFFFFFF00FFFFFF00FFFFFF00FFFFFF001F13
              13291F1111F41F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F111185FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1414191E1212551F10
              107D1F1111A4201010CA1F1111F01F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F11F1111D01F1111AF1F10
              108E1F1111D41F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E1111C10000
              0004FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1111A21F1111FF1F1111FF1F11
              11FE1E0F0F43FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001515
              150C1F1111DD1F1111FF1F1111FF1F1111EC2312121DFFFFFF00FFFFFF00FFFF
              FF00FFFFFF001E1212561F1111FD1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F11118400000001FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001C1C1C091A0D0D141E0F0F222010
              1030211313361F0F0F321E0F0F221A0D0D1424000007FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1212AE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111E11D14
              141AFFFFFF00FFFFFF00FFFFFF00FFFFFF001E10105D1F1111FF1F1111FF1F11
              11FF1F111194FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1212391F1111FB1F1111FF1F1111FF1F1111C633000005FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F11116C1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F11119A00000003FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1212AE1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111EC1F13
              1329FFFFFF00FFFFFF00FFFFFF00FFFFFF001D11112C1F1111F41F1111FF1F11
              11FF1F1111D51A1A1A0AFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00201111791F1111FF1F1111FF1F1111FF1F11
              1196FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212831F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1212AE2020
              2008FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F42013
              1337FFFFFF00FFFFFF00FFFFFF00FFFFFF001E0F0F111E1212DA1F1111FF1F11
              11FF1F1111F61C11112DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000021F1111B41F1111FF1F11
              11FF1F1111FF20111168FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11
              119A1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1E1111C1240C0C15FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FA1F11
              1149FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000004201010BA1F1111FF1F11
              11FF1F1111FF20101060FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E0F0F111E12
              12DA1F1111FF1F1111FF1F1111FB1F111149FFFFFF00FFFFFF00FFFFFF00FFFF
              FF0000000003201111AA1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111E41D11113DFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FC1F11
              115BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201111991F1111FF1F11
              11FF1F1111FF1F111195FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1313291F1111EF1F1111FF1F1111FF1F1111F321131336FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00000000031F11119A1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FB1F11117A00000002FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F62010
              104FFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10107F1F1111FF1F11
              11FF1F1111FF1F1111BE33000005FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E0F0F431F1111F91F1111FF1F1111FF1F1111EB1E12
              122BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212831F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1E11
              11B820151518FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F12
              12AE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111EF1D11
              113DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10106E1F1111FF1F11
              11FF1F1111FF1F1111D61E0F0F11FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11115B1F1111FD1F1111FF1F11
              11FF1F1010E820131328FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11
              116C1F1111FD1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111F01E10106D00000003FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001F1212AE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111E51C11
              112DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E1212661F1111FE1F11
              11FF1F1111FF1F1111E52110101FFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10106D1F11
              11FF1F1111FF1F1111FF1F1010E81D11112CFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001E1212561F1111F41F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111CD20131337FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1212AE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111D12110
              101FFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11116A1F1111FE1F11
              11FF1F1111FF1F1111EC1E12122BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001E1111761F1111FF1F1111FF1F1111FF1F1111EC21131336FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1313291F1111D31F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FD1F10
              109B20101020FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1212AE1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11119A1C1C
              1C09FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201111781F1111FE1F11
              11FF1F1111FF1F1111EE1F0F0F32FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E1111771F1111FF1F1111FF1F1111FF1F1111F32012
              1248FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001A1A1A0A1F10109D1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FA1E12129F21141427FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F21F11115AFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000021E12128F1F1111FF1F11
              11FF1F1111FF1F1111ED1E0F0F33FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E10106D1F1111FE1F1111FF1F11
              11FF1F1111FB20111169FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001E11115C1F1111F31F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FD1E1111A81D0F0F34FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111D021141427FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001717170B1F1212AE1F1111FF1F11
              11FF1F1111FF1F1111E72111112EFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11115B1F11
              11F91F1111FF1F1111FF1F1111FF1F1111952B000006FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F0F0F211F1111B31F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111D31F1111751D14141AFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F61F10107D24000007FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201010201F1111CF1F1111FF1F11
              11FF1F1111FF1F1111DC1D0F0F23FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001E0F0F431F1111EF1F1111FF1F1111FF1F1111FF1F1111C51B12121CFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002010104F1F1111E01F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FC1E1111B9201010612211111EFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F1212AE1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111B41E0F0F22FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F11114A1F1111EC1F1111FF1F11
              11FF1F1111FF1F1111C7230C0C16FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001F1313291E1212DA1F1111FF1F1111FF1F1111FF1F11
              11EB1D10104EFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001A1A
              1A0A1E1111871F1111F91F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111DB201111992011115820151518FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001F12
              12AE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111E120101050FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF002B0000061F11118B1F1111FE1F1111FF1F11
              11FF1F1111FF1F1111A61C1C1C09FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00201010101F1111B31F1111FF1F11
              11FF1F1111FF1F1111FF201111992714140DFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E0F0F221F11119A1F1111F91F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111EC1F1111C61F10
              109D1E111177201010501D1313351E12122A2110101F1E0F0F1100000003FFFF
              FF001F1212AE1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111E31E10106F1A1A1A0AFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001C11112D1F1111CE1F1111FF1F1111FF1F11
              11FF1F1111FB1F12127300000001FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000012011
              11791F1111FB1F1111FF1F1111FF1F1111FF1F1111E020121248FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001B12121C201212901F11
              11F51F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111F61F1111FA1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111DC1E1212652B000006FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF002B0000061E10107E1F1111F91F1111FF1F1111FF1F11
              11FF1F1111E41D11113DFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001F1212391F1111DC1F1111FF1F1111FF1F1111FF1F1111FF2011
              11A91B12121CFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00240C0C151F1111841F1111E61F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111C81F11115B00000004FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001E0F0F431F1111D71F1111FF1F1111FF1F1111FF1F11
              11FF1F1212AE1B0D0D13FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001515150C1E1111971F1111FE1F1111FF1F11
              11FF1F1111FF1F1111F41E10107F1717170BFFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF0000000003201212481F1111A51F1111F51F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111E11F11
              118421141427FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001C0E0E251F1212AE1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11EE1E10105EFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002010103F1F11
              11D81F1111FF1F1111FF1F1111FF1F1111FF1F1111E71F11116B24000007FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002714
              140D201010611E1111B91F1111F81F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1010E81F10109D201010400000
              0002FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001B12121C1E1111971F1111FA1F1111FF1F1111FF1F1111FF1F1111FF2011
              11AA1F141419FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00240000071F11117A1F1111F41F1111FF1F1111FF1F1111FF1F1111FF1F11
              11E31E10106F1717170BFFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001717170B1E11114C20121290201010CA1F11
              11FA1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111EF1F1111B51F11117A1E0F0F3300000001FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001D0F
              0F231E1111981F1111F81F1111FF1F1111FF1F1111FF1F1111FF1F1111D82012
              1247FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001D14141A1F10109D1F1111FC1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111ED201111882110101FFFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF001A1A1A0A1F12123A201111681E1111971F1111BF1F1111DF1F1111FB1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F41F1111D4201111B21E11
              1187201111581E12122A00000002FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002010103F1F12
              12AD1F1111FD1F1111FF1F1111FF1F1111FF1F1111FF1F1111EB1E10106D3300
              0005FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001E12122A2011
              11AA1F1111FD1F1111FF1F1111FF1F1111FF1F1111FF1F1111FC1F1111B41F10
              10512B000006FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
              00041C13131B2111112E1F1010411E1212541E1212551E10105E1E1212662011
              11581E1212551D10104E1E11113B201313281B0D0D13FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00211616171F1212731F1111D61F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F01E10107F2412120EFFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF001E12122A1F1111A21F1111FA1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111ED1F10109B201212472B000006FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF001A0D0D141F1212621E1111B81F1111FB1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1010E81F11117A2211110FFFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF001C13131B1E1111861F1111EA1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F11F1010AB1E12
              12651D0F0F23FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
              00041F1212391F10107C1F1111C41F1111FC1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111CE1F12126224000007FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF002400
              000720111158201010BA1F1111FC1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111E41F1010AB1F1111751E13134420151518FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF0000000003221414261E1212541E1111871F11
              11BE1F1111F31F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111F01F11119A21131336FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF001D14141A201010701F1111C41F1111FD1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111EE201010CA201111A91E12128F1F111175201010611F1010521E13
              1344201212381E0F0F331E0F0F331E0F0F332110103E211212461E1212552011
              11681E10107E1E1111971F1111B41F1111D61F1111F91F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111F21E11
              11A81F10105220202008FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00230C
              0C16201010601F1111A71F1010E81F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111D51E12128F201212472400
              0007FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00000000011E12122A1F1212641F10109B1F11
              11CD1F1111F81F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F1111FF1F11
              11FF1F1111ED1F1212BD2011118920101050230C0C16FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF0000000004211414271D10104E2010107020121290201111AA2011
              11C21F1111D51F1111E41F1111EE1F1111FC1F1111FF1F1111FF1F1111FF1F11
              11F51F1111EE1F1111DE1F1111CF1E1111B91F1111A21F1111851E1212651F0F
              0F421F141419FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
              FF00FFFFFF00FFFFFF00}
            Proportional = True
            Stretch = True
            Transparent = True
          end
          object pnlLogoLeft: TsPanel
            Left = 0
            Top = 0
            Width = 34
            Height = 188
            Align = alLeft
            BevelOuter = bvNone
            DoubleBuffered = False
            TabOrder = 0
          end
        end
      end
      object sPanel11: TsPanel
        Left = 0
        Top = 523
        Width = 1098
        Height = 48
        Align = alTop
        BevelOuter = bvNone
        BorderWidth = 24
        DoubleBuffered = False
        TabOrder = 2
        object sBitBtn1: TsBitBtn
          Left = 22
          Top = 6
          Width = 101
          Height = 29
          Caption = 'OK'
          TabOrder = 0
          ImageIndex = 36
          SkinData.OuterEffects.Visibility = ovAlways
        end
      end
    end
  end
end

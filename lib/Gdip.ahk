UpdateLayeredWindow(hwnd, hdcSrc, x:="", y:="", w:="", h:="", Alpha:=255) {
   if (x!="" && y!="")
      CreatePointF(pt, x, y, "uint")
   if (w="" || h="")
      GetWindowRect(hwnd, W, H)
   return DllCall("UpdateLayeredWindow"
               , "UPtr", hwnd
               , "UPtr", 0
               , "UPtr", ((x = "") && (y = "")) ? 0 : &pt
               , "int64*", w|h<<32
               , "UPtr", hdcSrc
               , "Int64*", 0
               , "UInt", 0
               , "UInt*", Alpha<<16|1<<24
               , "UInt", 2)
}

ConvertHueToRGB(v1, v2, vH) {
   vH := ((vH<0) ? ++vH : vH)
   vH := ((vH>1) ? --vH : vH)
   return  ((6 * vH) < 1) ? (v1 + (v2 - v1) * 6 * vH)
         : ((2 * vH) < 1) ? (v2)
         : ((3 * vH) < 2) ? (v1 + (v2 - v1) * ((2 / 3) - vH) * 6)
         : v1
}

SetImage(hwnd, hBitmap) {
   If (!hBitmap || !hwnd)
      Return
   E := DllCall("SendMessage", "UPtr", hwnd, "UInt", 0x172, "UInt", 0x0, "UPtr", hBitmap)
   DeleteObject(E)
   return E
}

Gdip_BitmapConvertFormat(pBitmap, PixelFormat, DitherType, DitherPaletteType, PaletteEntries, PaletteType, OptimalColors, UseTransparentColor:=0, AlphaThresholdPercent:=0) {
   VarSetCapacity(hPalette, 4 * PaletteEntries + 8, 0)
   NumPut(PaletteType, &hPalette, 0, "uint")
   NumPut(PaletteEntries, &hPalette, 4, "uint")
   NumPut(0, &hPalette, 8, "uint")
   E1 := DllCall("gdiplus\GdipInitializePalette", "UPtr", &hPalette, "uint", PaletteType, "uint", OptimalColors, "Int", UseTransparentColor, "UPtr", pBitmap)
   E2 := DllCall("gdiplus\GdipBitmapConvertFormat", "UPtr", pBitmap, "uint", PixelFormat, "uint", DitherType,   "uint", DitherPaletteType,   "UPtr", &hPalette, "float", AlphaThresholdPercent)
   E := E1 ? E1 : E2
   Return E
}

GetWindowRect(hwnd, W, H){
   bc := DllCall("GetSysColor", "Int", SysColor, "UInt")
   pBrushClear := Gdip_BrushCreateSolid(0xff000000 | (bc >> 16 | bc & 0xff00 | (bc & 0xff) << 16))
   pBitmap := Gdip_CreateBitmap(w, h)
   G := Gdip_GraphicsFromImage(pBitmap)
   Gdip_FillRectangle(G, pBrushClear, 0, 0, w, h)
   hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
   SetImage(hwnd, hBitmap)
   Gdip_DeleteBrush(pBrushClear)
   Gdip_DeleteGraphics(G)
   Gdip_DisposeImage(pBitmap)
   DeleteObject(hBitmap)
   return 0
}

Gdip_BitmapFromScreen(Screen:=0, Raster:="") {
   hhdc := 0
   if (Screen = 0)
   {
      _x := DllCall("GetSystemMetrics", "Int", 76)
      _y := DllCall("GetSystemMetrics", "Int", 77)
      _w := DllCall("GetSystemMetrics", "Int", 78)
      _h := DllCall("GetSystemMetrics", "Int", 79)
   } else if (SubStr(Screen, 1, 5) = "hwnd:")
   {
      hwnd := SubStr(Screen, 6)
      if !WinExist("ahk_id " hwnd)
         return -2
      GetWindowRect(hwnd, _w, _h)
      _x := _y := 0
      hhdc := GetDCEx(hwnd, 3)
   } else if IsInteger(Screen)
   {
      M := GetMonitorInfo(Screen)
      _x := M.Left, _y := M.Top, _w := M.Right-M.Left, _h := M.Bottom-M.Top
   } else
   {
      S := StrSplit(Screen, "|")
      _x := S[1], _y := S[2], _w := S[3], _h := S[4]
   }
   if (_x = "") || (_y = "") || (_w = "") || (_h = "")
      return -1
   chdc := CreateCompatibleDC()
   hbm := CreateDIBSection(_w, _h, chdc)
   obm := SelectObject(chdc, hbm)
   hhdc := hhdc ? hhdc : GetDC()
   BitBlt(chdc, 0, 0, _w, _h, hhdc, _x, _y, Raster)
   ReleaseDC(hhdc)
   pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
   SelectObject(chdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
   return pBitmap
}

Gdip_BitmapConvertGray(pBitmap, hue:=0, vibrance:=-40, brightness:=1, contrast:=0, KeepPixelFormat:=0) {
    If (pBitmap="")
       Return
    Gdip_GetImageDimensions(pBitmap, Width, Height)
    If (KeepPixelFormat=1)
       PixelFormat := Gdip_GetImagePixelFormat(pBitmap, 1)
    If StrLen(KeepPixelFormat)>3
       PixelFormat := KeepPixelFormat
    Else If (KeepPixelFormat=-1)
       PixelFormat := "0xE200B"
    newBitmap := Gdip_CreateBitmap(Width, Height, PixelFormat)
    G := Gdip_GraphicsFromImage(newBitmap, InterpolationMode)
    If (hue!=0 || vibrance!=0)
    {
       nBitmap := Gdip_CloneBitmap(pBitmap)
       pEffect := Gdip_CreateEffect(6, hue, vibrance, 0)
       Gdip_BitmapApplyEffect(nBitmap, pEffect)
       Gdip_DisposeEffect(pEffect)
    }
    matrix := GenerateColorMatrix(2, brightness, contrast)
    fBitmap := StrLen(nBitmap)>2 ? nBitmap : pBitmap
    gdipLastError := Gdip_DrawImage(G, fBitmap, 0, 0, Width, Height, 0, 0, Width, Height, matrix)
    Gdip_DeleteGraphics(G)
    If (nBitmap=fBitmap)
       Gdip_DisposeImage(nBitmap, 1)
    Return newBitmap
}

Gdip_GetImageThumbnail(pBitmap, W, H) {
    gdipLastError := DllCall("gdiplus\GdipGetImageThumbnail"
        ,"UPtr",pBitmap
        ,"UInt",W
        ,"UInt",H
        ,"UPtr*",pThumbnail
        ,"UPtr",0
        ,"UPtr",0)
   Return pThumbnail
}

CreatePointF(ByRef PointF, x, y, dtype:="float", ds:=4) {
   VarSetCapacity(PointF, ds*2, 0)
   NumPut(x, PointF, 0, dtype)
   NumPut(y, PointF, ds, dtype)
}

Gdip_PathGradientSetCenterColor(pBrush, CenterColor) {
   Return DllCall("gdiplus\GdipSetPathGradientCenterColor", "UPtr", pBrush, "UInt", CenterColor)
}

CreateCompatibleDC(hdc:=0) {
   return DllCall("CreateCompatibleDC", "UPtr", hdc)
}

Gdip_CreateFontFromDC(hDC) {
   pFont := 0
   gdipLastError := DllCall("gdiplus\GdipCreateFontFromDC", "UPtr", hDC, "UPtr*", pFont)
   Return pFont
}

DeleteObject(hObject) {
   return DllCall("DeleteObject", "UPtr", hObject)
}

GetDC(hwnd:=0) {
   return DllCall("GetDC", "UPtr", hwnd)
}

GetDCEx(hwnd, flags:=0, hrgnClip:=0) {
   return DllCall("GetDCEx", "UPtr", hwnd, "UPtr", hrgnClip, "int", flags)
}

ReleaseDC(hdc, hwnd:=0) {
   return DllCall("ReleaseDC", "UPtr", hwnd, "UPtr", hdc)
}

Gdip_GetFontHeight(hFont, pGraphics:=0) {
   result := 0
   gdipLastError := DllCall("gdiplus\GdipGetFontHeight", "UPtr", hFont, "UPtr", pGraphics, "float*", result)
   Return result
}

Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h:=0) {
   If (!pGraphics || !pBrush || !w)
      Return 2
   if (h<=0 || !h)
      h := w
   Return DllCall("gdiplus\GdipFillEllipse", "UPtr", pGraphics, "UPtr", pBrush, "float", x, "float", y, "float", w, "float", h)
}

Gdip_GraphicsFromImage(pBitmap, InterpolationMode:="", SmoothingMode:="", PageUnit:="", CompositingQuality:="") {
   pGraphics := 0
   gdipLastError := DllCall("gdiplus\GdipGetImageGraphicsContext", "UPtr", pBitmap, "UPtr*", pGraphics)
   If (gdipLastError=1 && A_LastError=8)
      gdipLastError := 3
   If (pGraphics!="" && !gdipLastError)
   {
      If (InterpolationMode!="")
         Gdip_SetInterpolationMode(pGraphics, InterpolationMode)
      If (SmoothingMode!="")
         Gdip_SetSmoothingMode(pGraphics, SmoothingMode)
      If (PageUnit!="")
         Gdip_SetPageUnit(pGraphics, PageUnit)
      If (CompositingQuality!="")
         Gdip_SetCompositingQuality(pGraphics, CompositingQuality)
   }
   return pGraphics
}

Gdip_GraphicsClear(pGraphics, ARGB:=0x00ffffff) {
   If (pGraphics="")
      return 2
   return DllCall("gdiplus\GdipGraphicsClear", "UPtr", pGraphics, "int", ARGB)
}

Gdip_SetAlphaChannel(pBitmap, pBitmapMask, invertAlphaMask:=0, replaceSourceAlphaChannel:=0, whichChannel:=1) {
  static mCodeFunc := 0
  if (mCodeFunc=0)
  {
      base64enc := "
      (LTrim Join
      2,x86:VVdWU4PsBIN8JDABD4T1AQAAg3wkMAIPhBwBAACDfCQwAw+E7AEAAIN8JDAEuBgAAAAPRUQkMIlEJDCDfCQsAQ+EBgEAAItUJCCF0g+OiQAAAItEJCDHBCQAAAAAjSyFAAAAAI10JgCLRCQkhcB+XosEJItcJBgx/400hQAAAAAB8wN0JByDfCQ
      oAXRjjXYAixOLBg+2TCQw0/iJ0cHpGA+2wI2ECAH///+5AAAAAIXAD0jBgeL///8Ag8cBAe7B4BgJwokTAes5fCQkdcKDBCQBiwQkOUQkIHWNg8QEuAEAAABbXl9dw420JgAAAACQixOLBg+2TCQw0/iJ0cHpGA+2wI2ECAH///+5AAAAAIXAD0jBuf8A
      AACB4v///wAB7oPHASnBicjB4BgJwokTAes5fCQkdbnrlYN8JCwBx0QkMAgAAAAPhfr+//+LTCQghcl+hzH/i0QkIItsJCSJPCSLTCQwjTSFAAAAAI10JgCF7X42g3wkKAGLBCR0Sot8JByNFIUAAAAAMdsB1wNUJBiNtCYAAAAAiweDwwEB99P4iEIDA
      fI53XXugwQkAYsEJDlEJCB1uYPEBLgBAAAAW15fXcONdCYAi1wkHMHgAjHSAcMDRCQYiceNtCYAAAAAiwODwgEB89P499CIRwMB9znVdeyDBCQBiwQkOUQkIA+Fa////+uwx0QkMBAAAADpJ/7//8dEJDAAAAAA6Rr+//8=
      )"

      mCodeFunc := Gdip_RunMCode(base64enc)
  }
  Gdip_GetImageDimensions(pBitmap, w, h)
  Gdip_GetImageDimensions(pBitmapMask, w2, h2)
  If (w2!=w || h2!=h || !pBitmap || !pBitmapMask)
     Return 0
  E1 := Gdip_LockBits(pBitmap, 0, 0, w, h, stride, iScan, iData)
  E2 := Gdip_LockBits(pBitmapMask, 0, 0, w, h, stride, mScan, mData)
  If (!E1 && !E2)
     r := DllCall(mCodeFunc, "UPtr", iScan, "UPtr", mScan, "Int", w, "Int", h, "Int", invertAlphaMask, "Int", replaceSourceAlphaChannel, "Int", whichChannel)
  If !E1
     Gdip_UnlockBits(pBitmap, iData)
  If !E2
     Gdip_UnlockBits(pBitmapMask, mData)
  return r
}

Gdip_CreateHBITMAPFromBitmap(pBitmap, Background:=0xffffffff) {
   hBitmap := 0
   If !pBitmap
   {
      gdipLastError := 2
      Return
   }
   gdipLastError := DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "UPtr", pBitmap, "UPtr*", hBitmap, "int", Background)
   return hBitmap
}

Gdip_CreateBitmap(Width, Height, PixelFormat:=0, Stride:=0, Scan0:=0) {
   If (!Width || !Height)
   {
      gdipLastError := 2
      Return
   }
   pBitmap := 0
   If !PixelFormat
      PixelFormat := 0x26200A
   gdipLastError := DllCall("gdiplus\GdipCreateBitmapFromScan0"
      , "int", Width  , "int", Height
      , "int", Stride , "int", PixelFormat
      , "UPtr", Scan0 , "UPtr*", pBitmap)
   Return pBitmap
}

Gdip_BrushCreateSolid(ARGB:=0xff000000) {
   pBrush := 0
   E := DllCall("gdiplus\GdipCreateSolidFill", "UInt", ARGB, "UPtr*", pBrush)
   return pBrush
}

MDMF_GetInfo(HMON) {
   NumPut(VarSetCapacity(MIEX, 40 + (32 << !!A_IsUnicode)), MIEX, 0, "UInt")
   If DllCall("User32.dll\GetMonitorInfo", "UPtr", HMON, "Ptr", &MIEX, "Int")
      Return {Name:      (Name := StrGet(&MIEX + 40, 32))
            , Num:       RegExReplace(Name, ".*(\d+)$", "$1")
            , Left:      NumGet(MIEX, 4, "Int")
            , Top:       NumGet(MIEX, 8, "Int")
            , Right:     NumGet(MIEX, 12, "Int")
            , Bottom:    NumGet(MIEX, 16, "Int")
            , WALeft:    NumGet(MIEX, 20, "Int")
            , WATop:     NumGet(MIEX, 24, "Int")
            , WARight:   NumGet(MIEX, 28, "Int")
            , WABottom:  NumGet(MIEX, 32, "Int")
            , Primary:   NumGet(MIEX, 36, "UInt")}
   Return False
}

Gdip_DisposeImage(pBitmap, noErr:=0) {
   If (StrLen(pBitmap)<=2 && noErr=1)
      Return 0
   r := DllCall("gdiplus\GdipDisposeImage", "UPtr", pBitmap)
   If (r=2 || r=1) && (noErr=1)
      r := 0
   Return r
}

Gdip_DeleteFontFamily(hFontFamily) {
   If (hFontFamily!="")
      return DllCall("gdiplus\GdipDeleteFontFamily", "UPtr", hFontFamily)
}

Gdip_StringFormatCreate(FormatFlags:=0, LangID:=0) {
   hStringFormat := 0
   gdipLastError := DllCall("gdiplus\GdipCreateStringFormat", "int", FormatFlags, "int", LangID, "UPtr*", hStringFormat)
   return hStringFormat
}

Gdip_SetStringFormatLineAlign(hStringFormat, StringAlign) {
   Return DllCall("gdiplus\GdipSetStringFormatLineAlign", "UPtr", hStringFormat, "int", StringAlign)
}

Gdip_CreateFontFamilyFromFile(FontFile, hFontCollection, FontName:="") {
   If (hFontCollection="")
      Return
   hFontFamily := 0
   E := DllCall("gdiplus\GdipPrivateAddFontFile", "uptr", hFontCollection, "str", FontFile)
   if (FontName="" && !E)
   {
      VarSetCapacity(pFontFamily, 10, 0)
      DllCall("gdiplus\GdipGetFontCollectionFamilyList", "uptr", hFontCollection, "int", 1, "uptr", &pFontFamily, "int*", found)

      VarSetCapacity(FontName, 100, 0)
      DllCall("gdiplus\GdipGetFamilyName", "uptr", NumGet(pFontFamily, 0, "uptr"), "str", FontName, "ushort", 1033)
   }
   If !E
      DllCall("gdiplus\GdipCreateFontFamilyFromName", "str", FontName, "uptr", hFontCollection, "uptr*", hFontFamily)
   Return hFontFamily
}

Gdip_SetTextRenderingHint(pGraphics, RenderingHint) {
   If !pGraphics
      Return 2
   Return DllCall("gdiplus\GdipSetTextRenderingHint", "UPtr", pGraphics, "int", RenderingHint)
}

Gdip_SetInterpolationMode(pGraphics, InterpolationMode) {
   If !pGraphics
      Return 2
   Return DllCall("gdiplus\GdipSetInterpolationMode", "UPtr", pGraphics, "int", InterpolationMode)
}

Gdip_SetSmoothingMode(pGraphics, SmoothingMode) {
   If !pGraphics
      Return 2
   Return DllCall("gdiplus\GdipSetSmoothingMode", "UPtr", pGraphics, "int", SmoothingMode)
}

Gdip_SetCompositingMode(pGraphics, CompositingMode) {
   If !pGraphics
      Return 2
   return DllCall("gdiplus\GdipSetCompositingMode", "UPtr", pGraphics, "int", CompositingMode)
}

Gdip_SetCompositingQuality(pGraphics, CompositionQuality) {
   If !pGraphics
      Return 2
   Return DllCall("gdiplus\GdipSetCompositingQuality", "UPtr", pGraphics, "int", CompositionQuality)
}

Gdip_SetPageUnit(pGraphics, Unit) {
   If !pGraphics
      Return 2
   Return DllCall("gdiplus\GdipSetPageUnit", "UPtr", pGraphics, "int", Unit)
}

Gdip_RestoreGraphics(pGraphics, State) {

    return DllCall("gdiplus\GdipRestoreGraphics", "UPtr", pGraphics, "UInt", State)
}

Gdip_SaveGraphics(pGraphics) {
   State := 0
   gdipLastError := DllCall("gdiplus\GdipSaveGraphics", "UPtr", pGraphics, "UInt*", State)
   return State
}

Gdip_RotateWorldTransform(pGraphics, Angle, MatrixOrder:=0) {
   return DllCall("gdiplus\GdipRotateWorldTransform", "UPtr", pGraphics, "float", Angle, "int", MatrixOrder)
}

Gdip_TranslateWorldTransform(pGraphics, x, y, MatrixOrder:=0) {
   return DllCall("gdiplus\GdipTranslateWorldTransform", "UPtr", pGraphics, "float", x, "float", y, "int", MatrixOrder)
}

Gdip_LockBits(pBitmap, x, y, w, h, ByRef Stride, ByRef Scan0, ByRef BitmapData, LockMode := 3, PixelFormat := 0x26200a) {
   CreateRectF(Rect, x, y, w, h, "uint")
   VarSetCapacity(BitmapData, 16+2*4, 0)
   _E := DllCall("Gdiplus\GdipBitmapLockBits", "UPtr", pBitmap, "UPtr", &Rect, "uint", LockMode, "int", PixelFormat, "UPtr", &BitmapData)
   Stride := NumGet(BitmapData, 8, "Int")
   Scan0 := NumGet(BitmapData, 16, "UPtr")
   return _E
}

Gdip_LoadImageFromFile(sFile, useICM:=0) {
   pImage := 0
   function2call := (useICM=1) ? "ICM" : ""
   gdipLastError := DllCall("gdiplus\GdipLoadImageFromFile" function2call, "WStr", sFile, "UPtr*", pImage)
   Return pImage
}

Gdip_ErrorHandler(errCode, throwErrorMsg, additionalInfo:="") {
   Static errList := {1:"Generic_Error", 2:"Invalid_Parameter"
         , 3:"Out_Of_Memory", 4:"Object_Busy"
         , 5:"Insufficient_Buffer", 6:"Not_Implemented"
         , 7:"Win32_Error", 8:"Wrong_State"
         , 9:"Aborted", 10:"File_Not_Found"
         , 11:"Value_Overflow", 12:"Access_Denied"
         , 13:"Unknown_Image_Format", 14:"Font_Family_Not_Found"
         , 15:"Font_Style_Not_Found", 16:"Not_TrueType_Font"
         , 17:"Unsupported_GdiPlus_Version", 18:"Not_Initialized"
         , 19:"Property_Not_Found", 20:"Property_Not_Supported"
         , 21:"Profile_Not_Found", 100:"Unknown_Wrapper_Error"}

   If !errCode
      Return
   aerrCode := (errCode<0) ? 100 : errCode
   If errList.HasKey(aerrCode)
      GdipErrMsg := "GDI+ ERROR: " errList[aerrCode]  " [CODE: " aerrCode "]" additionalInfo
   Else
      GdipErrMsg := "GDI+ UNKNOWN ERROR: " aerrCode additionalInfo
   If (throwErrorMsg=1)
      MsgBox, % GdipErrMsg
   Return GdipErrMsg
}

GetMonitorInfo(MonitorNum) {
   Monitors := MDMF_Enum()
   for k,v in Monitors
   {
      if (v.Num = MonitorNum)
         return v
   }
}

Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h:=0) {
   If (!pGraphics || !pBrush || !w)
      Return 2
   if (h<=0 || !h)
      h := w
   Return DllCall("gdiplus\GdipFillRectangle"
               , "UPtr", pGraphics
               , "UPtr", pBrush
               , "float", x, "float", y
               , "float", w, "float", h)
}

Gdip_DeleteBrush(pBrush) {
   If (pBrush!="")
      return DllCall("gdiplus\GdipDeleteBrush", "UPtr", pBrush)
}

Gdip_DeleteGraphics(pGraphics) {
   If (pGraphics!="")
      return DllCall("gdiplus\GdipDeleteGraphics", "UPtr", pGraphics)
}

IsInteger(Var) {
   Static Integer := "Integer"
   If Var Is Integer
      Return 1
   Return 0
}

CreateDIBSection(w, h, hdc:="", bpp:=32, ByRef ppvBits:=0, Usage:=0, hSection:=0, Offset:=0) {
   hdc2 := hdc ? hdc : GetDC()
   VarSetCapacity(bi, 40, 0)
   NumPut(40, bi, 0, "uint")
   NumPut(w, bi, 4, "uint")
   NumPut(h, bi, 8, "uint")
   NumPut(1, bi, 12, "ushort")
   NumPut(bpp, bi, 14, "ushort")
   NumPut(0, bi, 16, "uInt")
   hbm := DllCall("CreateDIBSection"
               , "UPtr", hdc2
               , "UPtr", &bi
               , "UInt", Usage
               , "UPtr*", ppvBits
               , "UPtr", hSection
               , "UInt", OffSet, "UPtr")
   if !hdc
      ReleaseDC(hdc2)
   return hbm
}

SelectObject(hdc, hgdiobj) {
   return DllCall("SelectObject", "UPtr", hdc, "UPtr", hgdiobj)
}

BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, raster:="") {
   return DllCall("gdi32\BitBlt"
               , "UPtr", dDC
               , "int", dX, "int", dY
               , "int", dW, "int", dH
               , "UPtr", sDC
               , "int", sX, "int", sY
               , "uint", Raster ? Raster : 0x00CC0020)
}

Gdip_CreateBitmapFromHBITMAP(hBitmap, hPalette:=0) {
   pBitmap := 0
   If !hBitmap
   {
      gdipLastError := 2
      Return
   }
   gdipLastError := DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "UPtr", hBitmap, "UPtr", hPalette, "UPtr*", pBitmap)
   return pBitmap
}

DeleteDC(hdc) {
   return DllCall("DeleteDC", "UPtr", hdc)
}

Gdip_GetImageDimensions(pBitmap, ByRef Width, ByRef Height) {
   Width := 0, Height := 0
   If StrLen(pBitmap)<3
      Return 2
   E := Gdip_GetImageDimension(pBitmap, Width, Height)
   Width := Round(Width)
   Height := Round(Height)
   return E
}

Gdip_GetImageDimension(pBitmap, ByRef w, ByRef h) {
   w := 0, h := 0
   If !pBitmap
      Return 2
   return DllCall("gdiplus\GdipGetImageDimension", "UPtr", pBitmap, "float*", w, "float*", h)
}

Gdip_GetImagePixelFormat(pBitmap, mode:=0) {
   Static PixelFormatsList := {0x30101:"1-INDEXED", 0x30402:"4-INDEXED", 0x30803:"8-INDEXED", 0x101004:"16-GRAYSCALE", 0x021005:"16-RGB555", 0x21006:"16-RGB565", 0x61007:"16-ARGB1555", 0x21808:"24-RGB", 0x22009:"32-RGB", 0x26200A:"32-ARGB", 0xE200B:"32-PARGB", 0x10300C:"48-RGB", 0x34400D:"64-ARGB", 0x1A400E:"64-PARGB", 0x200f:"32-CMYK"}
   PixelFormat := 0
   gdipLastError := DllCall("gdiplus\GdipGetImagePixelFormat", "UPtr", pBitmap, "UPtr*", PixelFormat)
   If gdipLastError
      Return -1
   If (mode=0)
      Return PixelFormat
   inHEX := Format("{1:#x}", PixelFormat)
   If (PixelFormatsList.Haskey(inHEX) && mode=2)
      result := PixelFormatsList[inHEX]
   Else
      result := inHEX
   return result
}

Gdip_CloneBitmap(pBitmap) {
   If !pBitmap
   {
      gdipLastError := 2
      Return
   }
   pBitmapDest := 0
   gdipLastError := DllCall("gdiplus\GdipCloneImage", "UPtr", pBitmap, "UPtr*", pBitmapDest)
   return pBitmapDest
}

Gdip_CreateEffect(whichFX, paramA, paramB, paramC:=0) {
    Static gdipImgFX := {1:"633C80A4-1843-482b-9EF2-BE2834C5FDD4", 2:"63CBF3EE-C526-402c-8F71-62C540BF5142", 3:"718F2615-7933-40e3-A511-5F68FE14DD74", 4:"A7CE72A9-0F7F-40d7-B3CC-D0C02D5C3212", 5:"D3A1DBE1-8EC4-4c17-9F4C-EA97AD1C343D", 6:"8B2DD6C3-EB07-4d87-A5F0-7108E26A9C5F", 7:"99C354EC-2A31-4f3a-8C34-17A803B33A25", 8:"1077AF00-2848-4441-9489-44AD4C2D7A2C", 9:"537E597D-251E-48da-9664-29CA496B70F8", 10:"74D29D05-69A4-4266-9549-3CC52836B632", 11:"DD6A0022-58E4-4a67-9D9B-D48EB881A53D"}
    pEffect := 0
    r1 := COM_CLSIDfromString(eFXguid, "{" gdipImgFX[whichFX] "}" )
    If r1
       Return "err-" r1
    r2 := DllCall("gdiplus\GdipCreateEffect"
       , "UInt", NumGet(eFXguid, 0, "UInt")
       , "UInt", NumGet(eFXguid, 4, "UInt")
       , "UInt", NumGet(eFXguid, 8, "UInt")
       , "UInt", NumGet(eFXguid, 12, "UInt")
       , "Ptr*", pEffect)
    If r2
       Return "err-" r2
    If (whichFX=3)  
       CreateColourMatrix(paramA, FXparams)
    Else
       VarSetCapacity(FXparams, 12, 0)
    If (whichFX=1)   
    {
       If (paramA>255)
          paramA := 255
       FXsize := 8
       NumPut(paramA, FXparams, 0, "Float")  
       NumPut(paramB, FXparams, 4, "Uchar")   
    } Else If (whichFX=3)  
    {
       FXsize := 100
    } Else If (whichFX=2)   
    {
       FXsize := 8
       NumPut(paramA, FXparams, 0, "Float") 
       NumPut(paramB, FXparams, 4, "Float") 
    } Else If (whichFX=5)  
    {
       FXsize := 8
       NumPut(paramA, FXparams, 0, "Int")
       NumPut(paramB, FXparams, 4, "Int") 
    } Else If (whichFX=6)   
    {
       FXsize := 12
       NumPut(paramA, FXparams, 0, "Int")   
       NumPut(paramB, FXparams, 4, "Int")  
       NumPut(paramC, FXparams, 8, "Int")   
    } Else If (whichFX=7)   
    {
       FXsize := 12
       NumPut(paramA, FXparams, 0, "Int")   
       NumPut(paramB, FXparams, 4, "Int")   
       NumPut(paramC, FXparams, 8, "Int")   
    } Else If (whichFX=8)   
    {
       FXsize := 8
       NumPut(paramA, FXparams, 0, "Int")    
       NumPut(paramB, FXparams, 4, "Int")    
    } Else If (whichFX=9)  
    {
       FXsize := 12
       NumPut(paramA, FXparams, 0, "Int")     
       NumPut(paramB, FXparams, 4, "Int")  
       NumPut(paramC, FXparams, 8, "Int") 
    } Else If (whichFX=11) 
    {
       FXsize := 12
       NumPut(paramA, FXparams, 0, "Int")
       NumPut(paramB, FXparams, 4, "Int")
       NumPut(paramC, FXparams, 8, "Int")
    }
    r3 := DllCall("gdiplus\GdipSetEffectParameters", "UPtr", pEffect, "UPtr", &FXparams, "UInt", FXsize)
    If r3
    {
       Gdip_DisposeEffect(pEffect)
       Return "err-" r3
    }
    Return pEffect
}

Gdip_BitmapApplyEffect(pBitmap, pEffect, x:="", y:="", w:="", h:="") {
  If (InStr(pEffect, "err-") || !pEffect || !pBitmap)
     Return 2
  If (!x && !y && !w && !h)
     none := 1
  Else
     CreateRectF(Rect, x, y, x + w, y + h, "uint")
  E := DllCall("gdiplus\GdipBitmapApplyEffect"
      , "UPtr", pBitmap
      , "UPtr", pEffect
      , "UPtr", (none=1) ? 0 : &Rect
      , "UPtr", 0    
      , "UPtr", 0     
      , "UPtr", 0) 
  Return E
}

Gdip_DisposeEffect(pEffect) {
   If (pEffect && !InStr(pEffect, "err"))
      r := DllCall("gdiplus\GdipDeleteEffect", "UPtr", pEffect)
   Return r
}

GenerateColorMatrix(modus, bright:=1, contrast:=0, saturation:=1, alph:=1, chnRdec:=0, chnGdec:=0, chnBdec:=0) {
    Static NTSCr := 0.308, NTSCg := 0.650, NTSCb := 0.095  
    matrix := ""
    If (modus=2)  
    {
       LGA := (bright<=1) ? bright/1.5 - 0.6666 : bright - 1
       Ra := NTSCr + LGA
       If (Ra<0)
          Ra := 0
       Ga := NTSCg + LGA
       If (Ga<0)
          Ga := 0
       Ba := NTSCb + LGA
       If (Ba<0)
          Ba := 0
       matrix := Ra "|" Ra "|" Ra "|0|0|" Ga "|" Ga "|" Ga "|0|0|" Ba "|" Ba "|" Ba "|0|0|0|0|0|" alph "|0|" contrast "|" contrast "|" contrast "|0|1"
    } Else If (modus=3) 
    {
       Ga := 0, Ba := 0, GGA := 0
       Ra := bright
       matrix := Ra "|" Ra "|" Ra "|0|0|" Ga "|" Ga "|" Ga "|0|0|" Ba "|" Ba "|" Ba "|0|0|0|0|0|" alph "|0|" GGA+0.01 "|" GGA "|" GGA "|0|1"
    } Else If (modus=4) 
    {
       Ra := 0, Ba := 0, GGA := 0
       Ga := bright
       matrix := Ra "|" Ra "|" Ra "|0|0|" Ga "|" Ga "|" Ga "|0|0|" Ba "|" Ba "|" Ba "|0|0|0|0|0|" alph "|0|" GGA "|" GGA+0.01 "|" GGA "|0|1"
    } Else If (modus=5)  
    {
       Ra := 0, Ga := 0, GGA := 0
       Ba := bright
       matrix := Ra "|" Ra "|" Ra "|0|0|" Ga "|" Ga "|" Ga "|0|0|" Ba "|" Ba "|" Ba "|0|0|0|0|0|" alph "|0|" GGA "|" GGA "|" GGA+0.01 "|0|1"
    } Else If (modus=6) 
    {
       matrix := "-1|0|0|0|0|0|-1|0|0|0|0|0|-1|0|0|0|0|0|" alph "|0|1|1|1|0|1"
    } Else If (modus=1)
    {
       bL := bright, aL := alph
       G := contrast, sL := saturation
       sLi := 1 - saturation
       bLa := bright - 1
       If (sL>1)
       {
          z := (bL<1) ? bL : 1
          sL := sL*z
          If (sL<0.98)
             sL := 0.98
          y := z*(1 - sL)
          mA := z*(y*NTSCr + sL + bLa + chnRdec)
          mB := z*(y*NTSCr)
          mC := z*(y*NTSCr)
          mD := z*(y*NTSCg)
          mE := z*(y*NTSCg + sL + bLa + chnGdec)
          mF := z*(y*NTSCg)
          mG := z*(y*NTSCb)
          mH := z*(y*NTSCb)
          mI := z*(y*NTSCb + sL + bLa + chnBdec)
          mtrx:= mA "|" mB "|" mC "|  0   |0"
           . "|" mD "|" mE "|" mF "|  0   |0"
           . "|" mG "|" mH "|" mI "|  0   |0"
           . "|  0   |  0   |  0   |" aL "|0"
           . "|" G  "|" G  "|" G  "|  0   |1"
       } Else
       {
          z := (bL<1) ? bL : 1
          tR := NTSCr - 0.5 + bL/2
          tG := NTSCg - 0.5 + bL/2
          tB := NTSCb - 0.5 + bL/2
          rB := z*(tR*sLi+bL*(1 - sLi) + chnRdec)
          gB := z*(tG*sLi+bL*(1 - sLi) + chnGdec)
          bB := z*(tB*sLi+bL*(1 - sLi) + chnBdec)    
          rF := z*(NTSCr*sLi + (bL/2 - 0.5)*sLi)
          gF := z*(NTSCg*sLi + (bL/2 - 0.5)*sLi)
          bF := z*(NTSCb*sLi + (bL/2 - 0.5)*sLi)
          rB := rB*z+rF*(1 - z)
          gB := gB*z+gF*(1 - z)
          bB := bB*z+bF*(1 - z)    
          If (rB<0)
             rB := 0
          If (gB<0)
             gB := 0
          If (bB<0)
             bB := 0
          If (rF<0)
             rF := 0
          If (gF<0)
             gF := 0
          If (bF<0)
             bF := 0
          mtrx:= rB "|" rF "|" rF "|  0   |0"
           . "|" gF "|" gB "|" gF "|  0   |0"
           . "|" bF "|" bF "|" bB "|  0   |0"
           . "|  0   |  0   |  0   |" aL "|0"
           . "|" G  "|" G  "|" G  "|  0   |1"
       }
       matrix := StrReplace(mtrx, A_Space)
    } Else If (modus=0)  
    {
       s1 := contrast 
       s2 := saturation
       s3 := bright
       aL := alph
       s1 := s2*sin(s1)
       sc := 1-s2
       r := NTSCr*sc-s1
       g := NTSCg*sc-s1
       b := NTSCb*sc-s1
       rB := r+s2+3*s1
       gB := g+s2+3*s1
       bB := b+s2+3*s1
       mtrx :=   rB "|" r  "|" r  "|  0   |0"
           . "|" g  "|" gB "|" g  "|  0   |0"
           . "|" b  "|" b  "|" bB "|  0   |0"
           . "|  0   |  0   |  0   |" aL "|0"
           . "|" s3 "|" s3 "|" s3 "|  0   |1"
       matrix := StrReplace(mtrx, A_Space)
    } Else If (modus=7)
    {
       matrix := "0|0|0|0|0"
              . "|0|0|0|0|0"
              . "|0|0|0|0|0"
              . "|1|1|1|25|0"
              . "|0|0|0|0|1"
    } Else If (modus=8)
    {
       matrix := "0.39|0.34|0.27|0|0"
              . "|0.76|0.58|0.33|0|0"
              . "|0.19|0.16|0.13|0|0"
              . "|0|0|0|" alph "|0"
              . "|0|0|0|0|1"
    } Else If (modus=9)
    {
       matrix := "1|0|0|0|0"
              . "|0|1|0|0|0"
              . "|0|0|1|0|0"
              . "|0|0|0|" alph "|0"
              . "|0|0|0|0|1"
    }
    Return matrix
}

Gdip_DrawImage(pGraphics, pBitmap, dx:="", dy:="", dw:="", dh:="", sx:="", sy:="", sw:="", sh:="", Matrix:=1, Unit:=2, ImageAttr:=0) {
   If (!pGraphics || !pBitmap)
      Return 2
   If !ImageAttr
   {
      if !IsNumber(Matrix)
         ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
      else if (Matrix!=1)
         ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
   } Else usrImageAttr := 1
   If (dx!="" && dy!="" && dw="" && dh="" && sx="" && sy="" && sw="" && sh="")
   {
      sx := sy := 0
      sw := dw := Gdip_GetImageWidth(pBitmap)
      sh := dh := Gdip_GetImageHeight(pBitmap)
   } Else If (sx="" && sy="" && sw="" && sh="")
   {
      If (dx="" && dy="" && dw="" && dh="")
      {
         sx := dx := 0, sy := dy := 0
         sw := dw := Gdip_GetImageWidth(pBitmap)
         sh := dh := Gdip_GetImageHeight(pBitmap)
      } Else
      {
         sx := sy := 0
         Gdip_GetImageDimensions(pBitmap, sw, sh)
      }
   }
   E := DllCall("gdiplus\GdipDrawImageRectRect"
            , "UPtr", pGraphics
            , "UPtr", pBitmap
            , "float", dX, "float", dY
            , "float", dW, "float", dH
            , "float", sX, "float", sY
            , "float", sW, "float", sH
            , "int", Unit
            , "UPtr", ImageAttr ? ImageAttr : 0
            , "UPtr", 0, "UPtr", 0)

   If (E=1 && A_LastError=8) ; out of memory
      E := 3
   if (ImageAttr && usrImageAttr!=1)
      Gdip_DisposeImageAttributes(ImageAttr)
   return E
}

Gdip_RunMCode(mcode) {
  static e := {1:4, 2:1}
       , c := "x86"
  if (!regexmatch(mcode, "^([0-9]+),(" c ":|.*?," c ":)([^,]+)", m))
     return
  if (!DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", StrLen(m3), "uint", e[m1], "ptr", 0, "uintp", s, "ptr", 0, "ptr", 0))
     return
  p := DllCall("GlobalAlloc", "uint", 0, "ptr", s, "ptr")
   DllCall("VirtualProtect", "ptr", p, "ptr", s, "uint", 0x40, "uint*", op)
  if (DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", StrLen(m3), "uint", e[m1], "ptr", p, "uint*", s, "ptr", 0, "ptr", 0))
     return p
  DllCall("GlobalFree", "ptr", p)
}

Gdip_UnlockBits(pBitmap, ByRef BitmapData) {
   return DllCall("Gdiplus\GdipBitmapUnlockBits", "UPtr", pBitmap, "UPtr", &BitmapData)
}

CreateRectF(ByRef RectF, x, y, w, h, dtype:="float", ds:=4) {
   VarSetCapacity(RectF, ds*4, 0)
   NumPut(x, RectF, 0,    dtype), NumPut(y, RectF, ds,   dtype)
   NumPut(w, RectF, ds*2, dtype), NumPut(h, RectF, ds*3, dtype)
}

MDMF_Enum(HMON := "") {
   Static CallbackFunc := Func(A_AhkVersion < "2" ? "RegisterCallback" : "CallbackCreate")
   Static EnumProc := CallbackFunc.Call("MDMF_EnumProc")
   Static Obj := (A_AhkVersion < "2") ? "Object" : "Map"
   Static Monitors := {}
   If (HMON = "") 
   {
      Monitors := %Obj%("TotalCount", 0)
      If !DllCall("User32.dll\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", EnumProc, "Ptr", &Monitors, "Int")
         Return False
   }
   Return (HMON = "") ? Monitors : Monitors.HasKey(HMON) ? Monitors[HMON] : False
}

COM_CLSIDfromString(ByRef CLSID, String) {
    VarSetCapacity(CLSID, 16, 0)
    Return DllCall("ole32\CLSIDFromString", "WStr", String, "UPtr", &CLSID)
}

CreateColourMatrix(clrMatrix, ByRef ColourMatrix) {
   VarSetCapacity(ColourMatrix, 100, 0)
   Matrix := RegExReplace(RegExReplace(clrMatrix, "^[^\d-\.]+([\d\.])", "$1", , 1), "[^\d-\.]+", "|")
   Matrix := StrSplit(Matrix, "|")
   Loop 25
   {
      M := (Matrix[A_Index] != "") ? Matrix[A_Index] : Mod(A_Index - 1, 6) ? 0 : 1
      NumPut(M, ColourMatrix, (A_Index - 1)*4, "float")
   }
}

IsNumber(Var) {
   Static number := "number"
   If Var Is number
      Return 1
   Return 0
}

Gdip_SetImageAttributesColorMatrix(clrMatrix, ImageAttr:=0, grayMatrix:=0, ColorAdjustType:=1, fEnable:=1, ColorMatrixFlag:=0) {
   If (StrLen(clrMatrix)<5 && ImageAttr)
      Return -1
   If (StrLen(clrMatrix)<5) || (ColorMatrixFlag=2 && StrLen(grayMatrix)<5)
      Return
   CreateColourMatrix(clrMatrix, ColourMatrix)
   If (ColorMatrixFlag=2)
      CreateColourMatrix(grayMatrix, GrayscaleMatrix)
   If !ImageAttr
   {
      created := 1
      ImageAttr := Gdip_CreateImageAttributes()
   }
   E := DllCall("gdiplus\GdipSetImageAttributesColorMatrix"
         , "UPtr", ImageAttr
         , "int", ColorAdjustType
         , "int", fEnable
         , "UPtr", &ColourMatrix
         , "UPtr", &GrayscaleMatrix
         , "int", ColorMatrixFlag)
   gdipLastError := E
   E := created=1 ? ImageAttr : E
   return E
}

Gdip_GetImageWidth(pBitmap) {
   Width := 0
   gdipLastError := DllCall("gdiplus\GdipGetImageWidth", "UPtr", pBitmap, "uint*", Width)
   return Width
}

Gdip_GetImageHeight(pBitmap) {
   Height := 0
   gdipLastError := DllCall("gdiplus\GdipGetImageHeight", "UPtr", pBitmap, "uint*", Height)
   return Height
}

Gdip_DisposeImageAttributes(ImageAttr) {
   If (ImageAttr!="")
      return DllCall("gdiplus\GdipDisposeImageAttributes", "UPtr", ImageAttr)
}

Gdip_CreateImageAttributes() {
   ImageAttr := 0
   gdipLastError := DllCall("gdiplus\GdipCreateImageAttributes", "UPtr*", ImageAttr)
   return ImageAttr
}

Gdip_CloneImageAttributes(ImageAttr) {
   newImageAttr := 0
   gdipLastError := DllCall("gdiplus\GdipCloneImageAttributes", "UPtr", ImageAttr, "UPtr*", newImageAttr)
   return newImageAttr
}

Gdip_Startup(multipleInstances:=0) {
   pToken := 0
   If (multipleInstances=0)
   {
      if !DllCall("GetModuleHandle", "str", "gdiplus", "UPtr")
         DllCall("LoadLibrary", "str", "gdiplus")
   } Else DllCall("LoadLibrary", "str", "gdiplus")
   VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
   DllCall("gdiplus\GdiplusStartup", "UPtr*", pToken, "UPtr", &si, "UPtr", 0)
   return pToken
}

Gdip_Shutdown(pToken) {
   DllCall("gdiplus\GdiplusShutdown", "UPtr", pToken)
   hModule := DllCall("GetModuleHandle", "Str", "gdiplus", "UPtr")
   if hModule
      DllCall("FreeLibrary", "UPtr", hModule)
   return 0
}

Gdip_GraphicsFromHDC(hDC, hDevice:="", InterpolationMode:="", SmoothingMode:="", PageUnit:="", CompositingQuality:="") {
   pGraphics := 0
   If hDevice
      gdipLastError := DllCall("Gdiplus\GdipCreateFromHDC2", "UPtr", hDC, "UPtr", hDevice, "UPtr*", pGraphics)
   Else
      gdipLastError := DllCall("gdiplus\GdipCreateFromHDC", "UPtr", hdc, "UPtr*", pGraphics)
   If (gdipLastError=1 && A_LastError=8)
      gdipLastError := 3
   If (pGraphics!="" && !gdipLastError)
   {
      If (InterpolationMode!="")
         Gdip_SetInterpolationMode(pGraphics, InterpolationMode)
      If (SmoothingMode!="")
         Gdip_SetSmoothingMode(pGraphics, SmoothingMode)
      If (PageUnit!="")
         Gdip_SetPageUnit(pGraphics, PageUnit)
      If (CompositingQuality!="")
         Gdip_SetCompositingQuality(pGraphics, CompositingQuality)
   }
   return pGraphics
}

Gdip_SetStringFormatAlign(hStringFormat, Align, LineAlign:="") {
   If (LineAlign!="")
      Gdip_SetStringFormatLineAlign(hStringFormat, LineAlign)
   return DllCall("gdiplus\GdipSetStringFormatAlign", "UPtr", hStringFormat, "int", Align)
}

Gdip_DrawString(pGraphics, sString, hFont, hStringFormat, pBrush, ByRef RectF) {
   return DllCall("gdiplus\GdipDrawString"
               , "UPtr", pGraphics
               , "WStr", sString
               , "int", -1
               , "UPtr", hFont
               , "UPtr", &RectF
               , "UPtr", hStringFormat
               , "UPtr", pBrush)
}

Gdip_DeleteStringFormat(hStringFormat) {
   return DllCall("gdiplus\GdipDeleteStringFormat", "UPtr", hStringFormat)
}

Gdip_CreateLineBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode:=1, WrapMode:=1) {
   return Gdip_CreateLinearGrBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode, WrapMode)
}

Gdip_CreateLinearGrBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode:=1, WrapMode:=1) {
   CreateRectF(RectF, x, y, w, h)
   pLinearGradientBrush := 0
   gdipLastError := DllCall("gdiplus\GdipCreateLineBrushFromRect", "UPtr", &RectF, "int", ARGB1, "int", ARGB2, "int", LinearGradientMode, "int", WrapMode, "UPtr*", pLinearGradientBrush)
   return pLinearGradientBrush
}

Gdip_FontCreate(hFontFamily, Size, Style:=0, Unit:=0) {
   hFont := 0
   gdipLastError := DllCall("gdiplus\GdipCreateFont", "UPtr", hFontFamily, "float", Size, "int", Style, "int", Unit, "UPtr*", hFont)
   Return hFont
}

Gdip_FontFamilyCreate(FontName) {
   hFontFamily := 0
   gdipLastError := DllCall("gdiplus\GdipCreateFontFamilyFromName"
               , "WStr", FontName, "uint", 0, "UPtr*", hFontFamily)
   Return hFontFamily
}

Gdip_DeleteFont(hFont) {
   If (hFont!="")
      return DllCall("gdiplus\GdipDeleteFont", "UPtr", hFont)
}
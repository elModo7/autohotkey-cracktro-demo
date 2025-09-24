; OS Version ...: Windows 10+
; Requires AutoHotkeyU32
;@Ahk2Exe-SetName Cracktro Demo
;@Ahk2Exe-SetDescription An AutoHotkey Demo showing some GDI+ features
;@Ahk2Exe-SetVersion 1.0
;@Ahk2Exe-SetCopyright Copyright (c) 2025`, elModo7 - VictorDevLog
;@Ahk2Exe-SetOrigFilename Cracktro Demo.exe
#SingleInstance, Force
#NoEnv
#Persistent
#Include <bassmod>
#Include <Gdip>
SetBatchLines, -1
ListLines, Off
SetWinDelay, -1
global pixelatedTexts := 1 ; Change this for smoothing the layered window, specially rotating text

If (A_PtrSize = 8)
	Throw, "BASSMOD.dll does not support 64-bit AutoHotkey!"
BASSMOD_Init()
BASSMOD_MusicLoad(false, A_ScriptDir "\lib\AGAiN - EIQ FirewallAnalyzer 3.2.10 kg.xm", 0, 0, BASS_UNICODE:=0x80000000)

global g_fontCollections := []

; Window
W := 960, H := 250
SysGet, Mon, MonitorWorkArea
posX := MonLeft  + ((MonRight  - MonLeft  - W) // 2)
posY := MonTop   + ((MonBottom - MonTop   - H) // 2)

; Title
title := "AutoHotkey"
titleFont := "Calibri"
titleSizeBase := 100
titlePulse := 22
titleRotAmp := 5
titleYAmp := 12

; Scrolling SIN text
scrollMsg  := "  GREETZ — elModo7 / VictorDevLog — PRESENTS... a New AutoHotkey DEMO - GDI+ Rules - Bassmod.dll - Cheers to the AHK Discord! "
scrollFont := "Consolas"
scrollSize := 28
scrollSpeed := 2.2
scrollAmp   := 16
scrollFreq  := 0.015
scrollY     := H - 78

; Stars
numStars := 220
starZSpeed := 0.045
fov := 340

; Bars
numBars := 22
barAmp := 36
barSpeed := 1.35
barH := 14

if !pToken := Gdip_Startup() {
    MsgBox, 16, GDI+ error, Could not start GDI+. Make sure Gdip.ahk is available and you are on AHK v1 (Unicode 32b).
    ExitApp
}

; GUI & GDI+ init
Gui, +E0x80000 +E0x20 +AlwaysOnTop -Caption +ToolWindow +OwnDialogs +LastFound
Gui, Show, NA w%W% h%H%
hWnd := WinExist()

hbm := CreateDIBSection(W, H)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
Gdip_SetSmoothingMode(G, pixelatedTexts ? 1 : 4)
Gdip_SetInterpolationMode(G, pixelatedTexts ? 1 : 4)
Gdip_SetTextRenderingHint(G, pixelatedTexts ? 1 : 4) 
Gdip_SetCompositingMode(G, 0)     
Gdip_SetCompositingQuality(G, pixelatedTexts ? 1 : 4)   

cx := W/2.0, cy := H/2.0
stars := []
Loop, %numStars%
    stars.Push(NewStar())

scrollX := W
startTick := A_TickCount
OnExit, Cleanup
BASSMOD_MusicPlay()
SetTimer, Render, 16
return

Render:
    now := A_TickCount - startTick
    t := now/1000.0

    Gdip_GraphicsClear(G, 0x00000000)
    brBG := Gdip_BrushCreateSolid(ARGB(255,6,8,12))
    Gdip_FillRectangle(G, brBG, 0, 0, W, H)
    Gdip_DeleteBrush(brBG)

    DrawVignette(G, W, H)
    DrawRasterBars(G, t)
    DrawStars(G, t)

    DrawTitle(G, t)
    DrawScroller(G, t)

    UpdateLayeredWindow(hWnd, hdc, posX, posY, W, H)
return

DrawStringBox(G, s, fontSpec, fSize, x, y, w, h, col, halign:=1, valign:=1, rot:=0) {
    fam := MakeFontFamilyFlex(fontSpec)
    if !fam
        return
    font := MakeFontFromFamily(fam, fSize, 0, 2)
    if !font {
        DeleteFontFamilySafe(fam)
        return
    }

    fmt := Gdip_StringFormatCreate()
    Gdip_SetStringFormatAlign(fmt, halign)      
    Gdip_SetStringFormatLineAlign(fmt, valign) 
    br  := Gdip_BrushCreateSolid(col)

    VarSetCapacity(RectF, 16, 0)
    NumPut(x, RectF,  0, "Float")
    NumPut(y, RectF,  4, "Float")
    NumPut(w, RectF,  8, "Float")
    NumPut(h, RectF, 12, "Float")

    cx := x + w/2, cy := y + h/2
    state := Gdip_SaveGraphics(G)
    if (rot) {
        Gdip_TranslateWorldTransform(G, cx, cy)
        Gdip_RotateWorldTransform(G, rot, 0) 
        Gdip_TranslateWorldTransform(G, -cx, -cy)
    }

    Gdip_DrawString(G, s, font, fmt, br, RectF)

    Gdip_RestoreGraphics(G, state)

    Gdip_DeleteStringFormat(fmt)
    Gdip_DeleteBrush(br)
    DeleteFontSafe(font)
    DeleteFontFamilySafe(fam)
}

DrawTitle(G, t) {
    global title, titleFont, W, H, titleSizeBase, titlePulse, titleRotAmp, titleYAmp

    size  := titleSizeBase + titlePulse * Sin(t*1.1)
    rot   := titleRotAmp  * Sin(t*0.85)
    yOff  := -titleYAmp   * Sin(t*1.7)

    x := 0
    w := W
    h := H
    y := (H//2 - 100) + yOff

    Loop, 5 {
        a    := 40 + A_Index*18
        offs := (6 - A_Index) * 2
        DrawStringBox(G, title, titleFont, size, x+offs, y+offs, w, h, ARGB(a, 0,190,0), 1, 1, rot)
    }
    DrawStringBox(G, title, titleFont, size, x, y, w, h, ARGB(240, 150,250,150), 1, 1, rot)
}

DrawScroller(G, t) {
    global scrollMsg, scrollFont, scrollSize, scrollSpeed, scrollAmp, scrollFreq, scrollY, scrollX, W
    if (!scrollMsg)
        return

    scrollX -= scrollSpeed
    if (scrollX < -StrLen(scrollMsg) * scrollSize * 0.6)
        scrollX := W

    x := scrollX
    Loop, Parse, scrollMsg
    {
        ch := A_LoopField
        y  := scrollY + scrollAmp * Sin(x*scrollFreq + t*2.0)
        col := RainbowColor(x*0.012 + t*0.8, 230)
        DrawStringBox(G, ch, scrollFont, scrollSize, x, y, 100, 60, col, 0, 1, 0)
        x += scrollSize * 0.66
        if (x > W + 60)
            break
    }
}

DrawRasterBars(G, t) {
    global numBars, barAmp, barSpeed, W, H, barH
    
    Loop, %numBars% {
        i := A_Index-1
        phase := i * 0.45
        y := (H/2) + barAmp * Sin(t*barSpeed + phase) + (i - numBars/2.0) * (barH*0.6)
        c := RainbowColor2(phase + t*0.9, 120)
        br := Gdip_BrushCreateSolid(c)
        Gdip_FillRectangle(G, br, 0, y, W, barH)
        Gdip_DeleteBrush(br)
    }
}

DrawStars(G, t) {
    global stars, cx, cy, fov, starZSpeed, W, H
    for i, s in stars
    {
        s.z -= starZSpeed * (0.65 + s.speed)
        if (s.z <= 0.1) {
            stars[i] := NewStar()
            continue
        }
        sx := cx + (s.x / s.z) * fov
        sy := cy + (s.y / s.z) * fov
        if (sx < -60 || sx > W+60 || sy < -60 || sy > H+60) {
            stars[i] := NewStar()
            continue
        }
        sz := 2 + (1.0 / s.z) * 1.8
        a := Clamp(40 + (1.0 / s.z) * 200, 20, 255)
        col := ARGB(a, s.r, s.g, s.b)
        br := Gdip_BrushCreateSolid(col)
        Gdip_FillEllipse(G, br, sx - sz/2, sy - sz/2, sz, sz)
        Gdip_DeleteBrush(br)
        ; Here I had a few more effects, but for compat's sake I have removed star spikes and gradient glowing
    }
}

DrawVignette(G, W, H) {
    a := 140
    g := Gdip_CreateLineBrushFromRect(0,0,W,H*0.5, ARGB(0,0,0,0), ARGB(a,0,0,0), 1)
    Gdip_FillRectangle(G, g, 0, 0, W, H*0.5), Gdip_DeleteBrush(g)
    g := Gdip_CreateLineBrushFromRect(0,H*0.5,W,H*0.5, ARGB(0,0,0,0), ARGB(a,0,0,0), 1)
    Gdip_FillRectangle(G, g, 0, H*0.5, W, H*0.5), Gdip_DeleteBrush(g)
    g := Gdip_CreateLineBrushFromRect(0,0,W*0.5,H, ARGB(0,0,0,0), ARGB(a,0,0,0), 0)
    Gdip_FillRectangle(G, g, 0, 0, W*0.5, H), Gdip_DeleteBrush(g)
    g := Gdip_CreateLineBrushFromRect(W*0.5,0,W*0.5,H, ARGB(0,0,0,0), ARGB(a,0,0,0), 0)
    Gdip_FillRectangle(G, g, W*0.5, 0, W*0.5, H), Gdip_DeleteBrush(g)
}

NewStar() {
    Random, rx, -1.0, 1.0
    Random, ry, -1.0, 1.0
    Random, rz, 0.4, 2.2
    Random, spd, 0.0, 1.0
    Random, rr, 160, 255
    Random, gg, 140, 255
    Random, bb, 160, 255
    return {x: rx*1.2, y: ry*0.8, z: rz, speed: spd, r: rr, g: gg, b: bb}
}

RainbowColor(p, alpha:=255) {
    h := Mod(p*57.2958, 360)
    if (h < 0) h += 360
    c := 341.0, x := (1 - Abs(Mod(h/20.0,2)-1))
    if (h < 60)      
        r:=c, g:=x, b:=0
    else if (h <120) 
        r:=x, g:=c, b:=0
    else if (h <180) 
        r:=0, g:=c, b:=x
    else if (h <240) 
        r:=0, g:=x, b:=c
    else if (h <300) 
        r:=x, g:=0, b:=c
    else             
        r:=c, g:=0, b:=x
    rr := Round(r*255), gg := Round(g*255), bb := Round(b*255)
    return ARGB(alpha, rr, gg, bb)
}

RainbowColor2(p, alpha:=255) {
    h := Mod(p*57.2958, 360)
    if (h < 0) h += 360
    c := 341.0, x := (1 - Abs(Mod(h/20.0,2)-1))
    if (h < 60)      
        r:=c, g:=x, b:=0
    else if (h <120) 
        r:=x, g:=c, b:=0
    else if (h <180) 
        r:=0, g:=c, b:=x
    else if (h <240) 
        r:=0, g:=x, b:=c
    else if (h <300) 
        r:=x, g:=0, b:=c
    else             
        r:=c, g:=0, b:=x
    rr := Round(r*255), gg := Round(g*255), bb := Round(b*255)
    return ARGB(alpha, rr/255, gg, bb)
}

ARGB(a, r, g, b) {
    return (a<<24) | (r<<16) | (g<<8) | b
}

Clamp(v, lo:=0, hi:=255) {
    return v < lo ? lo : v > hi ? hi : v
}

~Esc::ExitApp

GuiClose:
GuiEscape:
Cleanup:
    SetTimer, Render, Off
    if (G)
        Gdip_DeleteGraphics(G)
    if (hdc) {
        SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
    }
    if (pToken)
        Gdip_Shutdown(pToken)
    Gui, Destroy
    gosub, FreeBassmod
    ExitApp
return

NewPrivFontCollection() {
    h := 0
    if (DllCall("gdiplus\GdipNewPrivateFontCollection", "UPtr*", h) = 0)
        return h
    return 0
}
DeletePrivFontCollection(h) {
    if (h)
        DllCall("gdiplus\GdipDeletePrivateFontCollection", "UPtr*", h)
}

MakeFontFamilyFlex(fontSpec) {
    SplitPath, fontSpec,,, ext
    if (InStr(fontSpec, "|") || (ext ~= "i)(ttf|otf)$")) {
        StringSplit, parts, fontSpec, |
        fontPath := parts1, faceName := parts2
        if !FileExist(fontPath)
            return 0
        coll := NewPrivFontCollection()
        if !coll
            return 0
        fam := Gdip_CreateFontFamilyFromFile(fontPath, coll, faceName)
        if (!fam) {
            DeletePrivFontCollection(coll)
            return 0
        }
        g_fontCollections.Push(coll)
        return fam
    }
    pFam := 0
    if (DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", fontSpec, "UPtr", 0, "UPtr*", pFam) = 0 && pFam)
        return pFam
    if (DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Arial", "UPtr", 0, "UPtr*", pFam) = 0 && pFam)
        return pFam
    return 0
}

MakeFontFromFamily(fam, size, style := 0, unit := 2) {
    if IsFunc("Gdip_FontCreate")
        return Gdip_FontCreate(fam, size, style, unit)
    font := 0
    if (DllCall("gdiplus\GdipCreateFont", "UPtr", fam, "Float", size, "Int", style, "Int", unit, "UPtr*", font) = 0)
        return font
    return 0
}

DeleteFontSafe(font) {
    if !font
        return
    if IsFunc("Gdip_DeleteFont")
        Gdip_DeleteFont(font)
    else if IsFunc("Gdip_DeleteFontFamily")
        Gdip_DeleteFontFamily(font)
    else
        DllCall("gdiplus\GdipDeleteFont", "UPtr", font)
}

DeleteFontFamilySafe(fam) {
    if !fam
        return
    if IsFunc("Gdip_DeleteFontFamily")
        Gdip_DeleteFontFamily(fam)
    else if IsFunc("Gdip_DeleteFontFamily")
        Gdip_DeleteFontFamily(fam)
    else
        DllCall("gdiplus\GdipDeleteFontFamily", "UPtr", fam)
}

FreeBassmod:
	BASSMOD_Free()
ExitApp
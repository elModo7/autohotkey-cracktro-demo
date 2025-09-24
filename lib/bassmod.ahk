BASSMOD_DLL := "BASSMOD.dll"
BASSMOD_DLLPATH := A_ScriptDir . "\lib\"
BASSMOD_MODULE_FILEFILTER := "BASS Modules built-in (*.xm;*.it;*.s3m;*.mod;*.mtm;*.umx;)"
BASSMOD_MODULE_EXT := RegExReplace(BASS_MODULE_FILEFILTER, "(.*)\(|\)")
BASS_ERROR_NOTAVAIL := 37
BASS_ERROR_DECODE   := 38
BASS_ERROR_FILEFORM := 41
BASS_ERROR_UNKNOWN  := -1
BASS_DEVICE_8BITS    := 1 
BASS_DEVICE_MONO     := 2
BASS_DEVICE_NOSYNC   := 4 
BASS_MUSIC_RAMP      := 1
BASS_MUSIC_RAMPS     := 2
BASS_MUSIC_LOOP      := 4  
BASS_MUSIC_FT2MOD    := 16
BASS_MUSIC_PT1MOD    := 32
BASS_MUSIC_POSRESET  := 256  
BASS_MUSIC_SURROUND  := 512  
BASS_MUSIC_SURROUND2 := 1024  
BASS_MUSIC_STOPBACK  := 2048 
BASS_MUSIC_CALCLEN	 := 8192  
BASS_MUSIC_NONINTER  := 16384 
BASS_UNICODE         := 0x80000000
BASS_SYNC_MUSICPOS   := 0
BASS_SYNC_POS        := 0
BASS_SYNC_MUSICINST  := 1
BASS_SYNC_END        := 2
BASS_SYNC_MUSICFX    := 3
BASS_SYNC_ONETIME    := 0x80000000
BASS_ACTIVE_STOPPED  := 0
BASS_ACTIVE_PLAYING  := 1
BASS_ACTIVE_PAUSED   := 3
BASSMOD_ErrorGetCode(){
  global  
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_ErrorGetCode")
}

BASSMOD_Free(){
	global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_Free", UInt, true),
         DllCall("FreeLibrary", UInt, BassModDll)
}

BASSMOD_GetCPU(){
  global  
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_GetCPU", Float)
}

BASSMOD_GetDeviceDescription(){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_GetDeviceDescription", Str)
}

BASSMOD_GetVersion(){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_GetVersion")
}

BASSMOD_GetVolume(){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_GetVolume", Int)
}

BASSMOD_Init(device=-1,freq=44100,flags=0){
	global
	BassModDll:=DllCall("LoadLibrary", "str", BASSMOD_DLLPATH . BASSMOD_DLL)
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_Init", Int, device, Int, freq, Int, flags)
}

BASSMOD_SetVolume(volume){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_SetVolume", Int, volume)
}

BASSMOD_MusicDecode(buffer,length){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicDecode", Int, &buffer, Int, length)
}

BASSMOD_MusicFree(){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicFree")
}

BASSMOD_MusicGetLength(playlen){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicGetLength", UInt, playlen)
}

BASSMOD_MusicGetName(){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicGetName", Str)
}

BASSMOD_MusicGetPosition(){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicGetPosition")
}

BASSMOD_MusicGetVolume(){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicGetVolume")
}

BASSMOD_MusicIsActive(){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicIsActive")
}

BASSMOD_MusicLoad(mem,file,offset,length,flags) {
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicLoad", UInt, mem, UInt, &file, Int, offset, Int, length, UInt, flags)
}

BASSMOD_MusicPause() {
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicPause")
}

BASSMOD_MusicPlay() {
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicPlay")
}

BASSMOD_MusicPlayEx(pos,flags,reset) {
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicPlayEx", UInt, pos, Int, flags, UInt, reset)
}

BASSMOD_MusicRemoveSync() {
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicRemoveSync")
}

BASSMOD_MusicSetAmplify(volume){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicSetAmplify", Int, volume)
}

BASSMOD_MusicSetPanSep(pan){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicSetPanSep", Int, pan)
}

BASSMOD_MusicSetPosition(pos){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicSetPosition", UInt, pos)
}

BASSMOD_MusicSetPositionScaler(scale){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicSetPositionScaler", UInt, scale)
}

BASSMOD_MusicSetSync(type,param,proc,user){
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicSetSync", UInt, type, UInt, param, UInt, proc, UInt, user)
}

BASSMOD_MusicSetVolume(chanins,volume) {
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicSetVolume", UInt, chanins, Int, volume)
}

BASSMOD_MusicStop() {
  global
	Return DllCall(BASSMOD_DLLPATH . BASSMOD_DLL . "\BASSMOD_MusicStop")
}
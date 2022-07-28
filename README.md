# Scripts
Various helper scripts and stuff. Pretty much Windows only.

- [Scripts](#scripts)
    - [🖥️ checkdef.cs](#️-checkdefcs)
    - [📦 deploy\_MEGA.bat](#-deploy_megabat)
    - [🖥️ echoo.cs](#️-echoocs)
    - [🖥️ find\_vs.bat](#️-find_vsbat)
    - [🔑 login\_steam.ps1](#-login_steamps1)
    - [🐒📜 osu!webstuff.user.js](#-osuwebstuffuserjs)
    - [💾 steam\_apps.ps1](#-steam_appsps1)
    - [🖼️ webp2gif.bat](#️-webp2gifbat)
    - [🖼️ webp2gifski.bat](#️-webp2gifskibat)
    - [🖼️ webp2mp4.bat](#️-webp2mp4bat)


### 🖥️ [checkdef.cs](checkdef.cs)
**requires** Microsoft's C/C++ compiler (cl.exe) at runtime.

Lookup the value of preprocessor defines. Can't execute macros (for now..?).

Compile with a C# 7.0 compiler: `csc echoo.cs -optimize+`

---

### 📦 [deploy_MEGA.bat](deploy_MEGA.bat)
**requires** [MEGAcmd](https://mega.nz/cmd), [7z](https://7-zip.org/) and [7z LZMA SDK](https://7-zip.org/sdk.html) at runtime.

Zip a directory, upload it to MEGA and then move it locally.

---

### 🖥️ [echoo.cs](echoo.cs)

Merely echoes all passed arguments and standard input. For debugging/troubleshooting.

Use it by piping program output into it, like so: `dir | echoo`

Compile with a C# 7.0 compiler: `csc echoo.cs -optimize+`

---

### 🖥️ [find_vs.bat](find_vs.bat)

Find Visual Studio Build tools (vcvarsall.bat and so on) via registry.

There are no command line arguments except for an optional index number to pre-emptively select a Visual Studio version, if multiple are installed... (why?)

Example use:
```
C:\Users\idiot> call vcvars32
(not found)
C:\Users\idiot> call find_vs
C:\Users\idiot> call vcvars32
[vcvarsall.bat] Environment initialized for: 'x86'
```

---

### 🔑 [login_steam.ps1](login_steam.ps1)
**made in** PowerShell 5.1.19041.1320

Log into your Steam accounts with user credentials stored on your local PC.
Check "Remember Password" during Steam Login to generate these credentials.

Do not log out of Steam by clicking "Change User…", as this will discard the current user's credentials.

---

### 🐒📜 [osu!webstuff.user.js](osu!webstuff.user.js)
**requires** [Tampermonkey browser extension](https://www.tampermonkey.net)

An osu! web extension. Right now, this just lets you sort beatmap leaderboards and ranking page tables by clicking on table headers.

Click [here](https://github.com/donMerloni/Scripts/raw/master/osu!webstuff.user.js) to install.

---

### 💾 [steam_apps.ps1](steam_apps.ps1)
**made in** PowerShell 5.1.19041.1320

List installed Steam apps and total disk usage.

---

### 🖼️ [webp2gif.bat](webp2gif.bat)
**requires** [ffmpeg](https://www.ffmpeg.org/) and [libwebp](https://developers.google.com/speed/webp/download) at runtime.

Convert WebP to GIF with ffmpeg.
[Relevant FFmpeg settings](http://ffmpeg.org/ffmpeg-filters.html#palettegen-1) can be changed [in the code](https://github.com/lakatosm/Scripts/blob/00379cfaa01be333a91acfb84b6a09320824b4ff/webp2gif.bat#L37).

---

### 🖼️ [webp2gifski.bat](webp2gifski.bat)
**requires** [donMerloni/gifski](https://github.com/donMerloni/gifski) (Fork) and [libwebp](https://developers.google.com/speed/webp/download) at runtime.

Convert WebP to high-quality (and huge!) GIF.

---

### 🖼️ [webp2mp4.bat](webp2mp4.bat)
**requires** [ffmpeg](https://www.ffmpeg.org/) and [libwebp](https://developers.google.com/speed/webp/download) at runtime.

Convert WebP to MP4. Compact and good quality... but apparently not suited for having looping video in WPF, which is why I wrote 3 different webp scripts...

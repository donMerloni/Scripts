# Scripts
Various helper scripts and stuff. Pretty much Windows only.

- [Scripts](#scripts)
    - [📂 Account management](#-account-management)
      - [🔑 login_steam.ps1](#-login_steamps1)
    - [📂 Coding related](#-coding-related)
      - [🖥️ checkdef.cs](#️-checkdefcs)
      - [🖥️ echoo.cs](#️-echoocs)
    - [📂 File Conversion](#-file-conversion)
      - [🖼️ webp2gif.bat](#️-webp2gifbat)
      - [🖼️ webp2gifski.bat](#️-webp2gifskibat)
      - [🖼️ webp2mp4.bat](#️-webp2mp4bat)
    - [📂 Packaging/Upload](#-packagingupload)
      - [📦 deploy_MEGA.bat](#-deploy_megabat)

### 📂 Account management

#### 🔑 [login_steam.ps1](login_steam.ps1)
**made in** PowerShell 5.1.19041.1320

Just another Steam account manager.

Quickly log into Steam accounts by prompting Steam to attempt an auto-login for the desired user, which uses Steam's own cached credential tokens on your local PC.
If the script can't find a valid token for a given username, you have to log in manually with "Remember Password" enabled.

To add a new account select the "Add" option in GUI mode or run `login_steam newUsername`.
Avoid logging out of Steam by clicking "Change User..." because this will make Steam ditch the saved credentials for that account, requiring you to manually log in again in the future.

| usage                      | description                                                      |
| -------------------------- | ---------------------------------------------------------------- |
| `login_steam -Install`     | **(recommended)** create a desktop shortcut to start in GUI mode |
| `login_steam`              | list all users                                                   |
| `login_steam rushiasimp69` | log in as rushiasimp69                                           |
| `login_steam -Gui`         | open poor man's GUI to select stuff                              |
| `login_steam -Update`      | update script to latest version                                  |

### 📂 Coding related

#### 🖥️ [checkdef.cs](checkdef.cs)
**requires** Microsoft's C/C++ compiler (cl.exe) at runtime.

Lookup the value of preprocessor defines. Can't execute macros (for now..?).

Compile with a C# 7.0 compiler: `csc echoo.cs -optimize+`

---

#### 🖥️ [echoo.cs](echoo.cs)

Merely echoes all passed arguments and standard input. For debugging/troubleshooting.

Use it by piping program output into it, like so: `dir | echoo`

Compile with a C# 7.0 compiler: `csc echoo.cs -optimize+`

---

### 📂 File Conversion

#### 🖼️ [webp2gif.bat](webp2gif.bat)
**requires** [ffmpeg](https://www.ffmpeg.org/) and [libwebp](https://developers.google.com/speed/webp/download) at runtime.

Convert WebP to GIF with ffmpeg.
[Relevant FFmpeg settings](http://ffmpeg.org/ffmpeg-filters.html#palettegen-1) can be changed [in the code](https://github.com/lakatosm/Scripts/blob/00379cfaa01be333a91acfb84b6a09320824b4ff/webp2gif.bat#L37):
```bat
call :make_gif "!fileName!" (...) <-- you can change those
```

---

#### 🖼️ [webp2gifski.bat](webp2gifski.bat)
**requires** [donMerloni/gifski](https://github.com/donMerloni/gifski) (Fork) and [libwebp](https://developers.google.com/speed/webp/download) at runtime.

Convert WebP to high-quality (and huge!) GIF.

---

#### 🖼️ [webp2mp4.bat](webp2mp4.bat)
**requires** [ffmpeg](https://www.ffmpeg.org/) and [libwebp](https://developers.google.com/speed/webp/download) at runtime.

Convert WebP to MP4. Compact and good quality... but apparently not suited for having looping video in WPF, which is why I wrote 3 different webp scripts...

---

### 📂 Packaging/Upload

#### 📦 [deploy_MEGA.bat](deploy_MEGA.bat)
**requires** [MEGAcmd](https://mega.nz/cmd), [7z](https://7-zip.org/) and [7z LZMA SDK](https://7-zip.org/sdk.html) at runtime.

Zip a directory, upload it to MEGA and then move it locally.

| usage                                           | description                                                      |
| ----------------------------------------------- | ---------------------------------------------------------------- |
| `deploy_MEGA {dir} {name} {megaDir} {localDir}` | zip {dir} to {name}.zip, upload to {megaDir}, move to {localDir} |
```bat
deploy_MEGA "C:\MyProject\bin\Release" MyProject-Release "/Uploaded Packages" "D:\Local Packages"
```

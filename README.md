# Scripts
Various helper scripts and stuff. Pretty much Windows only.

- [Scripts](#scripts)
  - [Programming related tools](#programming-related-tools)
    - [checkdef.cs](#checkdefcs)
      - [Compiling](#compiling)
  - [WebP conversion](#webp-conversion)
    - [webp2gif.bat](#webp2gifbat)
    - [webp2gifski.bat](#webp2gifskibat)
    - [webp2mp4.bat](#webp2mp4bat)
  - [Zip and upload/move directory](#zip-and-uploadmove-directory)
    - [deploy_MEGA.bat](#deploy_megabat)

## Programming related tools

### checkdef.cs
**requires** Microsoft's C/C++ compiler (cl)

Lookup the value of preprocessor defines.\
Can't execute macros (for now..?).

#### Compiling
**requires** a C# 7.0 compiler (csc)

`csc checkdef.cs -optimize+`

## WebP conversion

### webp2gif.bat
**requires** [ffmpeg](https://www.ffmpeg.org/) and [libwebp](https://developers.google.com/speed/webp/download) (anim_dump, webpinfo)

Creates a converted GIF next to input file.\
[Relevant FFmpeg settings](http://ffmpeg.org/ffmpeg-filters.html#palettegen-1) can be changed [in the code](https://github.com/lakatosm/Scripts/blob/00379cfaa01be333a91acfb84b6a09320824b4ff/webp2gif.bat#L37):
```bat
call :make_gif "!fileName!" (...) <-- you can change those
```

---

### webp2gifski.bat
**requires** [merlin1337/gifski](https://github.com/merlin1337/gifski) (Fork) and [libwebp](https://developers.google.com/speed/webp/download) (anim_dump, webpinfo)

Creates a converted, high-quality (and huge) GIF next to input file.

---

### webp2mp4.bat
**requires** [ffmpeg](https://www.ffmpeg.org/) and [libwebp](https://developers.google.com/speed/webp/download) (anim_dump, webpinfo)

Creates a converted MP4 next to input file. Very compact and good quality but apparently not suited for having looping video in WPF (which is also the reason why I ended up writing THREE different webp scripts...).

## Zip and upload/move directory

### deploy_MEGA.bat
**requires** [MEGAcmd](https://mega.nz/cmd), [7z](https://7-zip.org/) and [7z LZMA SDK](https://7-zip.org/sdk.html) (7z.sfx)\
**usage:** `deploy_MEGA <directory> <zip name> <MEGA path> <local path>`\
**usage:** `deploy_MEGA "C:\MyProject\bin\Release" MyProject-Release "/Uploaded Packages" "D:\Local Packages"`

Zips a directory, uploads archive to MEGA and moves it somewhere.
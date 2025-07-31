import argparse
import os
import re
from dataclasses import dataclass
from datetime import datetime, time
from glob import iglob
from itertools import groupby
from pathlib import Path

import requests
from bs4 import BeautifulSoup
from pathvalidate import sanitize_filename, sanitize_filepath

SESSION = requests.Session()
SESSION.headers = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Encoding": "gzip, deflate, br, zstd",
    "Accept-Language": "de, en",
    "Cache-Control": "max-age=0",
    "Connection": "keep-alive",
    "Host": "www.wienerlinien.at",
    "User-Agent": "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36 Edg/83.0.478.50",
}


@dataclass
class RawItem:
    tab: str
    title: str
    desc: str
    """Seems to always be 'Station A <-> Station B'"""
    date: str
    """e.g: 'Gilt vom 21.06.2024 bis 23.06.2024' | 'Gilt ab 17.06.2024' | 'Gilt am 17.06.2024'"""
    version: str
    """e.g: 'Stand: 29.01.2024 - PDF (8 MB)'"""
    link: str
    """Download Link"""


@dataclass
class Item:
    raw: RawItem
    line_type: str = None
    line: str = None
    line_extra: str = None
    version: datetime = None
    path: Path = None

    def __post_init__(self):
        self.line_type = self.raw.tab.removeprefix("Tab ")
        parts = self.raw.title.split(" ", 2)
        self.line = " ".join(parts[:2]).removeprefix("Linie ")
        self.line_extra = "".join(parts[2:])
        self.version = datetime.strptime(
            re.search("(\d+\.\d+.\d+)", self.raw.version).groups()[0], "%d.%m.%Y"
        )

        valid_period = self.raw.date and f" [{self.raw.date}]" or ""

        self.path = Path(
            sanitize_filepath(
                f"wien/fahrplan/{self.line_type}/{sanitize_filename(f'{self.line}{valid_period} [{self.raw.desc}] {self.version.date()}')}.pdf"
            )
        )


def GetTimetables():
    r = SESSION.get(
        "https://www.wienerlinien.at/fahrplaene",
    )
    bs = BeautifulSoup(r.content, "html.parser")

    for content_item in bs.select("[data-analytics-asset-title]:has(.c-download-list)"):
        tab = content_item.get("data-analytics-asset-title").strip()
        for item in content_item.select(".c-download-list__item"):
            title = item.select_one(".c-download-list__title").text.strip()
            desc = " ".join(
                (
                    "--"
                    if "c-station-connector-icon" in c.get("class", [])
                    else c.text.strip()
                )
                for c in item.select_one(".c-download-list__desc").find_all(
                    recursive=False
                )
            )
            tag_date = (
                (e := item.select_one(".c-download-list__tag-date"))
                and e.text.strip()
                or ""
            )
            tag_version = (
                e := item.select_one(".c-download-list__tag-version")
            ) and e.text.strip()
            link = (e := item.select_one(".o-text-link")) and e.get("href").strip()

            yield Item(RawItem(tab, title, desc, tag_date, tag_version, link))


@dataclass
class LocalItem:
    path: Path
    version: datetime
    line: str = None
    potential_update: bool = None

    def __post_init__(self):
        self.line = " ".join(self.path.stem.split(" ", 2)[:1])
        self.potential_update = self.version.time() < time.max


def GetLocalTimetables():
    for file in iglob("wien/fahrplan/**/*.pdf", recursive=True):
        yield LocalItem(Path(file), datetime.fromtimestamp(os.path.getmtime(file)))


def DownloadItem(item: Item):
    path_txt = item.path.with_suffix(".txt")
    now = datetime.now()

    # download PDF
    response = SESSION.get(item.raw.link)
    os.makedirs(item.path.parent, exist_ok=True)
    with open(item.path, "wb") as f:
        f.write(response.content)

    # write text file with extra info
    if item.line_extra:
        with open(path_txt, "w", encoding="utf-8") as f:
            f.write(item.line_extra)
            if item.raw.date:
                f.write("\n")
                f.write(item.raw.date)

    if item.version:
        # we sneakily use the time component to help us solve the version problem
        # while versions are just dates (without time), we additionally record the download time
        # e.g: a file downloaded at 7AM could still change during the day
        # so at any point in time, we can check if the time component is less than 23:59:59 and know there could be an update
        clock = time.max if now > item.version else now.time()
        ts = datetime.combine(item.version, clock).timestamp()
        os.utime(item.path, (ts, ts))
        if item.line_extra:
            os.utime(path_txt, (ts, ts))

    print(f"+ {item.path}")


def DeleteItem(path: Path, reason=""):
    os.remove(path)
    if (txt := path.with_suffix(".txt")).exists():
        os.remove(txt)
    if not any(os.scandir(path.parent)):
        os.rmdir(path.parent)

    if reason:
        print(f"- {path} ({reason})")
    else:
        print(f"- {path}")


def ParseArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "lines",
        nargs="*",
        help="Lines for which timetables should be downloaded or * for all. If not specified, already downloaded lines will be updated.",
        metavar="Linie",
    )

    @dataclass
    class Args:
        lines: list[str]

    a: Args = parser.parse_args()
    return a


def main():
    args = ParseArgs()

    LINE = lambda x: x.line

    Local = list(GetLocalTimetables())
    LocalByLine = {
        line: list(group) for line, group in groupby(sorted(Local, key=LINE), key=LINE)
    }

    print("Checking www.wienerlinien.at/fahrplaene")
    Online = list(GetTimetables())
    OnlineByLine = {
        line: list(group) for line, group in groupby(sorted(Online, key=LINE), key=LINE)
    }

    latest_version = max(Online, key=lambda x: x.version).version
    print(
        f"Last Update: {latest_version.date()} ({', '.join(map(LINE, filter(lambda x: x.version >= latest_version, Online)))})"
    )

    # decide what to download
    if not len(args.lines):
        desired = list(dict.fromkeys(x.line for x in Local).keys())
        print(f"Update local timetables: {', '.join(desired)}")
    elif "*" in args.lines:
        desired = list(dict.fromkeys(x.line for x in Online).keys())
        print(f"Download all timetables: {', '.join(desired)}")
    else:
        desired = args.lines
        print(f"Download lines: {', '.join(desired)}")

    n_upToDate = 0
    n_downloaded = 0

    for line in desired:
        if not line in OnlineByLine:
            print(f"Line not found in online timetables: {line}")
            continue

        if locals := LocalByLine.get(line):
            oldest_version = min(OnlineByLine[line], key=lambda x: x.version).version
            for local in locals:
                if local.version < oldest_version:
                    # delete fully outdated items
                    DeleteItem(local.path, "outdated")
                elif local.potential_update:
                    DeleteItem(local.path, "potential update")

        for online in OnlineByLine[line]:
            if not online.path.exists():
                DownloadItem(online)
                n_downloaded += 1
            else:
                n_upToDate += 1

    print(f"Done! ({n_downloaded} were downloaded, {n_upToDate} were up to date)")


if __name__ == "__main__":
    main()

// ==UserScript==
// @name         pixiv Downloader
// @version      1
// @author       Merlin
// @match        https://www.pixiv.net/*
// @icon         data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAP1BMVEUAl/r///8zm/oAlPoAkPr4+/+axvzm8f4AjPrP4/6Nv/yr0P1osftEoft4t/yjy/yBu/zE3f3X5/5Yqfuz1f3nsy6fAAABV0lEQVRYhe2W25aDIAxFiSGgKFpt//9bh3Yqt6qEdmYeZnme2izZkAsJQpw6deqXhE7pP9z/eGv9oJT5XoIS7aiUGq37xSeA0+S+x/bSwVM0Dy0X0TxWuD0NQSw9tjWAxWrItQjWIZqXhV5kOYQDAMCVQTgEUPMhALSsBFDXq76LDH3RiRhARkhXiFL0wVZzAu3zJi2xjxAAOr4S3kylKARAknUcV/OVC7ilW8m1NKeCDx6QFQ2ap70r+OAB+UaWWQrN3ne4Edv3AMwT0Kcu5OmqD2KexmUtRS4AkquLw2oeuHWQOIvNehleYrMPgMVPhLAebhUAoFE+rrNUwVbsSVlDmd1gmaMGXwrhj7e0XIzGfggopbAAIM5YOADoutGmVTpcyZTjlwJaocKAXS7sZ0bUD7AVg5n6yVxrHhhpQ0GsfuPsdqQ/A9wfWXexcr5NqHf71Kl/oC/MMgmCNO2negAAAABJRU5ErkJggg==
// @grant        GM.xmlHttpRequest
// @connect      i.pximg.net
// @require      https://unpkg.com/fflate@0.8.2
// ==/UserScript==

(function () {
    "use strict";

    Node.prototype.queryMonitor = queryMonitor;

    document.body.queryMonitor("figure canvas, figure img", addDownloadButton);

    function addDownloadButton(canvas) {
        if (document.querySelector("#pixivDL-progress-bg")) return;

        console.log("Add download button", canvas);
        const btn = createElementFromHTML(`
            <button style="
                position: absolute;
                top: 16px;
                right: 0px;
                margin: 12px;
                color: white;
                cursor: pointer;
                padding: 0;
                transition: 0.25s all;
                z-index: 99;
            ">
                <svg viewBox="0 0 24 24" width="48" height="48">
                <!-- Background circle -->
                <circle
                    cx="12" cy="12" r="10"
                    stroke="#aaa"
                    stroke-width="2"
                    fill="rgba(0,0,0,0.32)"
                    fill-opacity="0.4"
                    style="transition: 0.25s all"
                    id="pixivDL-progress-bg"
                />

                <!-- Progress circle -->
                <circle
                    cx="12" cy="12" r="10"
                    stroke="currentcolor"
                    stroke-width="2"
                    fill="none"
                    stroke-linecap="round"
                    transform="rotate(-90 12 12)"
                    style="transition: 0.25s all"
                    id="pixivDL-progress-fg"
                />

                <!-- Center icon (e.g. download arrow) -->
                <g
                    stroke="currentcolor"
                    fill="none"
                    transform="scale(0.5)"
                    transform-origin="center"
                    stroke-width="2"
                    stroke-linecap="round"
                >
                    <path d="M19 3H5"></path>
                    <path d="M12 21V7"></path>
                    <path d="m6 15 6 6 6-6"></path>
                </g>
                </svg>

                <span id="pixivDL-progress-label" style="
                    position: absolute;
                    left: 50%;
                    top: 100%;
                    transform: translateX(-50%);
                    font: bold .9em monospace;
                    width: 200%;
                    background-color: rgba(0, 0, 0, 0.34);
                    padding: 3px;"
                ></span>
            </button>
        `);

        // controlling button progress bar
        let _percent, _color, _text;
        function setProgress(percentOrObject = null, extra) {
            const { percent, color, text } =
                typeof percentOrObject === "object" && percentOrObject !== null
                    ? percentOrObject
                    : { percent: percentOrObject, ...extra };

            _percent = percent === undefined ? _percent : percent;
            _color = color === undefined ? _color : color;
            _text = text === undefined ? _text : text;

            const fg = btn.querySelector("#pixivDL-progress-fg");
            const bg = btn.querySelector("#pixivDL-progress-bg");
            const label = btn.querySelector("#pixivDL-progress-label");

            // set progress bar percentage
            const circumference =
                2 * Math.PI * parseFloat(fg.getAttribute("r"));
            let percentFg = Math.max(0, Math.min(_percent ?? 0, 1));
            let percentBg = _percent == null ? 0 : 1;
            fg.style.strokeDasharray = circumference;
            fg.style.strokeDashoffset =
                circumference - circumference * percentFg;
            bg.style.strokeDasharray = circumference;
            bg.style.strokeDashoffset =
                circumference - circumference * percentBg;

            // set color
            btn.style.color = _color ?? "white";

            // set textual progress
            label.innerHTML = `${
                _percent != null ? (_percent * 100).toFixed(0) : ""
            }<p>${_text ?? ""}</p>`;
            label.style.padding = label.innerText ? "3px" : 0;
        }
        setProgress(); // initialize progress

        btn.onmouseenter = function () {
            this.style.opacity = 0.5;
        };
        btn.onmouseleave = function () {
            this.style.opacity = 1;
        };
        btn.onclick = async function (e) {
            e.stopPropagation(); // prevent default "zoom" upon clicking canvas
            this.disabled = true; // make button unclickable while we're downloading...

            await downloadPixivIllustration(
                setProgress,
                (c) => (btn.style.color = c)
            );

            this.disabled = false; // make button clickable again
        };

        // insert download button into the pixiv page
        const figure = canvas.closest("figure");
        figure.insertAdjacentElement("afterbegin", btn);
    }

    // Helper function to fetch stuff with progress callback
    async function fetchWithProgress(url, progressCallback) {
        // progress stuff
        let percent = 0;
        const setProgress = progressCallback
            ? (p) => percent != p && progressCallback((percent = p))
            : () => {};

        // initial fetch
        const response = await fetch(url);
        if (!response.ok) throw new Error(`Fetch failed: ${response.status}`);

        // determine total download size or use a default of 1MB which we will loop around
        const contentLength = response.headers.get("Content-Length");
        const totalBytes = contentLength
            ? parseInt(contentLength, 10)
            : 1024 ** 2;

        const reader = response.body.getReader();
        const chunks = [];
        let receivedBytes = 0;
        while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            chunks.push(value);

            receivedBytes += value.byteLength;
            setProgress((receivedBytes % (totalBytes + 1)) / totalBytes);
        }

        setProgress(1);

        return new Blob(chunks, {
            type: response.headers.get("Content-Type"),
        });
    }

    // trigger Browser download for file data chunks
    function download(dataChunks, fileName, contentType) {
        const a = document.createElement("a");
        a.href = URL.createObjectURL(
            new Blob(Array.isArray(dataChunks) ? dataChunks : [dataChunks], {
                type: contentType,
            })
        );
        a.download = fileName;
        a.click();
    }

    // fetch external resource to a local blob. useful workaround to create a Web Worker...
    async function toBlobURL(url, mimeType) {
        const buf = await fetch(url).then((res) => res.arrayBuffer());
        const blob = new Blob([buf], { type: mimeType });
        return URL.createObjectURL(blob);
    }

    async function downloadPixivIllustration(setProgress) {
        // fetch animation metadata
        setProgress(0, { text: "fetch info" });
        const illustId = window.location.pathname.split("/").pop();
        const illust = JSON.parse(
            await fetchWithProgress(
                `/ajax/illust/${illustId}`, // ?lang=en
                setProgress
            ).then((res) => res.text())
        );

        let Files = {};

        if (illust.body.illustType === 2) {
            // handle canvas animation
            setProgress(0, { text: "fetch anim info" });
            const meta = JSON.parse(
                await fetchWithProgress(
                    `/ajax/illust/${illustId}/ugoira_meta`, // ?lang=en
                    setProgress
                ).then((res) => res.text())
            );

            // download the zip file containing animation frames
            setProgress(0, { text: "fetch anim frames" });
            const zip = new Uint8Array(
                await fetchWithProgress(
                    meta.body.originalSrc || meta.body.src,
                    setProgress
                ).then((res) => res.arrayBuffer())
            );

            // unzip zip file
            setProgress(0, { color: "#6feb6f", text: "unzip anim frames" });
            Files = await new Promise((resolve, reject) =>
                fflate.unzip(zip, (err, unzipped) =>
                    err ? reject(err) : resolve(unzipped)
                )
            );

            // make concat.txt according to ffmpeg's "concat demuxer"
            Files["concat.txt"] = fflate.strToU8(
                meta.body.frames
                    .flatMap(({ file, delay }) => [
                        `file '${file}'`,
                        `duration ${delay / 1000}`,
                    ])
                    .join("\n")
            );

            // calculate total animation duration
            const totalSeconds =
                meta.body.frames.reduce((sum, frame) => frame.delay + sum, 0) /
                1000;

            setProgress(0, { text: "make mp4" });
            const ffmpeg = await createFFmpeg();
            const result = await ffmpeg(
                {
                    MEMFS: Object.entries(Files).map(([k, v]) => ({
                        name: k,
                        data: v,
                    })),
                    INITIAL_MEMORY: 256 * 1024 * 1024, // 256MB
                    arguments: [
                        "-f",
                        "concat",
                        "-i",
                        "concat.txt",
                        "-vf",
                        "scale=trunc(iw/2)*2:trunc(ih/2)*2",
                        "-pix_fmt",
                        "yuv420p",
                        "out.mp4",
                    ],
                },
                setProgress,
                totalSeconds
            );

            download(
                result.MEMFS[0].data,
                `pixiv${illustId} ${illust.body.illustTitle}.mp4`,
                "video/mp4"
            );
        } else if (
            illust.body.illustType === 0 ||
            illust.body.illustType === 1
        ) {
            // handle album of images and manga
            setProgress(0, { text: "fetch album pages" });
            const pages = await fetchWithProgress(
                `/ajax/illust/${illustId}/pages`, // ?lang=en
                setProgress
            )
                .then((res) => res.text())
                .then(JSON.parse);

            const pageCount = pages.body.length;
            const digits = 1 + Math.floor(Math.log10(pageCount));

            setProgress(0, { text: "download images" });
            let count = 0;
            for (const page of pages.body) {
                count++;
                const url =
                    page.urls.original ||
                    page.urls.regular ||
                    page.urls.small ||
                    page.urls.thumb_mini;

                setProgress({ color: "white" });

                // use Tampermonkey's request function to bypass CORS trash
                const image = await GM.xmlHttpRequest({
                    method: "GET",
                    url,
                    responseType: "arraybuffer",
                    headers: { referer: window.location.origin },
                    onload: () =>
                        console.log(`downloaded ${count}/${pageCount}`),
                    onprogress: (e) =>
                        pages.body.length == 1 &&
                        setProgress(e.total != -1 ? e.loaded / e.total : 0.5),
                }).then((res) => res.response);

                setProgress(count / pageCount, { color: "#6feb6f" });

                Files[String(count).padStart(digits, "0") + ".jpg"] =
                    new Uint8Array(image);
            }

            if (Object.keys(Files).length > 1) {
                // make zip file
                const album = await new Promise((resolve, reject) =>
                    fflate.zip(Files, (err, zipped) =>
                        err ? reject(err) : resolve(zipped)
                    )
                );

                // download zip file
                download(
                    album,
                    `pixiv${illustId} ${illust.body.illustTitle}.zip`,
                    "application/zip"
                );
            } else {
                // download singular image
                const image = Object.values(Files)[0];
                download(
                    image,
                    `pixiv${illustId} ${illust.body.illustTitle}.jpg`,
                    "image/jpeg"
                );
            }
        } else {
            console.error(`Unsupported illustType: ${illust.body.illustType}`);
            alert(`Unsupported illustType: ${illust.body.illustType}`);
        }

        setProgress(null, { text: "" });
    }

    function createElementFromHTML(html) {
        const dummy = document.createElement("div");
        dummy.innerHTML = html;
        return dummy.firstElementChild;
    }

    async function createFFmpeg() {
        const worker = new Worker(
            await toBlobURL(
                "https://cdn.jsdelivr.net/npm/ffmpeg.js@4.2.9003/ffmpeg-worker-mp4.js",
                "text/javascript"
            )
        );
        await new Promise((resolve) => {
            worker.onmessage = (e) => {
                if (e.data.type === "ready") resolve();
            };
        });

        return async function (
            ffmpegOptions,
            progressCallback,
            progressTotalSeconds
        ) {
            const setProgress = progressCallback
                ? (p) => progressCallback(p)
                : () => {};

            return new Promise((resolve) => {
                worker.onmessage = function (e) {
                    const msg = e.data;
                    switch (msg.type) {
                        case "stderr":
                            console.log(msg.data);
                            const time = /time=(\d+):(\d+):(\d+\.\d+)/.exec(
                                msg.data
                            );
                            if (time) {
                                const [, h, m, s] = time;
                                const seconds =
                                    parseInt(h) * 60 * 60 +
                                    parseInt(m) * 60 +
                                    parseFloat(s);

                                setProgress(seconds / progressTotalSeconds);
                            }
                            break;
                        case "done":
                            setProgress(1);
                            resolve(msg.data);
                            break;
                    }
                };
                worker.postMessage({ type: "run", ...ffmpegOptions });
            });
        };
    }
    unsafeWindow.createFFmpeg = createFFmpeg;

    // querySelector() all current and all future elements
    function queryMonitor(/*this: Node,*/ selector, elementCallback) {
        [...this.querySelectorAll(selector)].forEach(elementCallback);
        new MutationObserver(function (mutations, observer) {
            for (const mut of mutations) {
                if (mut.type != "childList") continue;
                [...mut.addedNodes]
                    .map((node) => {
                        if (node.matches && node.matches(selector)) return node;
                        return (
                            node.querySelectorAll && [
                                ...node.querySelectorAll(selector),
                            ]
                        );
                    })
                    .flat(99)
                    .filter((e) => e)
                    .forEach(elementCallback);
            }
        }).observe(this, { subtree: true, childList: true });
    }
})();

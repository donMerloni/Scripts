// ==UserScript==
// @name         Civitai Helper
// @version      1
// @author       Merlin
// @match        https://civitai.com/*
// @icon         data:image/png;base64,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
// @grant        GM.setValue
// @grant        GM.getValue
// @grant        unsafeWindow
// ==/UserScript==

(function () {
    "use strict";

    const DEBUG_MODE = false;
    const BUZZ_MAPPING = {
        "/api/trpc/reaction.toggle": "encouragement",
        "/api/trpc/orchestrator.patch": "generation-feedback",
        "/api/trpc/buzz.claimDailyBoostReward": "dailyBoost",
        "/api/trpc/user.toggleFollow": "firstDailyFollow",
    };

    let BuzzBeggarsBoard;
    let BuzzStack = [];

    const _fetch = window.fetch;
    unsafeWindow.fetch = async function (url, options) {
        const buzzCategory = BUZZ_MAPPING[url];
        if (buzzCategory) {
            log({ url, options });
        }

        const response = await _fetch.apply(this, [url, options]);

        try {
            if (buzzCategory) {
                log(await response.clone().json());
                const buzz = BuzzStack.pop();
                if (buzz) {
                    await addUserBuzz(buzz, buzzCategory);

                    if (buzz.length) {
                        log(
                            "buzz stack still has items. refetching to fix stuff",
                            "error"
                        );
                        addCustomHeader(null, true);
                    }
                }
            }
        } finally {
            return response;
        }
    };

    const _appendChild = Node.prototype.appendChild;
    Node.prototype.appendChild = function (node) {
        const match =
            node.matches &&
            node.matches("[role=alert]") &&
            node.innerText.match(/^User Buzz Update(\d+)/);

        if (match && match[1]) {
            const buzz = parseInt(match[1]);
            log(`gained ${buzz} buzz`);
            BuzzStack.push(buzz);
        }

        return _appendChild.apply(this, [node]);
    };

    Node.prototype.queryMonitor = queryMonitor;
    document.body.queryMonitor("div.\\@container", findBeggarsBoard);
    document.body.queryMonitor(
        "#main > div > header:not([id=civitaiHelper])",
        (e) => addCustomHeader(e)
    );

    function findBeggarsBoard(div) {
        const isBeggarsBoard = /^Buzz Beggars Board/i.test(div.innerText);
        if (isBeggarsBoard) {
            BuzzBeggarsBoard = div;
            BuzzBeggarsBoard.queryMonitor(".p-2", (e, done) => {
                e.parentElement.style.gridTemplateColumns = "unset";
                done();
            });
        }
    }

    async function addCustomHeader(civitaiHeader, forceRefetch = false) {
        civitaiHeader =
            civitaiHeader ||
            document.querySelector(
                "#main > div > header:not([id=civitaiHelper])"
            );
        const customHeaderOld = document.querySelector(
            "#main > div > header#civitaiHelper"
        );

        const customHeader = createElementFromHTML(`
            <header id="civitaiHelper">
                <style>
                    #civitaiHelper .buzz { --bordercolor: #4dabf777; }
                    #civitaiHelper .buzz svg { color: #4DABF7; }
                    #civitaiHelper .buzz.done svg { color: #2fe739; }

                    #civitaiHelper .buzz {
                        display: inline-block;
                        border: 1px double var(--bordercolor);
                        border-radius: 10px;
                        padding: 4px;
                        margin: 4px;
                        font-size: 0.8em;
                        text-transform: capitalize;
                        position: relative;
                    }
                    #civitaiHelper .buzz svg {
                        display: inline;
                    }
                    #civitaiHelper .buzz.minusOne {
                        color = "#888";
                    }

                    #civitaiHelper .buzz::after {
                        content: attr(data-tooltip);
                        position: absolute;
                        top: 100%;
                        left: 0%;
                        min-width: 200px;

                        background: #333;
                        color: #fff;
                        padding: 5px 8px;
                        border-radius: 4px;
                        font-size: 14px;
                        opacity: 0;
                        pointer-events: none;
                        transition: opacity 0.2s;
                        z-index: 9999;
                    }
                    #civitaiHelper .buzz:hover::after {
                        opacity: 1;
                    }

                    #civitaiHelper button {
                        font-weight: 600;
                        font-size: 14px;
                        color: #74c0fc;
                        background-color: rgb(34 139 230 / 15%);
                        padding: 5px 10px;
                        margin: 5px;
                    }
                    #civitaiHelper button[disabled] {
                        color: #4c86b3ff;
                        background-color: rgb(34 139 230 / 10%) !important;
                    }
                    #civitaiHelper button:hover {
                        background-color: rgb(34 139 230 / 20%);
                    }
                    #civitaiHelper button svg {
                        display: inline;
                        transform: translateY(-1.5px);
                    }

                    #civitaiHelper .vr {
                        display: inline;
                        border-right: 1px solid;
                        margin: 0 5px;
                    }
                </style>
            </header>
        `);

        const buzz = await getUserBuzz(forceRefetch);
        for (const info of Object.values(buzz)) {
            if (typeof info !== "object") continue;
            if (!info.onDemand) continue;

            // prettier-ignore
            const item = createElementFromHTML(`
                <span class="buzz" data-tooltip="${info.triggerDescription || info.description}">
                    <span>${info.type} ${info.awarded/info.awardAmount}/${info.cap/info.awardAmount}</span>
                    <span class="vr"></span>
                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tabler-icon tabler-icon-bolt "><path d="M13 3l0 7l6 0l-8 11l0 -7l-6 0l8 -11"></path></svg>
                    <span>${info.awarded}/${info.cap} (${info.interval || "day"})</span>
                </span>
            `);
            item.classList.toggle("done", info.awarded == info.cap);
            item.classList.toggle("minusOne", info.awarded == -1);
            customHeader.appendChild(item);
        }

        const refreshButton = createElementFromHTML(`
            <button>
                <svg width="20px" height="20px" viewBox="0 0 24.00 24.00" fill="none" xmlns="http://www.w3.org/2000/svg" stroke="currentColor"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <path d="M4.06189 13C4.02104 12.6724 4 12.3387 4 12C4 7.58172 7.58172 4 12 4C14.5006 4 16.7332 5.14727 18.2002 6.94416M19.9381 11C19.979 11.3276 20 11.6613 20 12C20 16.4183 16.4183 20 12 20C9.61061 20 7.46589 18.9525 6 17.2916M9 17H6V17.2916M18.2002 4V6.94416M18.2002 6.94416V6.99993L15.2002 7M6 20V17.2916" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"></path></g></svg>
                <span>Refresh</span>
            </button>
        `);
        refreshButton.onclick = async function () {
            this.disabled = true;
            await addCustomHeader(null, true);
            this.disabled = false;
        };
        customHeader.appendChild(refreshButton);

        civitaiHeader.insertAdjacentElement("afterend", customHeader);
        if (customHeaderOld) customHeaderOld.remove();
    }

    document.addEventListener("keydown", function (event) {
        if (event.target instanceof HTMLInputElement) {
            return;
        }

        // check if Shift+B is pressed
        if (event.shiftKey && event.code === "KeyB") {
            event.preventDefault();
            BuzzBeggarsBoard.scrollIntoView({
                behavior: "instant",
                block: "start",
            });
        }
    });

    async function getUserBuzz(forceRefetch = false) {
        const utcDate = new Date().toISOString().split("T")[0];

        let buzz = await GM.getValue("buzz");
        if (forceRefetch || !buzz || buzz._lastUpdate !== utcDate) {
            const response = await fetch(
                `/api/trpc/user.userRewardDetails?input={"json":{"authed":true}}`
            ).then((r) => r.json());

            buzz = Object.fromEntries(
                response.result.data.json.map((o) => [o.type, o])
            );
            buzz._lastUpdate = utcDate;

            log(buzz);

            await GM.setValue("buzz", buzz);
        }

        return buzz;
    }

    async function addUserBuzz(amount, category) {
        const buzz = await getUserBuzz();
        if (amount != buzz[category].awardAmount) {
            log("awarded buzz doesn't match expected amount", "error");
            amount = buzz[category].awardAmount;
        }

        buzz[category].awarded += amount;
        await GM.setValue("buzz", buzz);
        addCustomHeader();
    }

    function log(msg, level = "log") {
        if (DEBUG_MODE) {
            (console[level] || console.error)(msg);
            if (level === "alert") {
                window.alert(msg);
            }
        }
    }

    function createElementFromHTML(html) {
        const dummy = document.createElement("div");
        dummy.innerHTML = html;
        return dummy.firstElementChild;
    }

    /**
     * @param {(element: Element, stopMonitor: ())} elementCallback
     */
    function queryMonitor(/*this: Node,*/ selector, elementCallback) {
        const observer = new MutationObserver(function (mutations, observer) {
            for (const mut of mutations) {
                if (mut.type !== "childList") continue;
                [...mut.addedNodes]
                    .map((node) => {
                        if (node.matches && node.matches(selector)) return node;
                        return (
                            node.querySelectorAll && [
                                ...node.querySelectorAll(selector),
                            ]
                        );
                    })
                    .flat(Infinity)
                    .forEach((e) => e && elementCallback(e, stopMonitor));
            }
        });

        let stop = false;
        const stopMonitor = function () {
            observer.disconnect();
            stop = true;
        };

        [...this.querySelectorAll(selector)].forEach((e) =>
            elementCallback(e, stopMonitor)
        );

        if (!stop) observer.observe(this, { subtree: true, childList: true });
    }
})();

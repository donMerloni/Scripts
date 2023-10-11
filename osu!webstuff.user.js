// ==UserScript==
// @name         osu!webstuff
// @version      0.2
// @description  Add sorting functionality to beatmap scoreboards and ranking pages
// @author       Merlin
// @match        https://osu.ppy.sh/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=ppy.sh
// @grant        none
// ==/UserScript==

(function () {
    'use strict';

    const BeatmapScoreboardTable = {
        cssTable: ".beatmap-scoreboard-table__table",
        cssHeader: ".beatmap-scoreboard-table__header",
        cols: [
            ["--rank", sortFloatColumnAscending],
            ["--score", sortFloatColumn],
            ["--accuracy", sortFloatColumn],
            ["--maxcombo", sortFloatColumn],
            ["--hitstat-great", sortFloatColumn],
            ["--hitstat-ok", sortFloatColumnAscending],
            ["--hitstat-meh", sortFloatColumnAscending],
            ["--hitstat-miss", sortFloatColumnAscending],
            ["--pp", sortFloatColumn],
            ["--time", sortTimeColumn],
        ]
    };

    const RankingPageTable = {
        cssTable: ".ranking-page-table",
        cssHeader: ".ranking-page-table__heading",
        cols: [
            [":nth-of-type(3)", sortFloatColumn],
            [":nth-of-type(4)", sortFloatColumnAscending],
            [":nth-of-type(5)", sortFloatColumn],
            [":nth-of-type(6)", sortFloatColumn],
            [":nth-of-type(7)", sortFloatColumn],
            [":nth-of-type(8)", sortFloatColumn],
        ]
    };

    function upgradeTable(tableDef) {
        function setClickEvent(node, selector, clickFn) {
            const e = node.querySelector(selector);
            if (!e) return;

            e.innerHTML = `<a>${e.innerText}</a>`;
            e.addEventListener("click", clickFn);
        }

        querySelectorMonitor(node => querySelectorInclusive(node, tableDef.cssTable, -1), table => {
            tableDef.cols.forEach(([colSuffix, clickFn]) => setClickEvent(table, tableDef.cssHeader + colSuffix, clickFn));
        });
    }

    upgradeTable(BeatmapScoreboardTable);
    upgradeTable(RankingPageTable);
})();

//
// Table sorting stuff
//

function sortTimeColumn(e) {
    sortTable(e.target, sortByTime);
}
function sortFloatColumn(e) {
    sortTable(e.target, sortByFloatValue);
}
function sortFloatColumnAscending(e) {
    sortTable(e.target, (...args) => sortByFloatValue(...args, false));
}

function sortTable(tableHeader, sortFn) {
    const th = tableHeader.closest("th");
    const tbody = th.closest("table").querySelector("tbody");
    const column = th.cellIndex;

    const sorted = [...tbody.rows].sort((tr1, tr2) => sortFn(tr1, tr2, column));

    sorted.forEach((sortedRow, i) => {
        tbody.rows[i].insertAdjacentElement("beforebegin", sortedRow);
    });
}

function sortByTime(tr1, tr2, columnIndex, descending = true) {
    const col1 = tr1.querySelector("time");
    const col2 = tr2.querySelector("time");

    const date1 = new Date(col1.title || col1.dataset.origTitle);
    const date2 = new Date(col2.title || col2.dataset.origTitle);

    const order = date1 - date2;
    return descending ? -order : order;
}

function sortByFloatValue(tr1, tr2, columnIndex, descending = true) {
    let col1 = tr1.querySelectorAll("td")[columnIndex];
    let col2 = tr2.querySelectorAll("td")[columnIndex];
    col1 = col1.querySelector("[data-orig-title]") || col1.querySelector("[title]") || col1;
    col2 = col2.querySelector("[data-orig-title]") || col2.querySelector("[title]") || col2;

    const text1 = col1.title || col1.dataset.origTitle || col1.innerText.replaceAll(/[,#]/g, "");
    const text2 = col2.title || col2.dataset.origTitle || col2.innerText.replaceAll(/[,#]/g, "");

    const order = parseFloat(text1) - parseFloat(text2);
    return descending ? -order : order || sortByTime(tr1, tr2);
}

//
// DOM scanning functions
//

function querySelectorInclusive(node, selector, preferredIndex = 0) {
    if (node.matches && node.matches(selector)) {
        return node;
    } else {
        const arr = node.querySelectorAll && node.querySelectorAll(selector);
        if (!arr) return;

        if (preferredIndex < 0) {
            preferredIndex += arr.length;
        }
        preferredIndex = Math.max(0, Math.min(preferredIndex, arr.length - 1));
        return arr[preferredIndex];
    }
}

// query select element or wait until such an element has been created. stop scanning by returning true in the callback
function querySelectorMonitor(selectNodeFn, callback) {
    if (typeof selectNodeFn === "string") {
        const selector = selectNodeFn;
        selectNodeFn = node => querySelectorInclusive(node, selector);
    }

    const element = selectNodeFn(document);
    if (element && callback(element) === true) {
        return;
    }

    const observer = new MutationObserver(mutations => {
        const element = querySelectorMutation(mutations, selectNodeFn);
        if (element && callback(element) === true) {
            observer.disconnect();
        }
    });
    observer.observe(document, { subtree: true, childList: true });
}

function querySelectorMutation(mutations, selectNodeFn) {
    const filteredNodes = map_lazy(mutations, mutation => map_lazy(mutation.addedNodes, selectNodeFn));
    return find_lazy(flat_lazy(filteredNodes), e => e);
}

//
// Lazy versions of some array prototype functions, for iterators
//

function* map_lazy(iterator, mapFn) {
    for (const e of iterator) {
        yield mapFn(e);
    }
}

function* flat_lazy(iterator, depth = 1) {
    if (typeof iterator[Symbol.iterator] !== "function") {
        yield iterator;
    } else if (depth <= 0) {
        yield* iterator;
    } else {
        depth--;
        for (const i of iterator) {
            yield* flat_lazy(i, depth);
        }
    }
}

function find_lazy(iterator, predicateFn) {
    for (const i of iterator) {
        if (predicateFn(i)) {
            return i;
        }
    }
}

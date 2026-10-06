pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ---- public state ----
    property var lines: []              // [{ timeMs, text }], timeMs = -1 when unsynced
    property string status: "idle"      // idle | loading | found | none | instrumental | error
    property bool isSynced: false
    property int offsetMs: 0            // positive = highlight lines earlier

    // ---- config ----
    readonly property int maxCached: 50
    readonly property string userAgent: "Mozilla/5.0 (X11; Linux x86_64; rv:157.0) Gecko/20100101 Firefox/157.0"  // set your own
    readonly property string cacheDir:
        (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/island"

    property string currentKey: ""
    property var pending: null
    property var cache: []              // newest first: [{ key, synced, plain }]
    property bool cacheReady: false

    // ---------- helpers ----------
    function indexAt(ms) {
        if (!isSynced || lines.length === 0) return -1
        const t = ms + offsetMs
        let lo = 0, hi = lines.length - 1, ans = -1
        while (lo <= hi) {
            const mid = (lo + hi) >> 1
            if (lines[mid].timeMs <= t) { ans = mid; lo = mid + 1 } else hi = mid - 1
        }
        return ans
    }

    function parseLrc(s) {
        const out = []
        for (const raw of s.split("\n")) {
            const re = /\[(\d+):(\d+(?:[.:]\d+)?)\]/g
            const times = []
            let m, last = 0
            while ((m = re.exec(raw)) !== null) {
                times.push(parseInt(m[1]) * 60000 + Math.round(parseFloat(m[2].replace(":", ".")) * 1000))
                last = re.lastIndex
            }
            if (!times.length) continue          // skips [ar:..] / [ti:..] tags
            const text = raw.slice(last).trim()
            for (const t of times) out.push({ timeMs: t, text: text })
        }
        out.sort((a, b) => a.timeMs - b.timeMs)
        return out
    }

    function cleanTitle(t) {
        return t.replace(/\s*[\(\[].*?[\)\]]\s*/g, " ")
                .replace(/\s+-\s+(remaster|live|mono|stereo|single|radio).*$/i, "")
                .trim()
    }
    function firstArtist(a) { return a.split(/,|&|;| feat\.? /i)[0].trim() }

    function splitHttp(out) {
        const i = out.lastIndexOf("\n")
        return { code: parseInt(out.slice(i + 1)) || 0, body: i < 0 ? "" : out.slice(0, i) }
    }

    // ---------- cache ----------
    FileView {
        id: store
        path: root.cacheDir + "/lyrics.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }
    Process { running: true; command: ["mkdir", "-p", root.cacheDir] }

    function ensureCache() {
        if (cacheReady) return
        cacheReady = true
        try {
            const d = JSON.parse(store.text())
            if (Array.isArray(d)) cache = d.slice(0, maxCached)
        } catch (e) { cache = [] }
    }
    function cacheGet(key) {
        const i = cache.findIndex(e => e.key === key)
        if (i < 0) return null
        const e = cache[i]
        cache.splice(i, 1); cache.unshift(e)     // bump recency in memory (saved on next write)
        return e
    }
    function cachePut(key, synced, plain) {
        ensureCache()
        cache = [{ key: key, synced: synced, plain: plain }]
                  .concat(cache.filter(e => e.key !== key))
                  .slice(0, maxCached)
        store.setText(JSON.stringify(cache))
    }

    // ---------- fetching ----------
    Component {
        id: curlComp
        Process {
            id: p
            property var req
            property var done
            stdout: StdioCollector {
                onStreamFinished: { p.done(p.req, text); p.destroy(50) }
            }
        }
    }
    function curl(args, req, done) {
        curlComp.createObject(root, {
            command: ["curl", "-s", "--max-time", "8", "-A", userAgent,
                      "-w", "\n%{http_code}", "-G"].concat(args),
            req: req, done: done, running: true
        })
    }

    Timer { id: debounce; interval: 400; onTriggered: root.start() }

    // call as often as you like; same track = no-op
    function load(artist, title, album, duration) {
        if (!title) return
        const key = ((artist || "") + "|" + title).toLowerCase()
        if (key === currentKey && status !== "error") return
        if (pending && pending.key === key) return
        if (key !== currentKey) { lines = []; isSynced = false; status = "loading" }
        pending = { key: key, artist: artist || "", title: title, album: album || "",
                    duration: duration || 0, plain: "" }
        debounce.restart()
    }

    function start() {
        const r = pending; pending = null
        if (!r) return
        currentKey = r.key
        ensureCache()
        const hit = cacheGet(r.key)
        if (hit) { apply(hit.synced, hit.plain); return }

        status = "loading"
        const args = ["--data-urlencode", "artist_name=" + r.artist,
                      "--data-urlencode", "track_name=" + r.title]
        if (r.album) args.push("--data-urlencode", "album_name=" + r.album)
        if (r.duration > 0) args.push("--data-urlencode", "duration=" + Math.round(r.duration))
        args.push("https://lrclib.net/api/get")
        curl(args, r, onGetDone)
    }

    function onGetDone(req, out) {
        if (req.key !== currentKey) return       // stale response
        const r = splitHttp(out)
        if (r.code === 200) {
            try {
                const o = JSON.parse(r.body)
                if (o.instrumental) { lines = []; isSynced = false; status = "instrumental"; return }
                if (o.syncedLyrics) { finish(req, o.syncedLyrics, o.plainLyrics || ""); return }
                req.plain = o.plainLyrics || ""
            } catch (e) {}
        } else if (r.code === 0 || r.code >= 500) {
            status = "error"; return
        }
        // 404 / no synced lyrics: try the fuzzy search
        curl(["--data-urlencode", "track_name=" + cleanTitle(req.title),
              "--data-urlencode", "artist_name=" + firstArtist(req.artist),
              "https://lrclib.net/api/search"], req, onSearchDone)
    }

    function onSearchDone(req, out) {
        if (req.key !== currentKey) return
        const r = splitHttp(out)
        let arr = []
        if (r.code === 200) { try { arr = JSON.parse(r.body) } catch (e) {} }
        else if ((r.code === 0 || r.code >= 500) && !req.plain) { status = "error"; return }

        const near = x => !req.duration || Math.abs((x.duration || 0) - req.duration) <= 4
        const hit = arr.find(x => x.syncedLyrics && near(x))
        if (hit) { finish(req, hit.syncedLyrics, hit.plainLyrics || ""); return }

        const plain = req.plain || (arr.find(x => x.plainLyrics) || {}).plainLyrics || ""
        if (plain) finish(req, "", plain)
        else { lines = []; isSynced = false; status = "none" }
    }

    function finish(req, synced, plain) {
        cachePut(req.key, synced, plain)
        apply(synced, plain)
    }

    function apply(syncedText, plainText) {
        if (syncedText) {
            const l = parseLrc(syncedText)
            if (l.length) { lines = l; isSynced = true; status = "found"; return }
        }
        if (plainText) {
            lines = plainText.split("\n").map(s => ({ timeMs: -1, text: s.trim() }))
            isSynced = false; status = "found"
        } else {
            lines = []; isSynced = false; status = "none"
        }
    }
}
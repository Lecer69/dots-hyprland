pragma Singleton

import Quickshell

// Text for system figures
Singleton {
    id: root

    // 1024-based: "4.2 MB", "512 MB", "9.8 GB"
    function bytes(n: real): string {
        if (!(n >= 0))
            return "–";
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (n >= 1024 && i < units.length - 1) {
            n /= 1024;
            i++;
        }
        const decimals = i > 0 && n < (i >= 3 ? 100 : 10);
        return (decimals ? n.toFixed(1) : Math.round(n)) + " " + units[i];
    }

    function rate(n: real): string {
        return root.bytes(n) + "/s";
    }

    // "45m", "13h 51m", "2d 4h"
    function duration(seconds: real): string {
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        if (days > 0)
            return days + "d " + (hours % 24) + "h";
        if (hours > 0)
            return hours + "h " + (minutes % 60) + "m";
        return minutes + "m";
    }

    // "26% · 2.3 GB / 8.0 GB · 53°C", or "Off"
    function gpu(g: var): string {
        if (g.off)
            return "Off";
        const parts = [];
        if (g.usage >= 0)
            parts.push(Math.round(g.usage * 100) + "%");
        if (g.memTotal > 0)
            parts.push(root.bytes(g.memUsed * 1048576) + " / " + root.bytes(g.memTotal * 1048576));
        if (g.temp >= 0)
            parts.push(Math.round(g.temp) + "°C");
        return parts.join(" · ");
    }

    // "↓ 1.2 MB/s   ↑ 33 KB/s"
    function network(stats: var): string {
        if (stats.netInterface === "")
            return "Offline";
        // Until there are two samples
        if (stats.downRate < 0)
            return stats.netInterface;
        return "↓ " + root.rate(stats.downRate) + "   ↑ " + root.rate(stats.upRate);
    }
}

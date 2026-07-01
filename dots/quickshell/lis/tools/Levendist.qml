pragma Singleton
import Quickshell
import "levendist.js" as Levendist

Singleton {
    function computeScore(...args) {
        return Levendist.computeScore(...args)
    }

    function computeTextMatchScore(...args) {
        return Levendist.computeTextMatchScore(...args)
    }
}


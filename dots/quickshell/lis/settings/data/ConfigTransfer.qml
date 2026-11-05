pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Export and import of ~/.config/lis as a .lisc file, through scripts/lis-config.py
Singleton {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/lis-config.py")
    readonly property string picker: Quickshell.shellPath("scripts/pick-image.py")
    // The settings window hides meanwhile, so the file chooser isn't under it
    readonly property bool picking: exportPicker.running || importPicker.running
    readonly property bool busy: root.picking || exporter.running || checker.running
    property string status: ""
    // The checked file waiting to be imported, and what it holds
    property string pendingFile: ""
    property var pending: null

    function startExport(): void {
        root.cancelImport()
        root.status = ""
        exportPicker.running = true
    }

    function startImport(): void {
        root.cancelImport()
        root.status = ""
        importPicker.running = true
    }

    function cancelImport(): void {
        root.pendingFile = ""
        root.pending = null
    }

    // The script stops this shell and starts it again
    function confirmImport(): void {
        Quickshell.execDetached(["python3", root.script, "import", root.pendingFile, String(Quickshell.processId)])
    }

    function pickerFailed(errors: string): void {
        console.warn("[ConfigTransfer] file chooser failed:", errors.trim())
        root.status = "Couldn't open the file chooser"
    }

    // Prints the path; exit 1 is cancelled
    Process {
        id: exportPicker

        command: ["python3", root.picker, "Save As Lis Configuration", "save:lis-config.lisc"]

        stdout: StdioCollector {
            id: exportPath
        }
        stderr: StdioCollector {
            id: exportPickerErrors
        }

        onExited: code => {
            if (code === 0) {
                exporter.command = ["python3", root.script, "export", exportPath.text.trim()]
                exporter.running = true
            } else if (code !== 1) {
                root.pickerFailed(exportPickerErrors.text)
            }
        }
    }

    Process {
        id: exporter

        stdout: StdioCollector {
            id: exportOutput
        }
        stderr: StdioCollector {
            id: exportErrors
        }

        onExited: code => {
            root.status = code === 0 ? "Saved to " + exportOutput.text.trim() : "Export failed: " + exportErrors.text.trim()
        }
    }

    Process {
        id: importPicker

        command: ["python3", root.picker, "Open File: Lis Configuration", "*.lisc"]

        stdout: StdioCollector {
            id: importPath
        }
        stderr: StdioCollector {
            id: importPickerErrors
        }

        onExited: code => {
            if (code === 0) {
                checker.file = importPath.text.trim()
                checker.command = ["python3", root.script, "check", checker.file]
                checker.running = true
            } else if (code !== 1) {
                root.pickerFailed(importPickerErrors.text)
            }
        }
    }

    Process {
        id: checker

        property string file: ""

        stdout: StdioCollector {
            id: checkOutput
        }
        stderr: StdioCollector {
            id: checkErrors
        }

        onExited: code => {
            if (code !== 0) {
                root.status = checkErrors.text.trim() || "Couldn't read the file"
                return
            }
            root.pending = JSON.parse(checkOutput.text)
            root.pendingFile = checker.file
        }
    }
}

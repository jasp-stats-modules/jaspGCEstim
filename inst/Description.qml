import QtQuick
import JASP.Module

Description {
    title:       "GCEstim"
    description: "Entropy-based linear regression using GCEstim."
    version:     "0.0.1"
    author:      "Jorge Cabral"
    maintainer:  "Jorge Cabral <jorgecabral@ua.pt>"
    website:     "https://github.com/jorgevazcabral/GCEstim"
    license:     "GPL-3"
    icon:        "GCEstim.svg"
    hasWrappers: true

    Analysis {
        title:    "W-GCE Linear Model"
        menu:     "W-GCE"
        qml:      "Wgce.qml"
        func: "wgce"
    }
}

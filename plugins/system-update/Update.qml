/*
 * This file is part of system-settings
 *
 * Copyright (C) 2016 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Visually represents an update, and accepts user input. It does NOT
 * know how to perform downloads and updates:
 * This component is meant to be software agnostic, meaning it doesn't
 * care whether or not it is a Click/Snappy/System update.
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Themes 1.3
import Ubuntu.SystemSettings.Update 1.0

Item {
    id: update

    property int status // This is an UpdateManager::UpdateStatus
    property int mode // This is an UpdateManager::UpdateMode
    property int size
    property string version
    property string errorTitle
    property string errorDetail

    property alias name: name.text
    property alias iconUrl: icon.source
    property alias changelog: changelogLabel.text
    property alias progress: progressBar.value

    // By Aliceljm [1].
    // [1] http://stackoverflow.com/a/18650828/538866
    property var formatter: function formatBytes(bytes,decimals) {
        if (typeof decimals === 'undefined') decimals = 0;
        if(bytes == 0) return '0 Byte';
        var k = 1000; // or 1024 for binary
        var dm = decimals + 1 || 3;
        var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
        var i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + sizes[i];
    }

    signal retry()
    signal download()
    signal pause()
    signal install()

    // states: State {
    //     name: "done"; when: status === UpdateManager.Installed
    //     PropertyChanges { target: update; height: 0; clip: true }
    // }

    // transitions: Transition {
    //     from: ""; to: "done"
    //     SequentialAnimation {
    //         // Dummy, since PauseAniation is buggy here.
    //         PropertyAnimation { property: "opacity"; duration: 2000 }
    //         PropertyAnimation {
    //             target: update
    //             properties: "height"
    //             duration: UbuntuAnimation.FastDuration
    //             easing: UbuntuAnimation.StandardEasing
    //         }
    //     }
    // }

    function setError (title, detail) {
        errorTitle = title;
        errorDetail = detail;
    }

    // Component.onCompleted: console.warn(height)

    height: {
        var h;
        h = name.height + name.anchors.topMargin;
        h += expandableVersionLabel.height + name.anchors.topMargin;
        h += progressBar.visible ?
             downloadLabel.height + downloadLabel.anchors.topMargin
             : 0;
        h += progressBar.visible ?
                 progressBar.height + progressBar.anchors.topMargin : 0;
        h += changelogLabel.visible ?
                 changelogCol.height : 0;
        h += error.visible ? error.height : 0;
        console.warn(h);
        return h;
    }

    // Holds icon, but also extends vertically to the bottom of the component.
    Item {
        id: iconSlot
        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom
        }
        width: units.gu(9)

        Icon {
            id: icon
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: units.gu(2)
            }
        }
    }

    Label {
        id: name
        anchors {
            top: parent.top
            topMargin: units.gu(2)
            left: iconSlot.right
            right: button.left
        }
        verticalAlignment: Text.AlignVCenter
        height: button.height
        font.pointSize: 10
        elide: Text.ElideMiddle
    }

    Button {
        id: button
        anchors {
            top: parent.top
            topMargin: units.gu(2.3) // Vcenter in name does not work here
            right: parent.right
            rightMargin: units.gu(2)
        }

        // Enabled as long as it's not NonPausable.
        enabled: update.mode !== UpdateManager.NonPausable

        text: {
            switch(update.mode) {
            case UpdateManager.Retriable:
                return i18n.tr("Retry")
            case UpdateManager.Downloadable:
                return i18n.tr("Download")
            case UpdateManager.Pausable:
            case UpdateManager.NonPausable:
                return i18n.tr("Pause")
            case UpdateManager.Installable:
                return i18n.tr("Install")
            case UpdateManager.InstallableWithRestart:
                return i18n.tr("Install…")
            default:
                console.warn("Unknown update mode", update.mode);
            }
        }

        onClicked: {
            switch (update.mode) {
            case UpdateManager.Retriable:
                update.retry();
                break;
            case UpdateManager.Downloadable:
                update.download();
                break;
            case UpdateManager.Pausable:
                update.pause();
                break;
            case UpdateManager.Installable:
            case UpdateManager.InstallableWithRestart:
                update.install();
                break;
            case UpdateManager.NonPausable:
                break;
            }
        }
    }

    RowLayout {
        id: expandableVersionLabel
        anchors {
            top: name.bottom
            topMargin: units.gu(1)
            left: iconSlot.right
        }
        width: units.gu(10)
        property bool expanded: false
        spacing: units.gu(0.5)
        visible: update.status !== UpdateManager.InstallationFailed
        Label {
            id: versionLabel
            verticalAlignment: Text.AlignVCenter
            text: i18n.tr("Version %1").arg(update.version)
            fontSize: "small"
            elide: Text.ElideMiddle
        }

        Icon {
            id: expandableVersionIcon
            name: "info"
            visible: update.changelog
            color: parent.expanded ? theme.palette.selected.baseText : theme.palette.normal.baseText

            height: versionLabel.height
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!update.changelog) return;
                parent.expanded = !parent.expanded
            }
        }
    }

    Label {
        id: downloadLabel
        anchors {
            top: name.bottom
            topMargin: units.gu(1)
            left: iconSlot.right
        }
        width: units.gu(10)
        verticalAlignment: Text.AlignVCenter
        fontSize: "small"
        text: {
            switch (update.status) {
            case UpdateManager.AutomaticallyDownloading:
            case UpdateManager.ManuallyDownloading:
            case UpdateManager.DownloadPaused:
                return i18n.tr("Downloading");
            case UpdateManager.Installing:
            case UpdateManager.InstallationPaused:
                return i18n.tr("Installing");
            case UpdateManager.InstallationFailed:
                return i18n.tr("Installation failed");
            case UpdateManager.Installed:
                return i18n.tr("Installed");
            case UpdateManager.NotStarted:
            case UpdateManager.NotAvailable:
            default:
                return "";
            }
        }
    }


    Label {
        id: statusLabel
        anchors {
            top: name.bottom
            topMargin: units.gu(1)
            right: parent.right
            rightMargin: units.gu(2)
        }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        fontSize: "small"
        text: {
            switch (update.status) {
            case UpdateManager.NotStarted:
                return formatter(size);
            case UpdateManager.AutomaticallyDownloading:
            case UpdateManager.ManuallyDownloading:
            case UpdateManager.DownloadPaused:
                var down = formatter(size * (progressBar.value / 100));
                var left = formatter(size);
                return i18n.tr("%1 of %2").arg(down).arg(left);
            case UpdateManager.Installing:
            case UpdateManager.InstallationPaused:
                return i18n.tr("Downloaded");
            case UpdateManager.NotAvailable:
            case UpdateManager.DownloadFailed:
            case UpdateManager.InstallationFailed:
            case UpdateManager.Installed:
            default:
                return "";
            }
        }
    }

    Column {
        id: error
        spacing: units.gu(1)
        anchors {
            top: name.bottom
            left: iconSlot.right
            right: parent.right
            rightMargin: units.gu(2)

        }
        states: State {
            name: "visible"
            when: update.status === UpdateManager.DownloadFailed

            PropertyChanges {
                target: error
                visible: true
            }

            AnchorChanges {
                target: expandableVersionLabel
                anchors.top: error.bottom
            }
        }

        visible: false
        Label {
            text: update.errorTitle
            color: UbuntuColors.red
        }

        Label {
            anchors { left: parent.left; right: parent.right }
            text: update.errorDetail
            fontSize: "small"
            wrapMode: Text.WrapAnywhere
        }
    }


    ProgressBar {
        id: progressBar
        anchors {
            top: downloadLabel.bottom
            topMargin: units.gu(1)
            right: parent.right
            rightMargin: units.gu(2)
            left: iconSlot.right
        }

        states: State {
            name: "visible"
            when: {
                switch (update.status) {
                case UpdateManager.AutomaticallyDownloading:
                case UpdateManager.ManuallyDownloading:
                case UpdateManager.DownloadPaused:
                case UpdateManager.InstallationPaused:
                case UpdateManager.Installing:
                    return true;
                case UpdateManager.DownloadFailed:
                case UpdateManager.InstallationFailed:
                default:
                    return false;
                }
            }

            PropertyChanges {
                target: progressBar
                visible: true
            }

            AnchorChanges {
                target: expandableVersionLabel
                anchors.top: progressBar.bottom
            }
        }
        visible: false
        height: units.gu(0.5)
        indeterminate: progress < 0 || progress > 100
        minimumValue: 0
        maximumValue: 100
        showProgressPercentage: false
    }

    // RowLayout {
    //     id: progressBarSlot
    //     anchors {
    //         top: topSlot.bottom
    //         topMargin: units.gu(1)
    //         left: iconSlot.right
    //         right: update.right
    //         rightMargin: units.gu(2)
    //     }
    //     visible: {
    //         switch (update.status) {
    //         case UpdateManager.AutomaticallyDownloading:
    //         case UpdateManager.ManuallyDownloading:
    //         case UpdateManager.DownloadPaused:
    //         case UpdateManager.InstallationPaused:
    //         case UpdateManager.Installing:
    //             return true;
    //         case UpdateManager.Failed:
    //         default:
    //             return false;
    //         }
    //     }
    //     height: units.gu(2)

    //     ProgressBar {
    //         id: progressBar
    //         anchors { left: parent.left }
    //         indeterminate: progress < 0 || progress > 100
    //         minimumValue: 0
    //         maximumValue: 100
    //         showProgressPercentage: false
    //         Layout.fillWidth: true
    //         Layout.maximumHeight: units.gu(0.5)
    //     }

    //     Rectangle {
    //         id: progressBarInfo
    //         Layout.fillHeight: true
    //         Layout.minimumWidth: units.gu(12)
    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
    //     }
    // }

    // // RowLayout {
    // //     id: middleSlot
    // //     height: units.gu(3)

    // //     anchors {
    // //         top: topSlot.bottom
    // //         topMargin: progressBarSlot.visible ? units.gu(1) : 0
    // //         left: iconSlot.right
    // //         right: update.right
    // //         rightMargin: units.gu(2)
    // //     }

    // //     states: [
    // //         State {
    // //             when: progressBarSlot.visible
    // //             AnchorChanges { target: middleSlot; anchors.top: progressBarSlot.bottom }
    // //         },
    // //         State {
    // //             when: update.status === UpdateManager.Failed
    // //             AnchorChanges { target: middleSlot; anchors.top: errorSlot.bottom }
    // //         }
    // //     ]

    // //     // IMPROVE?
    // //     // transitions: Transition {
    // //     //     AnchorAnimation {
    // //     //         duration: UbuntuAnimation.FastDuration
    // //     //         easing: UbuntuAnimation.StandardEasing
    // //     //     }
    // //     // }

    // // }

    // Item {
    //     id: bottomSlot
    //     anchors {
    //         top: middleSlot.bottom
    //         left: iconSlot.right
    //         right: update.right
    //         rightMargin: units.gu(2)
    //     }
    //     height: childrenRect.height

    Column {
        id: changelogCol
        anchors {
            top: expandableVersionLabel.bottom
            topMargin: units.gu(1)
            left: iconSlot.right
            right: parent.right
        }

        // Whether or not to animate height. We will enable this
        // when changelogLabel has completed.
        property bool animate: false
        height: childrenRect.height
        Behavior on height {
            animation: UbuntuNumberAnimation {}
            enabled: changelogCol.animate
        }

        add: Transition {
            SequentialAnimation {
                // Wait out height animation
                NumberAnimation {
                    property: "opacity"
                    from: 0; to: 0;
                    duration: UbuntuAnimation.FastDuration
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0; to: 1.0;
                    duration: UbuntuAnimation.BriskDuration
                }
            }
        }

        Label {
            id: changelogLabel
            anchors { left: parent.left; right: parent.right }
            clip: true
            fontSize: "small"
            wrapMode: Text.WordWrap
            visible: expandableVersionLabel.expanded
            property int origHeight;
            Component.onCompleted: {
                origHeight = height;
                visible = Qt.binding(function (){
                    return expandableVersionLabel.expanded;
                });
                height = Qt.binding(function () {
                    return visible && text !== "" ? origHeight : 0;
                });
                changelogCol.animate = true;
            }
        }
    }

    ListItems.ThinDivider {
        id: divider
        anchors {
            top: parent.bottom
            topMargin: units.gu(1)
            left: iconSlot.right
            right: parent.right
            rightMargin: units.gu(2)
        }
    }
}

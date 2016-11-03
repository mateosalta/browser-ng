/*
 * Copyright 2013-2016 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import ".."

ChromeBase {
    id: chrome

    property var tabsModel
    property alias tab: navigationBar.tab
    readonly property var webview: tab ? tab.webview : null
    property alias searchUrl: navigationBar.searchUrl
    property alias text: navigationBar.text
    property alias bookmarked: navigationBar.bookmarked
    signal toggleBookmark()
    property alias drawerActions: navigationBar.drawerActions
    property alias drawerOpen: navigationBar.drawerOpen
    property alias requestedUrl: navigationBar.requestedUrl
    property alias canSimplifyText: navigationBar.canSimplifyText
    property alias findInPageMode: navigationBar.findInPageMode
    property alias editing: navigationBar.editing
    property alias incognito: navigationBar.incognito
    property alias showTabsBar: tabsBar.active
    property alias showFaviconInAddressBar: navigationBar.showFaviconInAddressBar
    property alias availableHeight: navigationBar.availableHeight
    readonly property alias bookmarkTogglePlaceHolder: navigationBar.bookmarkTogglePlaceHolder
    property bool touchEnabled: true

    signal switchToTab(int index)
    signal requestNewTab(int index, bool makeCurrent)
    signal tabClosed(int index)

    backgroundColor: incognito ? UbuntuColors.darkGrey : "#ffffff"

    implicitHeight: tabsBar.height + navigationBar.height + content.anchors.topMargin

    function selectAll() {
        navigationBar.selectAll()
    }

    FocusScope {
        id: content
        anchors.fill: parent
        anchors.topMargin: showTabsBar ? units.gu(1) : 0

        focus: true

        Rectangle {
            anchors.fill: navigationBar
            color: (showTabsBar || !incognito) ? "#ffffff" : UbuntuColors.darkGrey
        }

        Loader {
            id: tabsBar

            Component.onCompleted: {
                tabsBar.setSource("TabsBar.qml", {
                                      "model": Qt.binding(function () {return chrome.tabsModel}),
                                      "incognito": Qt.binding(function () {return chrome.incognito}),
                                      "fgColor": Qt.binding(function () {return navigationBar.fgColor}),
                                      "touchEnabled": Qt.binding(function () {return chrome.touchEnabled})
                })
            }

            Connections {
                target: tabsBar.item

                onSwitchToTab: chrome.switchToTab(index)
                onRequestNewTab: chrome.requestNewTab(index, makeCurrent)
                onTabClosed: chrome.tabClosed(index)
            }
            asynchronous: true

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: active ? (touchEnabled ? units.gu(4) : units.gu(3)) : 0
        }

        NavigationBar {
            id: navigationBar

            loading: chrome.loading
            fgColor: "#111111"
            iconColor: (incognito && !showTabsBar) ? "white" : fgColor

            focus: true

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: units.gu(6)

            onToggleBookmark: chrome.toggleBookmark()
        }
    }

    // Delay changing the 'loading' state, to allow for very brief load
    // sequences to not update the UI, which would result in inelegant
    // flickering (https://launchpad.net/bugs/1611680).
    Connections {
        target: webview
        onLoadingStateChanged: delayedLoadingNotifier.restart()
    }
    Timer {
        id: delayedLoadingNotifier
        interval: 100
        onTriggered: loading = webview.loading
    }

    loadProgress: (loading && webview) ? webview.loadProgress : 0

    // If the webview changes the use the loading state of the new webview
    // otherwise opening a new tab/window while another webview was loading
    // can cause a progress bar to be left behind at zero percent pad.lv/1638337
    onWebviewChanged: loading = webview ? webview.loading : false
}

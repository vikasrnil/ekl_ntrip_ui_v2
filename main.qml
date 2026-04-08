import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    visible: true
    width: 500
    height: 550

    property bool isConnected: false

    // ================= TIMER =================
    Timer {
        id: clearTimer
        interval: 1000
        repeat: false
        onTriggered: statusMsg.text = ""
    }

    function showMessage(msg) {
        statusMsg.text = msg
        clearTimer.restart()
    }

    // ================= MAIN PAGE =================
    Item {
        id: mainPage
        anchors.fill: parent
        visible: !isConnected

        Column {
            anchors.centerIn: parent
            spacing: 10
            width: parent.width * 0.8

            Text {
                text: "NTRIP CLIENT"
                font.pixelSize: 20
            }

            Text {
                id: statusMsg
                text: ""
                color: "blue"
            }

            // INPUT
            TextField { id: hostField; placeholderText: "Host" }
            TextField { id: portField; placeholderText: "Port" }

            // FETCH
            Button {
                text: "Fetch Mount Points"
                onClicked: {
                    if (hostField.text === "" || portField.text === "") {
                        showMessage("Enter Host & Port")
                        return
                    }

                    showMessage("Fetching...")
                    ntripClient.fetchMountPoints(
                        hostField.text,
                        parseInt(portField.text)
                    )
                }
            }

            // MOUNT
            ComboBox {
                id: mountCombo
                model: []
            }

            TextField { id: userField; placeholderText: "User" }
            TextField {
                id: passwordField
                placeholderText: "Password"
                echoMode: TextInput.Password
            }
            
            CheckBox {
	    id: ggaCheck
	    text: "Send GGA"
	    checked: false

	    onCheckedChanged: {
		ntripClient.setUseFileGGA(checked)
	          }
	     }
            

            // CONNECT
            Button {
                text: "Connect"
                onClicked: {
                    if (hostField.text === "" ||
                        portField.text === "" ||
                        mountCombo.currentText === "" ||
                        userField.text === "" ||
                        passwordField.text === "") {

                        showMessage("Fill all fields")
                        return
                    }

                    var auth = userField.text + ":" + passwordField.text
                    showMessage("Connecting...")

                    ntripClient.connectToMountPoint(
                        hostField.text,
                        parseInt(portField.text),
                        mountCombo.currentText,
                        auth
                    )
                }
            }

            // DISCONNECT
            Button {
                text: "Disconnect"
                onClicked: {
                    ntripClient.disconnectClient()
                    showMessage("Disconnected")
                }
            }
        }
    }

    // ================= DATA PAGE =================
    Item {
        id: dataPage
        anchors.fill: parent
        visible: isConnected

        property bool isDisconnected: false

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "Live GNSS Data"
                font.pixelSize: 20
            }

            Text {
                id: dataText
                text: "Waiting..."
                font.pixelSize: 16
            }

            Button {
                text: "Disconnect"
                onClicked: {
                    if (!dataPage.isDisconnected) {
                        ntripClient.disconnectClient()
                        dataPage.isDisconnected = true
                        dataText.text = "Disconnected"
                    }
                }
            }

            Button {
                text: "Back"
                onClicked: {
                    if (!dataPage.isDisconnected) {
                        ntripClient.disconnectClient()
                        dataPage.isDisconnected = true
                    }

                    isConnected = false
                }
            }
        }
    }

    // ================= BACKEND SIGNALS =================
    Connections {
        target: ntripClient

        function onMountPointsReceived(list) {
            mountCombo.model = list
            showMessage(list.length > 0 ? "Mountpoints loaded" : "No mountpoints")
        }

        function onConnectionStatus(s) {
            showMessage(s)

            if (s === "Connected") {
                isConnected = true
                dataPage.isDisconnected = false
                dataText.text = "Waiting..."
            }

            if (s === "Disconnected") {
                isConnected = false
            }
        }

        function onDataUpdated(line) {
            if (isConnected && !dataPage.isDisconnected)
                dataText.text = line
        }
    }
}

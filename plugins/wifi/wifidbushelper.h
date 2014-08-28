/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * Authors:
 *    Jussi Pakkanen <jussi.pakkanen@canonical.com>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef WIFI_DBUS_HELPER
#define WIFI_DBUS_HELPER

#include <QObject>
#include <arpa/inet.h>

/**
 * For sending specific dbus messages from QML.
 */

class WifiDbusHelper final : public QObject {
    Q_OBJECT
    Q_PROPERTY( QString wifiIp4Address
                READ wifiIp4Address
                NOTIFY wifiIp4AddressChanged )

public:
    WifiDbusHelper(QObject *parent = nullptr);
    ~WifiDbusHelper() {};
    QString wifiIp4Address();

    Q_INVOKABLE void connect(QString ssid, int security, QString password);
    Q_INVOKABLE QList<QStringList> getPreviouslyConnectedWifiNetworks();
    Q_INVOKABLE void forgetConnection(const QString dbus_path);

public Q_SLOTS:
    void deviceStateChanged(int new_state);

Q_SIGNALS:
    void wifiIp4AddressChanged(QString wifiIp4Address);

private:
    QString m_wifiIp4Address;
    void setIpAddress();
};


#endif

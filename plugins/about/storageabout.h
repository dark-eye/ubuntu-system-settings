/*
 * Copyright (C) 2013 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 * Sebastien Bacher <sebastien.bacher@canonical.com>
 *
*/

#ifndef STORAGEABOUT_H
#define STORAGEABOUT_H

#include "click.h"

#include <gio/gio.h>
#include <glib.h>

#include <QObject>
#include <QProcess>
#include <QVariant>


class StorageAbout : public QObject
{
    Q_OBJECT

    Q_ENUMS(ClickModel::Roles)

    Q_PROPERTY( QString serialNumber
                READ serialNumber
                CONSTANT)

    Q_PROPERTY( QString vendorString
                READ vendorString
                CONSTANT)

    Q_PROPERTY( QString updateDate
                READ updateDate
                CONSTANT)

    Q_PROPERTY(QAbstractItemModel *clickList
               READ getClickList
               CONSTANT)

    Q_PROPERTY(quint64 totalClickSize
               READ getClickSize
               CONSTANT)

    Q_PROPERTY(quint64 moviesSize
               READ getMoviesSize
               NOTIFY sizeReady)

    Q_PROPERTY(quint64 audioSize
               READ getAudioSize
               NOTIFY sizeReady)

    Q_PROPERTY(quint64 picturesSize
               READ getPicturesSize
               NOTIFY sizeReady)

    Q_PROPERTY(quint64 homeSize
               READ getHomeSize
               NOTIFY sizeReady)

    Q_PROPERTY(ClickModel::Roles sortRole
               READ getSortRole
               WRITE setSortRole
               NOTIFY sortRoleChanged)

public:
    explicit StorageAbout(QObject *parent = 0);
    ~StorageAbout();
    QAbstractItemModel *getClickList();
    QString serialNumber();
    QString vendorString();
    QString updateDate();
    Q_INVOKABLE QString licenseInfo(const QString &subdir) const;
    ClickModel::Roles getSortRole();
    void setSortRole(ClickModel::Roles newRole);
    quint64 getClickSize() const;
    quint64 getMoviesSize();
    quint64 getAudioSize();
    quint64 getPicturesSize();
    quint64 getHomeSize();
    Q_INVOKABLE QString formatSize (quint64 size) const;
    Q_INVOKABLE void populateSizes();

Q_SIGNALS:
    void sortRoleChanged();
    void sizeReady();

private:
    QString m_serialNumber;
    QString m_vendorString;
    QString m_updateDate;
    ClickModel m_clickModel;
    ClickFilterProxy m_clickFilterProxy;
    quint64 m_moviesSize;
    quint64 m_audioSize;
    quint64 m_picturesSize;
    quint64 m_otherSize;
    quint64 m_homeSize;

    GCancellable *m_cancellable;
};

#endif // STORAGEABOUT_H

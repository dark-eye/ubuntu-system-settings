/*
 * Copyright (C) 2013 - Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License, as
 * published by the  Free Software Foundation; either version 2.1 or 3.0
 * of the License.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the applicable version of the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of both the GNU Lesser General Public
 * License along with this program. If not, see <http://www.gnu.org/licenses/>
 *
 * Authored by: Diego Sarmentero <diego.sarmentero@canonical.com>
 */

#include "download_tracker.h"
#include "network/network.h"
#include <ubuntu/download_manager/download_struct.h>
#include <QProcessEnvironment>

#define DOWNLOAD_COMMAND "post-download-command"
#define APP_ID "app_id"
#define PKCON_COMMAND "pkcon"

namespace UpdatePlugin {

DownloadTracker::DownloadTracker(QObject *parent) :
    QObject(parent),
    m_clickToken(""),
    m_downloadUrl(""),
    m_download(nullptr),
    m_progress(0)
{
    m_manager = Manager::createSessionManager("", this);

    QObject::connect(m_manager, SIGNAL(downloadCreated(Download*)),
                     this, SLOT(downloadFileCreated(Download*)));
}

void DownloadTracker::setDownload(const QString& url)
{
    if (url != "") {
        m_downloadUrl = url;
        startService();
    }
}

void DownloadTracker::setClickToken(const QString& token)
{
    if (token != "") {
        m_clickToken = token;
        startService();
    }
}

void DownloadTracker::setPackageName(const QString& package)
{
    if (package != "") {
        m_packageName = package;
        startService();
    }
}

void DownloadTracker::startService()
{
    if (!m_clickToken.isEmpty() && !m_downloadUrl.isEmpty() && !m_packageName.isEmpty()) {
        QVariantMap vmap;
        QStringList args;
        QString command = getPkconCommand();
        args << command << "-p" << "install-local" << "$file";
        vmap[DOWNLOAD_COMMAND] = args;
        vmap[APP_ID] = m_packageName;
        StringMap map;
        map[X_CLICK_TOKEN] = m_clickToken;
        DownloadStruct dstruct = DownloadStruct(m_downloadUrl, vmap, map);
        m_manager->createDownload(dstruct);
    }
}

void DownloadTracker::bindDownload(Download* download)
{
    m_download = download;
//    connect(m_download, SIGNAL(error(Error*)), this,
//            SLOT(errorReceived(Error*)));
    connect(m_download, SIGNAL(finished(const QString &)), this,
            SIGNAL(finished(const QString &)));
    connect(m_download, SIGNAL(progress(qulonglong, qulonglong)), this,
            SLOT(setProgress(qulonglong, qulonglong)));

    m_download->start();
}

void DownloadTracker::pause()
{
    m_download->pause();
}

void DownloadTracker::resume()
{
    m_download->resume();
}

QString DownloadTracker::getPkconCommand()
{
    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    QString command = environment.value("PKCON_COMMAND", QString(PKCON_COMMAND));
    return command;
}

void DownloadTracker::setProgress(qulonglong received, qulonglong total)
{
    if (total > 0) {
        qulonglong result = (received * 100);
        m_progress = static_cast<int>(result / total);
        emit progressChanged();
    }
}

//void DownloadTracker::errorReceived(Error* e)
//{
//    Q_EMIT error(e->errorString());
//}

}

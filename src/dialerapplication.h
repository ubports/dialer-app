/*
 * Copyright (C) 2012-2013 Canonical, Ltd.
 *
 * This file is part of dialer-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef DIALERAPPLICATION_H
#define DIALERAPPLICATION_H

#include <QObject>
#include <QQuickView>
#include <QGuiApplication>

class DialerApplication : public QGuiApplication
{
    Q_OBJECT
    Q_PROPERTY(bool fullScreen READ fullScreen WRITE setFullScreen NOTIFY fullScreenChanged)

public:
    DialerApplication(int &argc, char **argv);
    virtual ~DialerApplication();

    bool setup();
    bool fullScreen() const;
    void setFullScreen(bool value);

public Q_SLOTS:
    void activateWindow();
    void parseArgument(const QString &arg);
    QStringList mmiPluginList();

Q_SIGNALS:
    void fullScreenChanged();

private Q_SLOTS:
    void onViewStatusChanged(QQuickView::Status status);
    void onApplicationReady();

private:
    QQuickView *m_view;
    QString m_arg;
    bool m_applicationIsReady;
    bool m_fullScreen;
    QList<QString> mValidSchemes;
};

#endif // DIALERAPPLICATION_H

/*
 * Copyright 2020 Ubports Foundation.
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

#ifndef DIALPADSEARCH_H
#define DIALPADSEARCH_H

#include <QObject>
#include <QContact>
#include <QContactManager>
#include <QContactAbstractRequest>
#include <QContactFetchRequest>
#include <QtContacts/QContactUnionFilter>
#include <QtContacts/QContactDetailFilter>
#include <QContactInvalidFilter>
#include <QAbstractListModel>

QTCONTACTS_USE_NAMESPACE

class Contact
{
public:
    Contact(const QString &displayLabel, const QStringList &phoneNumbers);

    QString displayLabel() const;
    QStringList phoneNumbers() const;

private:
    QString mDisplayLabel;
    QStringList mPhoneNumbers;

};

class DialPadSearch : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)
    Q_PROPERTY(QString phoneNumber READ phoneNumber WRITE setPhoneNumber)
    Q_PROPERTY(int countryCode READ countryCode WRITE setCountryCode)
    Q_PROPERTY(QString manager READ manager WRITE setManager NOTIFY managerChanged)
    Q_PROPERTY(QString state READ state WRITE setState NOTIFY stateChanged)

public:
    DialPadSearch(QObject *parent = 0);
    ~DialPadSearch();

    enum ContactRoles {
        ContactDisplayLabelRole = Qt::UserRole + 1,
        ContactPhoneNumbersRole,
    };
    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    QString phoneNumber() const;
    void setPhoneNumber(const QString &phoneNumber);
    int countryCode() const;
    void setCountryCode(int countryCode);
    QString state() const;
    void setState(const QString &state);
    void setManager(const QString &mContactManager);
    QString manager() const;

    Q_INVOKABLE void push(const QString& pattern);
    Q_INVOKABLE void pop();
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE QVariantMap get(int index) const;


protected Q_SLOTS:
    void onResultsAvailable();
    void onRequestStateChanged(QContactAbstractRequest::State state);

Q_SIGNALS:
    void stateChanged();
    void rowCountChanged();
    void managerChanged();

private:
    QContactFetchRequest *mRequest;
    QList<Contact> mContacts;
    QList<QString> mSearchHistory;
    QString mState;
    QString mPhoneNumber;
    QString mManager;
    int mCountryCode;
    int mNameSearchLastIndex;
    bool mRequestCompleted;

    void startSearching(const QContactFilter &filter);
    void generateFilters();
    void clearModel();
    QList<QContactFilter> generateTextFilters();
    QList<QString> cartesianProduct(const QList<QList<QString>>& lists);
};

#endif // DIALPADSEARCH_H

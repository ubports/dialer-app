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
#include <QContactFilter>
#include <QAbstractListModel>

QTCONTACTS_USE_NAMESPACE

class Contact
{
public:
    Contact(const QString &displayLabel, const QStringList &phoneNumbers);

    QString displayLabel() const;
    QStringList phoneNumbers() const;
    QStringList normalizedValues() const;
    void setNormalizedValues(const QStringList values);

private:
    QString mDisplayLabel;
    QStringList mPhoneNumbers;
    QStringList mNormalizedValues;
};

class DialPadSearch : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)
    Q_PROPERTY(QString phoneNumber READ phoneNumber WRITE setPhoneNumber)
    Q_PROPERTY(int countryCode READ countryCode WRITE setCountryCode)
    Q_PROPERTY(QString manager READ manager WRITE setManager NOTIFY managerChanged)

public:
    DialPadSearch(QObject *parent = 0);
    ~DialPadSearch();

    enum ContactRoles {
        ContactDisplayLabelRole = Qt::UserRole + 1,
        ContactPhoneNumbersRole,
    };

    enum SearchState {
        NO_FILTER,
        NAME_SEARCH,
        NUMBER_SEARCH
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    QString phoneNumber() const;
    void setPhoneNumber(const QString &phoneNumber);
    int countryCode() const;
    void setCountryCode(int countryCode);
    SearchState state() const;
    void setManager(const QString &mContactManager);
    QString manager() const;

    Q_INVOKABLE void push(const QString& pattern);
    Q_INVOKABLE void pop();
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE QVariantMap get(int index) const;


protected Q_SLOTS:
    void onQueryStateChanged(QContactAbstractRequest::State state);
    void onQueryChanged();
    void onQueryEnded();

Q_SIGNALS:
    void rowCountChanged();
    void managerChanged();
    void queryChanged();

private:
    QContactFetchRequest* mPendingRequest;
    QList<Contact> mContacts;
    QStringList mSearchHistory;
    QStringList mPatterns;
    SearchState mState;
    QString mPhoneNumber;
    QString mManager;
    int mCountryCode;
    int mLastSuccessfullSearchIdx;
    int mCurrentSearchIdx;
    bool mFetchAgainNeeded;

    bool valid();
    void clearModel();
    void search();
    void performInMemorySearch();
    void setState(const SearchState &state);
    QContactFilter generateFilters();
    QList<QContactFilter> generateTextFilters();
    QStringList generatePatterns(const QStringList &source, QStringList &currentPatterns);
    QString normalize(const QString &value) const;
    void populateContacts(const QList<QContact> &qcontacts);
};

#endif // DIALPADSEARCH_H

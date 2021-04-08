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
#include "dialpadsearch.h"
#include "contactutils.h"
#include <QDebug>
#include <QString>
#include <QContactDetail>
#include <QContactManager>
#include <QContactUnionFilter>
#include <QContactDetailFilter>
#include <QContactName>
#include <QContactExtendedDetail>
#include <QContactFetchHint>
#include <QContactDisplayLabel>
#include <QContactSortOrder>
#include <QContactFavorite>

#include <QContactPhoneNumber>
#include <QContactTimestamp>
#include <QContactAbstractRequest>


Contact::Contact(const QString &displayLabel, const QStringList &phoneNumbers)
    : mDisplayLabel(displayLabel), mPhoneNumbers(phoneNumbers)
{
}

QString Contact::displayLabel() const
{
    return mDisplayLabel;
}

QStringList Contact::phoneNumbers() const
{
    return mPhoneNumbers;
}

DialPadSearch::DialPadSearch(QObject *parent): QAbstractListModel(parent),
    mRequest(0),  mSearchHistory(), mState("NO_FILTER"), mCountryCode(-1), mNameSearchLastIndex(-1), mRequestCompleted(false)
{
}

DialPadSearch::~DialPadSearch()
{
    if (mRequest) {
        mRequest->cancel();
        delete mRequest;
    }
}

QString DialPadSearch::phoneNumber() const
{
    return mPhoneNumber;
}

void DialPadSearch::setPhoneNumber(const QString &phoneNumber)
{
    QString tmpNumber = QString(phoneNumber).replace(" ", "");
    if (mPhoneNumber.length() > 0) {
        int len = qMin(tmpNumber.length(), mPhoneNumber.length());
        if (!tmpNumber.startsWith(mPhoneNumber.left(len))) {
                // in case user set a different number from the contact page or outside of the app
                clearAll();
        }
    }
    mPhoneNumber = tmpNumber;
}

int DialPadSearch::countryCode() const
{
    return mCountryCode;
}

void DialPadSearch::setCountryCode(int countryCode)
{
    mCountryCode = countryCode;
}

QString DialPadSearch::state() const
{
    return mState;
}

void DialPadSearch::setState(const QString &state)
{
    if (!state.isEmpty() && state != mState) {
        mState = state;
        Q_EMIT stateChanged();
    }
}

void DialPadSearch::setManager(const QString &smanager)
{
    if (mManager != smanager) {
        mManager = smanager;
        Q_EMIT managerChanged();
        qDebug() << "manager set to:" << mManager;
    }
}

QString DialPadSearch::manager() const
{
    return mManager;
}

void DialPadSearch::push(const QString &pattern)
{
    if (pattern.isEmpty()) return;

    mSearchHistory << pattern;

    QString currentState;
    if (state() == "NO_FILTER") {
        if (pattern == "0" || pattern == "1") {
            currentState = "NUMBER_SEARCH";
        // start searching for name first, but don't start before at least to digits entered
        } else if (mSearchHistory.count() == 2) {
            currentState = "NAME_SEARCH";
        }
    }
    setState(currentState);

    if (state() == "NUMBER_SEARCH") {
        // no need to retrieve too many contacts if we are searching for numbers
        // for non international number, start to search when we have 3 digits
        // for international number, start to search 2 digits after the prefix
        if (mPhoneNumber.count() < 3 || (mPhoneNumber.startsWith("+") && mPhoneNumber.count() < QString::number(mCountryCode).count() + 3)) {
            return;
        }
    }

    generateFilters();

}

void DialPadSearch::pop()
{
    if (!mSearchHistory.isEmpty()) {
        mSearchHistory.pop_back();
    }

    QString currentState;
    if (mState == "NO_FILTER" && !mPhoneNumber.isEmpty()) {
        // user have selected a contact and hit back space
        currentState = "NUMBER_SEARCH";
    } else if (!mSearchHistory.isEmpty() && mSearchHistory.count() == mNameSearchLastIndex){
        // return to name search
        currentState = "NAME_SEARCH";
    } else if (mPhoneNumber.isEmpty() || mPhoneNumber.count() == 1) {
        clearAll();

    }
    setState(currentState);

    // no need to retrieve too many contacts if we are searching for numbers
    if (mState == "NUMBER_SEARCH") {
        if (mPhoneNumber.count() < 3 || (mPhoneNumber.startsWith("+") && mPhoneNumber.count() < QString::number(mCountryCode).count() + 3)) {
            clearModel();
            return;
        }
    }

    generateFilters();
}

void DialPadSearch::startSearching(const QContactFilter &filter)
{
    // cancel current request if necessary
    if (mRequest) {
        mRequest->cancel();
        mRequest->deleteLater();
    }

    QContactFetchHint fetchHint;
    fetchHint.setDetailTypesHint({QContactDetail::TypeDisplayLabel, QContactDetail::TypePhoneNumber, QContactDetail::TypeFavorite});

    QContactSortOrder sortOrder;
    sortOrder.setDetailType(QContactDetail::TypeDisplayLabel, QContactDisplayLabel::FieldLabel);
    sortOrder.setDirection(Qt::AscendingOrder);
    sortOrder.setBlankPolicy(QContactSortOrder::BlanksLast);
    sortOrder.setCaseSensitivity(Qt::CaseSensitive);

    mRequest = new QContactFetchRequest(this);
    mRequest->setManager(ContactUtils::sharedManager(mManager));
    mRequest->setFilter(filter);
    mRequest->setFetchHint(fetchHint);
    mRequest->setSorting({sortOrder});

    connect(mRequest, SIGNAL(resultsAvailable()), SLOT(onResultsAvailable()));
    connect(mRequest, SIGNAL(stateChanged(QContactAbstractRequest::State)),
                          SLOT(onRequestStateChanged(QContactAbstractRequest::State)));

    mRequestCompleted = false;
    mRequest->start();
}

void DialPadSearch::onRequestStateChanged(QContactAbstractRequest::State state)
{
    QContactFetchRequest *request = mRequest;
    if (request && state == QContactAbstractRequest::FinishedState) {
        mRequestCompleted = true;
        mRequest = 0;
        request->deleteLater();

        // if we got no results and we were in Name search, switch to number search
        if (request->contacts().isEmpty() && mState == "NAME_SEARCH") {
            //start to search for phone numbers if no contact found
            setState("NUMBER_SEARCH");
            //store here the last time we did a successfull textSearch
            mNameSearchLastIndex = mSearchHistory.count() -1;
            clearModel();
            generateFilters();
        }
    }
}

void DialPadSearch::onResultsAvailable()
{
    QContactFetchRequest *request = qobject_cast<QContactFetchRequest*>(sender());

    int favoritePos = 0;
    beginResetModel();
    mContacts.clear();
    if(request && request->contacts().size() > 0) {
        for (const auto& resultContact: request->contacts()) {
            QStringList phoneNumbers;
            for(const QContactPhoneNumber phoneNumber: resultContact.details(QContactDetail::TypePhoneNumber)) {
                phoneNumbers << phoneNumber.number();
            }

            if (!phoneNumbers.isEmpty()) {
                QString displayLabel = resultContact.detail(QContactDetail::TypeDisplayLabel).value(QContactDisplayLabel::FieldLabel).toString();

                bool isFavorite = resultContact.detail(QContactDetail::TypeFavorite).value(QContactFavorite::FieldFavorite).toBool();

                Contact contact = Contact(displayLabel, phoneNumbers);
                // show favorite first
                if (isFavorite) {
                    mContacts.insert(favoritePos, contact);
                    favoritePos++;
                } else {
                    mContacts << contact;
                }
            }
        }
    }
    endResetModel();
    Q_EMIT rowCountChanged();

}

void DialPadSearch::generateFilters()
{
    QContactFilter filter;

    if (mState == "NAME_SEARCH") {

        QContactUnionFilter unionFilter;
        unionFilter.setFilters(generateTextFilters());
        filter = unionFilter;

    } else if (mState == "NUMBER_SEARCH") {

        QContactUnionFilter unionFilter;
        QList<QContactFilter> filters;

        //a fake filter is needed with the phonumberFilter, otherwise no result will be found
        QContactDetailFilter mFakeFilter;
        mFakeFilter.setDetailType(QContactDetail::TypeTimestamp, QContactTimestamp::FieldCreationTimestamp);
        mFakeFilter.setMatchFlags(QContactFilter::MatchExactly);
        mFakeFilter.setValue(-1);
        filters << mFakeFilter;

        QContactDetailFilter mPhoneNumberFilter;
        mPhoneNumberFilter.setDetailType(QContactDetail::TypePhoneNumber, QContactPhoneNumber::FieldNumber);
        mPhoneNumberFilter.setMatchFlags(QContactFilter::MatchPhoneNumber | QContactFilter::MatchStartsWith);
        mPhoneNumberFilter.setValue(mPhoneNumber);
        filters << mPhoneNumberFilter;

        if (mPhoneNumber.startsWith("0") && mCountryCode > -1) {
            // when number start with 0, try to search also by adding the international region prefix, e.g +33
            QString number = QStringLiteral("+%1%2").arg(mCountryCode).arg(mPhoneNumber.right(mPhoneNumber.count() - 1));
            QContactDetailFilter internationalPhoneFilter;
            internationalPhoneFilter.setDetailType(QContactDetail::TypePhoneNumber, QContactPhoneNumber::FieldNumber);
            internationalPhoneFilter.setMatchFlags(QContactFilter::MatchPhoneNumber | QContactFilter::MatchStartsWith);
            internationalPhoneFilter.setValue(number);
            filters << internationalPhoneFilter;

        } else if (mCountryCode > -1 && mPhoneNumber.startsWith(QStringLiteral("+%1").arg(mCountryCode))) {
            // when start with international prefix, try also to look for numbers starting with 0
            QString prefix = QStringLiteral("+%1").arg(mCountryCode);
            QString number = QStringLiteral("0%1").arg(mPhoneNumber.right(mPhoneNumber.count() - prefix.size()));
            QContactDetailFilter localPhoneFilter;
            localPhoneFilter.setDetailType(QContactDetail::TypePhoneNumber, QContactPhoneNumber::FieldNumber);
            localPhoneFilter.setMatchFlags(QContactFilter::MatchPhoneNumber | QContactFilter::MatchStartsWith);
            localPhoneFilter.setValue(number);
            filters << localPhoneFilter;
        }

        unionFilter.setFilters(filters);
        filter = unionFilter;
    } else {
        //start with an invalid filter, otherwise backend return all contacts
        QContactInvalidFilter mInvalidFilter;
        filter = mInvalidFilter;
    }

    startSearching(filter);
}

void DialPadSearch::clearModel()
{
    beginResetModel();
    mContacts.clear();
    endResetModel();
    Q_EMIT rowCountChanged();
}

void DialPadSearch::clearAll()
{
    mSearchHistory.clear();
    mNameSearchLastIndex = -1;
    setState("NO_FILTER");
    clearModel();
}

QVariantMap DialPadSearch::get(int i) const
{
    QVariantMap item;
    QHash<int, QByteArray> roles = roleNames();

    QModelIndex modelIndex = index(i, 0);
    if (modelIndex.isValid()) {
        Q_FOREACH(int role, roles.keys()) {
            QString roleName = QString::fromUtf8(roles.value(role));
            item.insert(roleName, data(modelIndex, role));
        }
    }
    return item;
}

QList<QContactFilter> DialPadSearch::generateTextFilters()
{
    QList<QList<QString>> tempPatterns;
    for (const auto& pattern: mSearchHistory ) {
        tempPatterns << pattern.split("", QString::SkipEmptyParts);
    }
    QList<QString> patterns =  cartesianProduct(tempPatterns);
    QList<QContactFilter> filters;

    for (const auto& pattern : patterns) {
        QContactDetailFilter nameFilter;
        nameFilter.setDetailType(QContactDetail::TypeName, QContactName::FieldLastName);
        nameFilter.setMatchFlags(QContactFilter::MatchStartsWith);
        nameFilter.setValue(pattern);

        filters << nameFilter;

        QContactDetailFilter displayLabelFilter;
        displayLabelFilter.setDetailType(QContactDetail::TypeExtendedDetail,QContactExtendedDetail::FieldData );
        displayLabelFilter.setMatchFlags(QContactFilter::MatchStartsWith);
        displayLabelFilter.setValue(pattern);

        filters << displayLabelFilter;
    }

    return filters;
}

QList<QString> DialPadSearch::cartesianProduct(const QList<QList<QString>>& v)
{
    QList<QList<QString>> s = {{}};

    for (const auto& u : v) {
        QList<QList<QString>> r;
        for (const auto& x : s) {
            for (const auto y : u) {
                r.push_back(x);
                r.back().push_back(y);
            }
        }
        s = std::move(r);
    }
    QList<QString> result;
    for (const auto& patterns : s) {
        result << patterns.join("");
    }
    return result;
}


QHash<int, QByteArray> DialPadSearch::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[ContactDisplayLabelRole] = "displayLabel";
    roles[ContactPhoneNumbersRole] = "phoneNumbers";

    return roles;
}

int DialPadSearch::rowCount(const QModelIndex & parent) const
{
    Q_UNUSED(parent);
    return mContacts.count();
}

QVariant DialPadSearch::data(const QModelIndex & index, int role) const
{
    if (index.row() < 0 || index.row() >= mContacts.count())
        return QVariant();

    const Contact &contact = mContacts[index.row()];
    if (role == ContactDisplayLabelRole)
        return QVariant::fromValue(contact.displayLabel());
    else if (role == ContactPhoneNumbersRole) {
        return QVariant::fromValue(contact.phoneNumbers());
    } else {
        return QVariant();
    }
}

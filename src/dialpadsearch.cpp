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

QStringList Contact::normalizedValues() const
{
    return mNormalizedValues;
}

void Contact::setNormalizedValues(const QStringList values)
{
    mNormalizedValues = values;
}

DialPadSearch::DialPadSearch(QObject *parent): QAbstractListModel(parent),
    mPendingRequest(nullptr),  mState(SearchState::NO_FILTER), mCountryCode(-1), mLastSuccessfullSearchIdx(-1), mCurrentSearchIdx(-1), mFetchAgainNeeded(false)
{
    connect(this, SIGNAL(queryChanged()),this, SLOT(onQueryChanged()));
    connect(this, SIGNAL(rowCountChanged()),this, SLOT(onQueryEnded()));
}

DialPadSearch::~DialPadSearch()
{
    if (mPendingRequest) {
        mPendingRequest->cancel();
        mPendingRequest->deleteLater();
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

DialPadSearch::SearchState DialPadSearch::state() const
{
    return mState;
}

void DialPadSearch::setState(const SearchState &state)
{
    if (state != mState) {
        mState = state;
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

bool DialPadSearch::valid()
{
    bool valid = false;
    if (mState == SearchState::NUMBER_SEARCH) {
        // no need to retrieve too many contacts if we are searching for numbers
        // for non international number, start to search when we have 3 digits
        // for international number, start to search 2 digits after the prefix
        int minNumbers = mPhoneNumber.startsWith("+") ? QString::number(mCountryCode).count() + 3 : 3;
        valid = mPhoneNumber.count() >= minNumbers;
    } else  {
        valid = mSearchHistory.count() >= 2;
    }
    return valid;
}

void DialPadSearch::push(const QString &pattern)
{
    if (pattern.isEmpty()) return;

    mSearchHistory << pattern;

    SearchState nextState = mState;
    if (mState == SearchState::NO_FILTER) {
        if (pattern == "0" || pattern == "1") {
            nextState = SearchState::NUMBER_SEARCH;
        } else {
            // start searching for name first
            nextState = SearchState::NAME_SEARCH;
        }
    }

    setState(nextState);
    if (valid()) {
        Q_EMIT queryChanged();
    }
}

void DialPadSearch::pop()
{
    if (!mSearchHistory.isEmpty()) {
        mSearchHistory.pop_back();
    }

    SearchState nextState = mState;;
    if (mState == SearchState::NO_FILTER && !mPhoneNumber.isEmpty()) {
        // user have selected a contact and hit back space
        nextState = SearchState::NUMBER_SEARCH;
    } else if (!mSearchHistory.isEmpty() && mSearchHistory.count() == mLastSuccessfullSearchIdx){
        // return to name search
        nextState = SearchState::NAME_SEARCH;
    }

    setState(nextState);

    if (valid()) {
        Q_EMIT queryChanged();
    } else {
        setState(SearchState::NO_FILTER);
        clearModel();
    }
}

void DialPadSearch::onQueryStateChanged(QContactAbstractRequest::State state)
{
    if (state != QContactAbstractRequest::FinishedState)
        return;

    QContactFetchRequest* req = qobject_cast<QContactFetchRequest*>(QObject::sender());
    if (!req) {
        qWarning() << "onRequestStateChanged " << req->error();
        return;
    }

    beginResetModel();
    populateContacts(req->contacts());
    endResetModel();
    Q_EMIT rowCountChanged();
}

void DialPadSearch::onQueryChanged()
{
    mFetchAgainNeeded = mPendingRequest && mPendingRequest->isActive();
    if (mFetchAgainNeeded) {
        return;
    }

    if (mState == SearchState::NAME_SEARCH) {
        // try local search
        if (!mPatterns.isEmpty() && mContacts.count() > 0 && mSearchHistory.count() -1 >= mCurrentSearchIdx) {
            performInMemorySearch();
            return;
        }
    }
    search();
}

void DialPadSearch::onQueryEnded()
{
    if (mState == SearchState::NAME_SEARCH) {
        if (mContacts.count() == 0) {
            // if we got no results and we were in Name search, switch to number search
            setState(SearchState::NUMBER_SEARCH);
            Q_EMIT queryChanged();
            return;
        } else {
            //store here the last time we did a successfull textSearch
            mLastSuccessfullSearchIdx = mSearchHistory.count();
        }
    }

    if (mFetchAgainNeeded) {
        mFetchAgainNeeded = false;
        Q_EMIT queryChanged();
    }
}

void DialPadSearch::search()
{
    mCurrentSearchIdx = mSearchHistory.count() - 1;
    // cancel previous request if any
    if (mPendingRequest) {
        mPendingRequest->cancel();
        mPendingRequest->deleteLater();
    }

    QContactFetchHint fetchHint;
    fetchHint.setDetailTypesHint({QContactDetail::TypeName, QContactDetail::TypeDisplayLabel, QContactDetail::TypePhoneNumber, QContactDetail::TypeFavorite});

    QContactSortOrder sortOrder;
    sortOrder.setDetailType(QContactDetail::TypeDisplayLabel, QContactDisplayLabel::FieldLabel);
    sortOrder.setDirection(Qt::AscendingOrder);
    sortOrder.setBlankPolicy(QContactSortOrder::BlanksLast);
    sortOrder.setCaseSensitivity(Qt::CaseSensitive);

    mPendingRequest = new QContactFetchRequest(this);
    mPendingRequest->setManager(ContactUtils::sharedManager(mManager));
    connect(mPendingRequest, SIGNAL(stateChanged(QContactAbstractRequest::State)),
            SLOT(onQueryStateChanged(QContactAbstractRequest::State)));
    mPendingRequest->setFilter(generateFilters());
    mPendingRequest->setFetchHint(fetchHint);
    mPendingRequest->setSorting({sortOrder});

    mContacts.clear();
    mPendingRequest->start();
}


QContactFilter DialPadSearch::generateFilters()
{
    QContactUnionFilter unionFilter;

    if (mState == SearchState::NAME_SEARCH) {

        unionFilter.setFilters(generateTextFilters());

    } else if (mState == SearchState::NUMBER_SEARCH) {

        QContactDetailFilter mPhoneNumberFilter;
        mPhoneNumberFilter.setDetailType(QContactDetail::TypePhoneNumber, QContactPhoneNumber::FieldNumber);
        mPhoneNumberFilter.setMatchFlags(QContactFilter::MatchPhoneNumber | QContactFilter::MatchStartsWith);
        mPhoneNumberFilter.setValue(mPhoneNumber);

        QList<QContactFilter> filters;
        filters << mPhoneNumberFilter;

        // special case for local numbers
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
    }

    return QContactFilter(unionFilter);
}

void DialPadSearch::performInMemorySearch()
{
    // retain only patterns that matched contacts
    for (const QString& currentPattern: mPatterns ) {
        bool found = false;
        for (const Contact &ct: mContacts) {
            found = ct.normalizedValues().indexOf(QRegExp("^" + currentPattern + ".*")) > -1;
            if (found) {
                break;
            }
        }
        if (!found) {
            mPatterns.removeOne(currentPattern);
        }
    }
    // new patterns
    QStringList currentPatterns(mPatterns);
    mPatterns = generatePatterns(mSearchHistory.mid(mCurrentSearchIdx +1), currentPatterns);

    // now try to search with in memory contacts
    int oldCount = mContacts.count();
    for (int i = mContacts.count()-1; i >= 0; --i) {
        Contact contact = mContacts[i];
        bool found = false;

        for (const QString& currentPattern: mPatterns ) {
            found = contact.normalizedValues().indexOf(QRegExp("^" + currentPattern + ".*")) > -1;
            if (found) {
                break;
            }
        }

        if (!found) {
            beginRemoveRows(QModelIndex(), i, i);
            mContacts.removeAt(i);
            endRemoveRows();
        }
    }

    if (oldCount >= mContacts.count()) {
        mCurrentSearchIdx = mSearchHistory.count()-1;
        Q_EMIT rowCountChanged();
    }
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
    if (mPendingRequest) {
        mPendingRequest->cancel();
    }
    mSearchHistory.clear();
    mLastSuccessfullSearchIdx = -1;
    mPatterns.clear();
    setState(SearchState::NO_FILTER);
    clearModel();
}

QString DialPadSearch::normalize(const QString &value) const
{
    QString s2 = value.normalized(QString::NormalizationForm_D);
    QString out;

    for (int i=0, j=s2.length(); i<j; i++)
    {
        // strip diacritic marks
        if (s2.at(i).category() != QChar::Mark_NonSpacing &&
                s2.at(i).category() != QChar::Mark_SpacingCombining) {
            out.append(s2.at(i));
        }
    }
    return out.toUpper();
}

void DialPadSearch::populateContacts(const QList<QContact> &qcontacts)
{
    int favoritePos = 0;
    for (const QContact &resultContact: qcontacts) {

        QStringList phoneNumbers;
        for(const QContactPhoneNumber phoneNumber: resultContact.details(QContactDetail::TypePhoneNumber)) {
            phoneNumbers << phoneNumber.number();
        }

        if (!phoneNumbers.isEmpty()) {
            QString displayLabel = resultContact.detail(QContactDetail::TypeDisplayLabel).value(QContactDisplayLabel::FieldLabel).toString();
            bool isFavorite = resultContact.detail(QContactDetail::TypeFavorite).value(QContactFavorite::FieldFavorite).toBool();

            Contact contact = Contact(displayLabel, phoneNumbers);
            //store normalized field for later local search
            if (mState == SearchState::NAME_SEARCH) {
                QString nameLabel = resultContact.detail(QContactDetail::TypeName).value(QContactName::FieldLastName).toString();
                QString firstNameLabel = resultContact.detail(QContactDetail::TypeName).value(QContactName::FieldFirstName).toString();
                QStringList normalizedValues;
                normalizedValues << normalize(nameLabel) << normalize(firstNameLabel);
                contact.setNormalizedValues(normalizedValues);
            }

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

QList<QContactFilter> DialPadSearch::generateTextFilters()
{
    QStringList initialPatterns;
    mPatterns = generatePatterns(mSearchHistory, initialPatterns);

    QList<QContactFilter> filters;

    for (const auto& pattern : mPatterns) {
        QContactDetailFilter nameFilter;
        nameFilter.setDetailType(QContactDetail::TypeName, QContactName::FieldLastName);
        nameFilter.setMatchFlags(QContactFilter::MatchStartsWith);
        nameFilter.setValue(pattern);

        QContactDetailFilter firstnameFilter;
        firstnameFilter.setDetailType(QContactDetail::TypeName,QContactName::FieldFirstName);
        firstnameFilter.setMatchFlags(QContactFilter::MatchStartsWith);
        firstnameFilter.setValue(pattern);

        filters << nameFilter;
        filters << firstnameFilter;
    }
    return filters;
}

QStringList DialPadSearch::generatePatterns(const QStringList &source, QStringList &currentPatterns) {

    // transform a pattern list into a queryable text. e.g: {"ABC","DEF"} -> {"AD","AE","AF","BD","BE","BF","CD","CE","CF"}
    for (const QString& pattern: source) {
        const QStringList ps = pattern.split("", QString::SkipEmptyParts);

        if (currentPatterns.isEmpty()) {
            currentPatterns << ps;
        } else {
            QStringList tmpPatterns;
            for (const QString& currentPattern: currentPatterns ) {
                for (const QString& p: ps ) {
                    tmpPatterns << currentPattern + p;
                }
            }
            currentPatterns = tmpPatterns;
        }
    }
    return currentPatterns;
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

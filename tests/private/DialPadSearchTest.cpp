/*
 * Copyright 2020 Ubports Foundation
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

#include <QtCore/QObject>
#include <QtTest/QtTest>

#include "dialpadsearch.h"
#include "contactutils.h"
#include <QContact>
#include <QContactName>
#include <QContactPhoneNumber>
#include <QContactDisplayLabel>
#include <QContactExtendedDetail>
#include <QContactFavorite>

QTCONTACTS_USE_NAMESPACE

class DialPadSearchTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase();
    void init();
    void cleanup();
    void cleanupTestCase();
    void testShouldSwitchToNameSearch();
    void testShouldSwitchToNumberSearch();
    void testShouldSwitchToNumberSearchAfterNameSearch();
    void testShouldReturnToNoFilter();
    void testShouldReturnToNameFilter();
    void testShouldReturnAllContacts();
    void testShouldFindByNumber();
    void testShouldFindWithInternationalPrefix();
    void testShouldReturnFavoritesFirst();
    void testShouldClearAllWhenPhoneNumberIsOverwritten();

private:
    QContact createContact(const QString &firstName,
                           const QString &lastName,
                           const QStringList &phoneNumbers,
                           const QList<int> &subTypes,
                           const QList<int> &contexts);
    void clearManager();
    QContactManager *mManager;
    DialPadSearch *dialPadSearch;
};

void DialPadSearchTest::initTestCase()
{
    // instanciate the shared manager using the memory backend
    mManager = ContactUtils::sharedManager("memory");
    dialPadSearch = new DialPadSearch();
    dialPadSearch->setManager("memory");
}

void DialPadSearchTest::init()
{
    createContact("contactA",
                  "contactA",
                  QStringList() << "1111111111",
                  QList<int>() << 0 << 1 << 2,
                  QList<int>() << 3 << 4 << 5);

    createContact("contactB",
                  "contactB",
                  QStringList() << "3333333333",
                  QList<int>() << 0 << 1 << 2,
                  QList<int>() << 3 << 4 << 5);

}

void DialPadSearchTest::cleanupTestCase()
{
    dialPadSearch->deleteLater();
}

void DialPadSearchTest::cleanup()
{
    dialPadSearch->clearAll();
    dialPadSearch->setPhoneNumber("");
    clearManager();
}

void DialPadSearchTest::testShouldSwitchToNameSearch()
{
    QSignalSpy spyRowCount(dialPadSearch, SIGNAL(rowCountChanged()));
    QSignalSpy spyQueryChanged(dialPadSearch, SIGNAL(queryChanged()));

    dialPadSearch->setPhoneNumber("26");
    dialPadSearch->push("ABC");
    dialPadSearch->push("MNO");

    QTRY_COMPARE(spyRowCount.count(), 1);
    QTRY_COMPARE(spyQueryChanged.count(), 1);
    QCOMPARE(dialPadSearch->state(), DialPadSearch::NAME_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 2);

}

void DialPadSearchTest::testShouldSwitchToNumberSearch()
{
    QSignalSpy spyRowCount(dialPadSearch, SIGNAL(rowCountChanged()));
    QSignalSpy spyQueryChanged(dialPadSearch, SIGNAL(queryChanged()));

    dialPadSearch->setPhoneNumber("0");
    dialPadSearch->push("0");

    QTRY_COMPARE(spyRowCount.count(), 0);
    QTRY_COMPARE(spyQueryChanged.count(), 0);
    QCOMPARE(dialPadSearch->state(), DialPadSearch::NUMBER_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 0);

}

void DialPadSearchTest::testShouldReturnToNoFilter()
{

    dialPadSearch->setPhoneNumber("6");
    dialPadSearch->push("MNO");
    dialPadSearch->setPhoneNumber("");
    dialPadSearch->pop();

    QCOMPARE(dialPadSearch->state(), DialPadSearch::NO_FILTER);
    QCOMPARE(dialPadSearch->rowCount(), 0);

}

void DialPadSearchTest::testShouldReturnToNameFilter()
{

    QSignalSpy spyRowCount(dialPadSearch, SIGNAL(rowCountChanged()));

    dialPadSearch->setPhoneNumber("26");
    dialPadSearch->push("ABC");
    dialPadSearch->push("MNO");
    QTRY_COMPARE(spyRowCount.count(), 1);
    QCOMPARE(dialPadSearch->state(), DialPadSearch::NAME_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 2);

    dialPadSearch->setPhoneNumber("269");
    dialPadSearch->push("WXYZ");
    QCOMPARE(dialPadSearch->state(), DialPadSearch::NUMBER_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 0);

    dialPadSearch->pop();

    QCOMPARE(dialPadSearch->state(), DialPadSearch::NAME_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 2);

}

void DialPadSearchTest::testShouldReturnAllContacts()
{
    QSignalSpy spyRowCount(dialPadSearch, SIGNAL(rowCountChanged()));

    dialPadSearch->setPhoneNumber("26");
    dialPadSearch->push("ABC");
    dialPadSearch->push("MNO");

    QTRY_COMPARE(spyRowCount.count(), 1);
    QCOMPARE(dialPadSearch->state(), DialPadSearch::NAME_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 2);

}

void DialPadSearchTest::testShouldSwitchToNumberSearchAfterNameSearch()
{
    QSignalSpy spyRowCount(dialPadSearch, SIGNAL(rowCountChanged()));

    dialPadSearch->setPhoneNumber("666");
    dialPadSearch->push("MNO");
    dialPadSearch->push("MNO");
    dialPadSearch->push("MNO");

    QTRY_COMPARE(spyRowCount.count(), 3);
    QCOMPARE(dialPadSearch->state(), DialPadSearch::NUMBER_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 0);

}

void DialPadSearchTest::testShouldFindByNumber()
{
    QSignalSpy spyRowCount(dialPadSearch, SIGNAL(rowCountChanged()));

    dialPadSearch->setPhoneNumber("333");
    dialPadSearch->push("DEF");
    dialPadSearch->push("DEF");
    dialPadSearch->push("DEF");

    QTRY_COMPARE(spyRowCount.count(), 3);
    QCOMPARE(dialPadSearch->state(), DialPadSearch::NUMBER_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 1);

}

void DialPadSearchTest::testShouldFindWithInternationalPrefix()
{
    createContact("guillaume",
                  "guillaume",
                  QStringList() << "+3362111445",
                  QList<int>() << 0 << 1 << 2,
                  QList<int>() << 3 << 4 << 5);

    dialPadSearch->setCountryCode(33);

    dialPadSearch->setPhoneNumber("062");
    dialPadSearch->push("0");
    dialPadSearch->push("MNO");
    dialPadSearch->push("ABC");

    QCOMPARE(dialPadSearch->state(), DialPadSearch::NUMBER_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 1);
}

void DialPadSearchTest::testShouldReturnFavoritesFirst()
{

    QContact contact;

    // Name
    QContactName name;
    name.setFirstName("contactZ");
    name.setLastName("contactZ");
    contact.saveDetail(&name);

    QContactDisplayLabel displayLabel;
    displayLabel.setLabel("favorite contact");
    contact.saveDetail(&displayLabel);

    QContactPhoneNumber number;
    number.setNumber("5251254222");
    number.setSubTypes(QList<int>() << 0 << 1 << 2);
    number.setContexts(QList<int>() << 3 << 4 << 5);
    contact.saveDetail(&number);

    QContactFavorite favorite;
    favorite.setFavorite(true);
    contact.saveDetail(&favorite);

    mManager->saveContact(&contact);


    QSignalSpy spyRowCount(dialPadSearch, SIGNAL(rowCountChanged()));

    dialPadSearch->setPhoneNumber("26");
    dialPadSearch->push("ABC");
    dialPadSearch->push("MNO");

    QTRY_COMPARE(spyRowCount.count(), 1);
    QCOMPARE(dialPadSearch->state(), DialPadSearch::NAME_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 3);
    QCOMPARE(dialPadSearch->get(0)["displayLabel"], "favorite contact");


}

void DialPadSearchTest::testShouldClearAllWhenPhoneNumberIsOverwritten() {

    QSignalSpy spyRowCount(dialPadSearch, SIGNAL(rowCountChanged()));

    dialPadSearch->setPhoneNumber("26");
    dialPadSearch->push("ABC");
    dialPadSearch->push("MNO");

    QTRY_COMPARE(spyRowCount.count(), 1);
    QCOMPARE(dialPadSearch->state(), DialPadSearch::NAME_SEARCH);
    QCOMPARE(dialPadSearch->rowCount(), 2);
    //simulate a change from outside
    dialPadSearch->setPhoneNumber("185");
    QCOMPARE(dialPadSearch->state(), DialPadSearch::NO_FILTER);
    QCOMPARE(dialPadSearch->rowCount(), 0);
}

QContact DialPadSearchTest::createContact(const QString &firstName,
                                           const QString &lastName,
                                           const QStringList &phoneNumbers,
                                           const QList<int> &subTypes,
                                           const QList<int> &contexts)
{
    QContact contact;

    // Name
    QContactName name;
    name.setFirstName(firstName);
    name.setLastName(lastName);
    contact.saveDetail(&name);

    QContactDisplayLabel displayLabel;
    displayLabel.setLabel(firstName + " " + lastName);
    contact.saveDetail(&displayLabel);

    Q_FOREACH(const QString &phoneNumber, phoneNumbers) {
        QContactPhoneNumber number;
        number.setNumber(phoneNumber);
        number.setSubTypes(subTypes);
        number.setContexts(contexts);
        contact.saveDetail(&number);
    }

    mManager->saveContact(&contact);
    return contact;
}

void DialPadSearchTest::clearManager()
{
    Q_FOREACH(QContact contact, mManager->contacts()) {
        mManager->removeContact(contact.id());
    }
}

QTEST_MAIN(DialPadSearchTest)
#include "DialPadSearchTest.moc"

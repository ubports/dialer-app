# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2014 Canonical
# Author: Omer Akram <omer.akram@canonical.com>
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Dialer App"""

from autopilot.platform import model
from autopilot.matchers import Eventually
from testtools import skipIf
from testtools.matchers import Equals
from url_dispatcher_testability import (
    fake_dispatcher,
    fixture_setup as url_dispatcher_fixtures
)

from address_book_app.address_book import data
from dialer_app.tests import DialerAppTestCase
from dialer_app import fixture_setup
from dialer_app import ListItemWithActions
from dialer_app import ContactsPage
from dialer_app import DialerContactEditorPage
from dialer_app import DialerContactViewPage



class TestCallLogs(DialerAppTestCase):
    """Tests for the call log panel."""

    def setUp(self):
        # set the fixtures before launching the app
        testability_environment = fixture_setup.TestabilityEnvironment()
        self.useFixture(testability_environment)
        fill_history = fixture_setup.FillCustomHistory()
        self.useFixture(fill_history)
        self.fake_url_dispatcher = url_dispatcher_fixtures.FakeURLDispatcher()
        self.useFixture(self.fake_url_dispatcher)
        memory_backend = fixture_setup.UseMemoryContactBackend()
        self.useFixture(memory_backend)

        # now launch the app
        super().setUp()
        self.main_view.dialer_page.reveal_bottom_edge_page()

    def _get_main_view(self, proxy_object):
        return proxy_object.wait_select_single('QQuickView')

    def get_last_dispatch_url_call_parameter(self):
        try:
            fake = self.fake_url_dispatcher
            return fake.get_last_dispatch_url_call_parameter()
        except fake_dispatcher.FakeDispatcherException:
            return None

    @skipIf(model() == 'Desktop',
        'only run on Ubuntu touch platforms')
    def test_call_log_item_opens_messaging(self):
        """Ensure tapping on 'send text message' item of a call log opens
        the messaging app.

        """
        delegate = self.main_view.wait_select_single(
            ListItemWithActions.HistoryDelegate, objectName='historyDelegate0')
        delegate.send_message()

        self.assertThat(
            self.get_last_dispatch_url_call_parameter,
            Eventually(Equals('message:///800')))

    def test_add_new_contact_from_log(self):
        """Ensure tapping on 'add new contact' item of a call log opens
        the address-book app to allow adding new contact.

        """
        delegate = self.main_view.wait_select_single(
            ListItemWithActions.HistoryDelegate, objectName='historyDelegate0')
        delegate.add_contact()

        contactsPage = self.main_view.wait_select_single(
            ContactsPage, objectName='contactsPage')

        self.assertThat(
            contactsPage.phoneToAdd, Eventually(Equals('800')))

        # click add new button
        contactsPage.click_add_new()

        # wait page be ready for edit
        contactEditor = self.main_view.wait_select_single(
            DialerContactEditorPage, objectName='contactEditorPage')
        contactEditor.wait_get_focus('phones')

        # fill contact name
        test_contact = data.Contact('FirstName', 'LastName')
        test_contact.professional_details = []
        contactEditor.fill_form(test_contact)

        # save contact
        contactEditor.save()

        # contact view will appear with the new contact data
        contactView = contactsPage.open_contact(0)
        self.assertThat(contactView.visible, Eventually(Equals(True)))

        # check if contact contains the new phone number
        phone_group = contactView.select_single(
            'ContactDetailGroupWithTypeView',
            objectName='phones')
        self.assertThat(phone_group.detailsCount, Eventually(Equals(1)))

        # check if the new value is correct
        phone_label_1 = contactView.select_single(
            "Label",
            objectName="label_phoneNumber_0.0")
        self.assertThat(phone_label_1.text, Eventually(Equals('800')))

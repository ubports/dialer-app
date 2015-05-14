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
        preload_data = fixture_setup.PreloadVcards()
        self.useFixture(preload_data)

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

    @skipIf(model() == 'Desktop', 'only run on Ubuntu touch platforms')
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

        contacts_page = self.main_view.contacts_page
        self.assertThat(
            contacts_page.phoneToAdd, Eventually(Equals('800')))

        # click add new button
        contacts_page.click_add_new()

        # wait page be ready for edit
        contact_editor_page = self.main_view.contact_editor_page
        self.main_view.contact_editor_page.wait_get_focus('phones')

        # fill contact name
        test_contact = data.Contact('FirstName', 'LastName')
        test_contact.professional_details = []
        contact_editor_page.fill_form(test_contact)

        # save contact
        contact_editor_page.save()

        # contact view will appear with the new contact data
        contact_view_page = contacts_page.open_contact(3)
        self.assertThat(contact_view_page.visible, Eventually(Equals(True)))

        # check if contact contains the new phone number
        phone_group = contact_view_page.select_single(
            'ContactDetailGroupWithTypeView',
            objectName='phones')
        self.assertThat(phone_group.detailsCount, Eventually(Equals(1)))

        # check if the new value is correct
        phone_label_1 = contact_view_page.select_single(
            "Label",
            objectName="label_phoneNumber_0.0")
        self.assertThat(phone_label_1.text, Eventually(Equals('800')))

    def test_add_number_into_old_contact_from_log(self):
        """Ensure tapping on 'add new contact' item of a call log opens
        the address-book app to allow add the numbe into a contact

        """
        delegate = self.main_view.wait_select_single(
            ListItemWithActions.HistoryDelegate, objectName='historyDelegate0')
        delegate.add_contact()

        contacts_page = self.main_view.contacts_page
        self.assertThat(
            contacts_page.phoneToAdd, Eventually(Equals('800')))

        # click on first contact to add number
        contacts_page.click_contact(0)

        # wait page be ready for edit
        contact_editor_page = self.main_view.contact_editor_page
        contact_editor_page.wait_get_focus('phones')

        # save contact
        contact_editor_page.save()

        # contact view will appear with the new contact data
        contact_view_page = self.main_view.contact_view_page

        # check if contact contains the new phone number
        phone_group = contact_view_page.select_single(
            'ContactDetailGroupWithTypeView',
            objectName='phones')
        self.assertThat(phone_group.detailsCount, Eventually(Equals(2)))

        # check if the new value is correct
        phone_label_1 = contact_view_page.select_single(
            "Label",
            objectName="label_phoneNumber_1.0")
        self.assertThat(phone_label_1.text, Eventually(Equals('800')))


class TestSwipeItemTutorial(DialerAppTestCase):
    """Tests for swipe item tutorial."""

    def setUp(self):
        # set the fixtures before launching the app
        testability_environment = fixture_setup.TestabilityEnvironment()
        self.useFixture(testability_environment)
        fill_history = fixture_setup.FillCustomHistory()
        self.useFixture(fill_history)

        # now launch the app
        super().setUp(firstLaunch=True)
        self.main_view.dialer_page.reveal_bottom_edge_page()

    def _get_main_view(self, proxy_object):
        return proxy_object.wait_select_single('QQuickView')

    def test_swipe_item_tutorial_appears(self):
        """Ensure that the swipe item tutorial appears on first launch"""
        swipe_item_demo = self.main_view.wait_select_single(
            'SwipeItemDemo', objectName='swipeItemDemo')

        self.assertThat(swipe_item_demo.enabled, Eventually(Equals(True)))
        self.assertThat(swipe_item_demo.necessary, Eventually(Equals(True)))
        got_it_button = swipe_item_demo.select_single(
            'Button',
            objectName='gotItButton')
        self.main_view._click_button(got_it_button)
        self.assertThat(swipe_item_demo.enabled, Eventually(Equals(False)))
        self.assertThat(swipe_item_demo.necessary, Eventually(Equals(False)))

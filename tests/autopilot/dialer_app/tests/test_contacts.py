# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2015 Canonical
# Author: Renato Araujo Oliveira Filho <renato.filho@canonical.com>
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Dialer App"""

from autopilot.matchers import Eventually
from testtools.matchers import Equals

from dialer_app.tests import DialerAppTestCase
from dialer_app import fixture_setup


class TestContacts(DialerAppTestCase):
    """Tests for the contacts interaction with the app."""

    def setUp(self):
        # set the fixtures before launching the app
        testability_environment = fixture_setup.TestabilityEnvironment()
        self.useFixture(testability_environment)
        memory_backend = fixture_setup.UseMemoryContactBackend()
        self.useFixture(memory_backend)
        preload_data = fixture_setup.PreloadVcards()
        self.useFixture(preload_data)

        # now launch the app
        super().setUp()

    def _get_main_view(self, proxy_object):
        return proxy_object.wait_select_single('QQuickView')

    def test_call_a_contact_from_contact_view(self):
        dialer_page = self.main_view.dialer_page
        dialer_page.click_contacts_button()
        contact_view_page = self.main_view.contacts_page.open_contact(0)

        contact_view_page.call_phone(0)
        entry = dialer_page._get_keypad_entry()
        self.assertThat(entry.value, Eventually(Equals('444-44')))

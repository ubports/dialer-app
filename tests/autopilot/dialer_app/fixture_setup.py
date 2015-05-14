# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014 Canonical Ltd.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

"""Set up and clean up fixtures for the Inter-app integration tests."""


import fixtures
import subprocess
import os
import shutil
import dbusmock
from autopilot.platform import model
import dbus
from ubuntuuitoolkit import fixture_setup


class TestabilityEnvironment(fixtures.Fixture):

    def setUp(self):
        super().setUp()
        self._set_testability_environment_variable()
        self.addCleanup(self._reset_environment_variable)

    def _set_testability_environment_variable(self):
        """Make sure every app loads the testability driver."""
        subprocess.call(
            [
                '/sbin/initctl',
                'set-env',
                '--global',
                'QT_LOAD_TESTABILITY=1'
            ]
        )

    def _reset_environment_variable(self):
        """Resets the previously added env variable."""
        subprocess.call(
            [
                '/sbin/initctl',
                'unset-env',
                'QT_LOAD_TESTABILITY'
            ]
        )


class FillCustomHistory(fixtures.Fixture):

    history_db = "history.sqlite"
    data_sys = "/usr/lib/python3/dist-packages/dialer_app/data/"
    data_local = "dialer_app/data/"
    database_path = '/tmp/' + history_db

    prefilled_history_local = os.path.join(data_local, history_db)
    prefilled_history_system = os.path.join(data_sys, history_db)

    def setUp(self):
        super(FillCustomHistory, self).setUp()
        self.addCleanup(self._clear_test_data)
        self.addCleanup(self._kill_service_to_respawn)
        self._clear_test_data()
        self._prepare_history_data()
        self._kill_service_to_respawn()
        self._start_service_with_custom_data()

    def _prepare_history_data(self):
        if os.path.exists(self.prefilled_history_local):
            shutil.copy(self.prefilled_history_local, self.database_path)
        else:
            shutil.copy(self.prefilled_history_system, self.database_path)

    def _clear_test_data(self):
        if os.path.exists(self.database_path):
            os.remove(self.database_path)

    def _kill_service_to_respawn(self):
        subprocess.call(['pkill', 'history-daemon'])

    def _start_service_with_custom_data(self):
        os.environ['HISTORY_SQLITE_DBPATH'] = self.database_path
        with open(os.devnull, 'w') as devnull:
            subprocess.Popen(['history-daemon'], stderr=devnull)


class UseEmptyHistory(FillCustomHistory):
    database_path = ':memory:'

    def setUp(self):
        super(UseEmptyHistory, self).setUp()

    def _prepare_history_data(self):
        # just avoid doing anything
        self.database_path = ':memory:'

    def _clear_test_data(self):
        # don't do anything
        self.database_path = ''


class UsePhonesimModem(fixtures.Fixture):

    def setUp(self):
        super().setUp()

        # configure the cleanups
        self.addCleanup(self._hangupLeftoverCalls)
        self.addCleanup(self._restoreModems)

        self._switchToPhonesim()

    def _switchToPhonesim(self):
        # make sure the modem is running on phonesim
        subprocess.call(['mc-tool', 'update', 'ofono/ofono/account0',
                         'string:modem-objpath=/phonesim'])
        subprocess.call(['mc-tool', 'reconnect', 'ofono/ofono/account0'])

    def _hangupLeftoverCalls(self):
        # ensure that there are no leftover calls in case of failed tests
        subprocess.call(["/usr/share/ofono/scripts/hangup-all", "/phonesim"])

    def _restoreModems(self):
        # set the modem objpath in telepathy-ofono to the real modem
        subprocess.call(['mc-tool', 'update', 'ofono/ofono/account0',
                         'string:modem-objpath=/ril_0'])
        subprocess.call(['mc-tool', 'reconnect', 'ofono/ofono/account0'])


class UseMemoryContactBackend(fixtures.Fixture):

    def setUp(self):
        super().setUp()
        self.useFixture(
            fixtures.EnvironmentVariable(
                'QTCONTACTS_MANAGER_OVERRIDE', newvalue='memory')
        )
        self.useFixture(
            fixture_setup.InitctlEnvironmentVariable(
                QTCONTACTS_MANAGER_OVERRIDE='memory')
        )


class PreloadVcards(fixtures.Fixture):
    AUTOPILOT_DIR = "/usr/lib/python3/dist-packages/dialer_app/"
    VCARD_PATH_BIN = ("%s/testdata/vcard.vcf" % AUTOPILOT_DIR)
    VCARD_PATH_DEV = os.path.abspath("../data/vcard.vcf")

    def setUp(self):
        super().setUp()
        vcard_full_path = PreloadVcards.VCARD_PATH_BIN
        if os.path.isfile(PreloadVcards.VCARD_PATH_DEV):
            vcard_full_path = PreloadVcards.VCARD_PATH_DEV

        print("Loading contacts from: %s" % vcard_full_path)
        self.useFixture(
            fixtures.EnvironmentVariable(
                'QTCONTACTS_PRELOAD_VCARD', newvalue=vcard_full_path)
        )
        self.useFixture(
            fixture_setup.InitctlEnvironmentVariable(
                QTCONTACTS_PRELOAD_VCARD=vcard_full_path)
        )


class MockNotificationSystem(fixtures.Fixture):

    def setUp(self):
        super().setUp()

        # only mock the notification system on desktop, on ubuntu touch the
        # notification dbus service is embedded into unity
        if model() == 'Desktop':
            self.addCleanup(self._stop_mock)
            self._kill_notification_service()
            # start the mock service
            (self.process, self.obj) = \
                dbusmock.DBusTestCase.spawn_server_template(
                    'notification_daemon')
        else:
            self.addCleanup(self._clear_existing_notifications)

    def _stop_mock(self):
        self.process.terminate()
        self.process.wait()

    def _kill_notification_service(self):
        """Kill the notification daemon."""
        subprocess.call(['pkill', '-f', 'notify-osd'])

    def _clear_existing_notifications(self):
        """Kill processes that might be displaying notifications"""
        bus = dbus.SessionBus()
        indicator = bus.get_object('com.canonical.TelephonyServiceIndicator',
                                   '/com/canonical/TelephonyServiceIndicator')
        indicator.ClearNotifications()

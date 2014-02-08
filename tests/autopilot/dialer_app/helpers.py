# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014 Canonical Ltd.
# Author: Omer Akram <omer.akram@canonical.com>
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

from autopilot.platform import model

import subprocess
import sys
import time


class TelephonyTestHelpers(object):

    def wait_for_incoming_call(self):
        """Wait up to 5 s for an incoming phone call"""

        timeout = 10
        while timeout >= 0:
            out = subprocess.check_output(
                ['/usr/share/ofono/scripts/list-calls'],
                stderr=subprocess.PIPE)
            if 'State = incoming' in out:
                break
            timeout -= 1
            time.sleep(0.5)
        else:
            self.fail('timed out waiting for incoming phonesim call')

        # on desktop, notify-osd generates a persistent popup, clean this up
        if model() == 'Desktop':
            subprocess.call(['pkill', '-f', 'notify-osd'])

    def invoke_incoming_call(self):
        """Invoke an incoming call for test purpose."""
        # magic number 199 will cause a callback from 1234567; dialing 199
        # itself will fail, so quiesce the error
        subprocess.call(['/usr/share/ofono/scripts/dial-number', '199'],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def is_phonesim_running():
    """Determine whether we are running with phonesim."""
    try:
        out = subprocess.check_output(
            [
                '/usr/share/ofono/scripts/list-modems',
            ], stderr=subprocess.PIPE)
        return out.startswith('[ /phonesim ]')
    except subprocess.CalledProcessError:
        return False


def ensure_ofono_account():
    if not _is_ofono_account_set():
        subprocess.check_call(['ofono-setup'])
        if not _is_ofono_account_set():
            sys.stderr.write('ofono-setup failed to create ofono account!\n')
            sys.exit(1)


def _is_ofono_account_set():
    mc_tool = subprocess.Popen(
        [
            'mc-tool',
            'list',
        ], stdout=subprocess.PIPE, universal_newlines=True)
    mc_accounts = mc_tool.communicate()[0]
    return 'ofono/ofono/account' in mc_accounts

# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014-2015 Canonical Ltd.
# Authors: Omer Akram <omer.akram@canonical.com>
#          Gustavo Pichorim Boiko <gustavo.boiko@canonical.com>
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

import subprocess
import sys
import time
import dbus
import tempfile
import os
import shutil


def wait_for_incoming_call():
    """Wait up to 5 s for an incoming phone call"""

    timeout = 10
    while timeout >= 0:
        out = subprocess.check_output(
            ['/usr/share/ofono/scripts/list-calls'],
            stderr=subprocess.PIPE,
            universal_newlines=True)
        if 'State = incoming' in out or 'State = waiting' in out:
            break
        timeout -= 1
        time.sleep(0.5)
    else:
        raise RuntimeError('timed out waiting for incoming phonesim call')


def invoke_incoming_call(caller):
    """Receive an incoming call from the given caller

    :parameter caller: the phone number calling
    """

    # prepare and send a Qt GUI script to phonesim, over its private D-BUS
    # set up by ofono-phonesim-autostart
    script_dir = tempfile.mkdtemp(prefix="phonesim_script")
    os.chmod(script_dir, 0o755)
    with open(os.path.join(script_dir, "call.js"), "w") as f:
        f.write("""tabCall.gbIncomingCall.leCaller.text = "%s";
tabCall.gbIncomingCall.pbIncomingCall.click();
""" % (caller))

    with open("/run/lock/ofono-phonesim-dbus.address") as f:
        phonesim_bus = f.read().strip()
    bus = dbus.bus.BusConnection(phonesim_bus)
    script_proxy = bus.get_object("org.ofono.phonesim", "/")
    script_proxy.SetPath(script_dir)
    script_proxy.Run("call.js")
    shutil.rmtree(script_dir)


def accept_incoming_call():
    """Accept an existing incoming call"""
    subprocess.check_call(
        [
            "dbus-send", "--session", "--print-reply",
            "--dest=com.canonical.Approver", "/com/canonical/Approver",
            "com.canonical.TelephonyServiceApprover.AcceptCall"
        ], stdout=subprocess.PIPE)


def get_phonesim():
    bus = dbus.SystemBus()
    try:
        manager = dbus.Interface(bus.get_object('org.ofono', '/'),
                                 'org.ofono.Manager')
    except dbus.exceptions.DBusException:
        return False

    modems = manager.GetModems()

    for path, properties in modems:
        if path == '/phonesim':
            return properties

    return None


def is_phonesim_running():
    """Determine whether we are running with phonesim."""
    phonesim = get_phonesim()
    return phonesim is not None


def ensure_ofono_account():
    # oFono modems are now set online by NetworkManager, so for the tests
    # we need to manually put them online.
    subprocess.check_call(['/usr/share/ofono/scripts/enable-modem',
                           '/phonesim'])
    subprocess.check_call(['/usr/share/ofono/scripts/online-modem',
                           '/phonesim'])

    # wait until the modem is actually online
    for index in range(10):
        phonesim = get_phonesim()
        if phonesim['Online'] == 1:
            break
        time.sleep(1)
    else:
        raise RuntimeError("oFono phone simulator didn't get online.")

    # this is a bit drastic, but sometimes mission-control-5 won't recognize
    # clients installed after it was started, so, we make sure it gets
    # restarted
    subprocess.check_call(['pkill', '-9', 'mission-control'])

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

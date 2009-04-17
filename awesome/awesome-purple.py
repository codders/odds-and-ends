#!/usr/bin/env python

from BeautifulSoup import BeautifulSoup
import os
import dbus.glib
import gobject
import sys
from xml.sax.saxutils import escape

bus = dbus.SessionBus()

obj = None
try:
    obj = bus.get_object("im.pidgin.purple.PurpleService", "/im/pidgin/purple/PurpleObject")
except:
    pass

purple = dbus.Interface(obj, "im.pidgin.purple.PurpleInterface")

class CheckedObject:
    def __init__(self, obj):
        self.obj = obj

    def __getattr__(self, attr):
        return CheckedAttribute(self, attr)

class CheckedAttribute:
    def __init__(self, cobj, attr):
        self.cobj = cobj
        self.attr = attr
        
    def __call__(self, *args):
        result = self.cobj.obj.__getattr__(self.attr)(*args)
        if result == 0:
            raise "Error: " + self.attr + " " + str(args) + " returned " + str(result)
        return result

cpurple = CheckedObject(purple)

def awesome_write(string):
    awesome = os.popen("awesome-client", "w")
    widget_message = "mychatbox.text='%s'\n" % escape(string)
    awesome.write(widget_message)
    awesome.close()

def message_received(account, sender, message, conversation, flags):
    html = BeautifulSoup(message)
    try:
      message = html.font.font.string
    except Exception, e:
      try:
          message = html.body.string
      except Exception, e:
          pass
    awesome_write("%s <%s>" % (message, sender))

def message_sent(account, receiver, message):
    awesome_write("")

bus.add_signal_receiver(message_received, dbus_interface="im.pidgin.purple.PurpleInterface", signal_name="ReceivedImMsg")
bus.add_signal_receiver(message_sent, dbus_interface="im.pidgin.purple.PurpleInterface", signal_name="SentImMsg")

gobject.MainLoop().run()


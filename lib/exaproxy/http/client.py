#!/usr/bin/env python
# encoding: utf-8
"""
http.py

Created by Thomas Mangin on 2011-12-02.
Copyright (c) 2011 Exa Networks. All rights reserved.
"""

import socket
import errno

from exaproxy.util.logger import logger

class HTTPClient (object):
	def __init__  (self,cid,host,port,request):
		self.io = None
		self._request = request
		self.cid = cid
		self.host = host
		self.port = port
		self._recv = self._fetch()

	def fileno (self):
		return self.io.fileno()

	def connect (self):
		logger.debug('connecting to webserver %s:%d' % (self.host,self.port), 'http %d' %self.cid)
		try:
			self.io = socket.socket(socket.AF_INET, socket.SOCK_STREAM, socket.IPPROTO_TCP)
		except socket.error,e:
			logger.debug('problem create a connection to %s:%d' % (self.host,self.port), 'http %d' %self.cid)
			return False
		try:
			self.io.setblocking(0)
			self.io.connect((self.host, self.port))
			return True
		except socket.error,e:
			if e.errno in (errno.EINPROGRESS,):
				return True
			logger.debug('problem create a connection to %s:%d' % (self.host,self.port), 'http %d' %self.cid)
			self.close()
			return False

	def request (self):
		try:
			logger.debug('sending request to the website','http %d' % self.cid)
			number = self.io.send(self._request)
			logger.debug('sent %d bytes' % number,'http %d' % self.cid)
			self._request = self._request[number:]
			if not self._request:
				return True
			return False
		except socket.error,e:
#			if e.errno == errno.EISCONN:
#				break
#			if e.errno in (errno.EINPROGRESS,errno.EALREADY):
#				yield False
#				continue
			if e.errno in (errno.EAGAIN,errno.EWOULDBLOCK,errno.EINTR,errno.ENOTCONN):
				logger.debug('http client not ready yet for reading', 'http %d' %self.cid)
				return False
			# XXX: This may well be very incorrect
			logger.debug("problem sending request to %s:%d - %s" % (self.host,self.port,str(e)),'http %d' % self.cid)
			self.close()
			return None


	def fetch (self):
		return self._recv.next()

	def _fetch (self):
		logger.debug("waiting for data from %s:%d" % (self.host,self.port),'http %d' % self.cid)
		# Send the HTTP request to the remote website and yield True while working, otherwise yield None (and why not False ?)
		while True:
			try:
				content = self.io.recv(16*1024)
				if not content:
					# The socket is closed
					break
				yield content
			except socket.error,e:
				if e.errno in (errno.EAGAIN,errno.EWOULDBLOCK,errno.EINTR,):
					yield ''
					continue
				logger.debug('connection closed','http %d' % self.cid)
				break

		self.close()
		yield None

	def close (self):
		logger.debug('closing connection','http %d' % self.cid)
		try:
			self.io.shutdown(socket.SHUT_RDWR)
			self.io.close()
		except socket.error, e:
			pass
		self.runnning = False
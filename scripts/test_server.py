#!/usr/bin/python
from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
from os import curdir, sep
import os
import mimetypes;

PORT_NUMBER = 8080

#This class will handles any incoming request from
#the browser 
class myHandler(BaseHTTPRequestHandler):
  
  #Handler for the GET requests
  def do_GET(self):

    if self.path=="/":
      self.path="/index.html"

    try:
      #Check the file extension required and
      #set the right mime type

      sendReply = False

      if os.path.splitext(self.path)[-1].lower() == "":
        self.path += ".html"      

      sendReply = True
      mimetype = mimetypes.guess_type(curdir + sep + self.path)[0]

      if sendReply == True:
        #Open the static file requested and send it
        f = open(curdir + sep + self.path) 
        self.send_response(200)
        self.send_header('Content-type', mimetype)
        self.end_headers()
        self.wfile.write(f.read())
        f.close()
      return


    except IOError:
      self.send_error(404,'File Not Found: %s' % self.path)

try:
  #Create a web server and define the handler to manage the
  #incoming request
  server = HTTPServer(('', PORT_NUMBER), myHandler)
  print 'Started httpserver on port ' , PORT_NUMBER
  
  #Wait forever for incoming htto requests
  server.serve_forever()

except KeyboardInterrupt:
  print '^C received, shutting down the web server'
  server.socket.close()
#!/usr/bin/env python
import sys
import datetime
from flask import Flask, render_template, request, redirect
from subprocess import check_output, STDOUT, PIPE, CalledProcessError, Popen

app=Flask(__name__)
cmd_count = 0 

head = """
<!DOCTYPE html>
  <html>
    <head> 
      <style>
        table, th, td { border: 1px solid black; border-collapse: collapse; }
        th, td {padding: 15px;}
      </style>
      <br />
      </title> IEP Command Executor v0.1, Aug 2019 </title>
      <br />
    </head>
"""

body_1 = """
<body style="background-color:#F2EBE9">
  <br />
  <form action="/run" method="post">
    <input type="text" name="cmd"></input>
    <input type="submit" value="run"></input>
  </form>
  <br />
<form action="/run" method="post">
"""
 
def run_cmd(cmd):
    output = "error"
    try:
        ps = Popen(cmd, shell=True, stdout=PIPE, stderr=STDOUT)
        output = ps.communicate()[0]
    except CalledProcessError as exc:
        output = "{}".format(exc.output)
    except: # catch *all* exceptions
        output = "{}".format(sys.exc_info())
    return output

def list_to_table(l, fgcolor=None, bgcolor=None):
    rowstyle=""
    if fgcolor: rowstyle += 'style="color:{}"'.format(fgcolor)
    if bgcolor: rowstyle += " bgcolor={}".format(bgcolor)
    rows = ""
    for e in l:
        rows += "<tr {}><td>{}</td></tr>".format(rowstyle, e)
    return '<table style="width:100%">' + rows + "</table>"

@app.route('/run', methods = ['POST'])
def handle_cmd():
    global cmd_count
    cmd_count += 1
    cmd_args = ['timeout', '10']
    cmd = request.form['cmd'].decode("utf-8")
    print("The cmd is '" + cmd + "'" )
    if len(cmd) == 0:
        return "Empty cmd!"
    resp = run_cmd(cmd)
    resp_lines = resp.splitlines()
    print(resp_lines)
    html_resp = list_to_table(resp_lines)
    print(html_resp)
    body_2 = list_to_table(["[{}] Results for {}".format(cmd_count, cmd)], fgcolor='white', bgcolor='#81625C')
    return head + body_1 + body_2 + html_resp + "</body> </html>"

@app.route('/')
def home():
    return head + body_1 + "</html>"

if __name__ == '__main__':
    app.run(debug=True) 

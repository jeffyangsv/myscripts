#!/usr/bin/env python
# -*- coding: utf8 -*-
# --------------------------------------------------------------
# Name:        remote_subnet_command.py
# Version:     v1.0
# Create_Date：2017-7-29
# Author:      GuoLikai
# Description: "一个网段内远程批量执行命令"
# --------------------------------------------------------------
import paramiko
import sys
import threading
import os
def remote_comm(host,user,pwd,comm):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(host,username=user, password=pwd)
    except Exception,e:
        print '%s: Connection Refused' % host
    else:
        stdin, stdout, stderr = ssh.exec_command(comm)
        out = stdout.read()
        err = stderr.read()
        if out:
            print "%s: %s" % (host, out),
        if err:
            print "%s: %s" % (host, err),
    ssh.close()

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print "Usage: %s IpSubnet/IP 'Command'" % sys.argv[0]
        sys.exit(1)
    comm = sys.argv[2]
    user = 'root'
    password = 'srt123'
    if len(sys.argv[1].split('.')) == 3:
        ips = ["%s.%s" % (sys.argv[1],i) for i in range(1,253)]
        for ip  in ips:
            t = threading.Thread(target=remote_comm, args=(ip,user,password,comm))
            t.start()
    elif len(sys.argv[1].split('.')) ==4:
        ip = sys.argv[1]
        remote_comm(ip,user,password,comm)

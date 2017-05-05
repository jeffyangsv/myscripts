#!/bin/bash
systemctl start docker                     	    #启动docker服务
systemctl stop docker                    	      #停止docker服务
systemctl restart flanneld                	    #启动flannel服务
#mk-docker-opts.sh -i                      	    #生成环境变量
source /run/flannel/subnet.env            	    #将环境变量生效
ifconfig docker0 ${FLANNEL_SUBNET}        	    #设置docker0的网卡ip
systemctl restart docker kubelet kube-proxy     #启动docker服务

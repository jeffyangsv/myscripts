#!/usr/bin/env python
# _*_ coding:utf8 _*_
'''Created on 2016-11-20 @Author:Guolikai'''
import sys
import time
sys.path.append('/root/python/mysqlbank')
from Model.Bankdata   import UserInfo,UserLocked,AccountDetails
from BLL.AccountLogin import AccountLogin
from BLL.TryOperation import TryOperation

class AccountSavings(object):
    def __init__(self):
        pass
    def UserOperation(self):
        message = ['select_money','save_money','take_money','transfer_account','accout_details','exit']
        #查询额度、存钱、取钱、转账、账户记录、退出
        for item in enumerate(message,1):
            print item[0],item[1]
        tryoperation = TryOperation()
	while True:
        	your_choice = tryoperation.TryOperationInt('您接下来的操作[1-6]:')
		if your_choice  in range(7):
        	    return message[your_choice-1]
		else:
	            print '\033[32;5m输入的数字超过范围，请在[1-6]选择\033[0m'
		    continue
    def DataTime(self):
        time_result = time.strftime('%Y-%m-%d %H:%M:%S')
        return time_result
    def AccoutRecord(self,username,trans_amount,other_account,description):
        trans_date = self.DataTime()
        accountdetails = AccountDetails()
        record_result = accountdetails.InsertAccountDetails(trans_date,username,trans_amount,other_account,description)
        #print "时间%s用户%s操作%s金额%s " % (trans_date,username,description,trans_amount)
        return record_result

    def AccoutDetails(self,username):
        accountdetails = AccountDetails()
        data = accountdetails.SelectAccountDetails(username)
        for i in range(len(data)):
            dict  =  data[i]
            print dict['trans_date'],dict['trans_account'],dict['description'],dict['trans_amount'],'元'

    def SelectMoney(self,username):
        userinfo = UserInfo()
        selectmoney = userinfo.SelectCurrentMoney(username)
        print  '您的账户金额是%s' % selectmoney
    def SaveMoney(self,username):
        userinfo = UserInfo()
        save_old = userinfo.SelectCurrentMoney(username)
        save_money = 0
        while True:
            tryoperation = TryOperation()
            save_money_value = tryoperation.TryOperationInt('您的存款金额:')
            save_money += save_money_value
            save_old += save_money_value
            choice = tryoperation.TryOperationStr('您是否继续存钱[y/n]:')
            if choice == 'n':
                save_money_result = userinfo.UpdateUserinfoCurrentMoney(username,save_old)
                if save_money_result ==1:
                    record_result = self.AccoutRecord(username, save_money, '-', 'SaveMoney')
                    if record_result == 1:
                        print  'SaveMoney Success'
                        break
            else:
                continue
    def TakeMoney(self,username):
        userinfo = UserInfo()
        take_money = 0
        take_old = userinfo.SelectCurrentMoney(username)
        while True:
            tryoperation = TryOperation()
            take_money_value = tryoperation.TryOperationInt('您的取款金额:')
            if take_old >= take_money_value:
                take_old -= take_money_value
                take_money += take_money_value
                print '您的余额还剩%s元'  %  take_old
                choice = tryoperation.TryOperationStr('您是否继续取钱[y/n]:')
                if choice == 'n':
                    take_money_result = userinfo.UpdateUserinfoCurrentMoney(username, take_old)
                    if take_money_result ==1:
                        record_result = self.AccoutRecord(username, -take_money, '-', 'TakeMoney')
                        if record_result == 1:
                            print  'TakeMoney Success'
                    break
                else:
                    continue
            else:
                print "\033[35;5m您的余额不足剩%s元\033[1m"  %  take_old
                break
    def TransferMoney(self,username):
        userinfo = UserInfo()
        transfer_money = 0
        transfer_old = userinfo.SelectCurrentMoney(username)
        while True:
            tryoperation = TryOperation()
            transfer_money_value = tryoperation.TryOperationInt('请输入转账金额:')
            if transfer_old >= transfer_money_value:
                transfer_old -= transfer_money_value
                transfer_money += transfer_money_value
                print '您的余额还剩%s元' % transfer_old
                choice = tryoperation.TryOperationStr('您是否继续输入转账金额[y/n]:')
                if choice == 'n':
                    return transfer_money
                else:
                    continue
            else:
                print '您的余额不足，还剩%s元' % transfer_old
                continue
    def TransferOtherAccount(self,username):
        while True:
            tryoperation = TryOperation()
	    accountlogin = AccountLogin()
            transfer_other_account = tryoperation.TryOperationIntput('请输入转账账户:')
            lock_result = accountlogin.AccountNameLock(transfer_other_account)
            if lock_result == 'Account Unlock':
                exist_result =  accountlogin.AccountNameExist(transfer_other_account)
                if exist_result == 'Account Exist':
		    if transfer_other_account==username:
			print '\033[35;1m您不可以对自己转账!\033[0m'
			continue
		    else:		
                    	return transfer_other_account
                        choice = tryoperation.TryOperationStr('您是否继续输入转账账户[y/n]:')
                        if choice == 'n':
                    	    return 'Transfer Continue Failed'
                        else:
                            continue
	    else:
		print '您输入的账户被锁定，不能转账'
		continue
    def ProcessFee(self,money):
        percentage = "%5"
        return money*float(percentage.replace("%",""))/1000
    def TransferAccounts(self,username):
        while True:
            userinfo = UserInfo()
            other_account = self.TransferOtherAccount(username)
	    if other_account == 'Transfer Continue Failed':
	        break
            else: 
                trans_money = self.TransferMoney(username)
                processfee  = self.ProcessFee(trans_money)
                current_amount = userinfo.SelectCurrentMoney(username)
                other_amount = userinfo.SelectCurrentMoney(other_account)
                print '转账前',trans_money,current_amount,other_amount
                current_new_money = current_amount - trans_money - processfee
                other_new_amount  = other_amount + trans_money
                print '转账后',current_new_money,other_new_amount
                current_update_amount = userinfo.UpdateUserinfoCurrentMoney(username,current_new_money)
                if current_update_amount == 1:
                    other_update_amount = userinfo.UpdateUserinfoCurrentMoney(other_account,other_new_amount)
                    if other_update_amount ==1:
                        print 'TransAmount Success'
                        self.AccoutRecord(username,-trans_money,other_account,'AccountTransfer')
                        self.AccoutRecord(username,-processfee,other_account,'AccountProcessFee')
                        self.AccoutRecord(other_account,trans_money,username,'AccountReceived')
            		tryoperation = TryOperation()
                    	choice = tryoperation.TryOperationStr('您是否继续转账[y/n]:')
                    	if choice == 'n':
				break
                    	else:
                        	continue

                    else:
                        userinfo.UpdateUserinfoCurrentMoney(username,current_amount)
                        userinfo.UpdateUserinfoCurrentMoney(other_account,other_amount)
    def AccountSavingsMain(self,username):
        while True:
            login_operation_result = self.UserOperation()
            if login_operation_result=='select_money':
                self.SelectMoney(username)
            elif login_operation_result == 'accout_details':
                self.AccoutDetails(username)
            elif login_operation_result=='save_money':
                self.SaveMoney(username)
            elif login_operation_result == 'take_money':
                self.TakeMoney(username)
            elif login_operation_result == 'transfer_account':
                self.TransferAccounts(username)
            elif login_operation_result == 'exit':
                accountlogin = AccountLogin()
                accountlogin.AccountExit(username)
if __name__ == '__main__':
    username = raw_input('\033[32;1mUsername:\033[0m')
    accountsavings = AccountSavings()
    accountsavings.AccountSavingsMain(username)

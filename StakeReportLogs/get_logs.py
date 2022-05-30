from traceback import print_tb
from sqlalchemy import true
from thor_requests.connect import Connect
from thor_requests.wallet import Wallet
from thor_requests.contract import Contract
from decouple import config
import requests
import json
import uuid
import os

#
#Connect to Veblocks and import the DHN contract
#
def init():
    print("------------------Connect to Veblocks------------------\n")
    connector = Connect("http://3.124.193.149:8669/")

    print("------------------IMPORT DHN CONTRACT------------------\n")
    #Get the contract ABI and the different addresses
    _contract = Contract.fromFile("./build/contracts/StakingRewards.json")
    DHN_STAKE_contract_addresses = ['0x08c73B33115Cafda73371A23A98ee354598A4aBe',
                                    '0x732C69E4cb74279E1a9A6f31764D2C4668e1cba1',
                                    '0xCD88063E5bdC4416370557987Fc7D15baa447B1d',
                                    '0xa2bae9d627A29aE6914c7D18afCcb27664d1b436']

    return connector, _contract, DHN_STAKE_contract_addresses

#
#Get balance
#
def write_JSON(connector,_contract, DHN_STAKE_contract_addresses):

    #Loop Variables
    stakes=[]
    tx_length=True
    i=-1
    #Loop while the response is a real tx
    while(tx_length):
        #increment
        i=i+1
        #Call balance function
        balance_one = connector.call(
        caller='0x0000000000000000000000000000000000000000', # fill in your caller address or all zero address
        contract=_contract,
        func_name="stakes",
        func_params=[i],
        to=DHN_STAKE_contract_addresses,
        )

        #If there is no saved struct for this index
        if balance_one['data']=='0x':
            #end loop
            tx_length = False
        else:
            #Remove unwanted things from 'decoded'section
            balance_one['decoded'].pop("0", None)
            balance_one['decoded'].pop("1", None)
            balance_one['decoded'].pop("2", None)
            balance_one['decoded'].pop("3", None)
            balance_one['decoded'].pop("4", None)

            #Add info to the decoded section
            result = balance_one['decoded']
            result['reverted']=balance_one['reverted']
            result['vmError']=balance_one['vmError']
            result['data']=balance_one['data']

            #otherwise add to array of Stake struct objects 
            stakes.append(result)
            
    return stakes


def main():
    #Init connection
    (connector,_contract, DHN_STAKE_contract_addresses)=init()

    #Files to write to
    json_files = ['./json_files/90d.json', './json_files/183d.json', './json_files/365d.json', './json_files/3j.json']
    print("------------------Writting JSON files------------------\n")
    
    # For each json file expecified
    for i in range(0,len(json_files)-1):

        open(json_files[i], 'w').close()

        #Init with the contract address corresponding to the time lock we want
        array_result = write_JSON(connector,_contract, DHN_STAKE_contract_addresses[i])

        #Loop variables
        n_stakes = len(array_result)
        my_dict = {}
        j=-1

        #Add the number of stakes to the beggining of the json file
        my_dict['Number_of_Stakes']= n_stakes
        #Add an index for each stake
        for obj in array_result:
            j=j+1
            my_dict[j]=obj

        # use json.dump to write the file
        with open(json_files[i], 'w') as file:
            json.dump(my_dict, file, indent=4)
    
    print("--------------------Writing finished-------------------")

main()




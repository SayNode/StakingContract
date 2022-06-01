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
    connector = Connect("https://mainnet.veblocks.net/")

    print("------------------IMPORT DHN CONTRACT------------------\n")
    DHN_contract_address = '0x0867dd816763BB18e3B1838D8a69e366736e87a1'
    #Get the contract ABI and the different addresses
    _contract = Contract.fromFile("./build/contracts/StakingRewards.json")
    DHN_STAKE_contract_addresses = ['0x08c73B33115Cafda73371A23A98ee354598A4aBe',
                                    '0x732C69E4cb74279E1a9A6f31764D2C4668e1cba1',
                                    '0xCD88063E5bdC4416370557987Fc7D15baa447B1d',
                                    '0xa2bae9d627A29aE6914c7D18afCcb27664d1b436']

    return connector, _contract, DHN_contract_address, DHN_STAKE_contract_addresses

#
# Get the latest block number
#
def latest_block():
    headers = {
    'accept': 'application/json',
    }

    response = requests.get('https://mainnet.veblocks.net/blocks/best', headers=headers)
    return response.json()["number"]

#
# Returns all unique reverted txs
#
def get_unique_rev_txs(connector,_contract, DHN_STAKE_contract_addresses):

    
    #Removes the "0x" from the address
    DHN_STAKE_contract_addresses[0] = DHN_STAKE_contract_addresses[0][2:]

    #Will store the voters addresses
    voters = []

    #Request headers
    headers = {
        'accept': 'application/json'
    }

    json_data = {
        "range": {
            "unit": "block",
            "from": 0,
            "to": 10000000000
        },
        "options": {
            "offset": 0,
            "limit": 10000000000
        },
        "criteriaSet": [
            {
                "topic0": "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
                "topic2": "0x000000000000000000000000"+DHN_STAKE_contract_addresses[0]
            }
        ],
        "order": "asc"
    }

    # Get all txs of money (aka votes) to the specific contract wallet
    #https://mainnet.veblocks.net/logs/transfer
    response = requests.post('https://mainnet.veblocks.net/logs/event', headers=headers, json=json_data)

    print(response.json()[37]['meta']['txID'])
    print(connector.replay_tx(response.json()[37]['meta']['txID']))
    print('\n')
    #print(response.json()[35]['meta']['txID'])
    #print(connector.replay_tx(response.json()[35]['meta']['txID']))

def main():
    #Init connection
    (connector, _contract, DHN_contract_address, DHN_STAKE_contract_addresses)=init()
    get_unique_rev_txs(connector,_contract, DHN_STAKE_contract_addresses)
    print("--------------------Writing finished-------------------")

main()




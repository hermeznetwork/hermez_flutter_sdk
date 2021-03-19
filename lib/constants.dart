const TRANSACTION_POOL_KEY = 'transactionPool';

const HERMEZ_ACCOUNT_ACCESS_MESSAGE =
    'Hermez Network account access.\n\nSign this message if you are in a trusted application only.';

const CREATE_ACCOUNT_AUTH_MESSAGE = 'Account creation';
const EIP_712_VERSION = '1';
const EIP_712_PROVIDER = 'Hermez Network';

const ETHER_TOKEN_ID = 0;

const GAS_LIMIT = 5000000;

const GAS_MULTIPLIER = 1;

const DEFAULT_PAGE_SIZE = 20;

//const BASE_API_URL = '192.168.1.134:8086';
/*const BASE_API_URL = '192.168.250.101:8086';

//const BASE_WEB3_URL = 'http://192.168.1.134:8545';
const BASE_WEB3_URL = 'http://192.168.250.101:8545';

//const BASE_WEB3_RDP_URL = 'wss://192.168.1.134:8545';
const BASE_WEB3_RDP_URL = 'wss://192.168.250.101:8545';*/

//const BATCH_EXPLORER_URL = '192.168.1.134:8080';
/*const BATCH_EXPLORER_URL = '192.168.250.101:8080';

const ETHERSCAN_URL = 'https://etherscan.io';*/

const ContractNames = {
  "Hermez": 'Hermez',
  "WithdrawalDelayer": 'WithdrawalDelayer'
};

final Map<String, String> contractAddresses = {
  ContractNames['Hermez']: '0x10465b16615ae36F350268eb951d7B0187141D3B',
  ContractNames['WithdrawalDelayer']:
      '0x8EEaea23686c319133a7cC110b840d1591d9AeE0'
};

const STORAGE_VERSION_KEY = 'hermezStorageVersion';
const STORAGE_VERSION = 1;

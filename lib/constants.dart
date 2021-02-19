const TRANSACTION_POOL_KEY = 'transactionPool';

const MASTER_SECRET =
    'HERMEZ_ACCOUNT. Don\'t share this signature with anyone as this would reveal your Hermez private key. Unless you are in a trusted application, DO NOT SIGN THIS';

const CREATE_ACCOUNT_AUTH_MESSAGE =
    'I authorize this babyjubjub key for hermez rollup account creation';

const ETHER_TOKEN_ID = 0;

const GAS_LIMIT = 5000000;

const GAS_MULTIPLIER = 1;

const Map<String, String> contractAddresses = {
  'Hermez': '0x10465b16615ae36F350268eb951d7B0187141D3B',
  'WithdrawalDelayer': '0x8EEaea23686c319133a7cC110b840d1591d9AeE0'
};

const DEFAULT_PAGE_SIZE = 20;

//const BASE_API_URL = '192.168.1.134:8086';
const BASE_API_URL = '192.168.250.102:8086';
const BASE_WEB3_URL = 'http://192.168.250.102:8545';
const BASE_WEB3_RDP_URL = 'wss://192.168.250.102:8545';
//const BASE_WEB3_URL = 'http://192.168.1.134:8545';
//const BASE_WEB3_RDP_URL = 'wss://192.168.1.134:8545';
//const BASE_API_URL = '167.71.59.190:4010';

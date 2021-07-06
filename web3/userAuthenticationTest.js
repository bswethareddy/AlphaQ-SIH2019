const constants = require('../constants.json');
const constants = require('./creatAccount.js');
const constants = require('../login.js');
const constants = require('../changePassword.js');

const Web3 = require('web3');

const web3 = new Web3(constants.rpcURL);
const contract = new web3.eth.Contract(constants.contractAbi, constants.contractAddress);

const username = 'ak72';
const password = 'helloSIH2020';
const privateKey = '0x279a399defe756657771ed1fefb6de84e95f01f09642fda726e2c733c901d763';

createAccount(username, password, privateKey).then((result) => {
    console.log(result);
}).catch((err) => {
    console.log(err);
});

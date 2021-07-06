const constants = require('../constants.json');

const crypto = require('crypto');
const Web3 = require('web3');

const web3 = new Web3(constants.rpcURL);
const contract = new web3.eth.Contract(constants.contractAbi, constants.contractAddress);

module.exports = async function changePassword(username, newPassword, privateKey) {
    let status = null;
    try {
        const salt = crypto.randomBytes(16).toString('base64');
        const hash = crypto.createHmac('sha512', salt).update(newPassword).digest("base64");
        const newPasswordHash = salt + "$" + hash;

        const newKeyStore = web3.eth.accounts.encrypt(privateKey, newPassword);

        const tx = {
            to: constants.contractAddress,
            value: web3.utils.toHex(web3.utils.toWei('0', 'ether')),
            gasLimit: web3.utils.toHex(3000000),
            gasPrice: web3.utils.toHex(web3.utils.toWei('10', 'gwei')),
            data: contract.methods.changePassword(username, newPasswordHash, JSON.stringify(newKeyStore)).encodeABI()
        }

        const signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);
        const sentTx = await web3.eth.sendSignedTransaction(signedTx.raw || signedTx.rawTransaction);
        status = constants.statusCode.SUCCESS.PASSWORD_CHANGED;
    } catch(err) {
        status = constants.statusCode.ERROR.NO_STATUS;
        console.log(err);
    } finally {
        return status;
    }
}

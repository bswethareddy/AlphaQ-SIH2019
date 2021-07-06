module.exports = async function createAccount(username, password, privateKey) {
    const constants = require('../constants.json');

    const crypto = require('crypto');
    const Web3 = require('web3');

    const web3 = new Web3(constants.rpcURL);
    const contract = new web3.eth.Contract(constants.contractAbi, constants.contractAddress);

    let status = null;
    try {
        const result = await contract.methods.usernameExists(username).call();
        if (result) {
            status = constants.statusCode.ERROR.USER_EXIST;
        } else {
            const salt = crypto.randomBytes(16).toString('base64');
            const hash = crypto.createHmac('sha512', salt).update(password).digest("base64");
            const passwordHash = salt + "$" + hash;

            const keyStore = web3.eth.accounts.encrypt(privateKey, password);

            const tx = {
                to: constants.contractAddress,
                value: web3.utils.toHex(web3.utils.toWei('0', 'ether')),
                gasLimit: web3.utils.toHex(3000000),
                gasPrice: web3.utils.toHex(web3.utils.toWei('10', 'gwei')),
                data: contract.methods.createAccount(username, passwordHash, JSON.stringify(keyStore)).encodeABI()
            }

            const signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);
            const sentTx = await web3.eth.sendSignedTransaction(signedTx.raw || signedTx.rawTransaction);
            status = constants.statusCode.SUCCESS.ACCOUNT_CREATED;
        }
    } catch(err) {
        status = constants.statusCode.ERROR.NO_STATUS;
        console.log(err);
    } finally {
        return status;
    }
}

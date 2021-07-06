module.exports = async function login(username, password) {
    let account = null;
    const constants = require('../constants.json');
    
    const crypto = require('crypto');
    const Web3 = require('web3');
    
    const web3 = new Web3(constants.rpcURL);
    const contract = new web3.eth.Contract(constants.contractAbi, constants.contractAddress);
    let status = null;

    try {
        const passHash = await contract.methods.fetchpassHash(username).call();
        const keyStore = await contract.methods.fetchencKey(username).call();

        const salt = passHash.split("$")[0];
        const newHash = salt + "$" + crypto.createHmac('sha512', salt).update(password).digest("base64");
        if (newHash === passHash) {
            account = web3.eth.accounts.decrypt(keyStore, password);
            status = constants.statusCode.SUCCESS.LOGIN_SUCCESS;
        } else {
            status = constants.statusCode.ERROR.WRONG_PASSWD;
        }
    } catch(err) {
        status = constants.statusCode.ERROR.NO_STATUS;
        console.log(err);
    } finally {
        console.log(status);
        return [status, account];
    }
}

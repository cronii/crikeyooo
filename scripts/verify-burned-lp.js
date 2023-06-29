const ethers = require('ethers');
const Crocswap = require('@crocswap-libs/sdk');

const CONFIG = require('./config.json');

const CRIKEY_ADDRESS = '';
const DEPLOYER_ADDRESS = '';
const BURN_ADDRESS = '';

// this script is used to verify that initial crikey/eth lp has been sent to burn address
// @TODO this script should mint initial LP and send to burn address as well as verify LP has been burned
(async () => {
  try {
    const provider = new ethers.providers.JsonRpcProvider(CONFIG.goerliRpc);
    const croc = new Crocswap.CrocEnv(provider);

    // check deployer and burn address for crikey/eth lp positions
    const crikeyPool = await croc.poolEth(CRIKEY_ADDRESS);
    const deployerPositions = new Crocswap.CrocPositionView(crikeyPool, DEPLOYER_ADDRESS);
    const burnAddressPositions = new Crocswap.CrocPositionView(crikeyPool, BURN_ADDRESS);
    console.log(await deployerPositions.queryAmbient());
    console.log(await burnAddressPositions.queryAmbient());
  } catch (err) {
    console.error(err);
  }
})();

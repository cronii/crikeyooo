const ethers = require('ethers');
const Crocswap = require('@crocswap-libs/sdk');

const CONFIG = require('./config.json');

const USDC = '0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C';

(async () => {
  try {
    const provider = new ethers.providers.JsonRpcProvider(CONFIG.rpc);
    const wallet = new ethers.Wallet(CONFIG.pkey, provider);
    // const croc = new Crocswap.CrocEnv(ethersProvider, ethersWallet);
    const croc = new Crocswap.CrocEnv('goerli', wallet);

    const pool = croc.poolEthQuote(USDC);
    console.log(await pool.spotPrice());
    console.log(await pool.cumAmbientGrowth());
  } catch (err) {
    console.error(err);
  }
})();

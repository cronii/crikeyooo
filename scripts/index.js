const ethers = require('ethers');
const Crocswap = require('@crocswap-libs/sdk');

const ERC20ABI = require('./abis/erc20.json');
const CONFIG = require('./config.json');

const USDC = '0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C';
const DAI = '0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60';

(async () => {
  try {
    // connect to goerli
    const provider = new ethers.providers.JsonRpcProvider(CONFIG.goerliRpc);

    // user 1
    const walletUser1 = new ethers.Wallet(CONFIG.pkey1, provider);
    const crocUser1 = new Crocswap.CrocEnv(provider, walletUser1);

    // user 2
    const walletUser2 = new ethers.Wallet(CONFIG.pkey2, provider);
    const crocUser2 = new Crocswap.CrocEnv(provider, walletUser2);

    // usdc
    const usdcContract = new ethers.Contract(USDC, ERC20ABI, provider);
    const balance1 = await usdcContract.balanceOf(CONFIG.address1);
    console.log(ethers.utils.formatUnits(balance1, 6));
    console.log(await usdcContract.balanceOf(CONFIG.address2));

    const usdcPool = crocUser1.poolEthQuote(USDC);
    console.log(await usdcPool.spotPrice());
    console.log(await usdcPool.cumAmbientGrowth());

    const daiPool = crocUser1.poolEthQuote(DAI);
    console.log(await daiPool.spotPrice());
    console.log(await daiPool.cumAmbientGrowth());

    // await crocUser1.sellEth(0.0001).for(DAI).swap();

    // const user1, user2

    // User1 mints a new LP with lpConduit set to User2
    // Assert User2 has control of LP
    // User2 burns the LP with lpConduit set to User1
    // Assert User1 now has the underlying asssets
  } catch (err) {
    console.error(err);
  }
})();

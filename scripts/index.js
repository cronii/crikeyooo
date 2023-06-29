const ethers = require('ethers');
const Crocswap = require('@crocswap-libs/sdk');

const ERC20ABI = require('./abis/erc20.json');
const CONFIG = require('./config.json');

const { formatEther, formatUnits } = ethers.utils;

// const ETH = ethers.constants.AddressZero;
const USDC = '0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C';
const { user1, user2 } = CONFIG;

(async () => {
  try {
    // connect to goerli
    const provider = new ethers.providers.JsonRpcProvider(CONFIG.goerliRpc);

    // user 1
    const walletUser1 = new ethers.Wallet(user1.pkey, provider);
    const crocUser1 = new Crocswap.CrocEnv(provider, walletUser1);

    // user 2
    const walletUser2 = new ethers.Wallet(user2.pkey, provider);
    const crocUser2 = new Crocswap.CrocEnv(provider, walletUser2);

    // check users initial usdc balances
    const usdcContract = new ethers.Contract(USDC, ERC20ABI, provider);
    const initialEthBalance1 = await provider.getBalance(user1.address);
    const initialUsdcBalance1 = await usdcContract.balanceOf(user1.address);
    const initialEthBalance2 = await provider.getBalance(user2.address);
    const initialUsdcBalance2 = await usdcContract.balanceOf(user2.address);

    console.log(`User1 ETH: ${formatEther(initialEthBalance1)}`);
    console.log(`User1 USDC: ${formatUnits(initialUsdcBalance1, 6)}`);
    console.log(`User2 ETH: ${formatEther(initialEthBalance2)}`);
    console.log(`User2 USDC: ${formatUnits(initialUsdcBalance2, 6)}`);

    // swap logic for getting some usdc to accounts -- run and wait for block confirmation
    // await crocUser1.sellEth(0.1).for(USDC).swap();
    // await crocUser2.sellEth(0.1).for(USDC).swap();

    // check users initial usdc/eth lp
    const usdcPoolView = await crocUser1.poolEth(USDC);
    const user1Positions = new Crocswap.CrocPositionView(usdcPoolView, user1.address);
    const user2Positions = new Crocswap.CrocPositionView(usdcPoolView, user2.address);
    console.log(await user1Positions.queryAmbient());
    console.log(await user2Positions.queryAmbient());

    // user 1 mints new usdc/eth ambient LP

    // User1 mints a new LP with lpConduit set to User2
    // Assert User2 has control of LP
    // User2 burns the LP with lpConduit set to User1
    // Assert User1 now has the underlying asssets
  } catch (err) {
    console.error(err);
  }
})();

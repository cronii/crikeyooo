const {
  createPublicClient,
  createWalletClient,
  http,
  encodeAbiParameters,
  parseEther,
  parseUnits
} = require('viem');
const { goerli } = require('viem/chains');
const { privateKeyToAccount } = require('viem/accounts');
const ethers = require('ethers');
const Crocswap = require('@crocswap-libs/sdk');

const ERC20ABI = require('./abis/erc20.json');
const CROCSWAP_ABI = require('./abis/croc.json');
const CONFIG = require('./config.json');

const { formatEther, formatUnits } = ethers.utils;

// goerli constants
const ETH = ethers.constants.AddressZero;
const USDC = '0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C';
const CROCSWAP_ADDRESS = '0xfAfcD1f5530827e7398B6D3C509f450b1b24a209';
const TEST_TOKEN = '0x30C454aAEa255bD902ABd942aE782C8Ed1C2b878';
const TEST_TOKEN_LP_CONDUIT = '0x420fC4631a71006f47253B3963552ceBA2da9A15';

// crocswap constants
const LP_PROXY = 2;
const MINT_AMBIENT_QUOTE_LP = 32n;
const POOL_IDX_GOERLI = 36000n;

const BURN_AMBIENT_LIQ_LP = 4;

const { user1, user2 } = CONFIG;

(async () => {
  try {
    // connect to goerli
    const provider = new ethers.providers.JsonRpcProvider(CONFIG.goerliRpc);

    const account = privateKeyToAccount(user1.pkey);
    const account2 = privateKeyToAccount(user2.pkey);
    const transport = http(CONFIG.goerliRpc);
    const publicClient = createPublicClient({
      chain: goerli,
      transport
    });
    const walletClient = createWalletClient({
      account,
      chain: goerli,
      transport
    });
    const walletClient2 = createWalletClient({
      account: account2,
      chain: goerli,
      transport
    });

    const walletUser = new ethers.Wallet(user1.pkey, provider);
    const croc = new Crocswap.CrocEnv(provider, walletUser);

    // check users initial usdc balances
    const testTokenContract = new ethers.Contract(TEST_TOKEN, ERC20ABI, provider);
    const initialEthBalance = await provider.getBalance(user1.address);
    const initialTestBalance = await testTokenContract.balanceOf(user1.address);

    console.log(`User ETH: ${formatEther(initialEthBalance)}`);
    console.log(`User TEST: ${formatUnits(initialTestBalance, 18)}`);

    // approve crocswap to use test token
    // await testTokenContract.connect(walletUser).approve(CROCSWAP_ADDRESS, initialTestBalance);

    // send some test token to user 2
    // await testTokenContract.connect(walletUser).transfer(user2.address, parseUnits('10', 18));

    // check users initial usdc/eth lp
    const testPoolView = await croc.poolEth(TEST_TOKEN);
    const userPosition = new Crocswap.CrocPositionView(testPoolView, user1.address);
    const stakingContractPosition = new Crocswap.CrocPositionView(testPoolView, TEST_TOKEN_LP_CONDUIT);
    // console.log(await userPosition.queryAmbient());
    // console.log(await stakingContractPosition.queryAmbient());

    // console.log(await croc.poolEth(USDC).spotPrice());
    // console.log(await croc.poolEth(USDC).displayPrice());
    // console.log(await croc.poolEth(TEST_TOKEN).spotPrice());
    // console.log(await croc.poolEth(TEST_TOKEN).displayPrice());

    // console.log(await croc.sellEth(0.01).for(TEST_TOKEN).calcImpact());
    // console.log(await croc.sell(TEST_TOKEN, 0.00000000001).forEth().calcImpact());

    // await croc.sell(TEST_TOKEN, 0.00000000001).forEth().swap();

    // const usdcPrice = await croc.poolEth(USDC).spotPrice();
    // console.log(Crocswap.encodeCrocPrice(usdcPrice).toString());
    // const testPrice = await croc.poolEth(TEST_TOKEN).spotPrice();
    // console.log(Crocswap.encodeCrocPrice(testPrice).toString());

    // await croc.poolEth(TEST_TOKEN).initPool(1000000);

    const value = parseEther('0.1');
    const testTokenValue = parseUnits('0.00001', 18);

    // mint ambient LP and send to LP conduit. receive LP tokens in return
    // const input = encodeAbiParameters([
    //   { name: 'code', type: 'uint8' },
    //   { name: 'base', type: 'address' },
    //   { name: 'quote', type: 'address' },
    //   { name: 'poolIdx', type: 'uint256' },
    //   { name: 'bidTick', type: 'int24' },
    //   { name: 'askTick', type: 'int24' },
    //   { name: 'liq', type: 'uint128' },
    //   { name: 'limitLower', type: 'uint128' },
    //   { name: 'limitHigher', type: 'uint128' },
    //   { name: 'reserveFlags', type: 'uint8' },
    //   { name: 'lpConduit', type: 'address' }],
    // [MINT_AMBIENT_QUOTE_LP, ETH, TEST_TOKEN, POOL_IDX_GOERLI, 0, 0, testTokenValue, 0n, 126087635650665562771554304n, 0n, TEST_TOKEN_LP_CONDUIT]);

    // const { request } = await publicClient.simulateContract({
    //   address: CROCSWAP_ADDRESS,
    //   abi: CROCSWAP_ABI,
    //   functionName: 'userCmd',
    //   args: [LP_PROXY, input],
    //   value,
    //   account
    // });

    // await walletClient.writeContract(request);

    // approve LP tokens for transfer
    // const lpConduitContract = new ethers.Contract(TEST_TOKEN_LP_CONDUIT, ERC20ABI, provider);
    // const lpConduitBalance = await lpConduitContract.balanceOf(user1.address);
    // await lpConduitContract.connect(walletUser).approve(CROCSWAP_ADDRESS, parseUnits('1', 18));

    // burn ambient LP
    // const input = encodeAbiParameters([
    //   { name: 'code', type: 'uint8' },
    //   { name: 'base', type: 'address' },
    //   { name: 'quote', type: 'address' },
    //   { name: 'poolIdx', type: 'uint256' },
    //   { name: 'bidTick', type: 'int24' },
    //   { name: 'askTick', type: 'int24' },
    //   { name: 'liq', type: 'uint128' },
    //   { name: 'limitLower', type: 'uint128' },
    //   { name: 'limitHigher', type: 'uint128' },
    //   { name: 'reserveFlags', type: 'uint8' },
    //   { name: 'lpConduit', type: 'address' }],
    // [BURN_AMBIENT_LIQ_LP, ETH, TEST_TOKEN, POOL_IDX_GOERLI, 0, 0, lpConduitBalance, 0n, 126087635650665562771554304n, 0n, TEST_TOKEN_LP_CONDUIT]);

    // const { request } = await publicClient.simulateContract({
    //   address: CROCSWAP_ADDRESS,
    //   abi: CROCSWAP_ABI,
    //   functionName: 'userCmd',
    //   args: [LP_PROXY, input],
    //   value: 0,
    //   account
    // });
    // await walletClient.writeContract(request);
  } catch (err) {
    console.error(err);
  }
})();

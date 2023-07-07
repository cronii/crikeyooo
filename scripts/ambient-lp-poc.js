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
const CROCSWAP_ADDRESS = '0xfAfcD1f5530827e7398B6D3C509f450b1b24a209';
const TEST_TOKEN = '0xa6024a169c2fc6bfd0feabee150b86d268aaf4ce';
const TEST_TOKEN_LP_CONDUIT = '0x4111edb29044B41F3a0EE318B417899086c613f3';

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

    const walletUser = new ethers.Wallet(user2.pkey, provider);
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
    console.log(await userPosition.queryAmbient());
    console.log(await stakingContractPosition.queryAmbient());

    // console.log(await croc.poolEth(USDC).spotPrice());
    // console.log(await croc.poolEth(USDC).displayPrice());
    // console.log(await croc.poolEth(TEST_TOKEN).spotPrice());
    // console.log(await croc.poolEth(TEST_TOKEN).displayPrice());

    // const usdcPrice = await croc.poolEth(USDC).spotPrice();
    // console.log(Crocswap.encodeCrocPrice(usdcPrice).toString());
    // const testPrice = await croc.poolEth(TEST_TOKEN).spotPrice();
    // console.log(Crocswap.encodeCrocPrice(testPrice).toString());

    // await croc.poolEth(TEST_TOKEN).initPool(0.1);
    // await walletClient.writeContract(request);

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
    const lpConduitContract = new ethers.Contract(TEST_TOKEN_LP_CONDUIT, ERC20ABI, provider);
    const lpConduitBalance = await lpConduitContract.balanceOf(user1.address);
    // await lpConduitContract.connect(walletUser).approve(CROCSWAP_ADDRESS, parseUnits('1', 18));

    // burn ambient LP
    const input = encodeAbiParameters([
      { name: 'code', type: 'uint8' },
      { name: 'base', type: 'address' },
      { name: 'quote', type: 'address' },
      { name: 'poolIdx', type: 'uint256' },
      { name: 'bidTick', type: 'int24' },
      { name: 'askTick', type: 'int24' },
      { name: 'liq', type: 'uint128' },
      { name: 'limitLower', type: 'uint128' },
      { name: 'limitHigher', type: 'uint128' },
      { name: 'reserveFlags', type: 'uint8' },
      { name: 'lpConduit', type: 'address' }],
    [BURN_AMBIENT_LIQ_LP, ETH, TEST_TOKEN, POOL_IDX_GOERLI, 0, 0, lpConduitBalance, 0n, 126087635650665562771554304n, 0n, TEST_TOKEN_LP_CONDUIT]);

    const { request } = await publicClient.simulateContract({
      address: CROCSWAP_ADDRESS,
      abi: CROCSWAP_ABI,
      functionName: 'userCmd',
      args: [LP_PROXY, input],
      value: 0,
      account
    });
    await walletClient.writeContract(request);
  } catch (err) {
    console.error(err);
  }
})();

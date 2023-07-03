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
const TEST_TOKEN_RANGE_LP_CONDUIT = '0xd97D770755C7f8ea1cbD6EA2D0C1A1EF3264e277';

// crocswap constants
const LP_PROXY = 2;
const POOL_IDX_GOERLI = 36000n;
const MINT_CONC_BASE = 11
const BURN_CONCENTRATED = 2;
const SLIPPAGE_TOLERANCE = 0.01;

const { user1 } = CONFIG;

(async () => {
  try {
    // connect to goerli
    const provider = new ethers.providers.JsonRpcProvider(CONFIG.goerliRpc);

    const account = privateKeyToAccount(user1.pkey);
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

    const walletUser = new ethers.Wallet(user1.pkey, provider);
    const croc = new Crocswap.CrocEnv(provider, walletUser);

    // check users initial test balances
    const testTokenContract = new ethers.Contract(TEST_TOKEN, ERC20ABI, provider);
    const initialEthBalance = await provider.getBalance(user1.address);
    const initialTestBalance = await testTokenContract.balanceOf(user1.address);

    console.log(`User ETH: ${formatEther(initialEthBalance)}`);
    console.log(`User TEST: ${formatUnits(initialTestBalance, 18)}`);

    // approve crocswap to use test token
    // await testTokenContract.connect(walletUser).approve(CROCSWAP_ADDRESS, initialTestBalance);

    // check users initial usdc/eth lp
    const testPoolView = await croc.poolEth(TEST_TOKEN);
    const userPosition = new Crocswap.CrocPositionView(testPoolView, user1.address);
    const lpConduitPosition = new Crocswap.CrocPositionView(testPoolView, TEST_TOKEN_RANGE_LP_CONDUIT);
    // console.log(await userPosition.queryAmbient());
    // console.log(await lpConduitPosition.queryAmbient());

    const spotPrice = await croc.poolEth(TEST_TOKEN).spotPrice();
    const lowerLimit = spotPrice * (1 - SLIPPAGE_TOLERANCE);
    const upperLimit = spotPrice * (1 + SLIPPAGE_TOLERANCE);
    console.log(spotPrice);

    const encodedPrice = Crocswap.encodeCrocPrice(spotPrice);
    const encodedLowerLimit = Crocswap.encodeCrocPrice(lowerLimit);
    const encodedUpperLimit = Crocswap.encodeCrocPrice(upperLimit);

    console.log(encodedPrice.toString());
    console.log(encodedLowerLimit.toString());
    console.log(encodedUpperLimit.toString());

    // await croc.poolEth(TEST_TOKEN).mintRangeBase(0.001, [-640000, 0], [4999, 5001]);
    // console.log(await userPosition.queryRangePos(-640000, 0));

    // await croc.poolEth(TEST_TOKEN).mintRangeBase(0.001, [-640000, -320000], [4999, 5001]);
    // console.log(await userPosition.queryRangePos(-640000, 0));
    // console.log(await userPosition.queryRangePos(-640000, 640000));

    // console.log(await userPosition.queryRangePos(-640000, -320000));
    console.log(await lpConduitPosition.queryRangePos(-640000, -320000));
    console.log(await testPoolView.spotTick())

    // const initUserBalance = await userPosition.queryRangePos(-640000, -320000);
    // console.log(initUserBalance.liq);
    // await croc.poolEth(TEST_TOKEN).burnRangeLiq(initUserBalance.liq, [-640000, -320000], [4999, 5001]);

    // const testPrice = await croc.poolEth(TEST_TOKEN).spotPrice();
    // console.log(Crocswap.encodeCrocPrice(testPrice).toString());

    // 0xa15112f9
    // 0000000000000000000000000000000000000000000000000000000000000002
    // 0000000000000000000000000000000000000000000000000000000000000040
    // 0000000000000000000000000000000000000000000000000000000000000160
    // 000000000000000000000000000000000000000000000000000000000000000b
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 000000000000000000000000a6024a169c2fc6bfd0feabee150b86d268aaf4ce
    // 0000000000000000000000000000000000000000000000000000000000008ca0
    // fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff63c00
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000000000000000000000038d7ea4c68000
    // 000000000000000000000000000000000000000000000001000346d6ff110000
    // 0000000000000000000000000000000000000000000000640000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000

    // 0xa15112f9
    // 0000000000000000000000000000000000000000000000000000000000000002
    // 0000000000000000000000000000000000000000000000000000000000000040
    // 0000000000000000000000000000000000000000000000000000000000000160
    // 000000000000000000000000000000000000000000000000000000000000000b
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 000000000000000000000000a6024a169c2fc6bfd0feabee150b86d268aaf4ce
    // 0000000000000000000000000000000000000000000000000000000000008ca0
    // fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff63c00
    // 000000000000000000000000000000000000000000000000000000000009c400
    // 000000000000000000000000000000000000000000000000000009184e72a000
    // 000000000000000000000000000000000000000000000046b274160800000000
    // 0000000000000000000000000000000000000000000000640000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000

    // 000000000000000000000000000000000000000000000000000000000000000b
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 000000000000000000000000a6024a169c2fc6bfd0feabee150b86d268aaf4ce
    // 0000000000000000000000000000000000000000000000000000000000008ca0
    // fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff63c00
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000000000000000000000038d7ea4c68000
    // 000000000000000000000000000000000000000000000046b274160800000000
    // 0000000000000000000000000000000000000000000000640000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 000000000000000000000000d97d770755c7f8ea1cbd6ea2d0c1a1ef3264e277

    // 0xa15112f9
    // 0000000000000000000000000000000000000000000000000000000000000002
    // 0000000000000000000000000000000000000000000000000000000000000040
    // 0000000000000000000000000000000000000000000000000000000000000160
    // 000000000000000000000000000000000000000000000000000000000000000b
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
    // 00000000000000000000000000000000000000000000000000000000000001a4
    // 00000000000000000000000000000000000000000000000000000000000304a0
    // 0000000000000000000000000000000000000000000000000000000000030cc0
    // 000000000000000000000000000000000000000000000000002386f26fc10000
    // 0000000000000000000000000000000000000000000057b37b1bbf4000000000
    // 000000000000000000000000000000000000000000005a5f7048bb3d00000000
    // 0000000000000000000000000000000000000000000000000000000000000001
    // 0000000000000000000000000000000000000000000000000000000000000000

    // burn
    // 0xa15112f9
    // 0000000000000000000000000000000000000000000000000000000000000002
    // 0000000000000000000000000000000000000000000000000000000000000040
    // 0000000000000000000000000000000000000000000000000000000000000160
    // 0000000000000000000000000000000000000000000000000000000000000002
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 000000000000000000000000a6024a169c2fc6bfd0feabee150b86d268aaf4ce
    // 0000000000000000000000000000000000000000000000000000000000008ca0
    // fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff63c00
    // fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb1e00
    // 0000000000000000000000000000000000000000000003c2a9ebc628b0ab1000
    // 000000000000000000000000000000000000000000000046b41f918a00000000
    // 000000000000000000000000000000000000000000000046b7be633400000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000

    // const testTokenValue = parseUnits('0.00001', 18);
    const liq = parseEther('0.02');
    const value = parseEther('0.02');

    // mint range LP and send to LP conduit. receive LP tokens in return
    const mintInput = encodeAbiParameters([
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
    [MINT_CONC_BASE, ETH, TEST_TOKEN, POOL_IDX_GOERLI, -640000, 80000, liq, encodedLowerLimit, encodedUpperLimit, 0n, TEST_TOKEN_RANGE_LP_CONDUIT]);

    const { request: mintRequest } = await publicClient.simulateContract({
      address: CROCSWAP_ADDRESS,
      abi: CROCSWAP_ABI,
      functionName: 'userCmd',
      args: [LP_PROXY, mintInput],
      value,
      account
    });

    await walletClient.writeContract(mintRequest);

    // approve LP tokens for transfer
    // const lpConduitContract = new ethers.Contract(TEST_TOKEN_RANGE_LP_CONDUIT, ERC20ABI, provider);
    // const lpConduitBalance = await lpConduitContract.balanceOf(user1.address);
    // await lpConduitContract.connect(walletUser).approve(CROCSWAP_ADDRESS, parseUnits('100000000', 18));

    // burn range LP
    // const burnInput = encodeAbiParameters([
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
    // [BURN_CONCENTRATED, ETH, TEST_TOKEN, POOL_IDX_GOERLI, -640000, -320000, 213096142761584080156672n, encodedLowerLimit, encodedUpperLimit, 0n, TEST_TOKEN_RANGE_LP_CONDUIT]);

    // const { request: burnRequest } = await publicClient.simulateContract({
    //   address: CROCSWAP_ADDRESS,
    //   abi: CROCSWAP_ABI,
    //   functionName: 'userCmd',
    //   args: [LP_PROXY, burnInput],
    //   value: 0,
    //   account
    // });

    // await walletClient.writeContract(burnRequest);
  } catch (err) {
    console.error(err);
  }
})();

// forge create CrikeyRangeLpConduit --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args 0x0000000000000000000000000000000000000000 0xa6024a169c2fc6bfd0feabee150b86d268aaf4ce 36000

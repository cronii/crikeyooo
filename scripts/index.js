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

// crocswap constants
const LP_PROXY = 2;
// const MINT_AMBIENT_LIQ_LP = 3;
// const MINT_AMBIENT_BASE_LP = 31;
const MINT_AMBIENT_QUOTE_LP = 32n;
const POOL_IDX_GOERLI = 36000n;

const { user1, user2 } = CONFIG;

(async () => {
  try {
    // connect to goerli
    const provider = new ethers.providers.JsonRpcProvider(CONFIG.goerliRpc);

    const account1 = privateKeyToAccount(user1.pkey);
    const account2 = privateKeyToAccount(user2.pkey);
    const transport = http(CONFIG.goerliRpc);
    const publicClient = createPublicClient({
      chain: goerli,
      transport
    });
    const walletClient1 = createWalletClient({
      account: account1,
      chain: goerli,
      transport
    });
    const walletClient2 = createWalletClient({
      account: account2,
      chain: goerli,
      transport
    });

    // user 1
    const walletUser1 = new ethers.Wallet(user1.pkey, provider);
    const crocUser1 = new Crocswap.CrocEnv(provider, walletUser1);

    // user 2
    // const walletUser2 = new ethers.Wallet(user2.pkey, provider);
    // const crocUser2 = new Crocswap.CrocEnv(provider, walletUser2);

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

    // 0xa15112f9
    // 0000000000000000000000000000000000000000000000000000000000000002 // callpath (LP proxy)
    // 0000000000000000000000000000000000000000000000000000000000000040
    // 0000000000000000000000000000000000000000000000000000000000000160
    // 000000000000000000000000000000000000000000000000000000000000000c // 12 - MINT_RANGE_QUOTE_LP
    // 0000000000000000000000000000000000000000000000000000000000000000 // base - ETH
    // 000000000000000000000000d87ba7a50b2e7e660f678a895e4b72e7cb4ccd9c // quote - USDC
    // 0000000000000000000000000000000000000000000000000000000000008ca0 // POOL_IDX_GOERLI
    // 000000000000000000000000000000000000000000000000000000000002fd00
    // 0000000000000000000000000000000000000000000000000000000000032480
    // 0000000000000000000000000000000000000000000000000000000026fb3f80
    // 0000000000000000000000000000000000000000000059e82b158f8300000000
    // 0000000000000000000000000000000000000000000059ecd680f46900000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000

    // 0xa15112f9
    // 0000000000000000000000000000000000000000000000000000000000000002
    // 0000000000000000000000000000000000000000000000000000000000000040
    // 0000000000000000000000000000000000000000000000000000000000000160
    // 0000000000000000000000000000000000000000000000000000000000000020
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 000000000000000000000000d87ba7a50b2e7e660f678a895e4b72e7cb4ccd9c
    // 0000000000000000000000000000000000000000000000000000000000008ca0
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000000000000000000000000000000186a0
    // 0000000000000000000000000000000000000000000027100000000000000000
    // 0000000000000000000000000000000000000000001594458ff7aee300000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000

    // 0xa15112f9
    // 0000000000000000000000000000000000000000000000000000000000000002
    // 0000000000000000000000000000000000000000000000000000000000000040
    // 0000000000000000000000000000000000000000000000000000000000000160
    // 0000000000000000000000000000000000000000000000000000000000000020
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 000000000000000000000000d87ba7a50b2e7e660f678a895e4b72e7cb4ccd9c
    // 0000000000000000000000000000000000000000000000000000000000008ca0
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 00000000000000000000000000000000000000000000000000000000000186a0
    // 0000000000000000000000000000000000000000000027100000000000000000
    // 0000000000000000000000000000000000000000001594458ff7aee300000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000

    // 0xa15112f9
    // 0000000000000000000000000000000000000000000000000000000000000002
    // 0000000000000000000000000000000000000000000000000000000000000040
    // 0000000000000000000000000000000000000000000000000000000000000160
    // 0000000000000000000000000000000000000000000000000000000000000020
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 000000000000000000000000d87ba7a50b2e7e660f678a895e4b72e7cb4ccd9c
    // 0000000000000000000000000000000000000000000000000000000000008ca0
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000989680
    // 0000000000000000000000000000000000000000000027100000000000000000
    // 0000000000000000000000000000000000000000001594458ff7aee300000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000005f6823421974fac6626b121f49a85eec5b404413

    const value = parseEther('0.2');
    const usdcValue = parseUnits('10', 6);

    console.log(value);

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
    [MINT_AMBIENT_QUOTE_LP, ETH, USDC, POOL_IDX_GOERLI, 0, 0, usdcValue, 184467440737095516160000n, 26087635650665562771554304, 0n, user2.address]);

    // console.log(input);

    // await usdcPoolView.mintAmbientQuote(0.1, [0.0000, 1]);
    // await crocUser1.poolEth(USDC).mintAmbientBase(0.0001, [0.0001, 2])
    // await crocUser1.poolEth(USDC).mintAmbientQuote(0.1, [0.0001, 2])
    const { request } = await publicClient.simulateContract({
      address: CROCSWAP_ADDRESS,
      abi: CROCSWAP_ABI,
      functionName: 'userCmd',
      args: [LP_PROXY, input],
      value: 200000000000000000n,
      account: account1
    });

    // await walletClient.writeContract(request);

    // approve usdc for transfer
    // const { request } = await publicClient.simulateContract({
    //   address: USDC,
    //   abi: ERC20ABI,
    //   functionName: 'approve',
    //   args: [CROCSWAP_ADDRESS, 100000000000],
    //   account: account1
    // });
    // await walletClient1.writeContract(request);

    // user 1 mints new usdc/eth ambient LP

    // User1 mints a new LP with lpConduit set to User2
    // Assert User2 has control of LP
    // User2 burns the LP with lpConduit set to User1
    // Assert User1 now has the underlying asssets
  } catch (err) {
    console.error(err);
  }
})();

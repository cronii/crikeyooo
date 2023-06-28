const ethers = require('ethers');
const Crocswap = require('@crocswap-libs/sdk');
// const { createPublicClient, webSocket } = require('viem');
// const { mainnet } = require('viem/chains');

const CONFIG = require('./config.json');

// const VERBOSE = true;

const QUERY_ADDRESS = '0xc2e1f740E11294C64adE66f69a1271C5B32004c8';
const QUERY_ABI = require('./abis/query.json');

const ETH = '0x0000000000000000000000000000000000000000';
const USDC = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48';
const USDT = '0xdac17f958d2ee523a2206206994597c13d831ec7';

// init ethers
const ethersProvider = new ethers.providers.JsonRpcProvider(CONFIG.rpc);
const ethersWallet = new ethers.Wallet(CONFIG.pkey, ethersProvider);
const croc = new Crocswap.CrocEnv(ethersProvider, ethersWallet);

const queryContract = {
  address: QUERY_ADDRESS,
  abi: QUERY_ABI
};

// init viem
// const transport = webSocket(CONFIG.wsRemote);
// const viemClient = createPublicClient({
//   chain: mainnet,
//   transport
// });

// client.watchBlocks({
//   onBlock: block => parseBlock(block)
// });

viemClient.watchBlockNumber({
  onBlockNumber: block => parseBlockNumber(block)
});

// function parseBlock(block) {
//   console.timeEnd('newBlock');
//   console.time('newBlock');
// }

async function parseBlockNumber(block) {
  console.log('Viem: New Block Number');
  const results = await viemClient.multicall({
    contracts: [
      {
        ...queryContract,
        functionName: 'queryPrice',
        args: [ETH, USDC, 420n]
      },
      {
        ...queryContract,
        functionName: 'queryPrice',
        args: [ETH, USDT, 420n]
      }
    ]
  });

  console.log(results);
  // if (results[0].result > results[1].result) {

  // } else if (results[1].result > results[0].result) {

  // }
}

// Bare minimum calls in order to calc if an arb is available
async function calcArb() {

}

// Subscribe to new block headers
ethersProvider.on('block', async (blockNumber) => {
  console.log(`Ethers: New Block: ${blockNumber}`);

  try {
    const poolUSDC = croc.poolEthQuote(USDC);
    const poolUSDT = croc.poolEthQuote(USDT);

    console.log(`USDC: ${await poolUSDC.displayPrice()}`);
    console.log(`USDT: ${await poolUSDT.displayPrice()}`);

    // ASSUMTION: USDC = USDT
    // ASSUMTION: ETH/USDC pool price is real price
    // ASSUMTION: ETH/USDT is the pool out of balance
    // balance USDT pool
    // if USDC > USDT, attempt to buy ETH
    // - calc ETH where USDT pool price after ~= USDC
    // - if ETH out - ETH gas cost > 0, execute buy
    // else USDT > USDC, attempt to sell ETH
    // - calc ETH where USDT pool price after ~= USDC
    // - if USDT out - ETH gas cost ($) > 0, execute sell

    console.log(await croc.sellEth(1).for(USDT, { slippage: 0.05 }).calcImpact())
  } catch (error) {
    console.error('Error occurred while processing block:', error);
  }
});

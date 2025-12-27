// lib/stacks.ts
// Stacks blockchain integration helpers for contract calls

import {
  makeContractCall,
  broadcastTransaction,
  AnchorMode,
  PostConditionMode,
  stringAsciiCV,
  uintCV,
  principalCV,
  FungibleConditionCode,
  makeStandardSTXPostCondition,
  makeContractSTXPostCondition,
} from '@stacks/transactions';
import { StacksTestnet, StacksMainnet } from '@stacks/network';

export type Network = 'mainnet' | 'testnet';

export function getNetwork(network: Network) {
  return network === 'mainnet' ? new StacksMainnet() : new StacksTestnet();
}

export async function callSwapSingleHop(
  network: Network,
  senderAddress: string,
  pairContract: string,
  aToB: boolean,
  amountIn: number,
  minAmountOut: number,
  deadline: number
) {
  const [contractAddress, contractName] = pairContract.split('.');
  
  const txOptions = {
    contractAddress,
    contractName: 'router',
    functionName: 'swap-single-hop',
    functionArgs: [
      principalCV(pairContract),
      aToB ? stringAsciiCV('true') : stringAsciiCV('false'),
      uintCV(amountIn),
      uintCV(minAmountOut),
      uintCV(deadline),
    ],
    senderKey: '', // Wallet will provide signature
    validateWithAbi: true,
    network: getNetwork(network),
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Deny,
  };

  const transaction = await makeContractCall(txOptions);
  const broadcastResponse = await broadcastTransaction(transaction, getNetwork(network));
  return broadcastResponse;
}

export async function callAddLiquidity(
  network: Network,
  senderAddress: string,
  pairContract: string,
  amountA: number,
  amountB: number
) {
  const [contractAddress, contractName] = pairContract.split('.');
  
  const txOptions = {
    contractAddress,
    contractName,
    functionName: 'mint-liquidity',
    functionArgs: [
      uintCV(amountA),
      uintCV(amountB),
    ],
    senderKey: '',
    validateWithAbi: true,
    network: getNetwork(network),
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Deny,
  };

  const transaction = await makeContractCall(txOptions);
  const broadcastResponse = await broadcastTransaction(transaction, getNetwork(network));
  return broadcastResponse;
}

export async function callRemoveLiquidity(
  network: Network,
  senderAddress: string,
  pairContract: string,
  lpAmount: number
) {
  const [contractAddress, contractName] = pairContract.split('.');
  
  const txOptions = {
    contractAddress,
    contractName,
    functionName: 'burn-liquidity',
    functionArgs: [
      uintCV(lpAmount),
    ],
    senderKey: '',
    validateWithAbi: true,
    network: getNetwork(network),
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Deny,
  };

  const transaction = await makeContractCall(txOptions);
  const broadcastResponse = await broadcastTransaction(transaction, getNetwork(network));
  return broadcastResponse;
}

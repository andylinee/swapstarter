'use client';

import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { formatUnits, parseUnits } from 'viem';
import { useState } from 'react';
import SwapTokenArtifact from '@/abis/SwapToken.json';

const TOKEN_A_ADDRESS = '0x4D266e17bC87DeAD84e379DCB2d58312eAF49398';
const TOKEN_B_ADDRESS = '0x20AC3dDAD105C31D3cF129E9f1beFe9C2F851D38';

export function TokenBalance() {
  const { address } = useAccount();
  const [transferAmount, setTransferAmount] = useState('');
  const [recipientAddress, setRecipientAddress] = useState('');
  const SwapTokenABI = SwapTokenArtifact.abi;

  // Read Token A balance
  const { data: tokenABalance } = useReadContract({
    address: TOKEN_A_ADDRESS,
    abi: SwapTokenABI,
    functionName: 'balanceOf',
    args: [address],
  });

  // Read Token B balance
  const { data: tokenBBalance } = useReadContract({
    address: TOKEN_B_ADDRESS,
    abi: SwapTokenABI,
    functionName: 'balanceOf',
    args: [address],
  });

  // Write contract - transfer tokens
  const { data: hash, writeContract, isPending } = useWriteContract();

  // Wait for transaction confirmation
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const handleTransfer = async (tokenAddress: `0x${string}`) => {
    if (!recipientAddress || !transferAmount) return;

    writeContract({
      address: tokenAddress,
      abi: SwapTokenABI,
      functionName: 'transfer',
      args: [recipientAddress as `0x${string}`, parseUnits(transferAmount, 18)],
    });
  };

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Token A Card */}
        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg shadow-lg p-6 text-white">
          <h3 className="text-sm opacity-80 mb-2">Token A Balance</h3>
          <p className="text-3xl font-bold">
            {tokenABalance ? formatUnits(tokenABalance as bigint, 18) : '0.0'}
          </p>
          <p className="text-xs opacity-80 mt-1">TKA</p>
        </div>

        {/* Token B Card */}
        <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg shadow-lg p-6 text-white">
          <h3 className="text-sm opacity-80 mb-2">Token B Balance</h3>
          <p className="text-3xl font-bold">
            {tokenBBalance ? formatUnits(tokenBBalance as bigint, 18) : '0.0'}
          </p>
          <p className="text-xs opacity-80 mt-1">TKB</p>
        </div>
      </div>

      {/* Transfer Section */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold mb-4">Transfer Tokens</h3>
        <div className="space-y-4">
          <input
            type="text"
            placeholder="Recipient address (0x...)"
            value={recipientAddress}
            onChange={(e) => setRecipientAddress(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500"
          />
          <input
            type="number"
            placeholder="Amount"
            value={transferAmount}
            onChange={(e) => setTransferAmount(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500"
          />
          <div className="flex gap-2">
            <button
              onClick={() => handleTransfer(TOKEN_A_ADDRESS)}
              disabled={isPending || isConfirming}
              className="flex-1 bg-blue-500 text-white px-4 py-2 rounded-lg hover:bg-blue-600 disabled:opacity-50"
            >
              {isPending || isConfirming ? 'Sending...' : 'Send Token A'}
            </button>
            <button
              onClick={() => handleTransfer(TOKEN_B_ADDRESS)}
              disabled={isPending || isConfirming}
              className="flex-1 bg-purple-500 text-white px-4 py-2 rounded-lg hover:bg-purple-600 disabled:opacity-50"
            >
              {isPending || isConfirming ? 'Sending...' : 'Send Token B'}
            </button>
          </div>
          {isSuccess && (
            <div className="text-green-600 text-sm">
              ✓ Transfer successful! View on{' '}
              <a
                href={`https://sepolia.etherscan.io/tx/${hash}`}
                target="_blank"
                rel="noopener noreferrer"
                className="underline"
              >
                Etherscan
              </a>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
